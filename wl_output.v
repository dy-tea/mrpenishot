module main
import protocols.wayland as wlp

fn output_handle_geometry(mut output Output, _ &wlp.WlOutput, x int, y int, _ int, _ int, _ int, _ &char, _ &char, transform int) {
	output.x = x
	output.y = y
	output.transform = unsafe { wlp.WlOutput_Transform(transform) }
}

fn output_handle_mode(mut output Output, _ &wlp.WlOutput, flags u32, width int, height int, _ int) {
	if flags & u32(wlp.WlOutput_Mode.current) != 0 {
		output.mode_width = width
		output.mode_height = height
	}
}

fn output_handle_scale(mut output Output, _ &wlp.WlOutput, factor int) {
	output.scale = factor
}

fn output_handle_name(mut output Output, _ &wlp.WlOutput, name &char) {
	output.name = unsafe { name.vstring() }
}

const output_listener = C.wl_output_listener{
	geometry:    output_handle_geometry
	mode:        output_handle_mode
	done:        fn (_ voidptr, _ &wlp.WlOutput) {}
	scale:       output_handle_scale
	name:        output_handle_name
	description: fn (_ voidptr, _ &wlp.WlOutput, _ &char) {}
}
