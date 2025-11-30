module protocols

import wl

#flag linux -I../include
#include "../src/ext-image-copy-capture-v1-protocol.c"
#include "ext-image-copy-capture-v1-protocol.h"

pub struct C.ext_image_capture_source_v1 {}

pub struct C.ext_image_copy_capture_cursor_session_v1 {}

pub struct C.ext_image_copy_capture_frame_v1 {}

pub struct C.ext_image_copy_capture_manager_v1 {}

pub struct C.ext_image_copy_capture_session_v1 {}

pub struct C.wl_buffer {}

pub struct C.wl_pointer {}

__global C.ext_image_copy_capture_manager_v1_interface C.wl_interface
__global C.ext_image_copy_capture_session_v1_interface C.wl_interface
__global C.ext_image_copy_capture_frame_v1_interface C.wl_interface
__global C.ext_image_copy_capture_cursor_session_v1_interface C.wl_interface

pub enum Ext_image_copy_capture_manager_v1_error {
	invalid_option = 1
}

pub enum Ext_image_copy_capture_manager_v1_options {
	paint_cursors = 1
}

pub const ext_image_copy_capture_manager_v1_create_session = 0
pub const ext_image_copy_capture_manager_v1_create_pointer_cursor_session = 1
pub const ext_image_copy_capture_manager_v1_destroy = 2

pub const ext_image_copy_capture_manager_v1_create_session_since_version = 1
pub const ext_image_copy_capture_manager_v1_create_pointer_cursor_session_since_version = 1
pub const ext_image_copy_capture_manager_v1_destroy_since_version = 1

pub fn C.ext_image_copy_capture_manager_v1_set_user_data(ext_image_copy_capture_manager_v1 &C.ext_image_copy_capture_manager_v1, user_data voidptr)
pub fn C.ext_image_copy_capture_manager_v1_get_user_data(ext_image_copy_capture_manager_v1 &C.ext_image_copy_capture_manager_v1) voidptr
pub fn C.ext_image_copy_capture_manager_v1_get_version(ext_image_copy_capture_manager_v1 &C.ext_image_copy_capture_manager_v1) u32

pub fn C.ext_image_copy_capture_manager_v1_create_session(ext_image_copy_capture_manager_v1 &C.ext_image_copy_capture_manager_v1, source &C.ext_image_capture_source_v1, options u32) &C.ext_image_copy_capture_session_v1

pub fn C.ext_image_copy_capture_manager_v1_create_pointer_cursor_session(ext_image_copy_capture_manager_v1 &C.ext_image_copy_capture_manager_v1, source &C.ext_image_capture_source_v1, pointer &C.wl_pointer) &C.ext_image_copy_capture_cursor_session_v1
pub fn C.ext_image_copy_capture_manager_v1_destroy(ext_image_copy_capture_manager_v1 &C.ext_image_copy_capture_manager_v1)

pub enum Ext_image_copy_capture_session_v1_error {
	duplicate_frame = 1
}

pub struct C.ext_image_copy_capture_session_v1_listener {
	buffer_size   fn (data voidptr, ext_image_copy_capture_session_v1 &C.ext_image_copy_capture_session_v1, width u32, height u32)
	shm_format    fn (data voidptr, ext_image_copy_capture_session_v1 &C.ext_image_copy_capture_session_v1, format u32)
	dmabuf_device fn (data voidptr, ext_image_copy_capture_session_v1 &C.ext_image_copy_capture_session_v1, device &C.wl_array)
	dmabuf_format fn (data voidptr, ext_image_copy_capture_session_v1 &C.ext_image_copy_capture_session_v1, format u32, modifiers &C.wl_array)
	done          fn (data voidptr, ext_image_copy_capture_session_v1 &C.ext_image_copy_capture_session_v1)
	stopped       fn (data voidptr, ext_image_copy_capture_session_v1 &C.ext_image_copy_capture_session_v1)
}

pub fn C.ext_image_copy_capture_session_v1_add_listener(ext_image_copy_capture_session_v1 &C.ext_image_copy_capture_session_v1, listener &C.ext_image_copy_capture_session_v1_listener, data voidptr) int

pub const ext_image_copy_capture_session_v1_create_frame = 0
pub const ext_image_copy_capture_session_v1_destroy = 1

pub const ext_image_copy_capture_session_v1_buffer_size_since_version = 1
pub const ext_image_copy_capture_session_v1_shm_format_since_version = 1
pub const ext_image_copy_capture_session_v1_dmabuf_device_since_version = 1
pub const ext_image_copy_capture_session_v1_dmabuf_format_since_version = 1
pub const ext_image_copy_capture_session_v1_done_since_version = 1
pub const ext_image_copy_capture_session_v1_stopped_since_version = 1
pub const ext_image_copy_capture_session_v1_create_frame_since_version = 1
pub const ext_image_copy_capture_session_v1_destroy_since_version = 1

pub fn C.ext_image_copy_capture_session_v1_set_user_data(ext_image_copy_capture_session_v1 &C.ext_image_copy_capture_session_v1, user_data voidptr)
pub fn C.ext_image_copy_capture_session_v1_get_user_data(ext_image_copy_capture_session_v1 &C.ext_image_copy_capture_session_v1) voidptr
pub fn C.ext_image_copy_capture_session_v1_get_version(ext_image_copy_capture_session_v1 &C.ext_image_copy_capture_session_v1) u32
pub fn C.ext_image_copy_capture_session_v1_create_frame(ext_image_copy_capture_session_v1 &C.ext_image_copy_capture_session_v1) &C.ext_image_copy_capture_frame_v1
pub fn C.ext_image_copy_capture_session_v1_destroy(ext_image_copy_capture_session_v1 &C.ext_image_copy_capture_session_v1)

pub enum Ext_image_copy_capture_frame_v1_error {
	no_buffer             = 1
	invalid_buffer_damage = 2
	already_captured      = 3
}

pub enum Ext_image_copy_capture_frame_v1_failure_reason {
	unknown            = 0
	buffer_constraints = 1
	stopped            = 2
}

pub struct C.ext_image_copy_capture_frame_v1_listener {
	transform         fn (data voidptr, ext_image_copy_capture_frame_v1 &C.ext_image_copy_capture_frame_v1, transform u32)
	damage            fn (data voidptr, ext_image_copy_capture_frame_v1 &C.ext_image_copy_capture_frame_v1, x i32, y i32, width i32, height i32)
	presentation_time fn (data voidptr, ext_image_copy_capture_frame_v1 &C.ext_image_copy_capture_frame_v1, tv_sec_hi u32, tv_sec_lo u32, tv_nsec u32)
	ready             fn (data voidptr, ext_image_copy_capture_frame_v1 &C.ext_image_copy_capture_frame_v1)
	failed            fn (data voidptr, ext_image_copy_capture_frame_v1 &C.ext_image_copy_capture_frame_v1, reason u32)
}

pub fn C.ext_image_copy_capture_frame_v1_add_listener(ext_image_copy_capture_frame_v1 &C.ext_image_copy_capture_frame_v1, listener &C.ext_image_copy_capture_frame_v1_listener, data voidptr) int

pub const ext_image_copy_capture_frame_v1_destroy = 0
pub const ext_image_copy_capture_frame_v1_attach_buffer = 1
pub const ext_image_copy_capture_frame_v1_damage_buffer = 2
pub const ext_image_copy_capture_frame_v1_capture = 3

pub const ext_image_copy_capture_frame_v1_transform_since_version = 1
pub const ext_image_copy_capture_frame_v1_damage_since_version = 1
pub const ext_image_copy_capture_frame_v1_presentation_time_since_version = 1
pub const ext_image_copy_capture_frame_v1_ready_since_version = 1
pub const ext_image_copy_capture_frame_v1_failed_since_version = 1
pub const ext_image_copy_capture_frame_v1_destroy_since_version = 1
pub const ext_image_copy_capture_frame_v1_attach_buffer_since_version = 1
pub const ext_image_copy_capture_frame_v1_damage_buffer_since_version = 1
pub const ext_image_copy_capture_frame_v1_capture_since_version = 1

pub fn C.ext_image_copy_capture_frame_v1_set_user_data(ext_image_copy_capture_frame_v1 &C.ext_image_copy_capture_frame_v1, user_data voidptr)
pub fn C.ext_image_copy_capture_frame_v1_get_user_data(ext_image_copy_capture_frame_v1 &C.ext_image_copy_capture_frame_v1) voidptr
pub fn C.ext_image_copy_capture_frame_v1_get_version(ext_image_copy_capture_frame_v1 &C.ext_image_copy_capture_frame_v1) u32

pub fn C.ext_image_copy_capture_frame_v1_destroy(ext_image_copy_capture_frame_v1 &C.ext_image_copy_capture_frame_v1)
pub fn C.ext_image_copy_capture_frame_v1_attach_buffer(ext_image_copy_capture_frame_v1 &C.ext_image_copy_capture_frame_v1, buffer &C.wl_buffer)
pub fn C.ext_image_copy_capture_frame_v1_damage_buffer(ext_image_copy_capture_frame_v1 &C.ext_image_copy_capture_frame_v1, x i32, y i32, width i32, height i32)
pub fn C.ext_image_copy_capture_frame_v1_capture(ext_image_copy_capture_frame_v1 &C.ext_image_copy_capture_frame_v1)

pub enum Ext_image_copy_capture_cursor_session_v1_error {
	duplicate_session = 1
}

pub struct C.ext_image_copy_capture_cursor_session_v1_listener {
	enter    fn (data voidptr, ext_image_copy_capture_cursor_session_v1 &C.ext_image_copy_capture_cursor_session_v1)
	leave    fn (data voidptr, ext_image_copy_capture_cursor_session_v1 &C.ext_image_copy_capture_cursor_session_v1)
	position fn (data voidptr, ext_image_copy_capture_cursor_session_v1 &C.ext_image_copy_capture_cursor_session_v1, x i32, y i32)
	hotspot  fn (data voidptr, ext_image_copy_capture_cursor_session_v1 &C.ext_image_copy_capture_cursor_session_v1, x i32, y i32)
}

pub const ext_image_copy_capture_cursor_session_v1_destroy = 0
pub const ext_image_copy_capture_cursor_session_v1_get_capture_session = 1

pub const ext_image_copy_capture_cursor_session_v1_enter_since_version = 1
pub const ext_image_copy_capture_cursor_session_v1_leave_since_version = 1
pub const ext_image_copy_capture_cursor_session_v1_position_since_version = 1
pub const ext_image_copy_capture_cursor_session_v1_hotspot_since_version = 1
pub const ext_image_copy_capture_cursor_session_v1_destroy_since_version = 1
pub const ext_image_copy_capture_cursor_session_v1_get_capture_session_since_version = 1

pub fn C.ext_image_copy_capture_cursor_session_v1_set_user_data(ext_image_copy_capture_cursor_session_v1 &C.ext_image_copy_capture_cursor_session_v1, user_data voidptr)
pub fn C.ext_image_copy_capture_cursor_session_v1_get_user_data(ext_image_copy_capture_cursor_session_v1 &C.ext_image_copy_capture_cursor_session_v1) voidptr
pub fn C.ext_image_copy_capture_cursor_session_v1_get_version(ext_image_copy_capture_cursor_session_v1 &C.ext_image_copy_capture_cursor_session_v1) u32
pub fn C.ext_image_copy_capture_cursor_session_v1_destroy(ext_image_copy_capture_cursor_session_v1 &C.ext_image_copy_capture_cursor_session_v1)

pub fn C.ext_image_copy_capture_cursor_session_v1_get_capture_session(ext_image_copy_capture_cursor_session_v1 &C.ext_image_copy_capture_cursor_session_v1) &C.ext_image_copy_capture_session_v1
