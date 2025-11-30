module main

import math
import protocols.wayland as wlp
import protocols.xdg_output_unstable_v1 as xo

#flag linux -lwayland-client
#include <wayland-client.h>
#include <wayland-client-protocol.h>

// fn handle_global(mut state State, registry &C.wl_registry, name u32, interface_ &char, version u32) {
// interface_name := unsafe { interface_.vstring() }
// match interface_name {
//	'wl_shm' {
//		shm := wlp.wl_shm_interface
//		//shm := C.wl_registry_bind(registry, name, &C.wl_shm_interface, 1)
//		state.shm = registry.bind(name, wlp.wl_shm_interface, 1)
//	}
//	'wl_output' {
//		bind_version := math.min(version, 4)
//		output := &Output{
//			state:     state
//			wl_output: C.wl_registry_bind(registry, name, &C.wl_output_interface,
//				bind_version)
//			scale:     1
//		}
//		// C.wl_output_add_listener(output.output, &output_listener, output)
//		// add to outputs list
//	}
//	'zxdg_output_manager_v1' {
//		bind_version := math.min(version, 2)
//		manager := C.wl_registry_bind(registry, name, &C.zxdg_output_manager_v1_interface,
//			bind_version)
//		state.zxdg_output_manager_v1 = manager
//	}
//	'ext_output_image_capture_source_manager_v1' {
//		manager := C.wl_registry_bind(registry, name, &C.ext_output_image_capture_source_manager_v1_interface,
//			1)
//		state.ext_output_image_capture_source_manager_v1 = manager
//	}
//	'ext_foreign_toplevel_image_capture_source_manager_v1' {
//		manager := C.wl_registry_bind(registry, name, &C.ext_foreign_toplevel_image_capture_source_manager_v1_interface,
//			1)
//		state.ext_foreign_toplevel_image_capture_source_manager_v1 = manager
//	}
//	'ext_image_copy_capture_manager_v1' {
//		manager := C.wl_registry_bind(registry, name, &C.ext_image_copy_capture_manager_v1_interface,
//			1)
//		state.ext_image_copy_capture_manager_v1 = manager
//	}
//	else {
//		// println(interface_name)
//	}
//}
//}

// Registry listener callback functions
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
