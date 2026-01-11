module main

@[direct_array_access]
fn encode_ppm(image &C.pixman_image_t) []u8 {
	width := C.pixman_image_get_width(image)
	height := C.pixman_image_get_height(image)

	header := 'P6\n${width} ${height}\n255\n'

	mut buffer := []u8{}

	format := C.pixman_image_get_format(image)
	if format !in [.a8r8g8b8, .x8r8g8b8] {
		panic('PPM only supports up to 8 bit color depth')
	}

	pixels := C.pixman_image_get_data(image)
	for i in 0 .. height * width {
		p := unsafe { pixels[i] }
		buffer << [u8(p >> 16) & 0xff, u8(p >> 8) & 0xff, u8(p) & 0xff]
	}

	buffer.prepend(header.bytes())
	return buffer
}
