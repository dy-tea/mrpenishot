module main

import math
import protocols.wayland as wlp
import protocols.xdg_output_unstable_v1 as xo
import protocols.ext_image_copy_capture_v1 as cc
import protocols.ext_image_capture_source_v1 as cs
import protocols.ext_foreign_toplevel_list_v1 as ft

#flag linux -lwayland-client
#include <wayland-client.h>
#include <wayland-client-protocol.h>

fn xdg_output_handle_logical_position(mut output Output, _ &xo.ZxdgOutputV1, x int, y int) {
	output.logical_x = x
	output.logical_y = y
}

fn xdg_output_handle_logical_size(mut output Output, _ &xo.ZxdgOutputV1, width int, height int) {
	output.logical_width = width
	output.logical_height = height
}

fn xdg_output_handle_done(mut output Output, _ &xo.ZxdgOutputV1) {
	width, _ := transform_output(output.transform, output.mode_width, output.mode_height)
	output.logical_scale = f64(width) / output.logical_width
}

fn xdg_output_handle_name(mut output Output, _ &xo.ZxdgOutputV1, name &char) {
	if output.name == '' {
		output.name = unsafe { name.vstring() }
	}
}

const xdg_output_listener = C.zxdg_output_v1_listener{
	logical_position: xdg_output_handle_logical_position
	logical_size:     xdg_output_handle_logical_size
	done:             xdg_output_handle_done
	name:             xdg_output_handle_name
	description:      fn (_ voidptr, _ &xo.ZxdgOutputV1, _ &char) {}
}

fn output_handle_geometry(mut output Output, _ &wlp.WlOutput, x int, y int, _ int, _ int, _ int, _ &char, _ &char, transform int) {
	output.x = x
	output.y = y
	output.transform = unsafe { wlp.WlOutput_Transform(transform) }
}

fn output_handle_mode(mut output Output, _ &wlp.WlOutput, flags u32, width int, height int, _ int) {
	if flags & u32(wlp.WlOutput_Mode.current) != 0 {
		output.mode_width = width
		output.mode_height = height
	}
}

fn output_handle_scale(mut output Output, _ &wlp.WlOutput, factor int) {
	output.scale = factor
}

fn output_handle_name(mut output Output, _ &wlp.WlOutput, name &char) {
	output.name = unsafe { name.vstring() }
}

const output_listener = C.wl_output_listener{
	geometry:    output_handle_geometry
	mode:        output_handle_mode
	done:        fn (_ voidptr, _ &wlp.WlOutput) {}
	scale:       output_handle_scale
	name:        output_handle_name
	description: fn (_ voidptr, _ &wlp.WlOutput, _ &char) {}
}

fn registry_handle_global(mut state State, registry voidptr, name u32, iface &char, version u32) {
	interface_name := unsafe { iface.vstring() }

	match interface_name {
		wlp.wl_shm_interface_name {
			state.shm = &wlp.WlShm{state.registry.bind(name, wlp.wl_shm_interface_ptr(),
				version)}
		}
		wlp.wl_output_interface_name {
			mut output := &Output{
				state:     state
				scale:     1
				wl_output: &wlp.WlOutput{state.registry.bind(name, wlp.wl_output_interface_ptr(),
					math.min(version, 4))}
			}
			output.wl_output.add_listener(&output_listener, output)
			state.outputs << output
		}
		xo.zxdg_output_manager_v1_interface_name {
			bind_version := math.min(version, 2)
			state.zxdg_output_manager_v1 = &xo.ZxdgOutputManagerV1{state.registry.bind(name,
				xo.zxdg_output_manager_v1_interface_ptr(), bind_version)}
		}
		cs.ext_output_image_capture_source_manager_v1_interface_name {
			state.ext_output_image_capture_source_manager_v1 = &cs.ExtOutputImageCaptureSourceManagerV1{state.registry.bind(name,
				cs.ext_output_image_capture_source_manager_v1_interface_ptr(), 1)}
		}
		cs.ext_foreign_toplevel_image_capture_source_manager_v1_interface_name {
			state.ext_foreign_toplevel_image_capture_source_manager_v1 = &cs.ExtForeignToplevelImageCaptureSourceManagerV1{state.registry.bind(name,
				cs.ext_foreign_toplevel_image_capture_source_manager_v1_interface_ptr(),
				1)}
		}
		ft.ext_foreign_toplevel_list_v1_interface_name {
			state.ext_foreign_toplevel_list_v1 = &ft.ExtForeignToplevelListV1{state.registry.bind(name,
				ft.ext_foreign_toplevel_list_v1_interface_ptr(), 1)}
		}
		cc.ext_image_copy_capture_manager_v1_interface_name {
			state.ext_image_copy_capture_manager_v1 = &cc.ExtImageCopyCaptureManagerV1{state.registry.bind(name,
				cc.ext_image_copy_capture_manager_v1_interface_ptr(), 1)}
		}
		else {}
	}
}

const registry_listener = C.wl_registry_listener{
	global:        registry_handle_global
	global_remove: fn (_ voidptr, _ voidptr, _ u32) {}
}

fn main() {
	display_proxy := C.wl_display_connect(unsafe { nil })
	if display_proxy == unsafe { nil } {
		panic('Failed to connect to Wayland display')
	}

	mut display := &wlp.WlDisplay{
		proxy: display_proxy
	}

	mut state := State{
		display:  display
		registry: display.get_registry()
	}

	state.registry.add_listener(&registry_listener, &state)

	if C.wl_display_roundtrip(display_proxy) < 0 {
		panic('wl_display_roundtrip failed')
	}

	if state.shm == none {
		panic('wl_shm not supported by compositor')
	}

	if state.ext_output_image_capture_source_manager_v1 == none
		&& state.ext_image_copy_capture_manager_v1 == none {
		panic('ext_image_copy_capture_v1 and ext_output_image_capture_source_v1 not supported by compositor')
	}

	if state.outputs.len == 0 {
		panic('no outputs found')
	}

	println('init successful')

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

	C.wl_display_disconnect(display_proxy)
}
