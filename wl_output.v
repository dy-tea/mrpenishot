module main
import protocols.wayland as wlp

fn output_handle_geometry(data voidptr, obj voidptr, x int, y int, physical_width int, physical_height int, subpixel int, make &char, model &char, transform int) {
	mut output := unsafe { &Output(data) }
	output.x = x
	output.y = y
	output.transform = unsafe { wlp.WlOutput_Transform(transform) }
}

fn output_handle_mode(data voidptr, obj voidptr, flags u32, width int, height int, refresh int) {
	mut output := unsafe { &Output(data) }
	if flags & u32(wlp.WlOutput_Mode.current) != 0 {
		output.mode_width = width
		output.mode_height = height
	}
}

fn output_handle_scale(data voidptr, obj voidptr, factor int) {
	mut output := unsafe { &Output(data) }
	output.scale = factor
}

fn output_handle_name(data voidptr, obj voidptr, name &char) {
	mut output := unsafe { &Output(data) }
	output.name = unsafe { name.vstring() }
}

const output_listener = wlp.wloutput_listener(
	output_handle_geometry, // geometry
	output_handle_mode, // mode
	none, // done
	output_handle_scale, // scale
	output_handle_name, // name
	none // description
)
