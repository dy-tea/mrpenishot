module main

import math

struct Box {
	x i32
	y i32
	width i32
	height i32
}

fn Box.new(str string) !Box {
	pos, size := str.split_once(' ') or { return error('invalid format, no space') }
	x, y := pos.split_once(',') or { return error('invalid format, no position') }
	width, height := size.split_once('x') or { return error('invalid format, no size') }
	return Box { x.i32(), y.i32(), width.i32(), height.i32() }
}

fn (b Box) is_empty() bool {
	return b.width <= 0 || b.height <= 0
}

fn (b Box) intersect(o Box) bool {
	if b.is_empty() || o.is_empty() {
		return false
	}

	x1 := math.max(b.x, o.x)
	y1 := math.max(b.y, o.y)
	x2 := math.min(b.x + b.width, o.x + o.width)
	y2 := math.min(b.y + b.height, o.y + o.height)

	r := Box {
		x1, y1, x2 - x1, y2 - y1
	}
	return !r.is_empty()
}
