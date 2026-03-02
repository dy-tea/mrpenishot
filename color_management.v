module main

import protocols.color_management_v1 as cm

fn handle_cm_image_description_info_done(data voidptr, obj voidptr) {
	mut state := unsafe { &State(data) }
	state.n_cm_done++
}

fn handle_cm_image_description_info_tf_named(data voidptr, obj voidptr, tf u32) {
	mut state := unsafe { &State(data) }
	state.is_hdr = tf & u32(cm.WpColorManagerV1_TransferFunction.st2084_pq) != 0
}

const cm_image_description_info_listener = cm.wpimagedescriptioninfov1_listener(
	handle_cm_image_description_info_done, // done
	none, // icc_file
	none, // primaries
	none, // primaries_named
	none, // tf_power
	handle_cm_image_description_info_tf_named, // tf_named
	none, // luminances
	none, // target_primaries
	none, // target_luminance
	none, // target_max_cll
	none // target_max_fall
)

fn handle_cm_image_description_ready(data voidptr, description_proxy voidptr, identity u32) {
	mut state := unsafe { &State(data) }
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

const cm_image_description_listener = cm.wpimagedescriptionv1_listener(
	handle_cm_image_description_failed, // failed
	handle_cm_image_description_ready, // ready
	none // ready2
)

fn handle_cm_output_image_description_changed(data voidptr, mut cm_output cm.WpColorManagementOutputV1) {
	mut state := unsafe { &State(data) }
	mut description := cm_output.get_image_description()
	description.add_listener(&cm_image_description_listener, state)
}

const cm_output_listener = cm.wpcolormanagementoutputv1_listener(
	handle_cm_output_image_description_changed // image_description_changed
)
