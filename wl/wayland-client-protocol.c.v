module wl

#flag linux -I/usr/include
#flag linux -lwayland-client
#include <wayland-client-protocol.h>

pub struct C.wl_buffer {}
pub struct C.wl_callback {}
pub struct C.wl_compositor {}
pub struct C.wl_data_device {}
pub struct C.wl_data_device_manager {}
pub struct C.wl_data_offer {}
pub struct C.wl_data_source {}
pub struct C.wl_display {}
pub struct C.wl_fixes {}
pub struct C.wl_keyboard {}
pub struct C.wl_output{}
pub struct C.wl_pointer {}
pub struct C.wl_region {}
pub struct C.wl_registry {}
pub struct C.wl_seat {}
pub struct C.wl_shm {}
pub struct C.wl_shm_pool {}
pub struct C.wl_subcompositor {}
pub struct C.wl_subsurface {}
pub struct C.wl_surface {}
pub struct C.wl_touch {}

__global C.wl_display_interface C.wl_interface
__global C.wl_registry_interface C.wl_interface
__global C.wl_callback_interface C.wl_interface
__global C.wl_compositor_interface C.wl_interface
__global C.wl_shm_pool_interface C.wl_interface
__global C.wl_shm_interface C.wl_interface
__global C.wl_buffer_interface C.wl_interface
__global C.wl_data_offer_interface C.wl_interface
__global C.wl_data_source_interface C.wl_interface
__global C.wl_data_device_interface C.wl_interface
__global C.wl_data_device_manager_interface C.wl_interface
__global C.wl_shell_interface C.wl_interface
__global C.wl_shell_surface_interface C.wl_interface
__global C.wl_surface_interface C.wl_interface
__global C.wl_seat_interface C.wl_interface
__global C.wl_pointer_interface C.wl_interface
__global C.wl_keyboard_interface C.wl_interface
__global C.wl_touch_interface C.wl_interface
__global C.wl_output_interface C.wl_interface
__global C.wl_region_interface C.wl_interface
__global C.wl_subcompositor_interface C.wl_interface
__global C.wl_subsurface_interface C.wl_interface
__global C.wl_fixes_interface C.wl_interface

// wl_display

pub enum Wl_display_error {
	invalid_object
	invalid_method
	no_memory
	implementation
}

struct C.wl_display_listener {
	error fn (data voidptr, wl_display &C.wl_display, object_id voidptr, code u32, message &char)
	delete_id fn (data voidptr, wl_display &C.wl_display, id u32)
}

fn C.wl_display_add_listener(wl_display &C.wl_display, listener &C.wl_display_listener, data voidptr) int

const wl_display_sync = 0
const wl_display_get_registry = 1

const wl_display_error_since_version = 1
const wl_display_delete_id_since_version = 1

const wl_display_sync_since_version = 1
const wl_display_get_registry_since_version = 1

fn C.wl_display_set_user_data(wl_display &C.wl_display, user_data voidptr)
fn C.wl_display_get_user_data(wl_display &C.wl_display) voidptr
fn C.wl_display_get_version(wl_display &C.wl_display) u32
fn C.wl_display_sync(wl_display &C.wl_display) &C.wl_callback
fn C.wl_display_get_registry(wl_display &C.wl_display) &C.wl_registry

// wl_registry

pub struct C.wl_registry_listener {
	global fn (voidptr, &C.wl_registry, u32, &char, u32)
	global_remove fn (voidptr, &C.wl_registry, u32)
}

fn C.wl_registry_add_listener(wl_registry &C.wl_registry, listener &C.wl_registry_listener, data voidptr) int

pub const wl_registry_bind = 0

pub const wl_registry_global_since_version = 1
pub const wl_registry_global_remove_since_version = 1
pub const wl_registry_bind_since_version = 1

fn C.wl_registry_set_user_data(wl_registry &C.wl_registry, user_data voidptr)
fn C.wl_registry_get_user_data(wl_registry &C.wl_registry) voidptr
fn C.wl_registry_get_version(wl_registry &C.wl_registry) u32
fn C.wl_registry_destroy(wl_registry &C.wl_registry)
fn C.wl_registry_bind(&C.wl_registry, u32, &C.wl_interface, u32) voidptr

// wl_callback

struct C.wl_callback_listener {
	done fn (data voidptr, wl_callback &C.wl_callback, callback_data u32)
}

//...

// wl_compositor

const wl_compositor_create_surface = 0
const wl_compositor_create_region = 1

const wl_compositor_create_surface_since_version = 1
const wl_compositor_create_region_since_version = 1

fn C.wl_compositor_set_user_data(wl_compositor &C.wl_compositor, user_data voidptr)
fn C.wl_compositor_get_user_data(wl_compositor &C.wl_compositor) voidptr
fn C.wl_compositor_get_version(wl_compositor &C.wl_compositor) u32
fn C.wl_compositor_destroy(wl_compositor &C.wl_compositor)
fn C.wl_compositor_create_surface(wl_compositor &C.wl_compositor) &C.wl_surface
fn C.wl_compositor_create_region(wl_compositor &C.wl_compositor) &C.wl_region

// wl_shm_pool

const wl_shm_pool_create_buffer = 0
const wl_shm_pool_destroy = 1
const wl_shm_pool_resize = 2

const wl_shm_pool_create_buffer_since_version = 1
const wl_shm_pool_destroy_since_version = 1
const wl_shm_pool_resize_since_version = 1

fn C.wl_shm_pool_set_user_data(wl_shm_pool &C.wl_shm_pool, user_data voidptr)
fn C.wl_shm_pool_get_user_data(wl_shm_pool &C.wl_shm_pool) voidptr
fn C.wl_shm_pool_get_version(wl_shm_pool &C.wl_shm_pool) u32
fn C.wl_shm_pool_create_buffer(wl_shm_pool &C.wl_shm_pool, offset i32, width i32, height i32, stride i32, format u32) &C.wl_buffer
fn C.wl_shm_pool_destroy(wl_shm_pool &C.wl_shm_pool)
fn C.wl_shm_pool_resize(wl_shm_pool &C.wl_shm_pool, size i32)

// wl_shm

pub enum Wl_shm_error {
	invalid_format
	invalid_stride
	invalid_fd
}

pub enum Wl_shm_format {
	 // 32-BIT argb FORMAT [31:0] a:r:g:b 8:8:8:8 LITTLE ENDIAN
	argb8888 = 0
	 // 32-BIT rgb FORMAT [31:0] X:r:g:b 8:8:8:8 LITTLE ENDIAN
	xrgb8888 = 1
	 // 8-BIT COLOR INDEX FORMAT [7:0] c
	c8 = 0x20203843
	 // 8-BIT rgb FORMAT [7:0] r:g:b 3:3:2
	rgb332 = 0x38424752
	 // 8-BIT bgr FORMAT [7:0] b:g:r 2:3:3
	bgr233 = 0x38524742
	 // 16-BIT Xrgb FORMAT [15:0] X:r:g:b 4:4:4:4 LITTLE ENDIAN
	xrgb4444 = 0x32315258
	 // 16-BIT Xbgr FORMAT [15:0] X:b:g:r 4:4:4:4 LITTLE ENDIAN
	xbgr4444 = 0x32314258
	 // 16-BIT rgbX FORMAT [15:0] r:g:b:X 4:4:4:4 LITTLE ENDIAN
	rgbx4444 = 0x32315852
	 // 16-BIT bgrX FORMAT [15:0] b:g:r:X 4:4:4:4 LITTLE ENDIAN
	bgrx4444 = 0x32315842
	 // 16-BIT argb FORMAT [15:0] a:r:g:b 4:4:4:4 LITTLE ENDIAN
	argb4444 = 0x32315241
	 // 16-BIT abgr FORMAT [15:0] a:b:g:r 4:4:4:4 LITTLE ENDIAN
	abgr4444 = 0x32314241
	 // 16-BIT rbga FORMAT [15:0] r:g:b:a 4:4:4:4 LITTLE ENDIAN
	rgba4444 = 0x32314152
	 // 16-BIT bgra FORMAT [15:0] b:g:r:a 4:4:4:4 LITTLE ENDIAN
	bgra4444 = 0x32314142
	 // 16-BIT Xrgb FORMAT [15:0] X:r:g:b 1:5:5:5 LITTLE ENDIAN
	xrgb1555 = 0x35315258
	 // 16-BIT Xbgr 1555 FORMAT [15:0] X:b:g:r 1:5:5:5 LITTLE ENDIAN
	xbgr1555 = 0x35314258
	 // 16-BIT rgbX 5551 FORMAT [15:0] r:g:b:X 5:5:5:1 LITTLE ENDIAN
	rgbx5551 = 0x35315852
	 // 16-BIT bgrX 5551 FORMAT [15:0] b:g:r:X 5:5:5:1 LITTLE ENDIAN
	bgrx5551 = 0x35315842
	 // 16-BIT argb 1555 FORMAT [15:0] a:r:g:b 1:5:5:5 LITTLE ENDIAN
	argb1555 = 0x35315241
	 // 16-BIT abgr 1555 FORMAT [15:0] a:b:g:r 1:5:5:5 LITTLE ENDIAN
	abgr1555 = 0x35314241
	 // 16-BIT rgba 5551 FORMAT [15:0] r:g:b:a 5:5:5:1 LITTLE ENDIAN
	rgba5551 = 0x35314152
	 // 16-BIT bgra 5551 FORMAT [15:0] b:g:r:a 5:5:5:1 LITTLE ENDIAN
	bgra5551 = 0x35314142
	 // 16-BIT rgb 565 FORMAT [15:0] r:g:b 5:6:5 LITTLE ENDIAN
	rgb565 = 0x36314752
	 // 16-BIT bgr 565 FORMAT [15:0] b:g:r 5:6:5 LITTLE ENDIAN
	bgr565 = 0x36314742
	 // 24-BIT rgb FORMAT [23:0] r:g:b LITTLE ENDIAN
	rgb888 = 0x34324752
	 // 24-BIT bgr FORMAT [23:0] b:g:r LITTLE ENDIAN
	bgr888 = 0x34324742
	 // 32-BIT Xbgr FORMAT [31:0] X:b:g:r 8:8:8:8 LITTLE ENDIAN
	xbgr8888 = 0x34324258
	 // 32-BIT rgbX FORMAT [31:0] r:g:b:X 8:8:8:8 LITTLE ENDIAN
	rgbx8888 = 0x34325852
	 // 32-BIT bgrX FORMAT [31:0] b:g:r:X 8:8:8:8 LITTLE ENDIAN
	bgrx8888 = 0x34325842
	 // 32-BIT abgr FORMAT [31:0] a:b:g:r 8:8:8:8 LITTLE ENDIAN
	abgr8888 = 0x34324241
	 // 32-BIT rgba FORMAT [31:0] r:g:b:a 8:8:8:8 LITTLE ENDIAN
	rgba8888 = 0x34324152
	 // 32-BIT bgra FORMAT [31:0] b:g:r:a 8:8:8:8 LITTLE ENDIAN
	bgra8888 = 0x34324142
	 // 32-BIT Xrgb FORMAT [31:0] X:r:g:b 2:10:10:10 LITTLE ENDIAN
	xrgb2101010 = 0x30335258
	 // 32-BIT Xbgr FORMAT [31:0] X:b:g:r 2:10:10:10 LITTLE ENDIAN
	xbgr2101010 = 0x30334258
	 // 32-BIT rgbX FORMAT [31:0] r:g:b:X 10:10:10:2 LITTLE ENDIAN
	rgbx1010102 = 0x30335852
	 // 32-BIT bgrX FORMAT [31:0] b:g:r:X 10:10:10:2 LITTLE ENDIAN
	bgrx1010102 = 0x30335842
	 // 32-BIT argb FORMAT [31:0] a:r:g:b 2:10:10:10 LITTLE ENDIAN
	argb2101010 = 0x30335241
	 // 32-BIT abgr FORMAT [31:0] a:b:g:r 2:10:10:10 LITTLE ENDIAN
	abgr2101010 = 0x30334241
	 // 32-BIT rgba FORMAT [31:0] r:g:b:a 10:10:10:2 LITTLE ENDIAN
	rgba1010102 = 0x30334152
	 // 32-BIT bgra FORMAT [31:0] b:g:r:a 10:10:10:2 LITTLE ENDIAN
	bgra1010102 = 0x30334142
	 // PACKED ycBcR FORMAT [31:0] cR0:y1:cB0:y0 8:8:8:8 LITTLE ENDIAN
	yuyv = 0x56595559
	 // PACKED ycBcR FORMAT [31:0] cB0:y1:cR0:y0 8:8:8:8 LITTLE ENDIAN
	yvyu = 0x55595659
	 // PACKED ycBcR FORMAT [31:0] y1:cR0:y0:cB0 8:8:8:8 LITTLE ENDIAN
	uyvy = 0x59565955
	 // PACKED ycBcR FORMAT [31:0] y1:cB0:y0:cR0 8:8:8:8 LITTLE ENDIAN
	vyuy = 0x59555956
	 // PACKED aycBcR FORMAT [31:0] a:y:cB:cR 8:8:8:8 LITTLE ENDIAN
	ayuv = 0x56555941
	 // 2 PLANE ycBcR cR:cB FORMAT 2X2 SUBSAMPLED cR:cB PLANE
	nv12 = 0x3231564E
	 // 2 PLANE ycBcR cB:cR FORMAT 2X2 SUBSAMPLED cB:cR PLANE
	nv21 = 0x3132564E
	 // 2 PLANE ycBcR cR:cB FORMAT 2X1 SUBSAMPLED cR:cB PLANE
	nv16 = 0x3631564E
	 // 2 PLANE ycBcR cB:cR FORMAT 2X1 SUBSAMPLED cB:cR PLANE
	nv61 = 0x3136564E
	 // 3 PLANE ycBcR FORMAT 4X4 SUBSAMPLED cB (1) AND cR (2) PLANES
	yuv410 = 0x39565559
	 // 3 PLANE ycBcR FORMAT 4X4 SUBSAMPLED cR (1) AND cB (2) PLANES
	yvu410 = 0x39555659
	 // 3 PLANE ycBcR FORMAT 4X1 SUBSAMPLED cB (1) AND cR (2) PLANES
	yuv411 = 0x31315559
	 // 3 PLANE ycBcR FORMAT 4X1 SUBSAMPLED cR (1) AND cB (2) PLANES
	yvu411 = 0x31315659
	 // 3 PLANE ycBcR FORMAT 2X2 SUBSAMPLED cB (1) AND cR (2) PLANES
	yuv420 = 0x32315559
	 // 3 PLANE ycBcR FORMAT 2X2 SUBSAMPLED cR (1) AND cB (2) PLANES
	yvu420 = 0x32315659
	 // 3 PLANE ycBcR FORMAT 2X1 SUBSAMPLED cB (1) AND cR (2) PLANES
	yuv422 = 0x36315559
	 // 3 PLANE ycBcR FORMAT 2X1 SUBSAMPLED cR (1) AND cB (2) PLANES
	yvu422 = 0x36315659
	 // 3 PLANE ycBcR FORMAT NON-SUBSAMPLED cB (1) AND cR (2) PLANES
	yuv444 = 0x34325559
	 // 3 PLANE ycBcR FORMAT NON-SUBSAMPLED cR (1) AND cB (2) PLANES
	yvu444 = 0x34325659
	 // [7:0] r
	r8 = 0x20203852
	 // [15:0] r LITTLE ENDIAN
	r16 = 0x20363152
	 // [15:0] r:g 8:8 LITTLE ENDIAN
	rg88 = 0x38384752
	 // [15:0] g:r 8:8 LITTLE ENDIAN
	gr88 = 0x38385247
	 // [31:0] r:g 16:16 LITTLE ENDIAN
	rg1616 = 0x32334752
	 // [31:0] g:r 16:16 LITTLE ENDIAN
	gr1616 = 0x32335247
	 // [63:0] X:r:g:b 16:16:16:16 LITTLE ENDIAN
	xrgb16161616f = 0x48345258
	 // [63:0] X:b:g:r 16:16:16:16 LITTLE ENDIAN
	xbgr16161616f = 0x48344258
	 // [63:0] a:r:g:b 16:16:16:16 LITTLE ENDIAN
	argb16161616f = 0x48345241
	 // [63:0] a:b:g:r 16:16:16:16 LITTLE ENDIAN
	abgr16161616f = 0x48344241
	 // [31:0] x:y:cB:cR 8:8:8:8 LITTLE ENDIAN
	xyuv8888 = 0x56555958
	 // [23:0] cR:cB:y 8:8:8 LITTLE ENDIAN
	vuy888 = 0x34325556
	 // y FOLLOWED BY u THEN v 10:10:10. nON-LINEAR MODIFIER ONLY
	vuy101010 = 0x30335556
	 // [63:0] cR0:0:y1:0:cB0:0:y0:0 10:6:10:6:10:6:10:6 LITTLE ENDIAN PER 2 y PIXELS
	y210 = 0x30313259
	 // [63:0] cR0:0:y1:0:cB0:0:y0:0 12:4:12:4:12:4:12:4 LITTLE ENDIAN PER 2 y PIXELS
	y212 = 0x32313259
	 // [63:0] cR0:y1:cB0:y0 16:16:16:16 LITTLE ENDIAN PER 2 y PIXELS
	y216 = 0x36313259
	 // [31:0] a:cR:y:cB 2:10:10:10 LITTLE ENDIAN
	y410 = 0x30313459
	 // [63:0] a:0:cR:0:y:0:cB:0 12:4:12:4:12:4:12:4 LITTLE ENDIAN
	y412 = 0x32313459
	 // [63:0] a:cR:y:cB 16:16:16:16 LITTLE ENDIAN
	y416 = 0x36313459
	 // [31:0] x:cR:y:cB 2:10:10:10 LITTLE ENDIAN
	xvyu2101010 = 0x30335658
	 // [63:0] x:0:cR:0:y:0:cB:0 12:4:12:4:12:4:12:4 LITTLE ENDIAN
	xvyu12_16161616 = 0x36335658
	 // [63:0] x:cR:y:cB 16:16:16:16 LITTLE ENDIAN
	xvyu16161616 = 0x38345658
	 // [63:0]   a3:a2:y3:0:cR0:0:y2:0:a1:a0:y1:0:cB0:0:y0:0  1:1:8:2:8:2:8:2:1:1:8:2:8:2:8:2 LITTLE ENDIAN
	y0l0 = 0x304C3059
	 // [63:0]   x3:x2:y3:0:cR0:0:y2:0:x1:x0:y1:0:cB0:0:y0:0  1:1:8:2:8:2:8:2:1:1:8:2:8:2:8:2 LITTLE ENDIAN
	x0l0 = 0x304C3058
	 // [63:0]   a3:a2:y3:cR0:y2:a1:a0:y1:cB0:y0  1:1:10:10:10:1:1:10:10:10 LITTLE ENDIAN
	y0l2 = 0x324C3059
	 // [63:0]   x3:x2:y3:cR0:y2:x1:x0:y1:cB0:y0  1:1:10:10:10:1:1:10:10:10 LITTLE ENDIAN
	x0l2 = 0x324C3058
	yuv420_8bit = 0x38305559
	yuv420_10bit = 0x30315559
	xrgb8888_a8 = 0x38415258
	xbgr8888_a8 = 0x38414258
	rgbx8888_a8 = 0x38415852
	bgrx8888_a8 = 0x38415842
	rgb888_a8 = 0x38413852
	bgr888_a8 = 0x38413842
	rgb565_a8 = 0x38413552
	bgr565_a8 = 0x38413542
	 // NON-SUBSAMPLED cR:cB PLANE
	nv24 = 0x3432564E
	 // NON-SUBSAMPLED cB:cR PLANE
	nv42 = 0x3234564E
	 // 2X1 SUBSAMPLED cR:cB PLANE 10 BIT PER CHANNEL
	p210 = 0x30313250
	 // 2X2 SUBSAMPLED cR:cB PLANE 10 BITS PER CHANNEL
	p010 = 0x30313050
	 // 2X2 SUBSAMPLED cR:cB PLANE 12 BITS PER CHANNEL
	p012 = 0x32313050
	 // 2X2 SUBSAMPLED cR:cB PLANE 16 BITS PER CHANNEL
	p016 = 0x36313050
	 // [63:0] a:X:b:X:g:X:r:X 10:6:10:6:10:6:10:6 LITTLE ENDIAN
	axbxgxrx106106106106 = 0x30314241
	 // 2X2 SUBSAMPLED cR:cB PLANE
	nv15 = 0x3531564E
	q410 = 0x30313451
	q401 = 0x31303451
	 // [63:0] X:b:g:r 16:16:16:16 LITTLE ENDIAN
	xbgr16161616 = 0x38344258
	 // [63:0] a:r:g:b 16:16:16:16 LITTLE ENDIAN
	argb16161616 = 0x38345241
	 // [63:0] a:b:g:r 16:16:16:16 LITTLE ENDIAN
	abgr16161616 = 0x38344241
	 // [7:0] c0:c1:c2:c3:c4:c5:c6:c7 1:1:1:1:1:1:1:1 EIGHT PIXELS/BYTE
	c1 = 0x20203143
	 // [7:0] c0:c1:c2:c3 2:2:2:2 FOUR PIXELS/BYTE
	c2 = 0x20203243
	 // [7:0] c0:c1 4:4 TWO PIXELS/BYTE
	c4 = 0x20203443
	 // [7:0] d0:d1:d2:d3:d4:d5:d6:d7 1:1:1:1:1:1:1:1 EIGHT PIXELS/BYTE
	d1 = 0x20203144
	 // [7:0] d0:d1:d2:d3 2:2:2:2 FOUR PIXELS/BYTE
	d2 = 0x20203244
	 // [7:0] d0:d1 4:4 TWO PIXELS/BYTE
	d4 = 0x20203444
	 // [7:0] d
	d8 = 0x20203844
	 // [7:0] r0:r1:r2:r3:r4:r5:r6:r7 1:1:1:1:1:1:1:1 EIGHT PIXELS/BYTE
	r1 = 0x20203152
	 // [7:0] r0:r1:r2:r3 2:2:2:2 FOUR PIXELS/BYTE
	r2 = 0x20203252
	 // [7:0] r0:r1 4:4 TWO PIXELS/BYTE
	r4 = 0x20203452
	 // [15:0] X:r 6:10 LITTLE ENDIAN
	r10 = 0x20303152
	 // [15:0] X:r 4:12 LITTLE ENDIAN
	r12 = 0x20323152
	 // [31:0] a:cR:cB:y 8:8:8:8 LITTLE ENDIAN
	avuy8888 = 0x59555641
	 // [31:0] x:cR:cB:y 8:8:8:8 LITTLE ENDIAN
	xvuy8888 = 0x59555658
	 // 2X2 SUBSAMPLED cR:cB PLANE 10 BITS PER CHANNEL PACKED
	p030 = 0x30333050
}

struct C.wl_shm_listener {
	format fn (data voidptr, wl_shm &C.wl_shm, format u32)
}

fn C.wl_shm_add_listener(wl_shm &C.wl_shm, listener &C.wl_shm_listener, data voidptr) int

const wl_shm_create_pool = 0
const wl_shm_release = 1

const wl_shm_format_since_version = 1
const wl_shm_create_pool_since_version = 1
const wl_shm_release_since_version = 2

fn C.wl_shm_set_user_data(wl_shm &C.wl_shm, user_data voidptr)
fn C.wl_shm_get_user_data(wl_shm &C.wl_shm) voidptr
fn C.wl_shm_get_version(wl_shm &C.wl_shm) u32
fn C.wl_shm_destroy(wl_shm &C.wl_shm)
fn C.wl_shm_create_pool(wl_shm &C.wl_shm, fd i32, size i32) &C.wl_shm_pool
fn C.wl_shm_release(wl_shm &C.wl_shm)

// wl_buffer

struct C.wl_buffer_listener {
	release fn (data voidptr, wl_buffer &C.wl_buffer)
}

fn C.wl_buffer_add_listener(wl_buffer &C.wl_buffer, listener &C.wl_buffer_listener, data voidptr) int

const wl_buffer_destory = 0

const wl_buffer_release_since_version = 1
const wl_buffer_destroy_since_version = 1

fn C.wl_buffer_set_user_data(wl_buffer &C.wl_buffer, user_data voidptr)
fn C.wl_buffer_get_user_data(wl_buffer &C.wl_buffer) voidptr
fn C.wl_buffer_get_version(wl_buffer &C.wl_buffer) u32
fn C.wl_buffer_destroy(wl_buffer &C.wl_buffer)
