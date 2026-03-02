module main
import protocols.xdg_output_unstable_v1 as xo

fn xdg_output_handle_logical_position(data voidptr, obj voidptr, x int, y int) {
	mut output := unsafe { &Output(data) }
	output.logical_geometry.x = x
	output.logical_geometry.y = y
}

fn xdg_output_handle_logical_size(data voidptr, obj voidptr, width int, height int) {
	mut output := unsafe { &Output(data) }
	output.logical_geometry.width = width
	output.logical_geometry.height = height
}

fn xdg_output_handle_done(data voidptr, obj voidptr) {
	mut output := unsafe { &Output(data) }
	width, _ := transform_output(output.transform, output.mode_width, output.mode_height)
	output.logical_scale = f64(width) / output.logical_geometry.width
}

fn xdg_output_handle_name(data voidptr, obj voidptr, name &char) {
	mut output := unsafe { &Output(data) }
	if output.name == '' {
		output.name = unsafe { name.vstring() }
	}
}

const xdg_output_listener = xo.zxdgoutputv1_listener(
	xdg_output_handle_logical_position, // logical_position
	xdg_output_handle_logical_size, // logical_size
	xdg_output_handle_done, // done
	xdg_output_handle_name, // name
	none // description
)
