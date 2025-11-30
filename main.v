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

fn registry_handle_global(mut state State, registry voidptr, name u32, iface &char, version u32) {
	interface_name := unsafe { iface.vstring() }

	match interface_name {
		wlp.wl_shm_interface_name {
			state.shm = &wlp.WlShm{state.registry.bind(name, wlp.wl_shm_interface_ptr(),
				version)}
		}
		wlp.wl_output_interface_name {
			// TODO: implement wl_output binding
			_ = math.min(version, 4)
		}
		xo.zxdg_output_manager_v1_interface_name {
			bind_version := math.min(version, 2)
			state.zxdg_output_manager_v1 = &xo.ZxdgOutputManagerV1{state.registry.bind(name,
				&xo.zxdg_output_v1_interface, bind_version)}
		}
		cs.ext_output_image_capture_source_manager_v1_interface_name {
			state.ext_output_image_capture_source_manager_v1 = &cs.ExtOutputImageCaptureSourceManagerV1{state.registry.bind(name,
				&cs.ext_output_image_capture_source_manager_v1_interface, 1)}
		}
		cs.ext_foreign_toplevel_image_capture_source_manager_v1_interface_name {
			state.ext_foreign_toplevel_image_capture_source_manager_v1 = &cs.ExtForeignToplevelImageCaptureSourceManagerV1{state.registry.bind(name,
				&cs.ext_foreign_toplevel_image_capture_source_manager_v1_interface, 1)}
		}
		ft.ext_foreign_toplevel_list_v1_interface_name {
			state.ext_foreign_toplevel_list_v1 = &ft.ExtForeignToplevelListV1{state.registry.bind(name,
				&ft.ext_foreign_toplevel_list_v1_interface, 1)}
		}
		cc.ext_image_copy_capture_manager_v1_interface_name {
			state.ext_image_copy_capture_manager_v1 = &cc.ExtImageCopyCaptureManagerV1{state.registry.bind(name,
				&cc.ext_image_copy_capture_manager_v1_interface, 1)}
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

	println('init successful')
}
