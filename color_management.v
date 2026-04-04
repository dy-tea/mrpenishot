module main

import protocols.color_management_v1 as cm

fn handle_cm_image_description_info_done(mut state State, obj voidptr) {
	state.n_cm_done++
}

fn handle_cm_image_description_info_tf_named(mut state State, obj voidptr, tf u32) {
	state.is_hdr = tf & u32(cm.WpColorManagerV1_TransferFunction.st2084_pq) != 0
}

const cm_image_description_info_listener = cm.wpimagedescriptioninfov1_listener(handle_cm_image_description_info_done,
	none, none, none, none, handle_cm_image_description_info_tf_named, none, none, none,
	none, none)

fn handle_cm_image_description_ready(mut state State, description_proxy voidptr, identity u32) {
	mut desc := &cm.WpImageDescriptionV1{
		proxy: description_proxy
	}
	mut info := desc.get_information()
	info.add_listener(&cm_image_description_info_listener, state)
}

fn handle_cm_image_description_failed(data voidptr, description &cm.WpImageDescriptionV1, cause u32, msg &char) {
	msg_str := unsafe { msg.vstring() }
	eprintln('Image description failed: ${msg_str} (cause: ${cause})')
}

const cm_image_description_listener = cm.wpimagedescriptionv1_listener(handle_cm_image_description_failed,
	handle_cm_image_description_ready, none)

fn handle_cm_output_image_description_changed(mut state State, mut cm_output cm.WpColorManagementOutputV1) {
	mut description := cm_output.get_image_description()
	description.add_listener(&cm_image_description_listener, state)
}

const cm_output_listener = cm.wpcolormanagementoutputv1_listener(handle_cm_output_image_description_changed)
