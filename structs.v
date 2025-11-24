module main

import wl

struct State {
	display &C.wl_display
	registry &C.wl_registry
	shm &C.wl_shm

	outputs C.wl_list
	toplevels C.wl_list

	captures C.wl_list
	n_done usize
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
