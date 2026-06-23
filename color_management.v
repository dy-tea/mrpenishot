module main

import dy_tea.wayland as wl

fn make_cm_output_events() wl.WpColorManagementOutputV1Events[&Output] {
	return wl.WpColorManagementOutputV1Events[&Output]{
		image_description_changed: fn (o &Output) {
			// Will handle in dispatch
			_ := o
		}
	}
}

fn make_image_description_events() wl.WpImageDescriptionV1Events[&State] {
	return wl.WpImageDescriptionV1Events[&State]{
		failed: fn (s &State, cause u32, msg string) {
			eprintln('Image description failed: ${msg} (cause: ${cause})')
		}
		ready:  fn (s &State, identity u32) {
			// Get information from this description
			// We handle this via dispatched messages
			_ := identity
		}
		ready2: fn (s &State, identity_hi u32, identity_lo u32) {
			_ := identity_hi
			_ := identity_lo
		}
	}
}

fn make_image_desc_info_events() wl.WpImageDescriptionInfoV1Events[&State] {
	return wl.WpImageDescriptionInfoV1Events[&State]{
		done:     fn (s &State) {
			unsafe { s.n_cm_done++ }
		}
		tf_named: fn (s &State, tf u32) {
			unsafe {
				if tf & u32(wl.WpColorManagerV1TransferFunction.st2084_pq) != 0 {
					s.is_hdr = true
				}
			}
		}
	}
}
