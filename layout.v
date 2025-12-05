module main

import protocols.wayland as wlp

fn transform_output(transform wlp.WlOutput_Transform, width int, height int) (int, int) {
	if transform == ._90 {
		return height, width
	}
	return width, height
}
