module main

import os
import qoi
import jxl
import png
import flag
import protocols.wayland as wlp
import protocols.ext_image_copy_capture_v1 as cc

#pkgconfig wayland-client

const mrpenishot_version = '1.2.0'
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
		u32(cc.ExtImageCopyCaptureManagerV1_Options.paint_cursors)
	} else {
		0
	}
	if mut source_manager := state.ext_output_image_capture_source_manager_v1 {
		mut source := source_manager.create_source(output.wl_output.proxy)
		if mut session_manager := state.ext_image_copy_capture_manager_v1 {
			mut session := session_manager.create_session(source.proxy, options)
			capture.ext_image_copy_capture_session_v1 = session
			session.add_listener(&session_listener, capture)
		}
		source.destroy()
	}
}

fn (mut state State) capture_toplevel(toplevel &Toplevel, include_cursor bool) {
	mut capture := &Capture{
		state:    &state
		toplevel: &toplevel
	}
	options := if include_cursor {
		u32(cc.ExtImageCopyCaptureManagerV1_Options.paint_cursors)
	} else {
		0
	}
	if mut source_manager := state.ext_foreign_toplevel_image_capture_source_manager_v1 {
		mut source := source_manager.create_source(toplevel.handle.proxy)
		if mut capture_manager := state.ext_image_copy_capture_manager_v1 {
			mut session := capture_manager.create_session(source.proxy, options)
			capture.ext_image_copy_capture_session_v1 = session
			session.add_listener(&session_listener, capture)
		}
		source.destroy()
	}
	state.captures << capture
}

fn main() {
	// parse args
	mut fp := flag.new_flag_parser(os.args)
	fp.application('mrpenishot')
	fp.version(mrpenishot_version)
	fp.skip_executable()
	mut image_format := fp.string('format', `f`, 'png', 'output image format ${supported_formats}')
	include_cursor := fp.bool('cursor', `c`, false, 'include cursor in resulting image')
	passed_geometry := fp.string('geometry', `g`, '', 'geometry in the format "400,500 200x300"')
	output_name := fp.string('output', `o`, '', 'name of output to screenshot')
	toplevel_identifier := fp.string('toplevel', `t`, '', 'use a toplevel as the screenshot source by its identifier')
	freeze_screen_cmd := fp.string('freeze', `F`, '', 'freeze the screen until passed command finishes or until the -g command finishes')
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
		geometry_cmd = passed_geometry.trim_left('$')
		if freeze_screen_cmd != '' {
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
	display_proxy := C.wl_display_connect(unsafe { nil })
	if display_proxy == unsafe { nil } {
		panic('Failed to connect to Wayland display')
	}
	mut display := &wlp.WlDisplay{
		proxy: display_proxy
	}

	// init state
	mut state := State{
		display:  display
		registry: display.get_registry()
	}
	state.registry.add_listener(&registry_listener, &state)
	if C.wl_display_roundtrip(display_proxy) < 0 {
		panic('wl_display_roundtrip failed')
	}

	// add toplevel listener if available
	if mut list := state.ext_foreign_toplevel_list_v1 {
		list.add_listener(&foreign_toplevel_list_listener, &state)
		if C.wl_display_roundtrip(display_proxy) < 0 {
			panic('wl_display_roundtrip failed')
		}
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

	// init output manager
	if mut manager := state.zxdg_output_manager_v1 {
		for mut output in state.outputs {
			output.xdg_output = manager.get_xdg_output(output.wl_output.proxy)
			if mut xdg := output.xdg_output {
				xdg.add_listener(&xdg_output_listener, output)
			}
		}
	} else {
		println('note: xdg_output_manager_v1 not supported by compositor')
		for mut output in state.outputs {
			output.guess_logical_geometry()
		}
	}
	if state.zxdg_output_manager_v1 != none {
		if C.wl_display_roundtrip(display_proxy) < 0 {
			panic('wl_display_roundtrip failed')
		}
	}

	// init color management for outputs
	if mut color_manager := state.wp_color_manager_v1 {
		for mut output in state.outputs {
			mut cm_output := color_manager.get_output(output.wl_output.proxy)
			cm_output.add_listener(&cm_output_listener, state)
			mut description := cm_output.get_image_description()
		    description.add_listener(&cm_image_description_listener, output.state)
		    if C.wl_display_roundtrip(display_proxy) < 0 {
			    panic('wl_display_roundtrip failed')
		    }
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
			if !geometry_is_cmd && geometry != Geometry{} && !geometry.intersect(output.logical_geometry) {
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
	for !done && C.wl_display_dispatch(display_proxy) != -1{
		done = state.n_done == state.captures.len && state.n_cm_done >= expected_cm
	}

	// run geometry command with freeze
	if geometry_is_cmd {
		mut geometry_cmd_overlays := []&Overlay{}
		for capture in state.captures {
			overlay := Overlay.new(capture)
			geometry_cmd_overlays << overlay
		}

		// run command in background thread
		result_ch := chan string{cap: 1}
		spawn fn (cmd string, ch chan string) {
			result := os.execute(cmd)
			ch <- result.output
		}(geometry_cmd, result_ch)

		// process Wayland events while waiting for command
		mut cmd_output := ''
		for {
			C.wl_display_dispatch(display_proxy)
			C.wl_display_flush(display_proxy)
			select {
				output := <-result_ch {
					cmd_output = output
					break
				}
			}
		}
		for mut overlay in geometry_cmd_overlays {
			overlay.destroy()
		}
		geometry = Geometry.new(cmd_output.trim('\n')) or { panic('invalid geometry from command') }
		state.captures = []
		state.n_done = 0
		state.n_cm_done = 0
		for output in state.outputs {
			if geometry != Geometry{} && !geometry.intersect(output.logical_geometry) {
				continue
			}
			if output.logical_scale > scale {
				scale = output.logical_scale
			}
			state.capture_output(output, include_cursor)
		}
		if state.captures.len == 0 {
			panic('no captures found after geometry command')
		}
		// re-dispatch for new captures
		done = false
		for !done && C.wl_display_dispatch(display_proxy) != -1{
			done = state.n_done == state.captures.len && state.n_cm_done >= expected_cm
		}
	}

	// freeze screen overlay
	mut overlays := []&Overlay{}
	if freeze_screen_cmd != '' {
		for capture in state.captures {
			overlay := Overlay.new(capture)
			overlays << overlay
		}

		// run command in background thread
		ch := chan int{cap: 1}
		spawn fn (cmd string, result_ch chan int) {
			result := os.execute(cmd)
			result_ch <- result.exit_code
		}(freeze_screen_cmd, ch)

		// process events while waiting for command
		for {
			C.wl_display_dispatch(display_proxy)
			C.wl_display_flush(display_proxy)
			select {
				exit_code := <-ch {
					for mut overlay in overlays {
						overlay.destroy()
					}
					if exit_code != 0 {
						eprintln('freeze command exited with code ${exit_code}')
					}
					break
				}
			}
		}
	}
	if geometry == Geometry{0, 0, 0, 0} {
		geometry = state.get_extents()
	}

	// opacity only needed if there are toplevels
	fully_opaque := !state.captures.any(it.toplevel != none)

	// render image
	image := render(&state, geometry, scale, fully_opaque) or { panic(err) }

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
		os.write_bytes(output_filename, encoded) or { panic('Failed to write to file ${output_filename}') }
	}

	// destroy
	C.pixman_image_unref(image)
	for mut capture in state.captures {
		if mut frame := capture.ext_image_copy_capture_frame_v1 {
			frame.destroy()
		}
		if mut session := capture.ext_image_copy_capture_session_v1 {
			session.destroy()
		}
		if mut buffer := capture.buffer {
			buffer.destroy()
		}
	}
	for mut output in state.outputs {
		if mut xdg := output.xdg_output {
			xdg.destroy()
		}
		if mut cm_output := output.cm_output {
			cm_output.destroy()
		}
		output.wl_output.release()
	}
	for mut toplevel in state.toplevels {
		toplevel.handle.destroy()
	}
	if mut manager := state.ext_foreign_toplevel_list_v1 {
		manager.destroy()
	}
	if mut manager := state.ext_output_image_capture_source_manager_v1 {
		manager.destroy()
	}
	if mut manager := state.ext_foreign_toplevel_image_capture_source_manager_v1 {
		manager.destroy()
	}
	if mut manager := state.ext_image_copy_capture_manager_v1 {
		manager.destroy()
	}
	if mut manager := state.zxdg_output_manager_v1 {
		manager.destroy()
	}
	if mut manager := state.wp_viewporter {
		manager.destroy()
	}
	C.wl_display_disconnect(display_proxy)
}
