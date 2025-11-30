module wl

#flag linux -I/usr/include
#flag linux -lwayland-client
#include <wayland-client-core.h>

pub struct C.wl_proxy {}

pub struct C.wl_display {}

pub struct C.wl_event_queue {}

pub const wl_marshal_flag_destroy = 1 << 0

fn C.wl_event_queue_destroy(queue &C.wl_event_queue)

// wl_proxy stuff...

fn C.wl_event_queue_get_name(queue &C.wl_event_queue) &char

fn C.wl_display_connect(name &char) &C.wl_display
fn C.wl_display_connect_to_fd(fd int) &C.wl_display
fn C.wl_display_disconnect(display &C.wl_display)
fn C.wl_display_get_fd(display &C.wl_display) int
fn C.wl_display_dispatch(display &C.wl_display) int
fn C.wl_display_dispatch_queue(display &C.wl_display, queue &C.wl_event_queue) int
fn C.wl_display_dispatch_timeout(display &C.wl_display, timeout C.timespec) int
fn C.wl_display_dispatch_queue_timeout(display &C.wl_display, queue &C.wl_event_queue, timeout C.timespec) int
fn C.wl_display_dispatch_queue_pending(display &C.wl_display, queue &C.wl_event_queue) int
fn C.wl_display_dispatch_pending(display &C.wl_display) int
fn C.wl_display_get_error(display &C.wl_display) int
fn C.wl_display_get_protocol_error(display &C.wl_display, interface, &&C.wl_interface, id u32) u32
fn C.wl_display_flush(display &C.wl_display) int
fn C.wl_display_roundtrip_queue(display &C.wl_display, queue &C.wl_event_queue) int
fn C.wl_display_roundtrip(display &C.wl_display) int
fn C.wl_display_create_queue(display &C.wl_display) &C.wl_event_queue
fn C.wl_display_create_queue_with_name(display &C.wl_display, name &char) &C.wl_event_queue
fn C.wl_display_prepare_read_queue(display &C.wl_display, queue &C.wl_event_queue) int
fn C.wl_display_prepare_read(display &C.wl_display) int
fn C.wl_display_cancel_read(display &C.wl_display)
fn C.wl_display_read_events(display &C.wl_display)

fn C.wl_log_set_handler_client(handler Wl_log_func_t)

fn C.wl_display_set_max_buffer_size(display &C.wl_display, size usize)
