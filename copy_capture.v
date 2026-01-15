module main

import math
import protocols.wayland as wlp
import protocols.ext_image_copy_capture_v1 as cc

fn frame_handle_transform(mut capture Capture, frame &cc.ExtImageCopyCaptureFrameV1, transform u32) {
	capture.transform = unsafe { wlp.WlOutput_Transform(transform) }
}

fn frame_handle_ready(mut capture Capture, frame &cc.ExtImageCopyCaptureFrameV1) {
	capture.state.n_done++
}

fn frame_handle_failed(capture &Capture, frame &cc.ExtImageCopyCaptureFrameV1, reason u32) {
	name := if output := capture.output { output.name } else { 'unknown' }
	panic('failed to copy output ${name}, reason: ${reason}')
}

const frame_listener = C.ext_image_copy_capture_frame_v1_listener{
	transform:         frame_handle_transform
	damage:            fn (_ voidptr, _ voidptr, _ int, _ int, _ int, _ int) {}
	presentation_time: fn (_ voidptr, _ voidptr, _ u32, _ u32, _ u32) {}
	ready:             frame_handle_ready
	failed:            frame_handle_failed
}

fn session_handle_buffer_size(mut capture Capture, session &cc.ExtImageCopyCaptureSessionV1, width u32, height u32) {
	capture.buffer_width = width
	capture.buffer_height = height
	if capture.output == none {
		capture.logical_geometry.width = int(width)
		capture.logical_geometry.height = int(height)
	}
}

fn session_handle_shm_format(mut capture Capture, session &cc.ExtImageCopyCaptureSessionV1, format u32) {
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

fn session_handle_done(mut capture Capture, session &cc.ExtImageCopyCaptureSessionV1) {
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

const session_listener = C.ext_image_copy_capture_session_v1_listener{
	buffer_size:   session_handle_buffer_size
	shm_format:    session_handle_shm_format
	dmabuf_device: fn (_ voidptr, _ voidptr, _ voidptr) {}
	dmabuf_format: fn (_ voidptr, _ voidptr, _ u32, _ voidptr) {}
	done:          session_handle_done
	stopped:       fn (_ voidptr, _ voidptr) {}
}

fn is_alpha_format(format wlp.WlShm_Format) bool {
	alpha_formats := [wlp.WlShm_Format.argb8888, .abgr8888, .bgra8888, .rgba8888, .argb2101010, .abgr2101010]
	return format in alpha_formats
}
