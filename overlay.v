module main

import wl
import protocols.wayland as wlp
import protocols.wlr_layer_shell_unstable_v1 as ls

// needed for xdg_popup interface
import protocols.xdg_shell as _

fn layer_surface_v1_configure(data voidptr, obj voidptr, serial u32, width u32, height u32) {
	mut overlay := unsafe { &Overlay(data) }
	if mut layer_surface := overlay.layer_surface_v1 {
		layer_surface.ack_configure(serial)
	}
	if mut surface := overlay.surface {
		surface.commit()
	}
}

fn layer_surface_v1_closed(data voidptr, obj voidptr) {
	panic('Layer surface died unexpectedly')
}

const layer_surface_listener = ls.zwlrlayersurfacev1_listener(
	layer_surface_v1_configure, // configure
	layer_surface_v1_closed // closed
)

fn surface_enter(data voidptr, obj voidptr, output voidptr) {}
fn surface_leave(data voidptr, obj voidptr, output voidptr) {}
fn surface_preferred_buffer_scale(data voidptr, obj voidptr, factor int) {}
fn surface_preferred_buffer_transform(data voidptr, obj voidptr, transform u32) {}

const surface_listener = wlp.wlsurface_listener(
	surface_enter, // enter
	surface_leave, // leave
	surface_preferred_buffer_scale, // preferred_buffer_scale
	surface_preferred_buffer_transform // preferred_buffer_transform
)

fn Overlay.new(capture &Capture) &Overlay {
	mut overlay := &Overlay{
		capture:          capture
		layer_surface_v1: none
		surface:          none
	}
	mut compositor := capture.state.compositor or { panic('Failed to get compositor') }

	mut surface := compositor.create_surface()
	if surface.proxy == unsafe { nil } {
		panic('Failed to create surface')
	}
	overlay.surface = surface
	surface.add_listener(&surface_listener, overlay)

	mut wp_viewporter := capture.state.wp_viewporter or { panic('No viewporter init') }

	mut wp_viewport := wp_viewporter.get_viewport(surface.proxy)
	overlay.wp_viewport = wp_viewport
	if wp_viewport == unsafe { nil } {
		panic('Failed to create viewport')
	}
	wp_viewport.set_destination(capture.logical_geometry.width, capture.logical_geometry.height)
	wp_viewport.set_source(wl.wl_fixed_from_int(0), wl.wl_fixed_from_int(0), wl.wl_fixed_from_int(int(capture.buffer_width)),
		wl.wl_fixed_from_int(int(capture.buffer_height)))

	if output := capture.output {
		mut wlr_layer_shell := capture.state.wlr_layer_shell_v1 or { panic('No layer shell init') }

		mut layer_surface := wlr_layer_shell.get_layer_surface(surface.proxy, output.wl_output.proxy,
			u32(ls.ZwlrLayerShellV1_Layer.overlay), 'mrpenishot'.str)
		overlay.layer_surface_v1 = layer_surface
		if layer_surface == unsafe { nil } {
			panic('Failed to get layer surface')
		}
		layer_surface.add_listener(&layer_surface_listener, overlay)

		layer_surface.set_size(u32(output.logical_geometry.width), u32(output.logical_geometry.height))
		layer_surface.set_anchor(u32(int(ls.ZwlrLayerSurfaceV1_Anchor.top) | int(ls.ZwlrLayerSurfaceV1_Anchor.bottom) | int(ls.ZwlrLayerSurfaceV1_Anchor.left) | int(ls.ZwlrLayerSurfaceV1_Anchor.right)))
		layer_surface.set_exclusive_zone(-1)

		surface.commit()
		C.wl_display_roundtrip(overlay.capture.state.display.proxy)

		if buffer := capture.buffer {
			mut shm := capture.state.shm or { panic('No shm init') }
			stride := int(get_min_stride(buffer.shm_format, u32(buffer.width)))
			mut overlay_buffer := Buffer.new(mut shm, buffer.shm_format, buffer.width, buffer.height, stride)
			unsafe {
				C.memcpy(overlay_buffer.data, buffer.data, buffer.size)
			}
			overlay.buffer = overlay_buffer
			surface.attach(overlay_buffer.wl_buffer.proxy, 0, 0)
			surface.commit()
		}
	}

	return overlay
}

fn (mut overlay Overlay) destroy() {
	if mut layer_surface := overlay.layer_surface_v1 {
		layer_surface.destroy()
	}
	if mut surface := overlay.surface {
		surface.destroy()
	}
	if mut wp_viewport := overlay.wp_viewport {
		wp_viewport.destroy()
	}
	if mut buffer := overlay.buffer {
		buffer.destroy()
	}
}
