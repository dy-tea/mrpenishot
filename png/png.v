module png

@[unsafe]
fn pack_row32(row_in &u32, width int, fully_opaque bool, row_out &u8) {
	mut offset := 0
	for x in 0..width {
		pixel := unsafe { row_in[x] }
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

		unsafe {
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
}

pub fn write_to_png(image &C.pixman_image_t, path string) ! {
	width := C.pixman_image_get_width(image)
	height := C.pixman_image_get_height(image)
	stride := C.pixman_image_get_stride(image)
	format := C.pixman_image_get_format(image)
	pixels := C.pixman_image_get_data(image)

	if format !in [.a8r8g8b8, .x8r8g8b8] {
		return error('unsupported format')
	}

	mut fully_opaque := true
	if format == .a8r8g8b8 {
		for y in 0..height {
			row := unsafe { &u32(pixels + y * stride) }
			for x in 0..width {
				if unsafe { row[x] } >> 24 != 0xff {
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
	bit_depth := 8

	png_ptr := C.png_create_write_struct(png_libpng_ver_string, unsafe { nil }, unsafe { nil }, unsafe { nil })
	if png_ptr == unsafe { nil } {
		return error('failed to create PNG write struct')
	}

	info := C.png_create_info_struct(png_ptr)
	if info == unsafe { nil } {
		C.png_destroy_write_struct(&png_ptr, unsafe { nil })
		return error('failed to create PNG info struct')
	}

	stream := C.fopen(path.str, c'wb')
	if stream == unsafe { nil } {
		C.png_destroy_write_struct(&png_ptr, &info)
		return error('failed to open file: ${path}')
	}

	C.png_init_io(png_ptr, stream)

	C.png_set_IHDR(png_ptr, info, u32(width), u32(height), bit_depth, color_type,
		png_interlace_none, png_compression_type_base, png_filter_type_base)
	C.png_write_info(png_ptr, info)

	C.png_set_compression_level(png_ptr, 0)
	C.png_set_filter(png_ptr, 0, png_no_filters)

	bytes_per_pixel := if fully_opaque { 3 } else { 4 }
	row_buffer := []u8{len: int(width) * bytes_per_pixel}

	for y in 0..height {
		unsafe {
			row_ptr := &u32(&u8(pixels) + y * stride)
			pack_row32(row_ptr, width, fully_opaque, row_buffer.data)
			C.png_write_row(png_ptr, row_buffer.data)
		}
	}

	C.png_write_end(png_ptr, info)
	C.fclose(stream)
	C.png_destroy_write_struct(&png_ptr, &info)
}
