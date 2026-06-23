module main

import dy_tea.wayland as wl

fn make_toplevel_handle_events() wl.ExtForeignToplevelHandleV1Events[&Toplevel] {
	return wl.ExtForeignToplevelHandleV1Events[&Toplevel]{
		identifier: fn (mut t Toplevel, identifier string) {
			t.identifier = identifier
		}
	}
}

fn make_toplevel_list_events() wl.ExtForeignToplevelListV1Events[&State] {
	return wl.ExtForeignToplevelListV1Events[&State]{
		toplevel: fn (mut s State, handle wl.ExtForeignToplevelHandleV1) {
			toplevel := &Toplevel{
				handle: handle
			}
			s.toplevels << toplevel
			s.toplevels_by_id[handle.id] = toplevel
		}
	}
}
