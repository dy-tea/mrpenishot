module packer

import hdr
import pixman as px

pub const rgb_channels = 3
pub const rgba_channels = 4

@[direct_array_access; unsafe]
pub fn pack_row24_8(row_in &u8, width int, row_out &u8, format px.Pixman_format_code_t) {
	mut offset := 0
	for x in 0 .. width {
		p_idx := x * 3
		row_out[offset]     = row_in[p_idx]     // R
		row_out[offset + 1] = row_in[p_idx + 1] // G
		row_out[offset + 2] = row_in[p_idx + 2] // B
		offset += 3
	}
}

@[direct_array_access; unsafe]
pub fn pack_row32_8(row_in &u32, width int, row_out &u8, fully_opaque bool, format px.Pixman_format_code_t) {
  mut offset := 0
  for x in 0 .. width {
    pixel := row_in[x]
    mut r, mut g, mut b, mut a := match format {
      .a8r8g8b8, .x8r8g8b8 {
       	u8((pixel >> 16) & 0xff),
       	u8((pixel >> 8) & 0xff),
        u8(pixel & 0xff),
        u8((pixel >> 24) & 0xff)
      }
      .a8b8g8r8, .x8b8g8r8 {
        u8(pixel & 0xff),
        u8((pixel >> 8) & 0xff),
        u8((pixel >> 16) & 0xff),
        u8((pixel >> 24) & 0xff)
      }
      // .bgra8888, .rgba8888
      else {
     		u8((pixel >> 8) & 0xff),
      	u8((pixel >> 16) & 0xff),
      	u8((pixel >> 24) & 0xff),
        u8(pixel & 0xff)
      }
    }

    if !fully_opaque && a != 0 && a != 255 {
      r = u8((int(r) * 255) / int(a))
      g = u8((int(g) * 255) / int(a))
      b = u8((int(b) * 255) / int(a))
    }

    row_out[offset] = r
    row_out[offset + 1] = g
    row_out[offset + 2] = b
    if !fully_opaque {
      row_out[offset + 3] = a
      offset += 4
    } else {
      offset += 3
    }
  }
}

@[direct_array_access; unsafe]
pub fn pack_row32_10(row_in &u32, width int, row_out &u8, fully_opaque bool, format px.Pixman_format_code_t) {
  for x in 0 .. width {
	  p := row_in[x]
	  g10 := (p >> 10) & 0x3FF
		a2 := (p >> 30) & 0x3
	  r10, b10 := if format in [.a2b10g10r10, .x2b10g10r10] {
			(p >> 0) & 0x3FF, (p >> 20) & 0x3FF
		} else {
			(p >> 20) & 0x3FF, (p >> 0) & 0x3FF
		}
		a16 := u16(a2 * 0x5555)

    r16 := (r10 << 6) | (r10 >> 4)
    g16 := (g10 << 6) | (g10 >> 4)
    b16 := (b10 << 6) | (b10 >> 4)

    offset := x * if fully_opaque { 6 } else { 8 }
    row_out[offset + 0] = u8(r16 >> 8)
    row_out[offset + 1] = u8(r16 & 0xff)
    row_out[offset + 2] = u8(g16 >> 8)
    row_out[offset + 3] = u8(g16 & 0xff)
    row_out[offset + 4] = u8(b16 >> 8)
    row_out[offset + 5] = u8(b16 & 0xff)
    if !fully_opaque {
	    row_out[offset + 6] = u8(a16 >> 8)
	    row_out[offset + 7] = u8(a16 & 0xff)
	  }
  }
}

@[direct_array_access; unsafe]
pub fn pack_row32_10_hdr(row_in &u32, width int, row_out &u8, fully_opaque bool, format px.Pixman_format_code_t) {
  for x in 0 .. width {
	  p := row_in[x]
	  g10 := (p >> 10) & 0x3FF
		a2 := (p >> 30) & 0x3
		a16 := u16(a2 * 0x5555)
		r10, b10 := if format in [.a2b10g10r10, .x2b10g10r10] {
			(p >> 0) & 0x3FF, (p >> 20) & 0x3FF
		} else {
			(p >> 20) & 0x3FF, (p >> 0) & 0x3FF
		}

    r_lin := hdr.pq_to_linear(r10)
    g_lin := hdr.pq_to_linear(g10)
    b_lin := hdr.pq_to_linear(b10)

    r_s, g_s, b_s := hdr.apply_bt2020_to_srgb(r_lin, g_lin, b_lin)

    r16 := hdr.linear_to_srgb_16(r_s)
    g16 := hdr.linear_to_srgb_16(g_s)
    b16 := hdr.linear_to_srgb_16(b_s)

    offset := x * if fully_opaque { 6 } else { 8 }
    row_out[offset + 0] = u8(r16 >> 8)
    row_out[offset + 1] = u8(r16 & 0xff)
    row_out[offset + 2] = u8(g16 >> 8)
    row_out[offset + 3] = u8(g16 & 0xff)
    row_out[offset + 4] = u8(b16 >> 8)
    row_out[offset + 5] = u8(b16 & 0xff)
    if !fully_opaque {
      row_out[offset + 6] = u8(a16 >> 8)
      row_out[offset + 7] = u8(a16 & 0xff)
    }
  }
}

@[direct_array_access; unsafe]
pub fn pack_row32_10_to_32_8(row_in &u32, width int, row_out &u8, fully_opaque bool, format px.Pixman_format_code_t) {
  for x in 0 .. width {
	  p := row_in[x]

	  g10 := (p >> 10) & 0x3FF
	  a2 := (p >> 30) & 0x3
		a8 := u8(a2 * 0x55)
		r10, b10 := if format in [.a2b10g10r10, .x2b10g10r10] {
	    (p >> 0) & 0x3FF, (p >> 20) & 0x3FF
	  } else {
			(p >> 20) & 0x3FF, (p >> 0) & 0x3FF
	  }

	  r_lin := hdr.pq_to_linear(r10)
	  g_lin := hdr.pq_to_linear(g10)
	  b_lin := hdr.pq_to_linear(b10)

	  r8 := hdr.linear_to_srgb_8(r_lin)
	  g8 := hdr.linear_to_srgb_8(g_lin)
	  b8 := hdr.linear_to_srgb_8(b_lin)

	  offset := x * if fully_opaque { 3 } else { 4 }
	  row_out[offset]     = r8
	  row_out[offset + 1] = g8
	  row_out[offset + 2] = b8
    if !fully_opaque {
      row_out[offset + 3] = a8
    }
  }
}

@[direct_array_access; unsafe]
pub fn pack_row32_10_hdr_to_32_8(row_in &u32, width int, row_out &u8, fully_opaque bool, format px.Pixman_format_code_t) {
  for x in 0 .. width {
    p := row_in[x]

    g10 := (p >> 10) & 0x3FF
    a2 := (p >> 30) & 0x3
    a8 := u8(a2 * 0x55)
    r10, b10 := if format in [.a2b10g10r10, .x2b10g10r10] {
	    (p >> 0) & 0x3FF, (p >> 20) & 0x3FF
	  } else {
			(p >> 20) & 0x3FF, (p >> 0) & 0x3FF
	  }

    r_lin := hdr.pq_to_linear(r10)
    g_lin := hdr.pq_to_linear(g10)
    b_lin := hdr.pq_to_linear(b10)

    r_s, g_s, b_s := hdr.apply_bt2020_to_srgb(r_lin, g_lin, b_lin)

    r8 := hdr.linear_to_srgb_8(r_s)
    g8 := hdr.linear_to_srgb_8(g_s)
    b8 := hdr.linear_to_srgb_8(b_s)

    offset := x * if fully_opaque { 3 } else { 4 }
    row_out[offset]     = r8
    row_out[offset + 1] = g8
    row_out[offset + 2] = b8
    if !fully_opaque {
	    row_out[offset + 3] = a8
	  }
  }
}
