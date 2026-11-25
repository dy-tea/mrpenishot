module main

import pixman as px
import packer as pk
import fmt { Category }

@[direct_array_access]
fn encode_ppm(image voidptr, is_hdr bool) []u8 {
	width := C.pixman_image_get_width(image)
	height := C.pixman_image_get_height(image)
	stride := C.pixman_image_get_stride(image)
	format := C.pixman_image_get_format(image)

	category := Category.new(format)

	header := 'P6\n${width} ${height}\n255\n'

	pixels := px.image_bytes(image)
	mut buffer := []u8{}
	mut row_buffer := []u8{len: int(width) * 3}

	match category {
		._10c_32b {
			for y in 0 .. height {
				row_in := pixels[y * stride..(y + 1) * stride]
				if is_hdr {
					pk.pack_row32_10_hdr_to_32_8(row_in, width, mut row_buffer, true, format)
				} else {
					pk.pack_row32_10_to_32_8(row_in, width, mut row_buffer, true, format)
				}
				buffer << row_buffer
			}
		}
		._8c_32b {
			for y in 0 .. height {
				row_in := pixels[y * stride..(y + 1) * stride]
				pk.pack_row32_8(row_in, width, mut row_buffer, true, format)
				buffer << row_buffer
			}
		}
		._8c_24b {
			for y in 0 .. height {
				row_in := pixels[y * stride..(y + 1) * stride]
				pk.pack_row24_8(row_in, width, mut row_buffer)
				buffer << row_buffer
			}
		}
	}

	buffer.prepend(header.bytes())
	return buffer
}
