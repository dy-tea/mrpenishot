module main

import protocols.wayland as wlp
import protocols.xdg_output_unstable_v1 as xo
import protocols.ext_image_copy_capture_v1 as cc
import protocols.ext_image_capture_source_v1 as cs
import protocols.ext_foreign_toplevel_list_v1 as ft

@[heap]
struct State {
mut:
	display  &wlp.WlDisplay
	registry &wlp.WlRegistry

	shm                                                  ?&wlp.WlShm
	zxdg_output_manager_v1                               ?&xo.ZxdgOutputManagerV1
	ext_output_image_capture_source_manager_v1           ?&cs.ExtOutputImageCaptureSourceManagerV1
	ext_foreign_toplevel_image_capture_source_manager_v1 ?&cs.ExtForeignToplevelImageCaptureSourceManagerV1
	ext_foreign_toplevel_list_v1                         ?&ft.ExtForeignToplevelListV1
	ext_image_copy_capture_manager_v1                    ?&cc.ExtImageCopyCaptureManagerV1

	outputs []Output
}

struct Output {
	state &State
mut:
	wl_output      &wlp.WlOutput
	xdg_output     ?&xo.ZxdgOutputV1
	name           string
	scale          int
	x              int
	y              int
	transform      wlp.WlOutput_Transform
	mode_width     int
	mode_height    int
	logical_scale  f64
	logical_x      int
	logical_y      int
	logical_width  int
	logical_height int
}

struct Capture {
	state  &State
	output &Output
	link   C.wl_list
}

fn (mut o Output) guess_logical_geometry() {
	o.logical_x = o.x
	o.logical_y = o.y
	o.logical_width = o.mode_width / o.scale
	o.logical_height = o.mode_height / o.scale
	o.logical_width, o.logical_height = transform_output(o.transform, o.logical_width, o.logical_height)
	o.logical_scale = o.scale
}
