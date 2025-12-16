module main

import math
import protocols.wayland as wlp
import pixman as px

fn get_pixman_format(wl_fmt wlp.WlShm_Format) !px.Pixman_format_code_t {
	return match wl_fmt {
		.argb8888 {
			px.Pixman_format_code_t.a8r8g8b8
		}
		.xrgb8888 {
			px.Pixman_format_code_t.x8r8g8b8
		}
		.abgr8888 {
			px.Pixman_format_code_t.a8b8g8r8
		}
		.xbgr8888 {
			px.Pixman_format_code_t.x8b8g8r8
		}
		.bgra8888 {
			px.Pixman_format_code_t.b8g8r8a8
		}
		.bgrx8888 {
			px.Pixman_format_code_t.b8g8r8x8
		}
		.rgba8888 {
			px.Pixman_format_code_t.r8g8b8a8
		}
		.rgbx8888 {
			px.Pixman_format_code_t.r8g8b8x8
		}
		.argb2101010 {
			px.Pixman_format_code_t.a2r10g10b10
		}
		.xrgb2101010 {
			px.Pixman_format_code_t.x2r10g10b10
		}
		.abgr2101010 {
			px.Pixman_format_code_t.a2b10g10r10
		}
		.xbgr2101010 {
			px.Pixman_format_code_t.x2b10g10r10
		}
		else {
			error('Unsupported format')
		}
	}
}

fn get_min_stride(fmt wlp.WlShm_Format, width u32) u32 {
	format := get_pixman_format(fmt) or { px.Pixman_format_code_t.b8g8r8a8 }
	bpp := px.pixman_format_bpp(int(format))
	return ((width * bpp + 0x1f) >> 5) * 4
}

fn compute_composite_region(out2com &C.pixman_f_transform, output_width int, output_height int) (Box, bool) {
	mut o2c_fixedpt := C.pixman_transform{}
	C.pixman_transform_from_pixman_f_transform(&o2c_fixedpt, out2com)

	w := px.pixman_int_to_fixed(output_width)
	h := px.pixman_int_to_fixed(output_height)
	mut corner0 := C.pixman_vector{}
	mut corner1 := C.pixman_vector{}
	mut corner2 := C.pixman_vector{}
	mut corner3 := C.pixman_vector{}

	unsafe {
		corner0.vector[0] = 0
		corner0.vector[1] = 0
		corner0.vector[2] = px.pixman_fixed_1

		corner1.vector[0] = w
		corner1.vector[1] = 0
		corner1.vector[2] = px.pixman_fixed_1

		corner2.vector[0] = 0
		corner2.vector[1] = h
		corner2.vector[2] = px.pixman_fixed_1

		corner3.vector[0] = w
		corner3.vector[1] = h
		corner3.vector[2] = px.pixman_fixed_1
	}
	mut x_min := i32(math.maxof[i32]())
	mut x_max := i32(math.minof[i32]())
	mut y_min := i32(math.maxof[i32]())
	mut y_max := i32(math.minof[i32]())

	unsafe {
		C.pixman_transform_point(&o2c_fixedpt, &corner0)
		C.pixman_transform_point(&o2c_fixedpt, &corner1)
		C.pixman_transform_point(&o2c_fixedpt, &corner2)
		C.pixman_transform_point(&o2c_fixedpt, &corner3)
	}
	for corner in [corner0, corner1, corner2, corner3] {
		if corner.vector[0] < x_min {
			x_min = corner.vector[0]
		}
		if corner.vector[0] > x_max {
			x_max = corner.vector[0]
		}
		if corner.vector[1] < y_min {
			y_min = corner.vector[1]
		}
		if corner.vector[1] > y_max {
			y_max = corner.vector[1]
		}
	}

	grid_aligned := px.pixman_fixed_frac(x_min) == 0 && px.pixman_fixed_frac(x_max) == 0
		&& px.pixman_fixed_frac(y_min) == 0 && px.pixman_fixed_frac(y_max) == 0

	x1 := px.pixman_fixed_to_int(px.pixman_fixed_floor(x_min))
	x2 := px.pixman_fixed_to_int(px.pixman_fixed_ceil(x_max))
	y1 := px.pixman_fixed_to_int(px.pixman_fixed_floor(y_min))
	y2 := px.pixman_fixed_to_int(px.pixman_fixed_ceil(y_max))

	dest := Box{
		x:      x1
		y:      y1
		width:  x2 - x1
		height: y2 - y1
	}

	return dest, grid_aligned
}

fn render(state &State, geometry &Geometry, scale f64) !&C.pixman_image_t {
	common_width := int(geometry.width * scale)
	common_height := int(geometry.height * scale)
	common_image := C.pixman_image_create_bits(px.Pixman_format_code_t.a8r8g8b8, common_width,
		common_height, unsafe { nil }, 0)
	if common_image == unsafe { nil } {
		return error('failed to create image with size: ${common_width} x ${common_height}')
	}

	for capture in state.captures {
		buffer := capture.buffer or { continue }

		pixman_fmt := get_pixman_format(buffer.shm_format) or {
			return error('unsupported format ${buffer.shm_format}')
		}

		output_x := capture.logical_geometry.x - geometry.x
		output_y := capture.logical_geometry.y - geometry.y
		output_width := capture.logical_geometry.width
		output_height := capture.logical_geometry.height

		mut raw_output_width := buffer.width
		mut raw_output_height := buffer.height
		raw_output_width, raw_output_height = transform_output(capture.transform, raw_output_width,
			raw_output_height)

		output_flipped_x := get_output_flipped(capture.transform)
		output_flipped_y := 1

		output_image := C.pixman_image_create_bits(pixman_fmt, buffer.width, buffer.height,
			buffer.data, buffer.stride)
		if output_image == unsafe { nil } {
			C.pixman_image_unref(common_image)
			return error('Failed to create output image')
		}

		mut out2com := C.pixman_f_transform{}
		C.pixman_f_transform_init_identity(&out2com)
		C.pixman_f_transform_translate(&out2com, unsafe { nil }, -f64(buffer.width) / 2,
			-f64(buffer.height) / 2)
		C.pixman_f_transform_scale(&out2com, unsafe { nil }, f64(output_width) / raw_output_width,
			f64(output_height) * output_flipped_y / raw_output_height)
		C.pixman_f_transform_rotate(&out2com, unsafe { nil }, math.round(math.cos(get_output_rotation(capture.transform))),
			math.round(math.sin(get_output_rotation(capture.transform))))
		C.pixman_f_transform_scale(&out2com, unsafe { nil }, f64(output_flipped_x), 1)
		C.pixman_f_transform_translate(&out2com, unsafe { nil }, f64(output_width) / 2,
			f64(output_height) / 2)
		C.pixman_f_transform_translate(&out2com, unsafe { nil }, f64(output_x), f64(output_y))
		C.pixman_f_transform_scale(&out2com, unsafe { nil }, scale, scale)

		composite_dest, grid_aligned := compute_composite_region(&out2com, buffer.width,
			buffer.height)

		C.pixman_f_transform_translate(&out2com, unsafe { nil }, f64(-composite_dest.x),
			f64(-composite_dest.y))

		mut com2out := C.pixman_f_transform{}
		C.pixman_f_transform_invert(&com2out, &out2com)
		mut c2o_fixedpt := C.pixman_transform{}
		C.pixman_transform_from_pixman_f_transform(&c2o_fixedpt, &com2out)
		C.pixman_image_set_transform(output_image, &c2o_fixedpt)

		x_scale := math.max(math.abs(out2com.m[0][0]), math.abs(out2com.m[0][1]))
		y_scale := math.max(math.abs(out2com.m[1][0]), math.abs(out2com.m[1][1]))

		if x_scale >= 0.75 && y_scale >= 0.75 {
			C.pixman_image_set_filter(output_image, px.Pixman_filter_t.bilinear, unsafe { nil },
				0)
		} else {
			mut n_values := 0
			conv := C.pixman_filter_create_separable_convolution(&n_values, px.pixman_double_to_fixed(math.max(1.0,
				1.0 / x_scale)), px.pixman_double_to_fixed(math.max(1.0, 1.0 / y_scale)),
				px.Pixman_kernel_t.impulse, px.Pixman_kernel_t.impulse, px.Pixman_kernel_t.lanczos2,
				px.Pixman_kernel_t.lanczos2, 2, 2)
			C.pixman_image_set_filter(output_image, px.Pixman_filter_t.seperable_convolution,
				conv, n_values)
			unsafe { free(conv) }
		}

		mut overlapping := false
		for other_capture in state.captures {
			if capture != other_capture
				&& intersect_box(&capture.logical_geometry, &other_capture.logical_geometry) {
				overlapping = true
				break
			}
		}

		op := if grid_aligned && !overlapping {
			px.Pixman_op_t.src
		} else {
			px.Pixman_op_t.over
		}

		unsafe {
			C.pixman_image_composite32(op, output_image, nil, common_image, i32(0), i32(0),
				i32(0), i32(0), i32(composite_dest.x), i32(composite_dest.y), u32(composite_dest.width),
				u32(composite_dest.height))
		}

		C.pixman_image_unref(output_image)
	}

	// transpareny for toplevel
	has_toplevel := state.captures.any(it.toplevel != none)
	has_output := state.captures.any(it.output != none)
	if has_toplevel && !has_output {
		data := unsafe { &u32(C.pixman_image_get_data(common_image)) }
		stride_bytes := C.pixman_image_get_stride(common_image)
		for y in 0 .. common_height {
			row := unsafe { &u32(&u8(data) + y * stride_bytes) }
			for x in 0 .. common_width {
				pixel := unsafe { row[x] }
				if pixel & 0x00FFFFFF == 0 {
					unsafe { row[x] = 0x0000000 }
				}
			}
		}
	}

	return common_image
}
