module main

import dy_tea.wayland as wl

@[heap]
struct State {
mut:
	display &wl.Display

	shm                                                  ?wl.WlShm
	compositor                                           ?wl.WlCompositor
	zxdg_output_manager_v1                               ?wl.ZxdgOutputManagerV1
	wp_color_manager_v1                                  ?wl.WpColorManagerV1
	ext_output_image_capture_source_manager_v1           ?wl.ExtOutputImageCaptureSourceManagerV1
	ext_foreign_toplevel_image_capture_source_manager_v1 ?wl.ExtForeignToplevelImageCaptureSourceManagerV1
	ext_foreign_toplevel_list_v1                         ?wl.ExtForeignToplevelListV1
	ext_image_copy_capture_manager_v1                    ?wl.ExtImageCopyCaptureManagerV1
	wp_viewporter                                        ?wl.WpViewporter
	wlr_layer_shell_v1                                   ?wl.ZwlrLayerShellV1

	is_hdr    bool
	n_cm_done int

	outputs   []&Output
	toplevels []&Toplevel
	captures  []&Capture
	n_done    int

	// Dispatch lookup maps
	outputs_by_id    map[u32]&Output
	captures_by_sess map[u32]&Capture
	toplevels_by_id  map[u32]&Toplevel
	overlays_by_id   map[u32]&Overlay
	cm_descs_by_id   map[u32]wl.WpImageDescriptionV1
	cm_infos_by_id   map[u32]wl.WpImageDescriptionInfoV1
}

@[heap]
struct Output {
	state &State
mut:
	wl_output        wl.WlOutput
	xdg_output       ?wl.ZxdgOutputV1
	cm_output        ?wl.WpColorManagementOutputV1
	name             string
	scale            int
	x                int
	y                int
	transform        i32
	mode_width       int
	mode_height      int
	logical_scale    f64
	logical_geometry Geometry
}

@[heap]
struct Toplevel {
mut:
	handle     wl.ExtForeignToplevelHandleV1
	identifier string
}

struct Capture {
	output   ?&Output
	toplevel ?&Toplevel
mut:
	state &State

	transform        i32
	logical_geometry Geometry
	buffer           ?&Buffer

	ext_image_copy_capture_session_v1 ?wl.ExtImageCopyCaptureSessionV1
	ext_image_copy_capture_frame_v1   ?wl.ExtImageCopyCaptureFrameV1
	buffer_width                      u32
	buffer_height                     u32
	shm_format                        ?wl.WlShmFormat
}

@[heap]
struct Overlay {
mut:
	capture          &Capture
	layer_surface_v1 ?wl.ZwlrLayerSurfaceV1
	surface          ?wl.WlSurface
	wp_viewport      ?wl.WpViewport
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

struct EventHandlers {
	output_events            wl.WlOutputEvents[&Output]
	xdg_output_events        wl.ZxdgOutputV1Events[&Output]
	session_events           wl.ExtImageCopyCaptureSessionV1Events[&Capture]
	frame_events             wl.ExtImageCopyCaptureFrameV1Events[&Capture]
	cm_output_events         wl.WpColorManagementOutputV1Events[&Output]
	image_description_events wl.WpImageDescriptionV1Events[&State]
	image_info_events        wl.WpImageDescriptionInfoV1Events[&State]
	toplevel_handle_events   wl.ExtForeignToplevelHandleV1Events[&Toplevel]
	toplevel_list_events     wl.ExtForeignToplevelListV1Events[&State]
	layer_surface_events     wl.ZwlrLayerSurfaceV1Events[&Overlay]
}

fn make_event_handlers() EventHandlers {
	return EventHandlers{
		output_events:            make_output_events()
		xdg_output_events:        make_xdg_output_events()
		session_events:           make_session_events()
		frame_events:             make_frame_events()
		cm_output_events:         make_cm_output_events()
		image_description_events: make_image_description_events()
		image_info_events:        make_image_desc_info_events()
		toplevel_handle_events:   make_toplevel_handle_events()
		toplevel_list_events:     make_toplevel_list_events()
		layer_surface_events:     make_layer_surface_events()
	}
}
