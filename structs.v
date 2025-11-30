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
	ext_foreign_toplevel_image_capture_source_manager_v1 ?&ft.ExtForeignToplevelListV1
	ext_image_copy_capture_manager_v1                    ?&cc.ExtImageCopyCaptureManagerV1
}

struct Output {
	state     &State
	wl_output &wlp.WlOutput
	scale     int
}

struct Capture {
	state  &State
	output &Output
	link   C.wl_list
}
