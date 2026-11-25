module main

import wayland.protocols.ext_foreign_toplevel_list_v1 as ft

struct ForeignToplevelListener {
mut:
	toplevel &Toplevel
}

fn (mut l ForeignToplevelListener) closed(_ ft.ExtForeignToplevelHandleV1) {
}

fn (mut l ForeignToplevelListener) done(_ ft.ExtForeignToplevelHandleV1) {
}

fn (mut l ForeignToplevelListener) title(_ ft.ExtForeignToplevelHandleV1, _ string) {
}

fn (mut l ForeignToplevelListener) app_id(_ ft.ExtForeignToplevelHandleV1, _ string) {
}

fn (mut l ForeignToplevelListener) identifier(_ ft.ExtForeignToplevelHandleV1, identifier string) {
	l.toplevel.identifier = identifier
}

struct ForeignToplevelListListener {
mut:
	state &State
}

fn (mut l ForeignToplevelListListener) toplevel(_ ft.ExtForeignToplevelListV1, toplevel_handle ft.ExtForeignToplevelHandleV1) {
	mut handle := toplevel_handle
	toplevel := &Toplevel{
		handle: handle
	}
	handle.set_listener(&ForeignToplevelListener{
		toplevel: toplevel
	}) or {}
	l.state.toplevels << toplevel
}

fn (mut l ForeignToplevelListListener) finished(_ ft.ExtForeignToplevelListV1) {
}
