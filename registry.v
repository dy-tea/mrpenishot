module main

import math
import dy_tea.wayland as wl

fn init_globals(mut state State) {
	for g in state.display.get_globals() {
		match g.interface {
			'wl_shm' {
				raw := state.display.bind_global(g.name, g.interface, g.version) or { continue }
				state.shm = wl.new_wl_shm(raw)
			}
			'wl_compositor' {
				raw := state.display.bind_global(g.name, g.interface, 6) or { continue }
				state.compositor = wl.new_wl_compositor(raw)
			}
			'wl_output' {
				raw := state.display.bind_global(g.name, g.interface, math.min(g.version, 4)) or {
					continue
				}
				mut output := &Output{
					state:     &state
					scale:     1
					wl_output: wl.new_wl_output(raw)
				}
				state.outputs << output
				state.outputs_by_id[output.wl_output.id] = output
			}
			'wp_color_manager_v1' {
				raw := state.display.bind_global(g.name, g.interface, 1) or { continue }
				state.wp_color_manager_v1 = wl.new_wp_color_manager_v1(raw)
			}
			'zxdg_output_manager_v1' {
				bind_version := math.min(g.version, 2)
				raw := state.display.bind_global(g.name, g.interface, bind_version) or { continue }
				state.zxdg_output_manager_v1 = wl.new_zxdg_output_manager_v1(raw)
			}
			'ext_output_image_capture_source_manager_v1' {
				raw := state.display.bind_global(g.name, g.interface, 1) or { continue }
				state.ext_output_image_capture_source_manager_v1 =
					wl.new_ext_output_image_capture_source_manager_v1(raw)
			}
			'ext_foreign_toplevel_image_capture_source_manager_v1' {
				raw := state.display.bind_global(g.name, g.interface, 1) or { continue }
				state.ext_foreign_toplevel_image_capture_source_manager_v1 =
					wl.new_ext_foreign_toplevel_image_capture_source_manager_v1(raw)
			}
			'ext_foreign_toplevel_list_v1' {
				raw := state.display.bind_global(g.name, g.interface, 1) or { continue }
				state.ext_foreign_toplevel_list_v1 = wl.new_ext_foreign_toplevel_list_v1(raw)
			}
			'ext_image_copy_capture_manager_v1' {
				raw := state.display.bind_global(g.name, g.interface, 1) or { continue }
				state.ext_image_copy_capture_manager_v1 =
					wl.new_ext_image_copy_capture_manager_v1(raw)
			}
			'wp_viewporter' {
				raw := state.display.bind_global(g.name, g.interface, 1) or { continue }
				state.wp_viewporter = wl.new_wp_viewporter(raw)
			}
			'zwlr_layer_shell_v1' {
				raw := state.display.bind_global(g.name, g.interface, 1) or { continue }
				state.wlr_layer_shell_v1 = wl.new_zwlr_layer_shell_v1(raw)
			}
			else {}
		}
	}
}
