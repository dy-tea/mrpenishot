module jxl

#flag linux -L/usr/lib
#flag linux -ljxl
#flag linux -I/usr/include
#include <jxl/codestream_header.h>

pub enum JxlOrientation {
	identity        = 1
	flip_horizontal = 2
	rotate_180      = 3
	flip_vertical   = 4
	transpose       = 5
	rotate_90_cw    = 6
	anti_transpose  = 7
	rotate_90_ccw   = 8
}

pub enum JxlExtraChannelType {
	alpha
	delta
	spot_color
	selection_mask
	black
	cfa
	thermal
	reserved0
	reserved1
	reserved2
	reserved3
	reserved4
	reserved5
	reserved6
	reserved7
	unknown
	optional
}

@[typedef]
pub struct C.JxlPreviewHeader {
	xsize u32
	ysize u32
}

@[typedef]
pub struct C.JxlAnimationHeader {
	tps_numerator   u32
	tps_denominator u32
	num_loops       u32
	have_timecodes  bool
}

@[typedef]
pub struct C.JxlBasicInfo {
	have_container           bool
	xsize                    u32
	ysize                    u32
	bits_per_sample          u32
	exponent_bits_per_sample u32
	intensity_target         f32
	min_nits                 f32
	relative_to_max_display  bool
	linear_below             f32
	uses_original_profile    bool
	have_preview             bool
	have_animation           bool
	orientation              JxlOrientation
	num_color_channels       u32
	num_extra_channels       u32
	alpha_bits               u32
	alpha_exponent_bits      u32
	alpha_premultiplied      bool
	preview                  C.JxlPreviewHeader
	animation                C.JxlAnimationHeader
	intrinsic_xsize          u32
	intrinsic_ysize          u32
	padding                  [100]u8
}

@[typedef]
pub struct C.JxlExtraChannelInfo {
	type_                    JxlExtraChannelType
	bits_per_sample          u32
	exponent_bits_per_sample u32
	dim_shift                u32
	name_length              u32
	alpha_premultiplied      bool
	spot_color               [4]f32
	cfa_channel              u32
}

@[typedef]
pub struct C.JxlHeaderExtensions {
	extensions u64
}

pub enum JxlBlendMode {
	replace = 0
	add     = 1
	blend   = 2
	muladd  = 3
	mul     = 4
}

@[typedef]
pub struct C.JxlBlendInfo {
	blendmode JxlBlendMode
	source    u32
	alpha     u32
	clamp     bool
}

@[typedef]
pub struct C.JxlLayerInfo {
	have_crop         bool
	crop_x0           i32
	crop_y0           i32
	xsize             u32
	ysize             u32
	blend_info        C.JxlBlendInfo
	save_as_reference u32
}

@[typedef]
pub struct C.JxlFrameHeader {
	duration    u32
	timecode    u32
	name_length u32
	is_last     bool
	layer_info  C.JxlLayerInfo
}
