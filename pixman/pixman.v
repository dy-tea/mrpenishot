module pixman

pub fn image_bytes(image C.pixman_image_t) []u8 {
	stride := C.pixman_image_get_stride(image)
	height := C.pixman_image_get_height(image)
	return unsafe { C.pixman_image_get_data(image).vbytes(stride * height) }
}
