module main

import wayland.protocols.wayland as wl

struct OutputListener {
mut:
	output &Output
}

fn (mut l OutputListener) geometry(_ wl.WlOutput, x i32, y i32, _ i32, _ i32, _ i32, _ string, _ string, transform i32) {
	l.output.x = int(x)
	l.output.y = int(y)
	l.output.transform = u32(transform)
}

fn (mut l OutputListener) mode(_ wl.WlOutput, flags u32, width i32, height i32, _ i32) {
	if flags & u32(wl.wl_output_mode_current) != 0 {
		l.output.mode_width = int(width)
		l.output.mode_height = int(height)
	}
}

fn (mut l OutputListener) done(_ wl.WlOutput) {
}

fn (mut l OutputListener) scale(_ wl.WlOutput, factor i32) {
	l.output.scale = int(factor)
}

fn (mut l OutputListener) name(_ wl.WlOutput, name string) {
	l.output.name = name
}

fn (mut l OutputListener) description(_ wl.WlOutput, _ string) {
}
