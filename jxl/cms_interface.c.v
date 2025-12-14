module jxl

#flag linux -L/usr/lib
#flag linux -ljxl
#flag linux -I/usr/include
#include <jxl/cms_interface.h>

pub type Jpxegxl_cms_set_fields_from_icc_func = fn (user_data voidptr, icc_data &u8, icc_size usize, c &C.JxlColorEncoding, cmyk &bool) bool

@[typedef]
pub struct C.JxlColorProfile {
	icc            struct {
		data &u8
		size usize
	}
	color_encoding C.JxlColorEncoding
	num_channels   usize
}

//...
