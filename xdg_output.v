module main
import protocols.xdg_output_unstable_v1 as xo

fn xdg_output_handle_logical_position(mut output Output, _ &xo.ZxdgOutputV1, x int, y int) {
	output.logical_geometry.x = x
	output.logical_geometry.y = y
}

fn xdg_output_handle_logical_size(mut output Output, _ &xo.ZxdgOutputV1, width int, height int) {
	output.logical_geometry.width = width
	output.logical_geometry.height = height
}

fn xdg_output_handle_done(mut output Output, _ &xo.ZxdgOutputV1) {
	width, _ := transform_output(output.transform, output.mode_width, output.mode_height)
	output.logical_scale = f64(width) / output.logical_geometry.width
}

fn xdg_output_handle_name(mut output Output, _ &xo.ZxdgOutputV1, name &char) {
	if output.name == '' {
		output.name = unsafe { name.vstring() }
	}
}

const xdg_output_listener = C.zxdg_output_v1_listener{
	logical_position: xdg_output_handle_logical_position
	logical_size:     xdg_output_handle_logical_size
	done:             xdg_output_handle_done
	name:             xdg_output_handle_name
	description:      fn (_ voidptr, _ &xo.ZxdgOutputV1, _ &char) {}
}
