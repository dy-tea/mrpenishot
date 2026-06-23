module main

import math
import dy_tea.wayland as wl

fn make_session_events() wl.ExtImageCopyCaptureSessionV1Events[&Capture] {
	return wl.ExtImageCopyCaptureSessionV1Events[&Capture]{
		buffer_size: fn (mut c Capture, width u32, height u32) {
			c.buffer_width = width
			c.buffer_height = height
			if c.output == none {
				c.logical_geometry.width = int(width)
				c.logical_geometry.height = int(height)
			}
		}
		shm_format:  fn (mut c Capture, format u32) {
			fmt := unsafe { wl.WlShmFormat(format) }
			is_toplevel := c.toplevel != none
			if current_fmt := c.shm_format {
				if is_toplevel && is_alpha_format(fmt) {
					if !is_alpha_format(current_fmt) {
						get_pixman_format(fmt) or { return }
						c.shm_format = fmt
					}
				}
				return
			}
			get_pixman_format(fmt) or { return }
			c.shm_format = fmt
		}
		done:        fn (mut c Capture) {
			if c.ext_image_copy_capture_frame_v1 != none {
				return
			}
			shm_format := c.shm_format or { return }
			mut shm := c.state.shm or { return }

			stride := get_min_stride(shm_format, c.buffer_width)
			c.buffer = Buffer.new(mut shm, shm_format, int(c.buffer_width), int(c.buffer_height),
				int(stride))

			mut sess := c.ext_image_copy_capture_session_v1 or { return }
			mut frame := sess.create_frame() or { return }
			c.ext_image_copy_capture_frame_v1 = frame

			// Register this frame in the dispatch map
			c.state.captures_by_sess[frame.id] = c

			mut buffer := c.buffer or { return }
			frame.attach_buffer(buffer.wl_buffer) or {}
			i32_max := math.maxof[i32]()
			frame.damage_buffer(0, 0, i32_max, i32_max) or {}
			frame.capture() or {}
		}
	}
}

fn make_frame_events() wl.ExtImageCopyCaptureFrameV1Events[&Capture] {
	return wl.ExtImageCopyCaptureFrameV1Events[&Capture]{
		transform: fn (mut c Capture, transform u32) {
			c.transform = i32(transform)
		}
		ready:     fn (mut c Capture) {
			c.state.n_done++
		}
		failed:    fn (mut c Capture, reason u32) {
			name := if output := c.output { output.name } else { 'unknown' }
			panic('failed to copy output ${name}, reason: ${reason}')
		}
	}
}

fn is_alpha_format(format wl.WlShmFormat) bool {
	alpha_formats := [wl.WlShmFormat.argb8888, .abgr8888, .bgra8888, .rgba8888, .argb2101010,
		.abgr2101010]
	return format in alpha_formats
}
