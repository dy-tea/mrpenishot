module png

import fmt { Category }
import packer as pk

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
pub fn encode_png(image &C.pixman_image_t, fully_opaque bool, is_hdr bool) ![]u8 {
	width := C.pixman_image_get_width(image)
	height := C.pixman_image_get_height(image)
	stride := C.pixman_image_get_stride(image)
	pixels := C.pixman_image_get_data(image)
	format := C.pixman_image_get_format(image)
	bits := C.pixman_image_get_depth(image)

	category := Category.new(format)
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

	if category == ._10c_32b {
		C.png_set_cICP(png_ptr, info, 9, 14, 0, 1)
	}
	C.png_set_IHDR(png_ptr, info, u32(width), u32(height), if category == ._10c_32b { 16 } else { 8 }, color_type, png_interlace_none,
		png_compression_type_base, png_filter_type_base)
	C.png_write_info(png_ptr, info)

	row_buffer := []u8{len: int(width) * if fully_opaque { 3 } else { 4 } * bits / 8}
	match category {
		._10c_32b {
			if is_hdr {
				for y in 0 .. height {
					unsafe {
						row_ptr := &u32(&u8(pixels) + y * stride)
						pk.pack_row32_10_hdr(&u32(row_ptr), width, row_buffer.data, fully_opaque, format)
						C.png_write_row(png_ptr, row_buffer.data)
					}
				}
			} else {
				for y in 0 .. height {
					unsafe {
						row_ptr := &u32(&u8(pixels) + y * stride)
						pk.pack_row32_10(&u32(row_ptr), width, row_buffer.data, fully_opaque, format)
						C.png_write_row(png_ptr, row_buffer.data)
					}
				}
			}
		}
		._8c_32b {
			for y in 0 .. height {
				unsafe {
					row_ptr := &u32(&u8(pixels) + y * stride)
					pk.pack_row32_8(&u32(row_ptr), width, row_buffer.data, fully_opaque, format)
					C.png_write_row(png_ptr, row_buffer.data)
				}
			}
		}
		._8c_24b {
			for y in 0 .. height {
				unsafe {
					row_ptr := &u32(&u8(pixels) + y * stride)
					pk.pack_row24_8(&u8(row_ptr), width, row_buffer.data, format)
					C.png_write_row(png_ptr, row_buffer.data)
				}
			}
		}
	}

	C.png_write_end(png_ptr, info)
	C.png_destroy_write_struct(&png_ptr, &info)

	return ctx.buffer
}
