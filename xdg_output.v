module main

import wayland.protocols.xdg_output_unstable_v1 as xo

struct XdgOutputListener {
mut:
	output &Output
}

fn (mut l XdgOutputListener) logical_position(_ xo.ZxdgOutputV1, x i32, y i32) {
	l.output.logical_geometry.x = int(x)
	l.output.logical_geometry.y = int(y)
}

fn (mut l XdgOutputListener) logical_size(_ xo.ZxdgOutputV1, width i32, height i32) {
	l.output.logical_geometry.width = int(width)
	l.output.logical_geometry.height = int(height)
}

fn (mut l XdgOutputListener) done(_ xo.ZxdgOutputV1) {
	width, _ := transform_output(l.output.transform, l.output.mode_width, l.output.mode_height)
	l.output.logical_scale = f64(width) / l.output.logical_geometry.width
}

fn (mut l XdgOutputListener) name(_ xo.ZxdgOutputV1, name string) {
	if l.output.name == '' {
		l.output.name = name
	}
}

fn (mut l XdgOutputListener) description(_ xo.ZxdgOutputV1, _ string) {
}
