module main

import protocols.ext_foreign_toplevel_list_v1 as ft

fn foreign_toplevel_handle_identifier(data voidptr, obj voidptr, identifier &char) {
	mut toplevel := unsafe { &Toplevel(data) }
	toplevel.identifier = unsafe { identifier.vstring() }
}

const foreign_toplevel_listener = ft.extforeigntoplevelhandlev1_listener(
	none, // closed
	none, // done
	none, // title
	none, // app_id
	foreign_toplevel_handle_identifier // identifier
)

fn foreign_toplevel_list_handle_toplevel(data voidptr, obj voidptr, toplevel_handle voidptr) {
	mut state := unsafe { &State(data) }
	mut handle := &ft.ExtForeignToplevelHandleV1{
		proxy: toplevel_handle
	}
	toplevel := &Toplevel{
		handle: handle
	}
	handle.add_listener(&foreign_toplevel_listener, toplevel)
	state.toplevels << toplevel
}

const foreign_toplevel_list_listener = ft.extforeigntoplevellistv1_listener(
	foreign_toplevel_list_handle_toplevel, // toplevel
	none // finished
)
