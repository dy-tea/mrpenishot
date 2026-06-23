module main

import dy_tea.wayland as wl

fn make_output_events() wl.WlOutputEvents[&Output] {
	return wl.WlOutputEvents[&Output]{
		geometry: fn (mut o Output, x i32, y i32, physical_width i32, physical_height i32, subpixel i32, make string, model string, transform i32) {
			o.x = int(x)
			o.y = int(y)
			o.transform = transform
		}
		mode:     fn (mut o Output, flags u32, width i32, height i32, refresh i32) {
			if flags & 1 != 0 {
				o.mode_width = int(width)
				o.mode_height = int(height)
			}
		}
		scale:    fn (mut o Output, factor i32) {
			o.scale = int(factor)
		}
		name:     fn (mut o Output, name string) {
			o.name = name
		}
	}
}
