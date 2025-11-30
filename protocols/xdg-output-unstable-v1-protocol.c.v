module protocols

import wl

#flag linux -I../include
#include "../src/xdg-output-unstable-v1-protocol.c"
#include "xdg-output-unstable-v1-protocol.h"

pub struct C.zxdg_output_manager_v1 {}

pub struct C.zxdg_output_v1 {}

__global C.zxdg_output_manager_v1_interface C.wl_interface
__global C.zxdg_output_v1_interface C.wl_interface

pub const zxdg_output_manager_v1_destroy = 0
pub const zxdg_output_manager_v1_get_xdg_output = 1

@[inline]
pub fn C.zxdg_output_manager_v1_set_user_data(zxdg_output_manager_v1 &C.zxdg_output_manager_v1, user_data voidptr)

@[inline]
pub fn C.zxdg_output_manager_v1_get_user_data(zxdg_output_manager_v1 &C.zxdg_output_manager_v1) voidptr

@[inline]
pub fn C.zxdg_output_manager_v1_get_version(zxdg_output_manager_v1 &C.zxdg_output_manager_v1) u32

@[inline]
pub fn C.zxdg_output_manager_v1_destroy(zxdg_output_manager_v1 &C.zxdg_output_manager_v1)

@[inline]
pub fn C.zxdg_output_manager_v1_get_xdg_output(zxdg_output_manager_v1 &C.zxdg_output_manager_v1, output &C.wl_output) &C.zxdg_output_v1

pub struct C.zxdg_output_v1_listener {
	logical_position fn (data voidptr, zxdg_output_v1 &C.zxdg_output_v1, x i32, y i32)
	logical_size     fn (data voidptr, zxdg_output_v1 &C.zxdg_output_v1, width i32, height i32)
	done             fn (data voidptr, zxdg_output_v1 &C.zxdg_output_v1)
	name             fn (data voidptr, zxdg_output_v1 &C.zxdg_output_v1, name &char)
	description      fn (data voidptr, zxdg_output_v1 &C.zxdg_output_v1, description &char)
}

@[inline]
pub fn C.zxdg_output_v1_add_listener(zxdg_output_v1 &C.zxdg_output_v1, listener &C.zxdg_output_v1_listener, data voidptr) int

pub const zxdg_output_v1_destroy = 0

pub const zxdg_output_v1_logical_position_since_version = 1
pub const zxdg_output_v1_logical_size_since_version = 1
pub const zxdg_output_v1_done_since_version = 1
pub const zxdg_output_v1_name_since_version = 2
pub const zxdg_output_v1_description_since_version = 2
pub const zxdg_output_v1_destroy_since_version = 1

@[inline]
pub fn C.zxdg_output_v1_set_user_data(zxdg_output_v1 &C.zxdg_output_v1, user_data voidptr)

@[inline]
pub fn C.zxdg_output_v1_get_user_data(zxdg_output_v1 &C.zxdg_output_v1) voidptr

@[inline]
pub fn C.zxdg_output_v1_get_version(zxdg_output_v1 &C.zxdg_output_v1) u32

@[inline]
pub fn C.zxdg_output_v1_destroy(zxdg_output_v1 &C.zxdg_output_v1)
