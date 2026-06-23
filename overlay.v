module main

import dy_tea.wayland as wl

fn make_layer_surface_events() wl.ZwlrLayerSurfaceV1Events[&Overlay] {
	return wl.ZwlrLayerSurfaceV1Events[&Overlay]{
		configure: fn (o &Overlay, serial u32, width u32, height u32) {
			if mut layer_surface := o.layer_surface_v1 {
				layer_surface.ack_configure(serial) or {}
			}
			if mut surface := o.surface {
				surface.commit() or {}
			}
		}
		closed:    fn (o &Overlay) {
			panic('Layer surface died unexpectedly')
		}
	}
}

fn Overlay.new(capture &Capture) &Overlay {
	mut overlay := &Overlay{
		capture: capture
	}

	mut compositor := capture.state.compositor or { panic('Failed to get compositor') }

	mut surface := compositor.create_surface() or { panic('Failed to create surface') }
	overlay.surface = surface

	mut wp_viewporter := capture.state.wp_viewporter or { panic('No viewporter init') }

	mut wp_viewport := wp_viewporter.get_viewport(surface) or { panic('Failed to create viewport') }
	overlay.wp_viewport = wp_viewport
	wp_viewport.set_source(wl.Fixed(0), wl.Fixed(0), wl.Fixed(int(capture.buffer_width) * 256),
		wl.Fixed(int(capture.buffer_height) * 256)) or {}
	wp_viewport.set_destination(capture.logical_geometry.width, capture.logical_geometry.height) or {}

	if output := capture.output {
		mut wlr_layer_shell := capture.state.wlr_layer_shell_v1 or { panic('No layer shell init') }

		mut layer_surface := wlr_layer_shell.get_layer_surface(surface, output.wl_output,
			u32(wl.ZwlrLayerShellV1Layer.overlay), 'mrpenishot') or {
			panic('Failed to get layer surface')
		}
		overlay.layer_surface_v1 = layer_surface

		layer_surface.set_size(u32(output.logical_geometry.width),
			u32(output.logical_geometry.height)) or {}
		layer_surface.set_anchor(u32(int(wl.ZwlrLayerSurfaceV1Anchor.top) | int(wl.ZwlrLayerSurfaceV1Anchor.bottom) | int(wl.ZwlrLayerSurfaceV1Anchor.left) | int(wl.ZwlrLayerSurfaceV1Anchor.right))) or {}
		layer_surface.set_exclusive_zone(-1) or {}

		surface.commit() or {}

		_ := capture.state.display.connection()

		if buffer := capture.buffer {
			mut shm := capture.state.shm or { panic('No shm init') }
			stride := int(get_min_stride(buffer.shm_format, u32(buffer.width)))
			mut overlay_buffer := Buffer.new(mut shm, buffer.shm_format, buffer.width,
				buffer.height, stride)
			unsafe {
				C.memcpy(overlay_buffer.data, buffer.data, buffer.size)
			}
			overlay.buffer = overlay_buffer
			surface.attach(overlay_buffer.wl_buffer, 0, 0) or {}
			surface.commit() or {}
		}
	}

	return overlay
}

fn (mut overlay Overlay) destroy() {
	if mut layer_surface := overlay.layer_surface_v1 {
		layer_surface.destroy() or {}
	}
	if mut surface := overlay.surface {
		surface.destroy() or {}
	}
	if mut wp_viewport := overlay.wp_viewport {
		wp_viewport.destroy() or {}
	}
	if mut buffer := overlay.buffer {
		buffer.destroy()
	}
}
