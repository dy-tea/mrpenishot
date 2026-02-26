module main

import math
import protocols.wayland as wlp
import protocols.color_management_v1 as cm
import protocols.xdg_output_unstable_v1 as xo
import protocols.ext_image_copy_capture_v1 as cc
import protocols.ext_image_capture_source_v1 as cs
import protocols.ext_foreign_toplevel_list_v1 as ft
import protocols.viewporter as vp
import protocols.wlr_layer_shell_unstable_v1 as ls

fn registry_handle_global(mut state State, registry voidptr, name u32, iface &char, version u32) {
	interface_name := unsafe { iface.vstring() }

	match interface_name {
		wlp.wl_shm_interface_name {
			state.shm = &wlp.WlShm{state.registry.bind(name, wlp.wl_shm_interface_ptr(),
				version)}
		}
		wlp.wl_compositor_interface_name {
			state.compositor = &wlp.WlCompositor{state.registry.bind(name, wlp.wl_compositor_interface_ptr(),
				6)}
		}
		wlp.wl_output_interface_name {
			mut output := &Output{
				state:     state
				scale:     1
				wl_output: &wlp.WlOutput{state.registry.bind(name, wlp.wl_output_interface_ptr(),
					math.min(version, 4))}
			}
			output.wl_output.add_listener(&output_listener, output)
			state.outputs << output
		}
		cm.wp_color_manager_v1_interface_name {
			state.wp_color_manager_v1 = &cm.WpColorManagerV1{state.registry.bind(name,
				cm.wp_color_manager_v1_interface_ptr(), 1)}
		}
		xo.zxdg_output_manager_v1_interface_name {
			bind_version := math.min(version, 2)
			state.zxdg_output_manager_v1 = &xo.ZxdgOutputManagerV1{state.registry.bind(name,
				xo.zxdg_output_manager_v1_interface_ptr(), bind_version)}
		}
		cs.ext_output_image_capture_source_manager_v1_interface_name {
			state.ext_output_image_capture_source_manager_v1 = &cs.ExtOutputImageCaptureSourceManagerV1{state.registry.bind(name,
				cs.ext_output_image_capture_source_manager_v1_interface_ptr(), 1)}
		}
		cs.ext_foreign_toplevel_image_capture_source_manager_v1_interface_name {
			state.ext_foreign_toplevel_image_capture_source_manager_v1 = &cs.ExtForeignToplevelImageCaptureSourceManagerV1{state.registry.bind(name,
				cs.ext_foreign_toplevel_image_capture_source_manager_v1_interface_ptr(),
				1)}
		}
		ft.ext_foreign_toplevel_list_v1_interface_name {
			state.ext_foreign_toplevel_list_v1 = &ft.ExtForeignToplevelListV1{state.registry.bind(name,
				ft.ext_foreign_toplevel_list_v1_interface_ptr(), 1)}
		}
		cc.ext_image_copy_capture_manager_v1_interface_name {
			state.ext_image_copy_capture_manager_v1 = &cc.ExtImageCopyCaptureManagerV1{state.registry.bind(name,
				cc.ext_image_copy_capture_manager_v1_interface_ptr(), 1)}
		}
		vp.wp_viewporter_interface_name {
			state.wp_viewporter = &vp.WpViewporter{state.registry.bind(name, vp.wp_viewporter_interface_ptr(),
				1)}
		}
		ls.zwlr_layer_shell_v1_interface_name {
			state.wlr_layer_shell_v1 = &ls.ZwlrLayerShellV1{state.registry.bind(name,
				ls.zwlr_layer_shell_v1_interface_ptr(), 1)}
		}
		else {}
	}
}

const registry_listener = C.wl_registry_listener{
	global:        registry_handle_global
	global_remove: fn (_ voidptr, _ voidptr, _ u32) {}
}
