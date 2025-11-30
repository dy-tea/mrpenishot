module main

import wl
import protocols

struct State {
mut:
	display &C.wl_display
	registry &C.wl_registry
	shm ?&C.wl_shm

	zxdg_output_manager_v1 ?&C.zxdg_output_manager_v1
}

struct Output {
	state &State
	wl_output &C.wl_output

}

struct Capture {
	state &State
	output &Output
	link C.wl_list
}
