module main

import packer as pk
import fmt {Category}

@[direct_array_access]
fn encode_ppm(image &C.pixman_image_t, is_hdr bool) []u8 {
	width := C.pixman_image_get_width(image)
	height := C.pixman_image_get_height(image)
	stride := C.pixman_image_get_stride(image)
	format := C.pixman_image_get_format(image)

	category := Category.new(format)

	header := 'P6\n${width} ${height}\n255\n'

	pixels := unsafe {&u8(C.pixman_image_get_data(image))}
	mut buffer := []u8{}
	row_buffer := []u8{len: int(width) * 3}

	match category {
		._10c_32b {
			if is_hdr {
				for y in 0 .. height {
					unsafe {
						row_ptr := &u32(&u8(pixels) + y * stride)
						pk.pack_row32_10_hdr_to_32_8(row_ptr, width, row_buffer.data, true, format)
					}
					buffer << row_buffer
				}
			} else {
				for y in 0 .. height {
					unsafe {
						row_ptr := &u32(&u8(pixels) + y * stride)
						pk.pack_row32_10_to_32_8(row_ptr, width, row_buffer.data, true, format)
					}
					buffer << row_buffer
				}
			}
		}
		._8c_32b {
			for y in 0 .. height {
				unsafe {
					row_ptr := &u32(&u8(pixels) + y * stride)
					pk.pack_row32_8(row_ptr, width, row_buffer.data, true, format)
				}
				buffer << row_buffer
			}
		}
		._8c_24b {
			for y in 0 .. height {
				unsafe {
					row_ptr := &u32(&u8(pixels) + y * stride)
					pk.pack_row24_8(&u8(row_ptr), width, row_buffer.data, format)
				}
				buffer << row_buffer
			}
		}
	}

	buffer.prepend(header.bytes())
	return buffer
}
