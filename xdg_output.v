module main

import dy_tea.wayland as wl

fn make_xdg_output_events() wl.ZxdgOutputV1Events[&Output] {
	return wl.ZxdgOutputV1Events[&Output]{
		logical_position: fn (mut o Output, x i32, y i32) {
			o.logical_geometry.x = int(x)
			o.logical_geometry.y = int(y)
		}
		logical_size:     fn (mut o Output, width i32, height i32) {
			o.logical_geometry.width = int(width)
			o.logical_geometry.height = int(height)
		}
		done:             fn (mut o Output) {
			w := o.mode_width
			width, _ := transform_output(o.transform, w, o.mode_height)
			o.logical_scale = f64(width) / o.logical_geometry.width
		}
		name:             fn (mut o Output, name string) {
			if o.name == '' {
				o.name = name
			}
		}
	}
}
