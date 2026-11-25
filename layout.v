module main

import math
import wayland.protocols.wayland as wl

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

fn transform_output(transform u32, width int, height int) (int, int) {
	base := transform & 3
	if base == 1 || base == 3 {
		return height, width
	}
	return width, height
}

fn get_output_rotation(transform u32) f64 {
	base := transform & ~u32(wl.wl_output_transform_flipped)
	return match base {
		wl.wl_output_transform_num_90 { math.pi / 2 }
		wl.wl_output_transform_num_180 { math.pi }
		wl.wl_output_transform_num_270 { 3 * math.pi / 2 }
		else { 0 }
	}
}

fn get_output_flipped(transform u32) int {
	if transform & u32(wl.wl_output_transform_flipped) != 0 {
		return -1
	}
	return 1
}

fn intersect_box(a &Geometry, b &Geometry) bool {
	return a.intersect(b)
}
