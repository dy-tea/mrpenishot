module main

import protocols.wayland as wlp
import protocols.color_management_v1 as cm
import protocols.xdg_output_unstable_v1 as xo
import protocols.ext_image_copy_capture_v1 as cc
import protocols.ext_image_capture_source_v1 as cs
import protocols.ext_foreign_toplevel_list_v1 as ft
import protocols.viewporter as vp
import protocols.wlr_layer_shell_unstable_v1 as ls

@[heap]
struct State {
mut:
	display  &wlp.WlDisplay
	registry &wlp.WlRegistry

	shm                                                  ?&wlp.WlShm
	compositor                                           ?&wlp.WlCompositor
	zxdg_output_manager_v1                               ?&xo.ZxdgOutputManagerV1
	wp_color_manager_v1                                  ?&cm.WpColorManagerV1
	ext_output_image_capture_source_manager_v1           ?&cs.ExtOutputImageCaptureSourceManagerV1
	ext_foreign_toplevel_image_capture_source_manager_v1 ?&cs.ExtForeignToplevelImageCaptureSourceManagerV1
	ext_foreign_toplevel_list_v1                         ?&ft.ExtForeignToplevelListV1
	ext_image_copy_capture_manager_v1                    ?&cc.ExtImageCopyCaptureManagerV1
	wp_viewporter                                        ?&vp.WpViewporter
	wlr_layer_shell_v1                                   ?&ls.ZwlrLayerShellV1

	is_hdr             bool
	n_cm_done          int

	outputs   []Output
	toplevels []&Toplevel
	captures  []&Capture
	n_done    int
}

@[heap]
struct Output {
	state &State
mut:
	wl_output        &wlp.WlOutput
	xdg_output       ?&xo.ZxdgOutputV1
	cm_output        ?&cm.WpColorManagementOutputV1
	name             string
	scale            int
	x                int
	y                int
	transform        wlp.WlOutput_Transform
	mode_width       int
	mode_height      int
	logical_scale    f64
	logical_geometry Geometry
}

@[heap]
struct Toplevel {
mut:
	handle     &ft.ExtForeignToplevelHandleV1
	identifier string
}

struct Capture {
	output   ?&Output
	toplevel ?&Toplevel
mut:
	state &State

	transform        wlp.WlOutput_Transform
	logical_geometry Geometry
	buffer           ?&Buffer

	ext_image_copy_capture_session_v1 ?&cc.ExtImageCopyCaptureSessionV1
	ext_image_copy_capture_frame_v1   ?&cc.ExtImageCopyCaptureFrameV1
	buffer_width                      u32
	buffer_height                     u32
	shm_format                        ?wlp.WlShm_Format
}

@[heap]
struct Overlay {
mut:
	capture          &Capture
	layer_surface_v1 ?&ls.ZwlrLayerSurfaceV1
	surface          ?&wlp.WlSurface
	wp_viewport      ?&vp.WpViewport
	buffer           ?&Buffer
}

fn (mut o Output) guess_logical_geometry() {
	o.logical_geometry.x = o.x
	o.logical_geometry.y = o.y
	o.logical_geometry.width = o.mode_width / o.scale
	o.logical_geometry.height = o.mode_height / o.scale
	o.logical_geometry.width, o.logical_geometry.height = transform_output(o.transform,
		o.logical_geometry.width, o.logical_geometry.height)
	o.logical_scale = o.scale
}
