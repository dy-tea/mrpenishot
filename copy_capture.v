module main

import math
import wayland.protocols.wayland as wl
import wayland.protocols.ext_image_copy_capture_v1 as cc

struct FrameListener {
mut:
	capture &Capture
}

fn (mut l FrameListener) transform(_ cc.ExtImageCopyCaptureFrameV1, transform u32) {
	l.capture.transform = transform
}

fn (mut l FrameListener) damage(_ cc.ExtImageCopyCaptureFrameV1, _ i32, _ i32, _ i32, _ i32) {
}

fn (mut l FrameListener) presentation_time(_ cc.ExtImageCopyCaptureFrameV1, _ u32, _ u32, _ u32) {
}

fn (mut l FrameListener) ready(_ cc.ExtImageCopyCaptureFrameV1) {
	l.capture.state.n_done++
}

fn (mut l FrameListener) failed(_ cc.ExtImageCopyCaptureFrameV1, reason u32) {
	name := if output := l.capture.output { output.name } else { 'unknown' }
	panic('failed to copy output ${name}, reason: ${reason}')
}

struct SessionListener {
mut:
	capture &Capture
}

fn (mut l SessionListener) dmabuf_device(_ cc.ExtImageCopyCaptureSessionV1, _ []u8) {
}

fn (mut l SessionListener) dmabuf_format(_ cc.ExtImageCopyCaptureSessionV1, _ u32, _ []u8) {
}

fn (mut l SessionListener) stopped(_ cc.ExtImageCopyCaptureSessionV1) {
}

fn (mut l SessionListener) buffer_size(_ cc.ExtImageCopyCaptureSessionV1, width u32, height u32) {
	l.capture.buffer_width = width
	l.capture.buffer_height = height
	if l.capture.output == none {
		l.capture.logical_geometry.width = int(width)
		l.capture.logical_geometry.height = int(height)
	}
}

fn (mut l SessionListener) shm_format(_ cc.ExtImageCopyCaptureSessionV1, format u32) {
	is_toplevel := l.capture.toplevel != none
	if current_fmt := l.capture.shm_format {
		if is_toplevel && is_alpha_format(format) {
			if !is_alpha_format(current_fmt) {
				get_pixman_format(format) or { return }
				l.capture.shm_format = format
			}
		}
		return
	}
	get_pixman_format(format) or { return }
	l.capture.shm_format = format
}

fn (mut l SessionListener) done(_ cc.ExtImageCopyCaptureSessionV1) {
	if l.capture.ext_image_copy_capture_frame_v1 != none {
		return
	}
	shm_format := l.capture.shm_format or { panic('no supported shm format found') }
	mut shm := l.capture.state.shm or { return }

	stride := get_min_stride(shm_format, l.capture.buffer_width)
	l.capture.buffer = Buffer.new(mut shm, shm_format, int(l.capture.buffer_width), int(l.capture.buffer_height),
		int(stride))

	mut sess := l.capture.ext_image_copy_capture_session_v1 or { return }
	mut frame := sess.create_frame() or { return }
	l.capture.ext_image_copy_capture_frame_v1 = frame
	frame.set_listener(&FrameListener{
		capture: l.capture
	}) or {}
	mut buffer := l.capture.buffer or { return }
	frame.attach_buffer(buffer.wl_buffer) or {}
	i32_max := math.maxof[i32]()
	frame.damage_buffer(0, 0, i32_max, i32_max) or {}
	frame.capture() or {}
}

fn is_alpha_format(format u32) bool {
	alpha_formats := [wl.wl_shm_format_argb8888, wl.wl_shm_format_abgr8888, wl.wl_shm_format_bgra8888,
		wl.wl_shm_format_rgba8888, wl.wl_shm_format_argb2101010, wl.wl_shm_format_abgr2101010]
	return format in alpha_formats
}
