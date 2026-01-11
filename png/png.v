module png

import hdr

@[direct_array_access; unsafe]
fn pack_row32_8(row_in &u32, width int, fully_opaque bool, row_out &u8) {
	mut offset := 0
	for x in 0 .. width {
		pixel := row_in[x]
		mut b := u8((pixel >> 0) & 0xff)
		mut g := u8((pixel >> 8) & 0xff)
		mut r := u8((pixel >> 16) & 0xff)
		a := u8((pixel >> 24) & 0xff)

		if !fully_opaque && (a != 0 && a != 255) {
			inv := 0xff << 16 / a
			sr := int(r * inv)
			r = u8(if sr > (0xff << 16) { 0xff } else { sr >> 16 })
			sg := int(g * inv)
			g = u8(if sg > (0xff << 16) { 0xff } else { sg >> 16 })
			sb := int(b * inv)
			b = u8(if sb > (0xff << 16) { 0xff } else { sb >> 16 })
		}

		row_out[offset] = r
		row_out[offset + 1] = g
		row_out[offset + 2] = b
		offset += 3
		if !fully_opaque {
			row_out[offset] = a
			offset += 1
		}
	}
}

@[direct_array_access; unsafe]
fn pack_row32_10(row_in &u32, width int, fully_opaque bool, row_out &u8) {
	mut offset := 0
	for x in 0 .. width {
		pixel := row_in[x]

		mut r := (pixel >> 20) & 0x3ff
		mut g := (pixel >> 10) & 0x3ff
		mut b := (pixel >> 0) & 0x3ff
		a_2 := (pixel >> 30) & 0x03

		if !fully_opaque && a_2 > 0 && a_2 < 3 {
			r = (r * 3) / a_2
			g = (g * 3) / a_2
			b = (b * 3) / a_2
			if r > 1023 {
				r = 1023
			}
			if g > 1023 {
				g = 1023
			}
			if b > 1023 {
				b = 1023
			}
		}

		r_lin, g_lin, b_lin := hdr.apply_bt2020_to_srgb(hdr.pq_to_linear(r), hdr.pq_to_linear(g),
			hdr.pq_to_linear(b))

		r_16 := hdr.linear_to_srgb_16(r_lin)
		g_16 := hdr.linear_to_srgb_16(g_lin)
		b_16 := hdr.linear_to_srgb_16(b_lin)

		row_out[offset] = u8(r_16 >> 8)
		row_out[offset + 1] = u8(r_16 & 0xff)
		row_out[offset + 2] = u8(g_16 >> 8)
		row_out[offset + 3] = u8(g_16 & 0xff)
		row_out[offset + 4] = u8(b_16 >> 8)
		row_out[offset + 5] = u8(b_16 & 0xff)
		offset += 6

		if !fully_opaque {
			a_16 := u16(a_2 * 0x5555)
			row_out[offset] = u8(a_16 >> 8)
			row_out[offset + 1] = u8(a_16 & 0xff)
			offset += 2
		}
	}
}

struct PngWriteContext {
mut:
	buffer []u8
}

fn png_write_callback(png_ptr voidptr, data &u8, length usize) {
	mut ctx := unsafe { &PngWriteContext(C.png_get_io_ptr(png_ptr)) }
	unsafe {
		for i in 0 .. int(length) {
			ctx.buffer << data[i]
		}
	}
}

fn png_flush_callback(png_ptr voidptr) {
	// no-op for memory writing
}

@[direct_array_access]
pub fn encode_png(image &C.pixman_image_t) ![]u8 {
	width := C.pixman_image_get_width(image)
	height := C.pixman_image_get_height(image)
	stride := C.pixman_image_get_stride(image)
	format := C.pixman_image_get_format(image)
	pixels := C.pixman_image_get_data(image)

	bit_depth, is_10bit := match format {
		.a8r8g8b8, .x8r8g8b8 {
			8, false
		}
		.a2r10g10b10, .x2r10g10b10 {
			16, true
		}
		else {
			return error('unsupported format: 8-bit or 10-bit RGB required')
		}
	}

	mut fully_opaque := true
	if (!is_10bit && format == .a8r8g8b8) || format == .a2r10g10b10 {
		shift, comp := if is_10bit { 30, 3 } else { 24, 0xff }
		for y in 0 .. height {
			row := unsafe { &u32(pixels + y * stride) }
			for x in 0 .. width {
				if unsafe { row[x] } >> shift != comp {
					fully_opaque = false
					break
				}
			}
			if !fully_opaque {
				break
			}
		}
	}

	color_type := if fully_opaque { 2 } else { 2 | 4 }

	png_ptr := C.png_create_write_struct(png_libpng_ver_string, unsafe { nil }, unsafe { nil },
		unsafe { nil })
	if png_ptr == unsafe { nil } {
		return error('failed to create PNG write struct')
	}

	info := C.png_create_info_struct(png_ptr)
	if info == unsafe { nil } {
		C.png_destroy_write_struct(&png_ptr, unsafe { nil })
		return error('failed to create PNG info struct')
	}

	mut ctx := PngWriteContext{}
	C.png_set_write_fn(png_ptr, &ctx, png_write_callback, png_flush_callback)

	if is_10bit {
		C.png_set_cICP(png_ptr, info, 9, 14, 0, 1)
	}
	C.png_set_IHDR(png_ptr, info, u32(width), u32(height), bit_depth, color_type, png_interlace_none,
		png_compression_type_base, png_filter_type_base)
	C.png_write_info(png_ptr, info)

	row_buffer := []u8{len: int(width) * if fully_opaque { 3 } else { 4 } * bit_depth / 8}

	if is_10bit {
		for y in 0 .. height {
			unsafe {
				row_ptr := &u32(&u8(pixels) + y * stride)
				pack_row32_10(row_ptr, width, fully_opaque, row_buffer.data)
				C.png_write_row(png_ptr, row_buffer.data)
			}
		}
	} else {
		for y in 0 .. height {
			unsafe {
				row_ptr := &u32(&u8(pixels) + y * stride)
				pack_row32_8(row_ptr, width, fully_opaque, row_buffer.data)
				C.png_write_row(png_ptr, row_buffer.data)
			}
		}
	}

	C.png_write_end(png_ptr, info)
	C.png_destroy_write_struct(&png_ptr, &info)

	return ctx.buffer
}
