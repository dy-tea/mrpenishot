module main

import protocols.ext_foreign_toplevel_list_v1 as ft

fn foreign_toplevel_handle_identifier(mut toplevel &Toplevel, toplevel_handle voidptr, identifier &char) {
	toplevel.identifier = unsafe { identifier.vstring() }
}

const foreign_toplevel_listener = C.ext_foreign_toplevel_handle_v1_listener{
	closed:     fn (_ voidptr, _ voidptr) {}
	done:       fn (_ voidptr, _ voidptr) {}
	title:      fn (_ voidptr, _ voidptr, _ &char) {}
	app_id:     fn (_ voidptr, _ voidptr, _ &char) {}
	identifier: foreign_toplevel_handle_identifier
}

fn foreign_toplevel_list_handle_toplevel(mut state &State, list voidptr, toplevel_handle voidptr) {
	mut handle := &ft.ExtForeignToplevelHandleV1{
		proxy: toplevel_handle
	}
	toplevel := &Toplevel{
		handle: handle
	}
	handle.add_listener(&foreign_toplevel_listener, toplevel)
	state.toplevels << toplevel
}

const foreign_toplevel_list_listener = C.ext_foreign_toplevel_list_v1_listener{
	toplevel: foreign_toplevel_list_handle_toplevel
	finished: fn (_ voidptr, _ voidptr) {}
}
