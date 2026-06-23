module main

import os
import qoi
import jxl
import png
import flag
import v.vmod
import dy_tea.wayland as wl

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
		u32(wl.ExtImageCopyCaptureManagerV1Options.paint_cursors)
	} else {
		0
	}
	if mut source_manager := state.ext_output_image_capture_source_manager_v1 {
		mut source := source_manager.create_source(output.wl_output) or {
			panic('create_source failed: ${err}')
		}
		if mut session_manager := state.ext_image_copy_capture_manager_v1 {
			mut session := session_manager.create_session(source, options) or {
				panic('create_session failed: ${err}')
			}
			capture.ext_image_copy_capture_session_v1 = session
			state.captures_by_sess[session.id] = capture
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
		u32(wl.ExtImageCopyCaptureManagerV1Options.paint_cursors)
	} else {
		0
	}
	if mut source_manager := state.ext_foreign_toplevel_image_capture_source_manager_v1 {
		mut source := source_manager.create_source(toplevel.handle) or {
			panic('create_source failed: ${err}')
		}
		if mut capture_manager := state.ext_image_copy_capture_manager_v1 {
			mut session := capture_manager.create_session(source, options) or {
				panic('create_session failed: ${err}')
			}
			capture.ext_image_copy_capture_session_v1 = session
			state.captures_by_sess[session.id] = capture
		}
		source.destroy() or {}
	}
	state.captures << capture
}

fn main() {
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
	freeze_screen_cmd := fp.string('freeze', `F`, '',
		'freeze the screen until passed command finishes or until the -g command finishes')
	additional_args := fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		return
	}
	if additional_args.len > 1 {
		eprintln('ERROR: more than one arg supplied')
		println(fp.usage())
	}

	output_filename := if additional_args.len < 1 {
		'out.${image_format}'
	} else {
		name := additional_args[0]
		if _, fmt := name.split_once('.') {
			if fmt != 'png' && fmt in supported_formats {
				image_format = fmt
			}
		}
		name
	}

	geometry_is_cmd := passed_geometry.starts_with('$') && !passed_geometry.starts_with('$-')
	mut geometry_cmd := ''
	if geometry_is_cmd {
		geometry_cmd = passed_geometry.trim_left('$')
		if freeze_screen_cmd != '' {
			panic('ERROR: cannot use both --freeze and command prefix in -g')
		}
	}
	mut geometry := Geometry{}

	if output_name != '' && geometry != Geometry{} {
		panic('ERROR: cannot specify both output and geometry')
	}
	if output_name != '' && toplevel_identifier != '' {
		panic('ERROR: cannot specify both output and toplevel')
	}

	handlers := make_event_handlers()

	mut display := wl.connect_to_display('') or { panic('Failed to connect to Wayland display') }
	display.get_registry() or { panic('Failed to get registry') }
	display.roundtrip() or { panic('wl_display_roundtrip failed') }

	mut state := State{
		display: display
	}

	init_globals(mut state)

	mut conn := display.connection()
	drain_pending(mut conn, mut state, &handlers)

	if mut list := state.ext_foreign_toplevel_list_v1 {
		state.ext_foreign_toplevel_list_v1 = list
		display.roundtrip() or { panic('wl_display_roundtrip failed') }
		drain_pending(mut conn, mut state, &handlers)
	}

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
	needs_freeze := freeze_screen_cmd != '' || geometry_is_cmd
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

	if mut manager := state.zxdg_output_manager_v1 {
		for mut output in state.outputs {
			xdg := manager.get_xdg_output(output.wl_output) or { continue }
			output.xdg_output = xdg
			state.outputs_by_id[xdg.id] = output
		}
	} else {
		println('note: xdg_output_manager_v1 not supported by compositor')
		for mut output in state.outputs {
			output.guess_logical_geometry()
		}
	}
	if state.zxdg_output_manager_v1 != none {
		display.roundtrip() or { panic('wl_display_roundtrip failed') }
		drain_pending(mut conn, mut state, &handlers)
	}

	if mut color_manager := state.wp_color_manager_v1 {
		for mut output in state.outputs {
			cm_output := color_manager.get_output(output.wl_output) or { continue }
			output.cm_output = cm_output
			state.outputs_by_id[cm_output.id] = output
			display.roundtrip() or { panic('wl_display_roundtrip failed') }
			drain_pending(mut conn, mut state, &handlers)
		}
	}

	if output_name != '' {
		matching := state.outputs.filter(fn [output_name] (o &Output) bool {
			return o.name == output_name
		})
		if matching.len != 1 {
			panic('ERROR: unrecognized output name `${output_name}`')
		}
		geometry = matching[0].logical_geometry
	}

	mut scale := 1.0
	if toplevel_identifier != '' {
		matching := state.toplevels.filter(fn [toplevel_identifier] (t &Toplevel) bool {
			return t.identifier == toplevel_identifier
		})
		if matching.len != 1 {
			panic('cannot find toplevel')
		}
		state.capture_toplevel(matching[0], include_cursor)
	} else {
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

	mut done := false
	expected_cm := if state.wp_color_manager_v1 != none { state.outputs.len } else { 0 }
	for !done {
		display.roundtrip() or { break }
		drain_pending(mut conn, mut state, &handlers)
		conn.flush() or {}
		done = state.n_done == state.captures.len && state.n_cm_done >= expected_cm
	}

	if geometry_is_cmd {
		mut overlays := []&Overlay{}
		for capture in state.captures {
			overlay := Overlay.new(capture)
			if mut layer_surface := overlay.layer_surface_v1 {
				state.overlays_by_id[layer_surface.id] = overlay
			}
			overlays << overlay
		}
		display.roundtrip() or {}
		drain_pending(mut conn, mut state, &handlers)

		result_ch := chan string{cap: 1}
		spawn fn (cmd string, ch chan string) {
			result := os.execute(cmd)
			ch <- result.output
		}(geometry_cmd, result_ch)

		mut cmd_output := <-result_ch

		for mut overlay in overlays {
			overlay.destroy()
		}

		geometry = Geometry.new(cmd_output.trim('\n')) or { panic('invalid geometry from command') }
	} else if freeze_screen_cmd != '' {
		mut overlays := []&Overlay{}
		for capture in state.captures {
			overlay := Overlay.new(capture)
			if mut layer_surface := overlay.layer_surface_v1 {
				state.overlays_by_id[layer_surface.id] = overlay
			}
			overlays << overlay
		}
		display.roundtrip() or {}
		drain_pending(mut conn, mut state, &handlers)

		ch := chan int{cap: 1}
		spawn fn (cmd string, result_ch chan int) {
			result := os.execute(cmd)
			result_ch <- result.exit_code
		}(freeze_screen_cmd, ch)

		exit_code := <-ch
		if exit_code != 0 {
			eprintln('freeze command exited with code ${exit_code}')
		}

		for mut overlay in overlays {
			overlay.destroy()
		}
	}

	if geometry == Geometry{0, 0, 0, 0} {
		geometry = state.get_extents()
	}

	fully_opaque := !state.captures.any(it.toplevel != none)

	image := render(&state, geometry, scale, fully_opaque) or { panic(err) }

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

	if output_filename == '-' {
		mut stdout := os.stdout()
		stdout.write(encoded) or { panic('Failed to write to stdout') }
	} else {
		os.write_bytes(output_filename, encoded) or {
			panic('Failed to write to file ${output_filename}')
		}
	}

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
	display.close() or {}
}
