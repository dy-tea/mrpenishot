module jxl

#flag linux -L/usr/lib
#flag linux -ljxl
#flag linux -I/usr/include
#include <jxl/types.h>

pub enum JxlDataType {
	float   = 0
	uint8   = 2
	uint16  = 3
	float16 = 5
}

pub enum JxlEndianness {
	native_endian = 0
	little_endian = 1
	big_endian    = 2
}

@[typedef]
pub struct C.JxlPixelFormat {
	num_channels u32
	data_type    JxlDataType
	endianness   JxlEndianness
	align        usize
}

pub enum JxlBitDepthType {
	from_pixel_format = 0
	from_codestream   = 1
	custom            = 2
}

@[typedef]
pub struct C.JxlBitDepth {
	type_                    JxlBitDepthType
	bits_per_sample          u32
	exponent_bits_per_sample u32
}

type JxlBoxType = [4]char
