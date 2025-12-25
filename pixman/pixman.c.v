module pixman

#pkgconfig pixman-1
#include <pixman-1/pixman.h>

// boolean

pub type C.pixman_bool_t = bool

// standard integer types

pub type C.int32_t = i32
pub type C.uint32_t = u32

// fixed point numbers

pub type C.pixman_fixed_32_32_t = i64
pub type C.pixman_fixed_48_16_t = i64
pub type C.pixman_fixed_1_31_t = u32
pub type C.pixman_fixed_1_16_t = u32
pub type C.pixman_fixed_16_16_t = i32
pub type C.pixman_fixed_t = i32

pub const pixman_fixed_e = 1
pub const pixman_fixed_1 = pixman_int_to_fixed(1)
pub const pixman_fixed_1_minus_e = pixman_fixed_1 - pixman_fixed_e
pub const pixman_fixed_minus_1 = pixman_int_to_fixed(-1)

@[inline]
pub fn pixman_fixed_to_int(f C.pixman_fixed_t) int {
	return f >> 16
}

@[inline]
pub fn pixman_int_to_fixed(i int) C.pixman_fixed_t {
	return u32(i) << 16
}

@[inline]
pub fn pixman_fixed_to_double(f C.pixman_fixed_t) f64 {
	return f / pixman_fixed_1
}

@[inline]
pub fn pixman_double_to_fixed(d f64) C.pixman_fixed_t {
	return d * 65536.0
}

@[inline]
pub fn pixman_fixed_frac(f C.pixman_fixed_t) C.pixman_fixed_t {
	return f & pixman_fixed_1_minus_e
}

@[inline]
pub fn pixman_fixed_floor(f C.pixman_fixed_t) C.pixman_fixed_t {
	return f & ~pixman_fixed_1_minus_e
}

@[inline]
pub fn pixman_fixed_ceil(f C.pixman_fixed_t) C.pixman_fixed_t {
	return pixman_fixed_floor(f + pixman_fixed_1_minus_e)
}

@[inline]
pub fn pixman_fixed_fraction(f C.pixman_fixed_t) C.pixman_fixed_t {
	return f & pixman_fixed_1_minus_e
}

@[inline]
pub fn pixman_fixed_mod_2(f C.pixman_fixed_t) C.pixman_fixed_t {
	return f & pixman_fixed_1 | pixman_fixed_1_minus_e
}

pub const pixman_max_fixed_48_16 = 0x7fffffff
pub const pixman_min_fixed_48_16 = -(1 << 31)

// misc structs

pub type C.pixman_color_t = C.pixman_color
pub type C.pixman_point_fixed_t = C.pixman_point_fixed
pub type C.pixman_line_fixed_t = C.pixman_line_fixed
pub type C.pixman_vector_t = C.pixman_vector
pub type C.pixman_transform_t = C.pixman_transform

pub struct C.pixman_color {
	red   u16
	green u16
	blue  u16
	alpha u16
}

pub struct C.pixman_point_fixed {
	x C.pixman_fixed_t
	y C.pixman_fixed_t
}

pub struct C.pixman_line_fixed {
	p1 C.pixman_point_fixed_t
	p2 C.pixman_point_fixed_t
}

// fixed point matrices

pub struct C.pixman_vector {
	vector [3]C.pixman_fixed_t
}

pub struct C.pixman_transform {
	matrix [3][3]C.pixman_fixed_t
}

@[typedef]
pub struct C.pixman_image {}

pub type C.pixman_image_t = C.pixman_image

fn C.pixman_transform_init_identity(matrix &C.pixman_transform)
fn C.pixman_transform_point_3d(transform &C.pixman_transform, vector &C.pixman_vector) C.pixman_bool_t
fn C.pixman_transform_point(transform &C.pixman_transform, vector &C.pixman_vector) C.pixman_bool_t
fn C.pixman_transform_multiply(dst &C.pixman_transform, l &C.pixman_transform, r &C.pixman_transform) C.pixman_bool_t
fn C.pixman_transform_init_scale(t &C.pixman_transform, sx C.pixman_fixed_t, sy C.pixman_fixed_t)
fn C.pixman_transform_scale(forward &C.pixman_transform, sx C.pixman_fixed_t, sy C.pixman_fixed_t)
fn C.pixman_transform_init_rotate(t &C.pixman_transform, cos C.pixman_fixed_t, sin C.pixman_fixed_t)
fn C.pixman_transform_rotate(forward &C.pixman_transform, reverse &C.pixman_transform, c C.pixman_fixed_t, s C.pixman_fixed_t) C.pixman_bool_t
fn C.pixman_transform_init_translate(t &C.pixman_transform, tx C.pixman_fixed_t, ty C.pixman_fixed_t)
fn C.pixman_transform_translate(forward &C.pixman_transform, reverse &C.pixman_transform, tx C.pixman_fixed_t, ty C.pixman_fixed_t) C.pixman_bool_t
fn C.pixman_transform_bounds(matrix &C.pixman_transform, b &C.pixman_box16) C.pixman_bool_t
fn C.pixman_transform_invert(dst &C.pixman_transform, src &C.pixman_transform) C.pixman_bool_t
fn C.pixman_transform_is_identity(t &C.pixman_transform) C.pixman_bool_t
fn C.pixman_transform_is_scale(t &C.pixman_transform) C.pixman_bool_t
fn C.pixman_transform_is_int_translate(t &C.pixman_transform) C.pixman_bool_t
fn C.pixman_transform_is_inverse(a &C.pixman_transform, b &C.pixman_transform) C.pixman_bool_t

// floating point matrices

pub struct C.pixman_f_vector {
	v [3]f64
}

pub struct C.pixman_f_transform {
	m [3][3]f64
}

fn C.pixman_f_transform_init_identity(t &C.pixman_f_transform)
fn C.pixman_f_transform_translate(forward &C.pixman_f_transform, reverse &C.pixman_f_transform, tx f64, ty f64) C.pixman_bool_t
fn C.pixman_f_transform_scale(forward &C.pixman_f_transform, reverse &C.pixman_f_transform, sx f64, sy f64) C.pixman_bool_t
fn C.pixman_f_transform_rotate(forward &C.pixman_f_transform, reverse &C.pixman_f_transform, c f64, s f64) C.pixman_bool_t
fn C.pixman_f_transform_invert(dst &C.pixman_f_transform, src &C.pixman_f_transform) C.pixman_bool_t
fn C.pixman_transform_from_pixman_f_transform(t &C.pixman_transform, ft &C.pixman_f_transform) C.pixman_bool_t

// TODO: fixed point fns

pub enum Pixman_repeat_t {
	none
	normal
	pad
	reflect
}

pub enum Pixman_dither_t {
	none
	fast
	good
	best
	ordered_bayer_8
	ordered_blue_noise_64
}

pub enum Pixman_filter_t {
	fast
	good
	best
	nearest
	bilinear
	convolution
	seperable_convolution
}

pub enum Pixman_op_t {
	clear        = 0x00
	src          = 0x01
	dst          = 0x02
	over         = 0x03
	over_reverse = 0x04
	in           = 0x05
	in_reverse   = 0x06
	out          = 0x07
	out_reverse  = 0x08
	atop         = 0x09
	atop_reverse = 0x0a
	xor          = 0x0b
	add          = 0x0c
	saturate     = 0x0d

	disjoint_clear        = 0x10
	disjoint_src          = 0x11
	disjoint_dst          = 0x12
	disjoint_over         = 0x13
	disjoint_over_reverse = 0x14
	disjoint_in           = 0x15
	disjoint_in_reverse   = 0x16
	disjoint_out          = 0x17
	disjoint_out_reverse  = 0x18
	disjoint_atop         = 0x19
	disjoint_atop_reverse = 0x1a
	disjoint_xor          = 0x1b

	conjoint_clear        = 0x20
	conjoint_src          = 0x21
	conjoint_dst          = 0x22
	conjoint_over         = 0x23
	conjoint_over_reverse = 0x24
	conjoint_in           = 0x25
	conjoint_in_reverse   = 0x26
	conjoint_out          = 0x27
	conjoint_out_reverse  = 0x28
	conjoint_atop         = 0x29
	conjoint_atop_reverse = 0x2a
	conjoint_xor          = 0x2b

	multiply       = 0x30
	screen         = 0x31
	overlay        = 0x32
	darken         = 0x33
	lighten        = 0x34
	color_dodge    = 0x35
	color_burn     = 0x36
	hard_light     = 0x37
	soft_light     = 0x38
	difference     = 0x39
	exclusion      = 0x3a
	hsl_hue        = 0x3b
	hsl_saturation = 0x3c
	hsl_color      = 0x3d
	hsl_luminosity = 0x3e
}

// regions

pub type C.pixman_region16_data_t = C.pixman_region16_data
pub type C.pixman_box16_t = C.pixman_box16
pub type C.pixman_rectangle16_t = C.pixman_rectangle16
pub type C.pixman_region16_t = C.pixman_region16

pub struct C.pixman_region16_data {
	size     u64
	numRects u64
}

pub struct C.pixman_rectangle16 {
	x      i16
	y      i16
	width  u16
	height u16
}

pub struct C.pixman_box16 {
	x1 i16
	y1 i16
	x2 i16
	y2 i16
}

pub struct C.pixman_region16 {
	extents C.pixman_box16_t
	data    &C.pixman_region16_data_t
}

pub enum Pixman_region_overlap_t {
	out
	in
	part
}

// creation/destruction

fn C.pixman_region_init(region &C.pixman_region16_t)
fn C.pixman_region_init_rect(region &C.pixman_region16_t, x int, y int, width usize, height usize)
fn C.pixman_region_init_rects(region &C.pixman_region16_t, boxes &C.pixman_box16_t, count int) C.pixman_bool_t
fn C.pixman_init_with_extents(region &C.pixman_region16_t, extents &C.pixman_box16_t)
fn C.pixman_region_init_from_image(region &C.pixman_region16_t, image &C.pixman_image_t)
fn C.pixman_region_fini(region &C.pixman_region16_t)

// manipulation

fn C.pixman_region_translate(region &C.pixman_region16_t, x int, y int)
fn C.pixman_region_copy(dest &C.pixman_region16_t, source &C.pixman_region16_t) C.pixman_bool_t
fn C.pixman_region_intersect(new_reg &C.pixman_region16_t, reg1 &C.pixman_region16_t, reg2 &C.pixman_region16_t) C.pixman_bool_t
fn C.pixman_region_union(new_reg &C.pixman_region16_t, reg1 &C.pixman_region16_t, reg2 &C.pixman_region16_t) C.pixman_bool_t
fn C.pixman_region_union_rect(dest &C.pixman_region16_t, source &C.pixman_region16_t, x int, y int, width usize, height usize) C.pixman_bool_t
fn C.pixman_region_intersect_rect(dest &C.pixman_region16_t, source &C.pixman_region16_t, x int, y int, width usize, height usize) C.pixman_bool_t
fn C.pixman_region_subtract(reg_d &C.pixman_region16_t, reg_m &C.pixman_region16_t, reg_s &C.pixman_region16_t) C.pixman_bool_t
fn C.pixman_region_inverse(new_reg &C.pixman_region16_t, reg1 &C.pixman_region16_t, inv_rect &C.pixman_box16_6) C.pixman_bool_t
fn C.pixman_region_contains_point(region &C.pixman_region16_t, x int, y int, box &C.pixman_box16_t) C.pixman_bool_t
fn C.pixman_region_contains_rectangle(region &C.pixman_region16_t, prect &C.pixman_box16_t) Pixman_region_overlap_t
fn C.pixman_region_empty(region &C.pixman_region16_t) C.pixman_bool_t
fn C.pixman_region_not_empty(region &C.pixman_region16_t) C.pixman_bool_t
fn C.pixman_region_extents(region &C.pixman_region16_t) &C.pixman_box16_t
fn C.pixman_region_n_rects(region &C.pixman_region16_t) int
fn C.pixman_region_rectangles(region &C.pixman_region16_t, n_rects &int) &C.pixman_box16_t
fn C.pixman_region_equal(region1 &C.pixman_region16_t, region2 &C.pixman_region16_t) C.pixman_bool_t
fn C.pixman_region_selfcheck(region &C.pixman_region16_t) C.pixman_bool_t
fn C.pixman_region_reset(region &C.pixman_region16_t, box &C.pixman_box16_t)
fn C.pixman_region_clear(region &C.pixman_region16_t)

// 32 bit regions

pub type C.pixman_region32_data_t = C.pixman_region32_data
pub type C.pixman_box32_t = C.pixman_box32
pub type C.pixman_rectangle32_t = C.pixman_rectangle32
pub type C.pixman_region32_t = C.pixman_region32

pub struct C.pixman_region32_data {
	size     f64
	numRects f64
}

pub struct C.pixman_rectangle32 {
	x      i32
	y      i32
	width  u32
	height u32
}

pub struct C.pixman_box32 {
	x1 i32
	y1 i32
	x2 i32
	y2 i32
}

pub struct C.pixman_region32 {
	extents C.pixman_box32_t
	data    &C.pixman_region32_data_t
}

// creation/destruction

fn C.pixman_region32_init(region &C.pixman_region32_t)
fn C.pixman_region32_init_rect(region &C.pixman_region32_t, x int, y int, width usize, height usize)
fn C.pixman_region32_init_rects(region &C.pixman_region32_t, boxes &C.pixman_box32_t, count int) C.pixman_bool_t
fn C.pixman_region32_init_with_extents(region &C.pixman_region32_t, extents &C.pixman_box32_t)
fn C.pixman_region32_init_from_image(region &C.pixman_region32_t, image &C.pixman_image_t)
fn C.pixman_region32_fini(region &C.pixman_region32_t)

// manipulation

fn C.pixman_region32_translate(region &C.pixman_region32_t, x int, y int)
fn C.pixman_region32_copy(region &C.pixman_region32_t, source &C.pixman_region32_t) C.pixman_bool_t
fn C.pixman_region32_intersect(new_reg &C.pixman_region32_t, reg1 &C.pixman_region32_t, reg2 &C.pixman_region32_t) C.pixman_bool_t
fn C.pixman_region32_union(new_reg &C.pixman_region32_t, reg1 &C.pixman_region32_t, reg2 &C.pixman_region32_t) C.pixman_bool_t
fn C.pixman_region32_intersect_rect(dest &C.pixman_region32_t, source &C.pixman_region32_t, x int, y int, width usize, height usize) C.pixman_bool_t
fn C.pixman_region32_union_rect(dest &C.pixman_region32_t, source &C.pixman_region32_t, x int, y int, width usize, height usize) C.pixman_bool_t
fn C.pixman_region32_subtract(reg_d &C.pixman_region32_t, reg_m &C.pixman_region32_t, reg_s &C.pixman_region32_t) C.pixman_bool_t
fn C.pixman_region32_inverse(new_reg &C.pixman_region32_t, reg1 &C.pixman_region32_t, inv_rect &C.pixman_box32_t) C.pixman_bool_t
fn C.pixman_region32_contains_point(region &C.pixman_region32_t, x int, y int, box &C.pixman_box32_t) C.pixman_bool_t
fn C.pixman_region32_contains_rectangle(region &C.pixman_region32_t, prect &C.pixman_box32_t) Pixman_region_overlap_t
fn C.pixman_region32_empty(region &C.pixman_region32_t) C.pixman_bool_t
fn C.pixman_region32_not_empty(region &C.pixman_region32_t) C.pixman_bool_t
fn C.pixman_region32_extents(region &C.pixman_region32_t) &C.pixman_box32_t
fn C.pixman_region32_n_rects(region &C.pixman_region32_t) int
fn C.pixman_region32_rectangles(region &C.pixman_region32_t, n_rects &int) &C.pixman_box32_t
fn C.pixman_region32_equal(region1 &C.pixman_region32_t, region2 &C.pixman_region32_t) C.pixman_bool_t
fn C.pixman_region32_selfcheck(region &C.pixman_region32_t) C.pixman_bool_t
fn C.pixman_region32_reset(region &C.pixman_region32_t, box &C.pixman_box32_t)
fn C.pixman_region32_clear(region &C.pixman_region32_t)

// 64 bit fractional regions

pub type C.pixman_region64f_data_t = C.pixman_region64f_data
pub type C.pixman_box64f_t = C.pixman_box64f
pub type C.pixman_rectangle64f_t = C.pixman_rectangle64f
pub type C.pixman_region64f_t = C.pixman_region64f

pub struct C.pixman_region64f_data {
	size     f64
	numRects f64
}

pub struct C.pixman_rectangle64f {
	x      f64
	y      f64
	width  f64
	height f64
}

pub struct C.pixman_box64f {
	x1 f64
	y1 f64
	x2 f64
	y2 f64
}

pub struct C.pixman_region64f {
	extents C.pixman_box64f_t
	data    &C.pixman_region64f_data_t
}

// creation/destruction

fn C.pixman_region64f_init(region &C.pixman_region64f_t)
fn C.pixman_region64f_init_rect(region &C.pixman_region64f_t, x int, y int, width usize, height usize)
fn C.pixman_region64f_init_rectf(region &C.pixman_region64f_t, x f64, y f64, width f64, height f64)
fn C.pixman_region64f_init_rects(region &C.pixman_region64f_t, boxes &C.pixman_box64f_t, count int) C.pixman_bool_t
fn C.pixman_region64f_init_with_extents(region &C.pixman_region64f_t, extents &C.pixman_box64f_t)
fn C.pixman_region64f_init_from_image(region &C.pixman_region64f_t, image &C.pixman_image_t)
fn C.pixman_region64f_fini(region &C.pixman_region64f_t)

// manipulation

fn C.pixman_region64f_translate(region &C.pixman_region64f_t, x int, y int)
fn C.pixman_region64f_translatef(region &C.pixman_region64f_t, x f64, y f64)
fn C.pixman_region64f_copy(dest &C.pixman_region64f_t, source &C.pixman_region64f_t) C.pixman_bool_t
fn C.pixman_region64f_intersect(new_reg &C.pixman_region64f_t, reg1 &C.pixman_region64f_t, reg2 &C.pixman_region64f_t) C.pixman_bool_t
fn C.pixman_region64f_union(new_reg &C.pixman_region64f_t, reg1 &C.pixman_region64f_t, reg2 &C.pixman_region64f_t) C.pixman_bool_t
fn C.pixman_region64f_intersect_rect(dest &C.pixman_region64f_t, source &C.pixman_region64f_t, x int, y int, width usize, height usize) C.pixman_bool_t
fn C.pixman_region64f_intersect_rectf(dest &C.pixman_region64f_t, source &C.pixman_region64f_t, x f64, y f64, width f64, height f64) C.pixman_bool_t
fn C.pixman_region64f_union_rect(dest &C.pixman_region64f_t, source &C.pixman_region64f_t, x int, y int, width usize, height usize) C.pixman_bool_t
fn C.pixman_region64f_union_rectf(dest &C.pixman_region64f_t, source &C.pixman_region64f_t, x f64, y f64, width f64, height f64) C.pixman_bool_t
fn C.pixman_region64f_subtract(reg_d &C.pixman_region64f_t, reg_m &C.pixman_region64f_t, reg_s &C.pixman_region64f_t) C.pixman_bool_t
fn C.pixman_region64f_inverse(new_reg &C.pixman_region64f_t, reg1 &C.pixman_region64f_t, inv_rect &C.pixman_box64f_t) C.pixman_bool_t
fn C.pixman_region64f_contains_point(region &C.pixman_region64f_t, x int, y int, box &C.pixman_box64f_t) C.pixman_bool_t
fn C.pixman_region64f_contains_pointf(region &C.pixman_region64f_t, x f64, y f64, box &C.pixman_box64f_t) C.pixman_bool_t
fn C.pixman_region64f_contains_rectangle(region &C.pixman_region64f_t, prect &C.pixman_box64f_t) Pixman_region_overlap_t
fn C.pixman_region64f_emtpy(region &C.pixman_region64f_t) C.pixman_bool_t
fn C.pixman_region64f_not_empty(region &C.pixman_region64f_t) C.pixman_bool_t
fn C.pixman_region64f_extents(region &C.pixman_region64f_t) &C.pixman_box64f_t
fn C.pixman_region64f_n_rects(region &C.pixman_region64f_t) int
fn C.pixman_region64f_rectangles(region &C.pixman_region64f_t, n_rects &int) &C.pixman_box64f_t
fn C.pixman_region64f_equal(region1 &C.pixman_region64f_t, region2 &C.pixman_region64f_t) C.pixman_bool_t
fn C.pixman_region64f_selfcheck(region &C.pixman_region64f_t) C.pixman_bool_t
fn C.pixman_region64f_reset(region &C.pixman_region64f_t, box &C.pixman_box64f_t)
fn C.pixman_region64f_clear(region &C.pixman_region64f_t)

// copy/fill/misc

fn C.pixman_blt(src_bits &u32, dst_bits &u32, src_stride int, dst_stride int, src_bpp int, dst_bpp int, src_x int, src_y int, dest_x int, dest_y int, width int, height int) C.pixman_bool_t
fn C.pixman_fill(bits &u32, stride int, bpp int, x int, y int, width int, height int, _xor uint32_t) C.pixman_bool_t
fn C.pixman_version() int
fn C.pixman_version_string() &char

// images

pub type C.pixman_indexed_t = C.pixman_indexed
pub type Pixman_gradient_stop_t = C.pixman_gradient_stop

pub type Pixman_read_memory_func_t = fn (src voidptr, size int) u32

pub type Pixman_write_memory_func_t = fn (dst voidptr, value u32, size int)

pub type Pixman_image_destroy_func_t = fn (image &C.pixman_image_t, data voidptr)

pub struct C.pixman_gradient_stop {
	x C.pixman_fixed_t
	y C.pixman_color_t
}

pub const pixman_max_indexed = 256

pub type C.pixman_index_type = u8

pub struct C.pixman_indexed {
	color C.pixman_bool_t
	rgba  [pixman_max_indexed]u32
	ent   [32768]C.pixman_index_type
}

// macros

@[inline]
pub fn pixman_format(bpp int, type int, a int, r int, g int, b int) u32 {
	return (u32(bpp) << 24) | (u32(type) << 16) | (u32(a) << 12) | (u32(r) << 8) | (u32(g) << 4) | u32(b)
}

@[inline]
pub fn pixman_format_byte(bpp int, type int, a int, r int, g int, b int) u32 {
	return (u32(bpp >> 3) << 24) | (3 << 22) | (u32(type) << 16) | ((u32(a) >> 3) << 12) | ((u32(r) >> 3) << 8) | ((u32(g) >> 3) << 4) | (u32(b) >> 3)
}

@[inline]
pub fn pixman_format_reshift(val int, ofs int, num int) u32 {
	return ((u32(val) >> u32(ofs)) & ((1 << num) - 1)) << ((val >> 22) & 3)
}

@[inline]
pub fn pixman_format_bpp(f int) u32 {
	return pixman_format_reshift(f, 24, 8)
}

@[inline]
pub fn pixman_format_shift(f int) u32 {
	return u32((f >> 22) & 3)
}

@[inline]
pub fn pixman_format_type(f int) u32 {
	return (u32(f) >> 16) & 0x3f
}

@[inline]
pub fn pixman_format_a(f int) u32 {
	return pixman_format_reshift(f, 12, 4)
}

@[inline]
pub fn pixman_format_r(f int) u32 {
	return pixman_format_reshift(f, 8, 4)
}

@[inline]
pub fn pixman_format_g(f int) u32 {
	return pixman_format_reshift(f, 4, 4)
}

@[inline]
pub fn pixman_format_b(f int) u32 {
	return pixman_format_reshift(f, 0, 4)
}

@[inline]
pub fn pixman_format_rgb(f int) u32 {
	return u32(f) & 0xfff
}

@[inline]
pub fn pixman_format_vis(f int) u32 {
	return u32(f) & 0xffff
}

@[inline]
pub fn pixman_format_depth(f int) u32 {
	return pixman_format_a(f) + pixman_format_r(f) + pixman_format_g(f) + pixman_format_b(f)
}

pub const pixman_type_other = 0
pub const pixman_type_a = 1
pub const pixman_type_argb = 2
pub const pixman_type_abgr = 3
pub const pixman_type_color = 4
pub const pixman_type_gray = 5
pub const pixman_type_yuy2 = 6
pub const pixman_type_yv12 = 7
pub const pixman_type_bgra = 8
pub const pixman_type_rgba = 9
pub const pixman_type_argb_srgb = 10
pub const pixman_type_rgba_float = 11

@[inline]
pub fn pixman_format_color(f int) bool {
	return pixman_format_type(f) == pixman_type_argb || pixman_format_type(f) == pixman_type_abgr
		|| pixman_format_type(f) == pixman_type_bgra || pixman_format_type(f) == pixman_type_rgba
		|| pixman_format_type(f) == pixman_type_rgba_float
}

@[_allow_multiple_values]
pub enum Pixman_format_code_t {
	// 128bpp formats
	rgba_float = 0x10cb4444

	// 96bpp formats
	rgb_float = 0x0ccb0444

	// 64bpp formats
	//[63:0] A:B:G:R 16:16:16:16 native endian
	a16b16g16r16 = 0x08c32222

	// 32bpp formats
	a8r8g8b8    = 0x20028888
	x8r8g8b8    = 0x20020888
	a8b8g8r8    = 0x20038888
	x8b8g8r8    = 0x20030888
	b8g8r8a8    = 0x20088888
	b8g8r8x8    = 0x20080888
	r8g8b8a8    = 0x20098888
	r8g8b8x8    = 0x20090888
	x14r6g6b6   = 0x20020666
	x2r10g10b10 = 0x20020aaa
	a2r10g10b10 = 0x20022aaa
	x2b10g10r10 = 0x20030aaa
	a2b10g10r10 = 0x20032aaa

	// sRGB formats
	a8r8g8b8_srgb = 0x200a8888
	r8g8b8_srgb   = 0x180a0888

	// 24bpp formats
	r8g8b8 = 0x18020888
	b8g8r8 = 0x18030888

	// 16bpp formats
	r5g6b5 = 0x10020565
	b5g6r5 = 0x10030565

	a1r5g5b5 = 0x10021555
	x1r5g5b5 = 0x10020555
	a1b5g5r5 = 0x10031555
	x1b5g5r5 = 0x10030555
	a4r4g4b4 = 0x10024444
	x4r4g4b4 = 0x10020444
	a4b4g4r4 = 0x10034444
	x4b4g4r4 = 0x10030444

	// 8bpp formats
	a8       = 0x08018000
	r3g3b2   = 0x08020332
	b2g3r3   = 0x08030332
	a2r2g2b2 = 0x08022222
	a2b2g2r2 = 0x08032222

	c8 = 0x08040000
	g8 = 0x08050000

	x4a4 = 0x08014000

	x4c4 = 0x08040000
	x4g4 = 0x08050000

	// 4bpp formats
	a4       = 0x04014000
	r1g2b1   = 0x04020121
	b1g2r1   = 0x04030121
	a1r1g1b1 = 0x04021111
	a1b1g1r1 = 0x04031111

	c4 = 0x04040000
	g4 = 0x04050000

	// 1bpp formats
	a1 = 0x01011000

	g1 = 0x01050000

	// YUV formats
	yuy2 = 0x10060000
	yv12 = 0x0c070000
}

// querying supported format values

fn C.pixman_format_supported_destination(format Pixman_format_code_t) C.pixman_bool_t
fn C.pixman_format_supported_source(format Pixman_format_code_t) C.pixman_bool_t

// pub constructors

fn C.pixman_image_create_solid_fill(color &Pixman_color_t) &C.pixman_image_t
fn C.pixman_image_create_linear_gradient(p1 &C.pixman_point_fixed_t, p2 &C.pixman_point_fixed_t, stops &Pixman_gradient_stop_t, n_stops int) &C.pixman_image_t
fn C.pixman_image_create_radial_gradient(inner &C.pixman_point_fixed_t, outer &C.pixman_point_fixed_t, inner_radius C.pixman_fixed_t, outer_radius C.pixman_fixed_t, stops &Pixman_gradient_stop_t, n_stops int) &C.pixman_image_t
fn C.pixman_image_create_conical_gradient(center &C.pixman_point_fixed_t, angle C.pixman_fixed_t, stops &Pixman_gradient_stop_t, n_stops int) &C.pixman_image_t
fn C.pixman_image_create_bits(format Pixman_format_code_t, width int, height int, bits &uint32_t, rowstride_bytes int) &C.pixman_image_t
fn C.pixman_image_create_bits_no_clear(format Pixman_format_code_t, width int, height int, bits &uint32_t, rowstride_bytes int) &C.pixman_image_t

// destructor

fn C.pixman_image_ref(image &C.pixman_image_t) &C.pixman_image_t
fn C.pixman_image_unref(image &C.pixman_image_t) C.pixman_bool_t
fn C.pixman_image_set_destroy_function(image &C.pixman_image_t, function C.pixman_image_destroy_func_t, data voidptr)
fn C.pixman_image_get_destroy_data(image &C.pixman_image_t) voidptr

// set properties

fn C.pixman_image_set_clip_region(image &C.pixman_image_t, region &C.pixman_region16_t) C.pixman_bool_t
fn C.pixman_image_set_clip_region32(image &C.pixman_image_t, region &C.pixman_region32_t) C.pixman_bool_t
fn C.pixman_image_set_clip_region64f(image &C.pixman_image_t, region &C.pixman_region64f_t) C.pixman_bool_t
fn C.pixman_image_set_has_client_clip(image &C.pixman_image_t, clien_clip C.pixman_bool_t)
fn C.pixman_image_set_transform(image &C.pixman_image_t, transform &C.pixman_transform_t) C.pixman_bool_t
fn C.pixman_image_set_repeat(image &C.pixman_image_t, repeat Pixman_repeat_t)
fn C.pixman_image_set_dither(image &C.pixman_image_t, dither Pixman_dither_t)
fn C.pixman_image_set_dither_offset(image &C.pixman_image_t, offset_x int, offset_y int)
fn C.pixman_image_set_filter(image &C.pixman_image_t, filter Pixman_filter_t, filter_params &C.pixman_fixed_t, n_filter_params int) C.pixman_bool_t
fn C.pixman_image_set_source_clipping(image &C.pixman_image_t, source_clipping C.pixman_bool_t)
fn C.pixman_image_set_alpha_map(image &C.pixman_image_t, alpha_map &C.pixman_image_t, x int16_t, y int16_t)
fn C.pixman_image_set_component_alpha(image &C.pixman_image_t, component_alpha C.pixman_bool_t)
fn C.pixman_image_get_component_alpha(image &C.pixman_image_t) C.pixman_bool_t
fn C.pixman_image_set_accessors(image &C.pixman_image_t, read_func Pixman_read_memory_func_t, write_func Pixman_write_memory_func_t)
fn C.pixman_image_set_indexed(image &C.pixman_image_t, indexed &C.pixman_indexed_t)
fn C.pixman_image_get_data(image &C.pixman_image_t) &u32
fn C.pixman_image_get_width(image &C.pixman_image_t) int
fn C.pixman_image_get_height(image &C.pixman_image_t) int
fn C.pixman_image_get_stride(image &C.pixman_image_t) int
fn C.pixman_image_get_depth(image &C.pixman_image_t) int
fn C.pixman_image_get_format(image &C.pixman_image_t) Pixman_format_code_t

pub enum Pixman_kernel_t {
	impulse
	box
	linear
	cubic
	gaussian
	lanczos2
	lanczos3
	lanczos3_stretched
}

fn C.pixman_filter_create_separable_convolution(n_values &int, scale_x C.pixman_fixed_t, scale_y C.pixman_fixed_t, reconstruct_x Pixman_kernel_t, reconstruct_y Pixman_kernel_t, sample_x Pixman_kernel_t, sample_y Pixman_kernel_t, subsample_bits_x int, subsample_bits_y int) &C.pixman_fixed_t
fn C.pixman_image_fill_rectangles(op Pixman_op_t, image &C.pixman_image_t, color C.pixman_color_t, n_rects int, rects &C.pixman_rectangle_t) C.pixman_bool_t
fn C.pixman_image_fill_boxes(op Pixman_op_t, dest &C.pixman_image_t, color C.pixman_color_t, n_boxes int, boxes &C.pixman_box32_t) C.pixman_bool_t

// composite

fn C.pixman_compute_composite_region(region &C.pixman_region16_t, src_image &C.pixman_image_t, mask_image &C.pixman_image_t, dest_image &C.pixman_image_t, src_x int16_t, src_y int16_t, mask_x int16_t, mask_y int16_t, dest_x int16_t, dest_y int16_t, width uint16_t, height uint16_t) C.pixman_bool_t
fn C.pixman_image_composite(op Pixman_op_t, src &C.pixman_image_t, mask &C.pixman_image_t, dest &C.pixman_image_t, src_x int16_t, src_y int16_t, mask_x int16_t, mask_y int16_t, dest_x int16_t, dest_y int16_t, width uint16_t, height uint16_t) C.pixman_bool_t
fn C.pixman_image_composite32(op Pixman_op_t, src &C.pixman_image_t, mask &C.pixman_image_t, dest &C.pixman_image_t, src_x i32, src_y i32, mask_x i32, mask_y i32, dest_x i32, dest_y i32, width u32, height u32) C.pixman_bool_t
fn C.pixman_image_composite64(op Pixman_op_t, src &C.pixman_image_t, mask &C.pixman_image_t, dest &C.pixman_image_t, src_x int64_t, src_y int64_t, mask_x int64_t, mask_y int64_t, dest_x int64_t, dest_y int64_t, width uint64_t, height uint64_t) C.pixman_bool_t

// glyphs

pub struct C.pixman_glyph_cache_t {}

@[typedef]
pub struct C.pixman_glyph_t {
	x     int
	y     int
	glyph voidptr
}

fn C.pixman_glyph_cache_create() &C.pixman_glyph_cache_t
fn C.pixman_glyph_cache_destroy(cache &C.pixman_glyph_cache_t)
fn C.pixman_glyph_cache_freeze(cache &C.pixman_glyph_cache_t)
fn C.pixman_glyph_cache_thaw(cache &C.pixman_glyph_cache_t)
fn C.pixman_glyph_cache_lookup(cache &C.pixman_glyph_cache_t, font_key voidptr, glyph_key voidptr) voidptr
fn C.pixman_glyph_cache_insert(cache &C.pixman_glyph_cache_t, font_key voidptr, glyph_key voidptr, origin_x int, origin_y int, glyph_image &C.pixman_image_t) C.pixman_bool_t
fn C.pixman_glyph_cache_remove(cache &C.pixman_glyph_cache_t, font_key voidptr, glyph_key voidptr)
fn C.pixman_glyph_get_extents(cache &C.pixman_glyph_cache_t, n_glyphs int, glyphs &C.pixman_glyph_t, extents &C.pixman_box32_t)
fn C.pixman_glyph_get_mask_format(cache &C.pixman_glyph_cache_t, n_glyphs int, glyphs &C.pixman_glyph_t) Pixman_format_code_t
fn C.pixman_composite_glyphs(op Pixman_op_t, src &C.pixman_image_t, dest &C.pixman_image_t, mask_format Pixman_format_code_t, src_x i32, src_y i32, mask_x i32, mask_y i32, dest_x i32, dest_y i32, width i32, height i32, cache &C.pixman_glyph_cache_t, n_glyphs int, glyphs &C.pixman_glyph_t)
fn C.pixman_composite_glyphs_no_mask(op Pixman_op_t, src &C.pixman_image_t, dest &C.pixman_image_t, src_x i32, src_y i32, dest_x i32, dest_y i32, cache &C.pixman_glyph_cache_t, n_glyphs int, glyphs &C.pixman_glyph_t)

// trapezoids

type C.pixman_edge_t = C.pixman_edge
type C.pixman_trapezoid_t = C.pixman_trapezoid
type C.pixman_trap_t = C.pixman_trap
type C.pixman_span_fix_t = C.pixman_span_fix
type C.pixman_triangle_t = C.pixman_triangle

struct C.pixman_edge {
	x      C.pixman_fixed_t
	e      C.pixman_fixed_t
	stepx  C.pixman_fixed_t
	signdx C.pixman_fixed_t
	dy     C.pixman_fixed_t
	dx     C.pixman_fixed_t

	stepx_small C.pixman_fixed_t
	stepx_big   C.pixman_fixed_t
	dx_small    C.pixman_fixed_t
	dx_big      C.pixman_fixed_t
}

struct C.pixman_trapezoid {
	top    C.pixman_fixed_t
	bottom C.pixman_fixed_t
	left   C.pixman_line_fixed_t
	right  C.pixman_line_fixed_t
}

struct C.pixman_triangle {
	p1 C.pixman_point_fixed_t
	p2 C.pixman_point_fixed_t
	p3 C.pixman_point_fixed_t
}

@[inline]
pub fn pixman_trapezoid_valid(t &C.pixman_trapezoid_t) bool {
	return t.left.p1.y != t.left.p2.y && t.right.p1.y != t.right.p2.y && t.bottom > t.top
}

pub struct C.pixman_span_fix {
	l C.pixman_fixed_t
	r C.pixman_fixed_t
	y C.pixman_fixed_t
}

pub struct C.pixman_trap {
	top C.pixman_span_fix_t
	bot C.pixman_span_fix_t
}

fn C.pixman_sample_ceil_y(y C.pixman_fixed_t, bpp int) C.pixman_fixed_t
fn C.pixman_sample_floor_y(y C.pixman_fixed_t, bpp int) C.pixman_fixed_t
fn C.pixman_edge_step(e &C.pixman_edge_t, n int)
fn C.pixman_edge_init(e &C.pixman_edge_t, bpp int, y_start C.pixman_fixed_t, x_top C.pixman_fixed_t, y_top C.pixman_fixed_t, x_bot C.pixman_fixed_t, y_bot C.pixman_fixed_t)
fn C.pixman_line_fixed_edge_init(e &C.pixman_edge_t, bpp int, y C.pixman_fixed_t, line &C.pixman_line_fixed_t, x_off int, y_off int)
fn C.pixman_rasterize_edges(image &C.pixman_image_t, l &C.pixman_edge_t, r &C.pixman_edge_t, t C.pixman_fixed_t, b C.pixman_fixed_t)
fn C.pixman_add_traps(image &C.pixman_image_t, x_off int16_t, y_off int16_t, ntrap int, traps &C.pixman_trap_t)
fn C.pixman_add_trapezoids(image &C.pixman_image_t, x_off int16_t, y_off int16_t, ntraps int, traps &C.pixman_trapezoid_t)
fn C.pixman_rasterize_trapezoid(image &C.pixman_image_t, trap &C.pixman_trapezoid_t, x_off int, y_off int)
fn C.pixman_composite_trapezoids(op Pixman_op_t, src &C.pixman_image_t, dst &C.pixman_image_t, mask_format Pixman_format_code_t, x_src int, y_src int, x_dst int, y_dst int, n_traps int, traps &C.pixman_trap_t)
fn C.pixman_composite_triangles(op Pixman_op_t, src &C.pixman_image_t, dst &C.pixman_image_t, mask_format Pixman_format_code_t, x_src int, y_src int, x_dst int, y_dst int, n_tris int, tris &C.pixman_triangle_t)
fn C.pixman_add_triangles(image &C.pixman_image_t, x_off u32, y_off u32, n_tris int, tris &C.pixman_triangle_t)
