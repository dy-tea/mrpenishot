module main

import flag
import wl
import math
import protocols as pt

fn handle_global(mut state State, registry &C.wl_registry, name u32, interface_ &char, version u32) {
	interface_name := unsafe { interface_.vstring() }
	match interface_name {
		'wl_shm' {
			shm := C.wl_registry_bind(registry, name, &C.wl_shm_interface, 1)
			state.shm = shm
		}
		'zxdg_output_manager_v1' {
			bind_version := math.min(version, 2)
			output_manager := C.wl_registry_bind(registry, name, &C.zxdg_output_manager_v1_interface,
				bind_version)
			state.zxdg_output_manager_v1 = output_manager
		}
		else {
			// println(interface_name)
		}
	}
}

const registry_listener = C.wl_registry_listener{handle_global, fn (_ voidptr, _ &C.wl_registry, name u32) {}}

fn main() {
	mut display := C.wl_display_connect(unsafe { nil })
	mut state := State{
		display:  display
		registry: C.wl_display_get_registry(display)
	}
	C.wl_registry_add_listener(state.registry, &registry_listener, &state)

	if C.wl_display_roundtrip(display) < 0 {
		panic('wl_display_roundtrip failed')
	}

	if state.shm == none {
		panic('wl_shm not supported by compositor')
	}

	println('init successful')
}
