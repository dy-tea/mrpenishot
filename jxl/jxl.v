module jxl

import os

pub fn write_to_jxl(image &C.pixman_image_t, path string) ! {
	width := C.pixman_image_get_width(image)
	height := C.pixman_image_get_height(image)
	format := C.pixman_image_get_format(image)
	pixels := C.pixman_image_get_data(image)

	if format !in [.a8r8g8b8, .x8r8g8b8] {
		return error('unsupported format')
	}

	// create encoder
	enc := C.JxlEncoderCreate(unsafe { nil })
	if enc == unsafe { nil } {
		return error('failed to create encoder')
	}
	defer {
		C.JxlEncoderDestroy(enc)
	}

	// configure basic info
	mut basic_info := C.JxlBasicInfo{}
	C.JxlEncoderInitBasicInfo(&basic_info)
	basic_info.xsize = u32(width)
	basic_info.ysize = u32(height)
	basic_info.bits_per_sample = 8
	basic_info.exponent_bits_per_sample = 0
	basic_info.uses_original_profile = false
	basic_info.num_color_channels = 3
	basic_info.num_extra_channels = if format == .a8r8g8b8 { u32(1) } else { u32(0) }

	if C.JxlEncoderSetBasicInfo(enc, &basic_info) != .success {
		return error('failed to set basic info')
	}

	// set color encoding for srgb
	mut color_encoding := C.JxlColorEncoding{}
	C.JxlColorEncodingSetToSRGB(&color_encoding, false)
	if C.JxlEncoderSetColorEncoding(enc, &color_encoding) != .success {
		return error('failed to set color encoding')
	}

	// get frame settings
	frame_settings := C.JxlEncoderFrameSettingsCreate(enc, unsafe { nil })
	if frame_settings == unsafe { nil } {
		return error('failed to create frame settings')
	}

	// lossless
	C.JxlEncoderSetFrameLossless(frame_settings, true)
	C.JxlEncoderFrameSettingsSetOption(frame_settings, .effort, 7)

	// rgba for jxl
	pixel_count := width * height
	mut buffer := []u8{len: pixel_count * 4}
	for i in 0 .. pixel_count {
		p := unsafe { pixels[i] }
		r := u8((p >> 16) & 0xff)
		g := u8((p >> 8) & 0xff)
		b := u8(p & 0xff)
		a := u8(p >> 24)
		buffer[i * 4] = r
		buffer[i * 4 + 1] = g
		buffer[i * 4 + 2] = b
		buffer[i * 4 + 3] = a
	}

	// set pixel format
	pixel_format := C.JxlPixelFormat{
		num_channels: if format == .a8r8g8b8 { u32(4) } else { u32(3) }
		data_type: .uint8
		endianness: .native_endian
		align: 0
	}

	// add image frame
	if C.JxlEncoderAddImageFrame(frame_settings, &pixel_format, buffer.data, usize(buffer.len)) != .success {
		return error('failed to add image frame')
	}

	// close input
	C.JxlEncoderCloseInput(enc)

	// process output
	mut output := []u8{cap: pixel_count * 4}
	mut next_out := unsafe { &u8(0) }
	mut avail_out := usize(0)

	for {
		status := C.JxlEncoderProcessOutput(enc, &next_out, &avail_out)
		match status {
			.success {
				break
			}
			.need_more_output {
				offset := output.len
				unsafe { output.grow_len(65536) }
				next_out = unsafe { &output[offset] }
				avail_out = 65536
			}
			else {
				return error('encoding failed')
			}
		}
	}

	// write to file
	os.write_file(path, output.bytestr())!
}
