module main

import protocols.wayland as wlp

fn output_handle_geometry(mut output Output, obj voidptr, x int, y int, physical_width int, physical_height int, subpixel int, make &char, model &char, transform int) {
	output.x = x
	output.y = y
	output.transform = unsafe { wlp.WlOutput_Transform(transform) }
}

fn output_handle_mode(mut output Output, obj voidptr, flags u32, width int, height int, refresh int) {
	if flags & u32(wlp.WlOutput_Mode.current) != 0 {
		output.mode_width = width
		output.mode_height = height
	}
}

fn output_handle_scale(mut output Output, obj voidptr, factor int) {
	output.scale = factor
}

fn output_handle_name(mut output Output, obj voidptr, name &char) {
	output.name = unsafe { name.vstring() }
}

const output_listener = wlp.wloutput_listener(output_handle_geometry, output_handle_mode,
	none, output_handle_scale, output_handle_name, none)
