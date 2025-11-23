module main

import wl
import pixman as px

#flag -I./include
#include "wlr-screencopy-unstable-v1-protocol.h"

fn get_pixman_format(wl_fmt wl.Wl_shm_format) px.Pixman_format_code_t {
	return match wl_fmt {
		.wl_shm_format_argb_8888 {
			px.Pixman_format_code_t.b8g8r8a8
		}
		.wl_shm_format_xrgb_8888 {
			px.Pixman_format_code_t.b8g8r8x8
		}
		.wl_shm_format_abgr_8888 {
			px.Pixman_format_code_t.r8g8b8a8
		}
		.wl_shm_format_xbgr_8888 {
			px.Pixman_format_code_t.r8g8b8x8
		}
		.wl_shm_format_bgra_8888 {
			px.Pixman_format_code_t.a8r8g8b8
		}
		.wl_shm_format_bgrx_8888 {
			px.Pixman_format_code_t.x8r8g8b8
		}
		.wl_shm_format_rgba_8888 {
			px.Pixman_format_code_t.a8b8g8r8
		}
		.wl_shm_format_rgbx_8888 {
			px.Pixman_format_code_t.x8b8g8r8
		}
		else {
			panic("Unsupported format")
		}
	}
}
