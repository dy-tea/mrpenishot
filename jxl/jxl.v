module jxl

import fmt { Category }
import packer as pk

pub fn encode_jxl(image &C.pixman_image_t, fully_opaque bool, is_hdr bool) ![]u8 {
	width := C.pixman_image_get_width(image)
	height := C.pixman_image_get_height(image)
	format := C.pixman_image_get_format(image)
	pixels := unsafe { &u8(C.pixman_image_get_data(image)) }
	stride := C.pixman_image_get_stride(image)

	category := Category.new(format)

	// create encoder
	enc := C.JxlEncoderCreate(unsafe { nil })
	if enc == unsafe { nil } {
		return error('failed to create encoder')
	}
	defer { C.JxlEncoderDestroy(enc) }

	// set basic info
	mut basic_info := C.JxlBasicInfo{}
	C.JxlEncoderInitBasicInfo(&basic_info)
	basic_info.xsize = u32(width)
	basic_info.ysize = u32(height)
	basic_info.bits_per_sample = if is_hdr { u32(16) } else { u32(8) }
	basic_info.num_color_channels = 3
	basic_info.num_extra_channels = if fully_opaque { u32(0) } else { u32(1) }
	basic_info.uses_original_profile = false

	if C.JxlEncoderSetBasicInfo(enc, &basic_info) != .success {
		return error('failed to set basic info')
	}

	// set color encoding
	mut color_encoding := C.JxlColorEncoding{}
	C.JxlColorEncodingSetToSRGB(&color_encoding, false)

	if is_hdr && category == ._10c_32b {
		color_encoding.color_space = .rgb
		color_encoding.primaries = ._2100
		color_encoding.transfer_function = .pq
		color_encoding.white_point = .d65
		color_encoding.rendering_intent = .relative
	}

	if C.JxlEncoderSetColorEncoding(enc, &color_encoding) != .success {
		println(color_encoding)
		return error('failed to set color encoding')
	}

	// set frame settings
	frame_settings := C.JxlEncoderFrameSettingsCreate(enc, unsafe { nil })
	C.JxlEncoderSetFrameLossless(frame_settings, true)

	// pixel packing
	bytes_per_chan := if is_hdr { 2 } else { 1 }
	channels := if fully_opaque { 3 } else { 4 }
	mut buffer := []u8{}
	mut row_buffer := []u8{len: width * channels * bytes_per_chan}

	match category {
		._10c_32b {
			for y in 0 .. height {
				unsafe {
					row_ptr := &u32(&u8(pixels) + y * stride)
					pk.pack_row32_10(&u32(row_ptr), width, row_buffer.data, fully_opaque, format)
				}
				buffer << row_buffer
			}
		}
		._8c_32b {
			for y in 0 .. height {
				unsafe {
					row_ptr := &u32(&u8(pixels) + y * stride)
					pk.pack_row32_8(&u32(row_ptr), width, row_buffer.data, fully_opaque, format)
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

	pixel_format := C.JxlPixelFormat{
		num_channels: u32(channels)
		data_type: if is_hdr { .uint16 } else { .uint8 }
		endianness: .big_endian
		align: 0
	}

	if C.JxlEncoderAddImageFrame(frame_settings, &pixel_format, buffer.data, usize(buffer.len)) != .success {
		return error('failed to add image frame')
	}

	C.JxlEncoderCloseInput(enc)

	mut output := []u8{cap: 65536}
	mut next_out := unsafe { &u8(0) }
	mut avail_out := usize(0)

	for {
		status := C.JxlEncoderProcessOutput(enc, &next_out, &avail_out)
		match status {
			.success { break }
			.need_more_output {
				offset := output.len
				unsafe { output.grow_len(65536) }
				next_out = unsafe { &output[offset] }
				avail_out = 65536
			}
			else { return error('encoding failed') }
		}
	}

	return output
}
