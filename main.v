module main

import os
import qoi
import jxl
import png
import flag
import protocols.wayland as wlp
import protocols.ext_image_copy_capture_v1 as cc

#flag linux -lwayland-client
#include <wayland-client.h>
#include <wayland-client-protocol.h>

const mrpenishot_version = '1.0.0'
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

	// get geometry if passed
	mut geometry := if passed_geometry == '' {
		Geometry{}
	} else {
		Geometry.new(passed_geometry) or { panic('invalid geometry') }
	}

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
			if geometry != Geometry{} && !geometry.intersect(output.logical_geometry) {
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

	// dispatch captures
	mut done := false
	for !done && C.wl_display_dispatch(display_proxy) != -1 {
		done = state.n_done == state.captures.len
	}
	if geometry == Geometry{0, 0, 0, 0} {
		geometry = state.get_extents()
	}

	// render image
	image := render(&state, geometry, scale) or { panic(err) }

	// encode image
	encoded := match image_format {
		'png' {
			png.encode_png(image)!
		}
		'ppm' {
			encode_ppm(image)
		}
		'qoi' {
			qoi.encode_qoi(image)!
		}
		'jxl' {
			jxl.encode_jxl(image)!
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
	C.wl_display_disconnect(display_proxy)
}
