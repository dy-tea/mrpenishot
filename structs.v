module main

import wl
import protocols

@[heap]
struct State {
mut:
	display  &C.wl_display
	registry &C.wl_registry

	shm                                 ?&C.wl_shm
	zxdg_output_manager_v1              ?&C.zxdg_output_manager_v1
	ext_output_image_capture_source_manager_v1 ?&C.ext_output_image_capture_source_manager_v1
	ext_foreign_toplevel_image_capture_source_manager_v1 ?&C.ext_foreign_toplevel_image_capture_source_manager_v1
	ext_image_copy_capture_manager_v1   ?&C.ext_image_copy_capture_manager_v1
}

struct Output {
	state     &State
	wl_output &C.wl_output
	scale     int
}

struct Capture {
	state  &State
	output &Output
	link   C.wl_list
}
