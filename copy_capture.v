module main

import math
import protocols.wayland as wlp
import protocols.ext_image_copy_capture_v1 as cc

fn frame_handle_transform(mut capture Capture, obj voidptr, transform u32) {
	capture.transform = unsafe { wlp.WlOutput_Transform(transform) }
}

fn frame_handle_ready(mut capture Capture, obj voidptr) {
	capture.state.n_done++
}

fn frame_handle_failed(mut capture Capture, obj voidptr, reason u32) {
	name := if output := capture.output { output.name } else { 'unknown' }
	panic('failed to copy output ${name}, reason: ${reason}')
}

const frame_listener = cc.extimagecopycaptureframev1_listener(frame_handle_transform,
	none, none, frame_handle_ready, frame_handle_failed)

fn session_handle_buffer_size(mut capture Capture, obj voidptr, width u32, height u32) {
	capture.buffer_width = width
	capture.buffer_height = height
	if capture.output == none {
		capture.logical_geometry.width = int(width)
		capture.logical_geometry.height = int(height)
	}
}

fn session_handle_shm_format(mut capture Capture, obj voidptr, format u32) {
	fmt := unsafe { wlp.WlShm_Format(format) }
	is_toplevel := capture.toplevel != none
	if current_fmt := capture.shm_format {
		if is_toplevel && is_alpha_format(fmt) {
			if !is_alpha_format(current_fmt) {
				get_pixman_format(fmt) or { return }
				capture.shm_format = fmt
			}
		}
		return
	}
	get_pixman_format(fmt) or { return }
	capture.shm_format = fmt
}

fn session_handle_done(mut capture Capture, obj voidptr) {
	if capture.ext_image_copy_capture_frame_v1 != none {
		return
	}
	shm_format := capture.shm_format or { panic('no supported shm format found') }
	mut shm := capture.state.shm or { return }

	stride := get_min_stride(shm_format, capture.buffer_width)
	capture.buffer = Buffer.new(mut shm, shm_format, int(capture.buffer_width), int(capture.buffer_height),
		int(stride))

	mut sess := capture.ext_image_copy_capture_session_v1 or { return }
	mut frame := sess.create_frame()
	capture.ext_image_copy_capture_frame_v1 = frame
	frame.add_listener(&frame_listener, capture)

	mut buffer := capture.buffer or { return }
	frame.attach_buffer(buffer.wl_buffer.proxy)
	i32_max := math.maxof[i32]()
	frame.damage_buffer(0, 0, i32_max, i32_max)
	frame.capture()
}

const session_listener = cc.extimagecopycapturesessionv1_listener(session_handle_buffer_size,
	session_handle_shm_format, none, none, session_handle_done, none)

fn is_alpha_format(format wlp.WlShm_Format) bool {
	alpha_formats := [wlp.WlShm_Format.argb8888, .abgr8888, .bgra8888, .rgba8888, .argb2101010,
		.abgr2101010]
	return format in alpha_formats
}
