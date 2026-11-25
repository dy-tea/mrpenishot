module jxl

import pixman as px
import fmt { Category }
import packer as pk

pub fn encode_jxl(image voidptr, fully_opaque bool, is_hdr bool) ![]u8 {
	width := C.pixman_image_get_width(image)
	height := C.pixman_image_get_height(image)
	format := C.pixman_image_get_format(image)
	pixels := px.image_bytes(image)
	stride := C.pixman_image_get_stride(image)

	category := Category.new(format)
	// A 24 bit source has no alpha channel, so it is always encoded as RGB.
	has_alpha := !fully_opaque && category != ._8c_24b

	// create encoder
	enc := C.JxlEncoderCreate(voidptr(0))
	if enc == voidptr(0) {
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
	basic_info.num_extra_channels = if has_alpha { u32(1) } else { u32(0) }
	basic_info.uses_original_profile = 1

	if C.JxlEncoderSetBasicInfo(enc, &basic_info) != .success {
		return error('failed to set basic info')
	}

	// set color encoding
	mut color_encoding := C.JxlColorEncoding{}
	C.JxlColorEncodingSetToSRGB(&color_encoding, 0)

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
	frame_settings := C.JxlEncoderFrameSettingsCreate(enc, voidptr(0))
	C.JxlEncoderFrameSettingsSetOption(frame_settings, .modular, 1)
	C.JxlEncoderSetFrameLossless(frame_settings, 1)
	C.JxlEncoderSetFrameDistance(frame_settings, 0.0)

	// pixel packing
	bytes_per_chan := if is_hdr { 2 } else { 1 }
	channels := if has_alpha { 4 } else { 3 }
	mut buffer := []u8{}
	mut row_buffer := []u8{len: width * channels * bytes_per_chan}

	match category {
		._10c_32b {
			for y in 0 .. height {
				row_in := pixels[y * stride..(y + 1) * stride]
				pk.pack_row32_10(row_in, width, mut row_buffer, fully_opaque, format)
				buffer << row_buffer
			}
		}
		._8c_32b {
			for y in 0 .. height {
				row_in := pixels[y * stride..(y + 1) * stride]
				pk.pack_row32_8(row_in, width, mut row_buffer, fully_opaque, format)
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

	pixel_format := C.JxlPixelFormat{
		num_channels: u32(channels)
		data_type:    if is_hdr { .uint16 } else { .uint8 }
		endianness:   .big_endian
		align:        0
	}

	if C.JxlEncoderAddImageFrame(frame_settings, &pixel_format, buffer.data, uint(buffer.len)) != .success {
		return error('failed to add image frame')
	}

	C.JxlEncoderCloseInput(enc)

	mut output := []u8{cap: 65536}
	mut next_out := voidptr(0)
	mut avail_out := uint(0)

	for {
		status := C.JxlEncoderProcessOutput(enc, &next_out, &avail_out)
		match status {
			.success {
				break
			}
			.need_more_output {
				offset := output.len
				output << []u8{len: 65536}
				next_out = output[offset..].data
				avail_out = 65536
			}
			else {
				return error('encoding failed: ${C.JxlEncoderGetError(enc)}')
			}
		}
	}

	return output
}
