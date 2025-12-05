module main

import math
import protocols.wayland as wlp

fn (state &State) get_extents() Geometry {
	mut x1 := math.maxof[int]()
	mut x2 := math.minof[int]()
	mut y1 := math.maxof[int]()
	mut y2 := math.minof[int]()

	for capture in state.captures {
		if capture.logical_geometry.x < x1 {
			x1 = capture.logical_geometry.x
		}
		if capture.logical_geometry.x + capture.logical_geometry.width > x2 {
			x2 = capture.logical_geometry.x + capture.logical_geometry.width
		}
		if capture.logical_geometry.y < y1 {
			y1 = capture.logical_geometry.y
		}
		if capture.logical_geometry.y + capture.logical_geometry.height > y2 {
			y2 = capture.logical_geometry.y + capture.logical_geometry.height
		}
	}

	return Geometry{x1, y1, x2 - x1, y2 - y1}
}

fn transform_output(transform wlp.WlOutput_Transform, width int, height int) (int, int) {
	if int(transform) & int(wlp.WlOutput_Transform._90) != 0 {
		return height, width
	}
	return width, height
}

fn get_output_rotation(transform wlp.WlOutput_Transform) f64 {
	base := int(transform) & ~int(wlp.WlOutput_Transform.flipped)
	return match base {
		int(wlp.WlOutput_Transform._90) { math.pi / 2 }
		int(wlp.WlOutput_Transform._180) { math.pi }
		int(wlp.WlOutput_Transform._270) { 3 * math.pi / 2 }
		else { 0 }
	}
}

fn get_output_flipped(transform wlp.WlOutput_Transform) int {
	if int(transform) & int(wlp.WlOutput_Transform.flipped) != 0 {
		return -1
	}
	return 1
}

fn intersect_box(a &Geometry, b &Geometry) bool {
	return a.intersects(b)
}
