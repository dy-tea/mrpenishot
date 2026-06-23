module main

import dy_tea.wayland as wl

fn dispatch_one(mut conn wl.Connection, mut state State, id u32, opcode u16, mut reader wl.MessageReader, handlers &EventHandlers) ! {
	obj := conn.get_object(id) or { return }
	match obj.iface {
		'wl_output' {
			output := state.outputs_by_id[id] or { return }
			wl.wl_output_dispatch(conn, id, opcode, mut reader, &handlers.output_events, output)!
		}
		'zxdg_output_v1' {
			output := state.outputs_by_id[id] or { return }
			wl.zxdg_output_v1_dispatch(conn, id, opcode, mut reader, &handlers.xdg_output_events,
				output)!
		}
		'ext_image_copy_capture_session_v1' {
			capture := state.captures_by_sess[id] or { return }
			wl.ext_image_copy_capture_session_v1_dispatch(conn, id, opcode, mut reader,
				&handlers.session_events, capture)!
		}
		'ext_image_copy_capture_frame_v1' {
			capture := state.captures_by_sess[id] or { return }
			wl.ext_image_copy_capture_frame_v1_dispatch(conn, id, opcode, mut reader,
				&handlers.frame_events, capture)!
		}
		'wp_color_management_output_v1' {
			if opcode == wl.wp_color_management_output_v1_image_description_changed_opcode {
				output := state.outputs_by_id[id] or { return }
				if mut cm_output := output.cm_output {
					mut desc := cm_output.get_image_description() or { return }
					mut info := desc.get_information() or { return }
					state.cm_descs_by_id[desc.id] = desc
					state.cm_infos_by_id[info.id] = info
				}
			}
		}
		'wp_image_description_v1' {
			wl.wp_image_description_v1_dispatch(conn, id, opcode, mut reader,
				&handlers.image_description_events, &state)!
		}
		'wp_image_description_info_v1' {
			wl.wp_image_description_info_v1_dispatch(conn, id, opcode, mut reader,
				&handlers.image_info_events, &state)!
		}
		'ext_foreign_toplevel_list_v1' {
			if opcode == wl.ext_foreign_toplevel_list_v1_toplevel_opcode {
				raw_id := reader.read_u32()!
				reg_obj := conn.register_object(raw_id, 'ext_foreign_toplevel_handle_v1', 1)
				pr := wl.new_proxy(conn, reg_obj.id, reg_obj.iface, reg_obj.version)
				handle := wl.new_ext_foreign_toplevel_handle_v1(pr)
				toplevel := &Toplevel{
					handle: handle
				}
				state.toplevels << toplevel
				state.toplevels_by_id[handle.id] = toplevel
			}
		}
		'ext_foreign_toplevel_handle_v1' {
			toplevel := state.toplevels_by_id[id] or { return }
			wl.ext_foreign_toplevel_handle_v1_dispatch(conn, id, opcode, mut reader,
				&handlers.toplevel_handle_events, toplevel)!
		}
		'zwlr_layer_surface_v1' {
			overlay := state.overlays_by_id[id] or { return }
			wl.zwlr_layer_surface_v1_dispatch(conn, id, opcode, mut reader,
				&handlers.layer_surface_events, overlay)!
		}
		else {}
	}
}

fn drain_pending(mut conn wl.Connection, mut state State, handlers &EventHandlers) {
	for {
		id, opcode, body, _ := conn.try_read_message() or { break }
		mut reader := wl.new_message_reader(body)
		dispatch_one(mut conn, mut state, id, opcode, mut reader, handlers) or {}
	}
}
