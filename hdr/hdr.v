module hdr

import math

pub fn pq_to_linear(val_10bit u32) f64 {
	mut x := f32(val_10bit) / 1023.0

	// PQ Constants
	m1 := 2610.0 / 16384.0
	m2 := (2523.0 / 4096.0) * 128.0
	c1 := 3424.0 / 4096.0
	c2 := (2413.0 / 4096.0) * 32.0
	c3 := (2392.0 / 4096.0) * 32.0

	x_pow := math.pow(x, 1.0 / m2)
	num := math.max(x_pow - c1, 0.0)
	den := c2 - c3 * x_pow
	return math.pow(num / den, 1.0 / m1)
}

pub fn linear_to_srgb_16(lin f64) u16 {
	mut s := lin * 50.0 // this might be per-display
	s = if s <= 0.0031308 {
		s * 12.92
	} else {
		1.055 * math.pow(s, 1.0 / 2.4) - 0.055
	}
	return u16(math.max(0.0, math.min(1.0, s)) * 65535.0)
}

@[inline]
pub fn apply_bt2020_to_srgb(r f64, g f64, b f64) (f64, f64, f64) {
	return 1.6605 * r - 0.5876 * g - 0.0728 * b, -0.1246 * r + 1.1329 * g - 0.0083 * b,
		-0.0182 * r - 0.1006 * g + 1.1188 * b
}
