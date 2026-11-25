module main

import os
import qoi
import jxl
import png
import flag
import v.vmod
import wayland
import wayland.protocols.wayland as wl
import wayland.protocols.ext_image_copy_capture_v1 as cc
import wayland.protocols.ext_image_capture_source_v1 as cs
import wayland.protocols.ext_foreign_toplevel_list_v1 as ft
import wayland.protocols.xdg_output_unstable_v1 as xo
import wayland.protocols.viewporter as vp
import wayland.protocols.wlr_layer_shell_unstable_v1 as ls
import wayland.protocols.color_management_v1 as cm

const supported_formats = ['png', 'ppm', 'qoi', 'jxl']

fn (mut state State) capture_output(output &Output, include_cursor bool) {
	mut capture := &Capture{
		state:            &state
		output:           output
		transform:        output.transform
		logical_geometry: output.logical_geometry
	}
	state.captures << capture

	options := if include_cursor {
		u32(cc.ext_image_copy_capture_manager_v1_options_paint_cursors)
	} else {
		0
	}
	if mut source_manager := state.ext_output_image_capture_source_manager_v1 {
		mut source := source_manager.create_source(output.wl_output) or { return }
		if mut session_manager := state.ext_image_copy_capture_manager_v1 {
			mut session := session_manager.create_session(source, options) or { return }
			capture.ext_image_copy_capture_session_v1 = session
			session.set_listener(&SessionListener{
				capture: capture
			}) or {}
		}
		source.destroy() or {}
	}
}

fn (mut state State) capture_toplevel(toplevel &Toplevel, include_cursor bool) {
	mut capture := &Capture{
		state:    &state
		toplevel: &toplevel
	}
	options := if include_cursor {
		u32(cc.ext_image_copy_capture_manager_v1_options_paint_cursors)
	} else {
		0
	}
	if mut source_manager := state.ext_foreign_toplevel_image_capture_source_manager_v1 {
		mut source := source_manager.create_source(toplevel.handle) or { return }
		if mut capture_manager := state.ext_image_copy_capture_manager_v1 {
			mut session := capture_manager.create_session(source, options) or { return }
			capture.ext_image_copy_capture_session_v1 = session
			session.set_listener(&SessionListener{
				capture: capture
			}) or {}
		}
		source.destroy() or {}
	}
	state.captures << capture
}

fn main() {
	// parse args
	mut fp := flag.new_flag_parser(os.args)
	fp.application('mrpenishot')
	fp.version(vmod.decode(@VMOD_FILE)!.version)
	fp.skip_executable()
	mut image_format := fp.string('format', `f`, 'png', 'output image format ${supported_formats}')
	include_cursor := fp.bool('cursor', `c`, false, 'include cursor in resulting image')
	passed_geometry := fp.string('geometry', `g`, '', 'geometry in the format "400,500 200x300"')
	output_name := fp.string('output', `o`, '', 'name of output to screenshot')
	toplevel_identifier := fp.string('toplevel', `t`, '',
		'use a toplevel as the screenshot source by its identifier')
	freeze_raw := fp.string('freeze', `F`, '',
		'freeze the screen until passed command finishes or until the -g command finishes')
	freeze_screen_cmd := freeze_raw
	additional_args := fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		return
	}
	if additional_args.len > 1 {
		eprintln('ERROR: more than one arg supplied')
		println(fp.usage())
	}

	// get output filename if passed
	output_filename := if additional_args.len < 1 {
		'out.${image_format}'
	} else {
		name := additional_args[0]
		if _, fmt := name.split_once('.') {
			// if not default format and supported, update from file extension
			if fmt != 'png' && fmt in supported_formats {
				image_format = fmt
			}
		}
		name
	}

	// check if geometry needs command execution (prefix with $)
	geometry_is_cmd := passed_geometry.starts_with('$') && !passed_geometry.starts_with('$-')
	mut geometry_cmd := ''
	if geometry_is_cmd {
		mut cmd_str := passed_geometry.trim_left('$')
		// support command substitution syntax: $(cmd ...)
		if cmd_str.starts_with('(') && cmd_str.ends_with(')') && cmd_str.len >= 2 {
			cmd_str = cmd_str[1..cmd_str.len - 1]
		}
		geometry_cmd = cmd_str.trim_space()
		if freeze_screen_cmd.len > 0 {
			panic('ERROR: cannot use both --freeze and command prefix in -g')
		}
	}
	mut geometry := Geometry{}

	// mutual exclusion
	if output_name != '' && geometry != Geometry{} {
		panic('ERROR: cannot specify both output and geometry')
	}
	if output_name != '' && toplevel_identifier != '' {
		panic('ERROR: cannot specify both output and toplevel')
	}

	// init display
	mut conn := wayland.connect() or { panic('Failed to connect to Wayland display') }
	defer {
		conn.close()
	}

	globals := conn.globals() or { panic('Failed to get globals') }

	// init state
	mut state := State{
		conn: &conn
	}
	for g in globals {
		match g.interface {
			'wl_shm' {
				state.shm = wl.bind_wl_shm(conn, g) or { continue }
			}
			'wl_compositor' {
				state.compositor = wl.bind_wl_compositor(conn, g) or { continue }
			}
			'wl_output' {
				mut output := &Output{
					state:     &state
					scale:     1
					wl_output: wl.bind_wl_output(conn, g) or { continue }
				}
				output.wl_output.set_listener(&OutputListener{
					output: output
				}) or {}
				state.outputs << output
			}
			'wp_color_manager_v1' {
				state.wp_color_manager_v1 = cm.bind_wp_color_manager_v1(conn, g) or { continue }
			}
			'zxdg_output_manager_v1' {
				state.zxdg_output_manager_v1 = xo.bind_zxdg_output_manager_v1(conn, g) or { continue }
			}
			'ext_output_image_capture_source_manager_v1' {
				state.ext_output_image_capture_source_manager_v1 = cs.bind_ext_output_image_capture_source_manager_v1(conn, g) or { continue }
			}
			'ext_foreign_toplevel_image_capture_source_manager_v1' {
				state.ext_foreign_toplevel_image_capture_source_manager_v1 = cs.bind_ext_foreign_toplevel_image_capture_source_manager_v1(conn, g) or { continue }
			}
			'ext_foreign_toplevel_list_v1' {
				state.ext_foreign_toplevel_list_v1 = ft.bind_ext_foreign_toplevel_list_v1(conn, g) or { continue }
			}
			'ext_image_copy_capture_manager_v1' {
				state.ext_image_copy_capture_manager_v1 = cc.bind_ext_image_copy_capture_manager_v1(conn, g) or { continue }
			}
			'wp_viewporter' {
				state.wp_viewporter = vp.bind_wp_viewporter(conn, g) or { continue }
			}
			'zwlr_layer_shell_v1' {
				state.wlr_layer_shell_v1 = ls.bind_zwlr_layer_shell_v1(conn, g) or { continue }
			}
			else {}
		}
	}

	// roundtrip to receive wl_output events
	conn.roundtrip() or { panic('wl_display_roundtrip failed') }

	// add toplevel listener if available
	if mut list := state.ext_foreign_toplevel_list_v1 {
		list.set_listener(&ForeignToplevelListListener{
			state: &state
		}) or {}
		conn.roundtrip() or { panic('wl_display_roundtrip failed') }
	}

	// check for state init
	if state.shm == none {
		panic('wl_shm not supported by compositor')
	}
	if state.ext_output_image_capture_source_manager_v1 == none
		&& state.ext_image_copy_capture_manager_v1 == none {
		panic('ext_image_copy_capture_v1 and ext_output_image_capture_source_v1 not supported by compositor')
	}
	if toplevel_identifier != '' {
		if state.ext_foreign_toplevel_image_capture_source_manager_v1 == none {
			panic('ext_foreign_toplevel_image_capture_source_manager_v1 not supported, cannot capture toplevels')
		}
	}
	if state.outputs.len == 0 {
		panic('no outputs found')
	}
	needs_freeze := freeze_screen_cmd.len > 0 || geometry_is_cmd
	if needs_freeze {
		if state.compositor == none {
			panic('wl_compositor not supported by compositor')
		}
		if state.wp_viewporter == none {
			panic('wp_viewporter not supported by compositor')
		}
		if state.wlr_layer_shell_v1 == none {
			panic('zwlr_layer_shell_v1 not supported by compositor')
		}
	}

	// init output manager
	if mut manager := state.zxdg_output_manager_v1 {
		for mut output in state.outputs {
			output.xdg_output = manager.get_xdg_output(output.wl_output) or { continue }
			if mut xdg := output.xdg_output {
				xdg.set_listener(&XdgOutputListener{
					output: output
				}) or {}
			}
		}
	} else {
		println('note: xdg_output_manager_v1 not supported by compositor')
		for mut output in state.outputs {
			output.guess_logical_geometry()
		}
	}
	if state.zxdg_output_manager_v1 != none {
		conn.roundtrip() or { panic('wl_display_roundtrip failed') }
	}

	// init color management for outputs
	if mut color_manager := state.wp_color_manager_v1 {
		for mut output in state.outputs {
			mut cm_output := color_manager.get_output(output.wl_output) or { continue }
			output.cm_output = cm_output
			cm_output.set_listener(&CmOutputListener{
				state: &state
			}) or {}
			mut description := cm_output.get_image_description() or { continue }
			description.set_listener(&CmImageDescriptionListener{
				state: &state
			}) or {}
			conn.roundtrip() or { panic('wl_display_roundtrip failed') }
		}
	}

	// grab geometry from output name
	if output_name != '' {
		matching := state.outputs.filter(fn [output_name] (o Output) bool {
			return o.name == output_name
		})
		if matching.len != 1 {
			panic('ERROR: unrecognized output name `${output_name}`')
		}
		geometry = matching[0].logical_geometry
	}

	mut scale := 1.0
	if toplevel_identifier != '' {
		// capture toplevel
		matching := state.toplevels.filter(fn [toplevel_identifier] (t &Toplevel) bool {
			return t.identifier == toplevel_identifier
		})
		if matching.len != 1 {
			panic('cannot find toplevel')
		}
		state.capture_toplevel(matching[0], include_cursor)
	} else {
		// capture output
		for output in state.outputs {
			if !geometry_is_cmd && geometry != Geometry{}
				&& !geometry.intersect(output.logical_geometry) {
				continue
			}
			if output.logical_scale > scale {
				scale = output.logical_scale
			}
			state.capture_output(output, include_cursor)
		}
	}
	if state.captures.len == 0 {
		panic('no captures found')
	}

	// dispatch initial captures to get buffer data for overlays
	mut done := false
	expected_cm := if state.wp_color_manager_v1 != none { state.outputs.len } else { 0 }
	for !done {
		conn.dispatch() or { break }
		done = state.n_done == state.captures.len && state.n_cm_done >= expected_cm
	}

	// run geometry command with freeze
	if geometry_is_cmd {
		mut overlays := []&Overlay{}
		for capture in state.captures {
			overlay := Overlay.new(capture)
			overlays << overlay
		}

		// run command in background thread
		result_ch := chan string{cap: 1}
		spawn fn (cmd string, ch chan string) {
			result := os.exec(['sh', '-c', cmd])
			ch <- result.output
		}(geometry_cmd, result_ch)

		// process events while waiting for command
		mut cmd_output := ''
		for {
			conn.dispatch() or { break }
			conn.flush() or {}
			select {
				output := <-result_ch {
					cmd_output = output
					break
				}
			}
		}

		for mut overlay in overlays {
			overlay.destroy()
		}

		// get geometry from command output
		geometry = Geometry.new(cmd_output.trim('\n')) or { panic('invalid geometry from command') }
	} else if freeze_screen_cmd.len > 0 {
		mut overlays := []&Overlay{}
		for capture in state.captures {
			overlay := Overlay.new(capture)
			overlays << overlay
		}

		// run command in background thread
		ch := chan int{cap: 1}
		spawn fn (cmd string, result_ch chan int) {
			result := os.exec(['sh', '-c', cmd])
			result_ch <- result.exit_code
		}(freeze_screen_cmd, ch)

		// process events while waiting for command
		for {
			conn.dispatch() or { break }
			conn.flush() or {}
			select {
				exit_code := <-ch {
					if exit_code != 0 {
						eprintln('freeze command exited with code ${exit_code}')
					}
					break
				}
			}
		}

		for mut overlay in overlays {
			overlay.destroy()
		}
	}

	// get default geometry if none provided
	if geometry == Geometry{0, 0, 0, 0} {
		geometry = state.get_extents()
	}

	// opacity only needed if there are toplevels
	fully_opaque := !state.captures.any(it.toplevel != none)

	// render image
	image := render(&state, &geometry, scale, fully_opaque) or { panic(err) }

	// encode image
	encoded := match image_format {
		'png' {
			png.encode_png(image, fully_opaque, state.is_hdr)!
		}
		'ppm' {
			encode_ppm(image, state.is_hdr)
		}
		'qoi' {
			qoi.encode_qoi(image, fully_opaque, state.is_hdr)!
		}
		'jxl' {
			jxl.encode_jxl(image, fully_opaque, state.is_hdr)!
		}
		else {
			panic('ERROR: unrecognized image format `${image_format}` not in ${supported_formats}')
		}
	}

	// write to file or stdout
	if output_filename == '-' {
		mut stdout := os.stdout()
		stdout.write(encoded) or { panic('Failed to write to stdout') }
	} else {
		os.write_bytes(output_filename, encoded) or {
			panic('Failed to write to file ${output_filename}')
		}
	}

	// destroy
	C.pixman_image_unref(image)
	for mut capture in state.captures {
		if mut frame := capture.ext_image_copy_capture_frame_v1 {
			frame.destroy() or {}
		}
		if mut session := capture.ext_image_copy_capture_session_v1 {
			session.destroy() or {}
		}
		if mut buffer := capture.buffer {
			buffer.destroy()
		}
	}
	for mut output in state.outputs {
		if mut xdg := output.xdg_output {
			xdg.destroy() or {}
		}
		if mut cm_output := output.cm_output {
			cm_output.destroy() or {}
		}
		output.wl_output.release() or {}
	}
	for mut toplevel in state.toplevels {
		toplevel.handle.destroy() or {}
	}
	if mut manager := state.ext_foreign_toplevel_list_v1 {
		manager.destroy() or {}
	}
	if mut manager := state.ext_output_image_capture_source_manager_v1 {
		manager.destroy() or {}
	}
	if mut manager := state.ext_foreign_toplevel_image_capture_source_manager_v1 {
		manager.destroy() or {}
	}
	if mut manager := state.ext_image_copy_capture_manager_v1 {
		manager.destroy() or {}
	}
	if mut manager := state.zxdg_output_manager_v1 {
		manager.destroy() or {}
	}
	if mut manager := state.wp_viewporter {
		manager.destroy() or {}
	}
}
