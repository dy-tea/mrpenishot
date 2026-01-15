module fmt

import pixman as px

pub enum Category {
	_8c_32b
	_10c_32b
	_8c_24b
}

pub fn Category.new(p px.Pixman_format_code_t) Category {
	return match p {
		.a8r8g8b8, .x8r8g8b8, .a8b8g8r8, .x8b8g8r8, .b8g8r8a8, .b8g8r8x8, .r8g8b8a8, .r8g8b8x8 {
			._8c_32b
		}
		.a2r10g10b10, .x2r10g10b10, .a2b10g10r10, .x2b10g10r10 {
			._10c_32b
		}
		.r8g8b8, .b8g8r8 {
			._8c_24b
		}
		else {
			panic("Unsupported format: ${p}")
		}
	}
}
