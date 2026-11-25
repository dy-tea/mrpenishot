module main

import wayland.protocols.wayland as wl
import wayland.protocols.wlr_layer_shell_unstable_v1 as ls

struct LayerSurfaceListener {
mut:
	overlay &Overlay
}

fn (mut l LayerSurfaceListener) configure(_ ls.ZwlrLayerSurfaceV1, serial u32, _ u32, _ u32) {
	if mut layer_surface := l.overlay.layer_surface_v1 {
		layer_surface.ack_configure(serial) or {}
	}
	if mut surface := l.overlay.surface {
		surface.commit() or {}
	}
}

fn (mut l LayerSurfaceListener) closed(_ ls.ZwlrLayerSurfaceV1) {
	panic('Layer surface died unexpectedly')
}

struct SurfaceListener {
mut:
	overlay &Overlay
}

fn (mut l SurfaceListener) enter(_ wl.WlSurface, _ wl.WlOutput) {
}

fn (mut l SurfaceListener) leave(_ wl.WlSurface, _ wl.WlOutput) {
}

fn (mut l SurfaceListener) preferred_buffer_scale(_ wl.WlSurface, _ i32) {
}

fn (mut l SurfaceListener) preferred_buffer_transform(_ wl.WlSurface, _ u32) {
}

fn Overlay.new(capture &Capture) &Overlay {
	mut overlay := &Overlay{
		capture:          capture
		layer_surface_v1: none
		surface:          none
	}
	mut compositor := capture.state.compositor or { panic('Failed to get compositor') }

	mut surface := compositor.create_surface() or { panic('Failed to create surface') }
	overlay.surface = surface
	surface.set_listener(&SurfaceListener{
		overlay: overlay
	}) or {}

	mut wp_viewporter := capture.state.wp_viewporter or { panic('No viewporter init') }

	mut wp_viewport := wp_viewporter.get_viewport(surface) or { panic('Failed to create viewport') }
	overlay.wp_viewport = wp_viewport
	wp_viewport.set_destination(capture.logical_geometry.width, capture.logical_geometry.height) or {}
	wp_viewport.set_source(0, 0, f64(capture.buffer_width), f64(capture.buffer_height)) or {}

	if output := capture.output {
		mut wlr_layer_shell := capture.state.wlr_layer_shell_v1 or { panic('No layer shell init') }

		mut layer_surface := wlr_layer_shell.get_layer_surface(surface, output.wl_output, u32(ls.zwlr_layer_shell_v1_layer_overlay), 'mrpenishot') or { panic('Failed to get layer surface') }
		overlay.layer_surface_v1 = layer_surface
		layer_surface.set_listener(&LayerSurfaceListener{
			overlay: overlay
		}) or {}

		layer_surface.set_size(u32(output.logical_geometry.width), u32(output.logical_geometry.height)) or {}
		layer_surface.set_anchor(u32(int(ls.zwlr_layer_surface_v1_anchor_top) | int(ls.zwlr_layer_surface_v1_anchor_bottom) | int(ls.zwlr_layer_surface_v1_anchor_left) | int(ls.zwlr_layer_surface_v1_anchor_right))) or {}
		layer_surface.set_exclusive_zone(-1) or {}

		surface.commit() or {}
		capture.state.conn.roundtrip() or { panic('roundtrip failed') }

		if buffer := capture.buffer {
			mut shm := capture.state.shm or { panic('No shm init') }
			mut overlay_buffer := Buffer.new(mut shm, buffer.shm_format, buffer.width, buffer.height,
				buffer.stride)
			overlay_buffer.copy_from(buffer)
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
