module main

import wayland.protocols.color_management_v1 as cm

struct CmImageDescriptionInfoListener {
mut:
	state &State
}

fn (mut l CmImageDescriptionInfoListener) done(_ cm.WpImageDescriptionInfoV1) {
	l.state.n_cm_done++
}

fn (mut l CmImageDescriptionInfoListener) icc_file(_ cm.WpImageDescriptionInfoV1, _ int, _ u32) {
}

fn (mut l CmImageDescriptionInfoListener) primaries(_ cm.WpImageDescriptionInfoV1, _ i32, _ i32, _ i32, _ i32, _ i32, _ i32, _ i32, _ i32) {
}

fn (mut l CmImageDescriptionInfoListener) primaries_named(_ cm.WpImageDescriptionInfoV1, _ u32) {
}

fn (mut l CmImageDescriptionInfoListener) tf_power(_ cm.WpImageDescriptionInfoV1, _ u32) {
}

fn (mut l CmImageDescriptionInfoListener) tf_named(_ cm.WpImageDescriptionInfoV1, tf u32) {
	l.state.is_hdr = tf == cm.wp_color_manager_v1_transfer_function_st2084_pq
}

fn (mut l CmImageDescriptionInfoListener) luminances(_ cm.WpImageDescriptionInfoV1, _ u32, _ u32, _ u32) {
}

fn (mut l CmImageDescriptionInfoListener) target_primaries(_ cm.WpImageDescriptionInfoV1, _ i32, _ i32, _ i32, _ i32, _ i32, _ i32, _ i32, _ i32) {
}

fn (mut l CmImageDescriptionInfoListener) target_luminance(_ cm.WpImageDescriptionInfoV1, _ u32, _ u32) {
}

fn (mut l CmImageDescriptionInfoListener) target_max_cll(_ cm.WpImageDescriptionInfoV1, _ u32) {
}

fn (mut l CmImageDescriptionInfoListener) target_max_fall(_ cm.WpImageDescriptionInfoV1, _ u32) {
}

struct CmImageDescriptionListener {
mut:
	state &State
}

fn (mut l CmImageDescriptionListener) failed(_ cm.WpImageDescriptionV1, cause u32, msg string) {
	eprintln('Image description failed: ${msg} (cause: ${cause})')
}

fn (mut l CmImageDescriptionListener) ready(proxy cm.WpImageDescriptionV1, _ u32) {
	mut info := proxy.get_information() or { return }
	info.set_listener(&CmImageDescriptionInfoListener{
		state: l.state
	}) or {}
}

fn (mut l CmImageDescriptionListener) ready2(proxy cm.WpImageDescriptionV1, _ u32, _ u32) {
	mut info := proxy.get_information() or { return }
	info.set_listener(&CmImageDescriptionInfoListener{
		state: l.state
	}) or {}
}

struct CmOutputListener {
mut:
	state &State
}

fn (mut l CmOutputListener) image_description_changed(proxy cm.WpColorManagementOutputV1) {
	mut description := proxy.get_image_description() or { return }
	description.set_listener(&CmImageDescriptionListener{
		state: l.state
	}) or {}
}
