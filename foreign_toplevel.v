module main

import protocols.ext_foreign_toplevel_list_v1 as ft

fn foreign_toplevel_handle_identifier(mut toplevel Toplevel, obj voidptr, identifier &char) {
	toplevel.identifier = unsafe { identifier.vstring() }
}

const foreign_toplevel_listener = ft.extforeigntoplevelhandlev1_listener(none, none, none,
	none, foreign_toplevel_handle_identifier)

fn foreign_toplevel_list_handle_toplevel(mut state State, obj voidptr, toplevel_handle voidptr) {
	mut handle := &ft.ExtForeignToplevelHandleV1{
		proxy: toplevel_handle
	}
	toplevel := &Toplevel{
		handle: handle
	}
	handle.add_listener(&foreign_toplevel_listener, toplevel)
	state.toplevels << toplevel
}

const foreign_toplevel_list_listener = ft.extforeigntoplevellistv1_listener(foreign_toplevel_list_handle_toplevel,
	none)
