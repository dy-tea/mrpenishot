module main

import protocols.color_management_v1 as cm

fn handle_cm_image_description_info_done(mut state State, proxy voidptr) {
    state.n_cm_done++
}

fn handle_cm_image_description_info_tf_named(mut state State, info &cm.WpImageDescriptionInfoV1, tf u32) {
	state.is_hdr = tf & u32(cm.WpColorManagerV1_TransferFunction.st2084_pq) != 0
}

const cm_image_description_info_listener = C.wp_image_description_info_v1_listener{
	done:             handle_cm_image_description_info_done
	icc_file:         fn (_ voidptr, _ voidptr, _ int, _ u32) {}
	primaries:        fn (_ voidptr, _ voidptr, _ int, _ int, _ int, _ int, _ int, _ int, _ int, _ int) {}
	primaries_named:  fn (_ voidptr, _ voidptr, _ u32) {}
	tf_power:         fn (_ voidptr, _ voidptr, _ u32) {}
	tf_named:         handle_cm_image_description_info_tf_named
	luminances:       fn (_ voidptr, _ voidptr, _ u32, _ u32, _ u32) {}
	target_primaries: fn (_ voidptr, _ voidptr, _ int, _ int, _ int, _ int, _ int, _ int, _ int, _ int) {}
	target_luminance: fn (_ voidptr, _ voidptr, _ u32, _ u32) {}
	target_max_cll:   fn (_ voidptr, _ voidptr, _ u32) {}
	target_max_fall:  fn (_ voidptr, _ voidptr, _ u32) {}
}

fn handle_cm_image_description_ready(mut state State, description_proxy voidptr, identity u32) {
	mut desc := &cm.WpImageDescriptionV1{
		proxy: description_proxy
	}
	mut info := desc.get_information()
	info.add_listener(&cm_image_description_info_listener, state)
}

fn handle_cm_image_description_failed(mut state State, description &cm.WpImageDescriptionV1, cause u32, msg &char) {
	msg_str := unsafe { msg.vstring() }
	eprintln('Image description failed: ${msg_str} (cause: ${cause})')
}

const cm_image_description_listener = C.wp_image_description_v1_listener{
	failed: handle_cm_image_description_failed
	ready:  handle_cm_image_description_ready
	ready2: fn (_ voidptr, _ voidptr, _ u32, _ u32) {}
}

fn handle_cm_output_image_description_changed(mut state State, mut cm_output cm.WpColorManagementOutputV1) {
	mut description := cm_output.get_image_description()
	description.add_listener(&cm_image_description_listener, state)
}

const cm_output_listener = C.wp_color_management_output_v1_listener{
	image_description_changed: handle_cm_output_image_description_changed
}
