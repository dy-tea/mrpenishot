module main

import flag
import wl

fn handle_global(data voidptr, registry &C.wl_registry, name u32, interface_ &char, version u32) {
	println('aboba')
}

const registry_listener = C.wl_registry_listener {
	handle_global,
	fn (_ voidptr, _ &C.wl_registry, name u32) {}
}

fn main() {
	display := C.wl_display_connect(voidptr(0))
	registry := C.wl_display_get_registry(display)
	C.wl_registry_add_listener(registry, &registry_listener, voidptr(0))
	if C.wl_display_roundtrip(display) < 0 {
		panic('wl_display_roundtrip failed')
	}
}
