module png

import pixman as px
import fmt { Category }
import packer as pk

struct PngWriteContext {
mut:
	buffer []u8
}

fn png_write_callback(png_ptr voidptr, data &u8, length uint) {
	mut ctx := unsafe { &PngWriteContext(C.png_get_io_ptr(png_ptr)) }
	ctx.buffer << unsafe { voidptr(data).vbytes(int(length)) }
}

fn png_flush_callback(_ voidptr) {
	// no-op for memory writing
}

@[direct_array_access]
pub fn encode_png(image voidptr, fully_opaque bool, is_hdr bool) ![]u8 {
	width := C.pixman_image_get_width(image)
	height := C.pixman_image_get_height(image)
	stride := C.pixman_image_get_stride(image)
	pixels := px.image_bytes(image)
	format := C.pixman_image_get_format(image)

	category := Category.new(format)
	// A 24 bit source has no alpha channel, so it is always written as RGB.
	has_alpha := !fully_opaque && category != ._8c_24b
	color_type := if has_alpha { 2 | 4 } else { 2 }
	bytes_per_pixel := match category {
		._10c_32b {
			if has_alpha { 8 } else { 6 }
		}
		._8c_24b {
			3
		}
		._8c_32b {
			if has_alpha { 4 } else { 3 }
		}
	}

	png_ptr := C.png_create_write_struct(png_libpng_ver_string, voidptr(0), voidptr(0),
		voidptr(0))
	if png_ptr == voidptr(0) {
		return error('failed to create PNG write struct')
	}

	info := C.png_create_info_struct(png_ptr)
	if info == voidptr(0) {
		C.png_destroy_write_struct(&png_ptr, voidptr(0))
		return error('failed to create PNG info struct')
	}

	mut ctx := PngWriteContext{}
	C.png_set_write_fn(png_ptr, &ctx, png_write_callback, png_flush_callback)

	if category == ._10c_32b {
		C.png_set_cICP(png_ptr, info, 9, 14, 0, 1)
	}
	C.png_set_IHDR(png_ptr, info, u32(width), u32(height), if category == ._10c_32b {
		16
	} else {
		8
	},
		color_type, png_interlace_none, png_compression_type_base, png_filter_type_base)
	C.png_write_info(png_ptr, info)

	mut row_buffer := []u8{len: int(width) * bytes_per_pixel}
	match category {
		._10c_32b {
			for y in 0 .. height {
				row_in := pixels[y * stride..(y + 1) * stride]
				if is_hdr {
					pk.pack_row32_10_hdr(row_in, width, mut row_buffer, fully_opaque, format)
				} else {
					pk.pack_row32_10(row_in, width, mut row_buffer, fully_opaque, format)
				}
				C.png_write_row(png_ptr, row_buffer.data)
			}
		}
		._8c_32b {
			for y in 0 .. height {
				row_in := pixels[y * stride..(y + 1) * stride]
				pk.pack_row32_8(row_in, width, mut row_buffer, fully_opaque, format)
				C.png_write_row(png_ptr, row_buffer.data)
			}
		}
		._8c_24b {
			for y in 0 .. height {
				row_in := pixels[y * stride..(y + 1) * stride]
				pk.pack_row24_8(row_in, width, mut row_buffer)
				C.png_write_row(png_ptr, row_buffer.data)
			}
		}
	}

	C.png_write_end(png_ptr, info)
	C.png_destroy_write_struct(&png_ptr, &info)

	return ctx.buffer
}
