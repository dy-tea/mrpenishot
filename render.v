module main

import protocols.wayland as wlp
import pixman as px

fn get_pixman_format(wl_fmt wlp.WlShm_Format) px.Pixman_format_code_t {
	return match wl_fmt {
		.argb8888 {
			px.Pixman_format_code_t.b8g8r8a8
		}
		.xrgb8888 {
			px.Pixman_format_code_t.b8g8r8x8
		}
		.abgr8888 {
			px.Pixman_format_code_t.r8g8b8a8
		}
		.xbgr8888 {
			px.Pixman_format_code_t.r8g8b8x8
		}
		.bgra8888 {
			px.Pixman_format_code_t.a8r8g8b8
		}
		.bgrx8888 {
			px.Pixman_format_code_t.x8r8g8b8
		}
		.rgba8888 {
			px.Pixman_format_code_t.a8b8g8r8
		}
		.rgbx8888 {
			px.Pixman_format_code_t.x8b8g8r8
		}
		else {
			panic('Unsupported format')
		}
	}
}
