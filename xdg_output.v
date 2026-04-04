module main

import protocols.xdg_output_unstable_v1 as xo

fn xdg_output_handle_logical_position(mut output Output, obj voidptr, x int, y int) {
	output.logical_geometry.x = x
	output.logical_geometry.y = y
}

fn xdg_output_handle_logical_size(mut output Output, obj voidptr, width int, height int) {
	output.logical_geometry.width = width
	output.logical_geometry.height = height
}

fn xdg_output_handle_done(mut output Output, obj voidptr) {
	width, _ := transform_output(output.transform, output.mode_width, output.mode_height)
	output.logical_scale = f64(width) / output.logical_geometry.width
}

fn xdg_output_handle_name(mut output Output, obj voidptr, name &char) {
	if output.name == '' {
		output.name = unsafe { name.vstring() }
	}
}

const xdg_output_listener = xo.zxdgoutputv1_listener(xdg_output_handle_logical_position,
	xdg_output_handle_logical_size, xdg_output_handle_done, xdg_output_handle_name, none)
