module png

#flag linux -L/usr/lib
#flag linux -lpng16
#flag linux -I/usr/include
#include <libpng16/png.h>
#include <stdio.h>

#define PNG_GET_VERSION_STRING() PNG_LIBPNG_VER_STRING

pub type C.png_struct = voidptr
pub type C.png_info = voidptr

pub type C.png_structp = &C.png_struct
pub type C.png_infop = &C.png_info

pub type C.png_const_bytep = &u8
pub type C.png_bytep = &u8
pub type C.png_byte = u8

// color types
pub const png_color_type_gray = 0
pub const png_color_type_palette = 1
pub const png_color_type_rgb = 2
pub const png_color_type_rgb_alpha = 6
pub const png_color_type_gray_alpha = 4

pub const png_color_mask_palette = 1
pub const png_color_mask_color = 2
pub const png_color_mask_alpha = 4

// interlace methods
pub const png_interlace_none = 0
pub const png_interlace_adam7 = 1

// compression methods
pub const png_compression_type_base = 0
pub const png_compression_type_default = 0

// filter types
pub const png_filter_type_base = 0
pub const png_filter_type_default = 0

// filter values
pub const png_no_filters = 0x00
pub const png_filter_none = 0x08
pub const png_filter_sub = 0x10
pub const png_filter_up = 0x20
pub const png_filter_avg = 0x40
pub const png_filter_paeth = 0x80
pub const png_all_filters = 0xF8

// function pointers for error handling
pub type C.png_error_ptr = voidptr
pub type C.png_rw_ptr = voidptr

// version string constant
pub const png_libpng_ver_string = c'1.6.53'

// functions
pub fn C.png_create_write_struct(user_png_ver &char, error_ptr voidptr, error_fn C.png_error_ptr, warn_fn C.png_error_ptr) C.png_structp

pub fn C.png_create_info_struct(png_ptr C.png_structp) C.png_infop

pub fn C.png_init_io(png_ptr C.png_structp, fp voidptr)

pub fn C.png_set_IHDR(png_ptr C.png_structp, info_ptr C.png_infop, width u32, height u32, bit_depth int, color_type int, interlace_method int, compression_method int, filter_method int)

pub fn C.png_write_info(png_ptr C.png_structp, info_ptr C.png_infop)

pub fn C.png_set_compression_level(png_ptr C.png_structp, level int)

pub fn C.png_set_filter(png_ptr C.png_structp, method int, filters int)

pub fn C.png_write_row(png_ptr C.png_structp, row C.png_const_bytep)

pub fn C.png_write_end(png_ptr C.png_structp, info_ptr C.png_infop)

pub fn C.png_destroy_write_struct(png_ptr_ptr &C.png_structp, info_ptr_ptr &C.png_infop)

pub fn C.png_set_write_fn(png_ptr C.png_structp, io_ptr voidptr, write_data_fn voidptr, output_flush_fn voidptr)

pub fn C.png_get_io_ptr(png_ptr C.png_structp) voidptr

pub fn C.fopen(filename &char, mode &char) voidptr
pub fn C.fclose(stream voidptr) int
