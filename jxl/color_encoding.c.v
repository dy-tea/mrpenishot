module jxl

#flag linux -L/usr/lib
#flag linux -ljxl
#flag linux -I/usr/include
#include <jxl/color_encoding.h>

pub enum JxlColorSpace {
	rgb
	gray
	xyb
	unknown
}

pub enum JxlWhitePoint {
	d65    = 1
	custom = 2
	e      = 10
	dci    = 11
}

pub enum JxlPrimaries {
	srgb   = 1
	custom = 2
	_2100  = 9
	p3     = 11
}

pub enum JxlTransferFunction {
	_709    = 1
	unknown = 2
	linear  = 8
	srgb    = 13
	pq      = 16
	dci     = 17
	hlg     = 18
	gamma   = 65535
}

pub enum JxlRenderingIntent {
	perceptual = 0
	relative
	saturation
	absolute
}

@[typedef]
pub struct C.JxlColorEncoding {
	color_space        JxlColorSpace
	white_point        JxlWhitePoint
	white_point_xy     [2]f32
	primaries          JxlPrimaries
	primaries_red_xy   [2]f32
	primaries_green_xy [2]f32
	primaries_blue_xy  [2]f32
	transfer_function  JxlTransferFunction
	gamma              f64
	rendering_intent   JxlRenderingIntent
}
