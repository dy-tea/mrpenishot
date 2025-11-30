module wl

#flag linux -I/usr/include
#flag linux -lwayland-client
#include <wayland-client-core.h>

pub struct C.wl_proxy {}

pub struct C.wl_display {}

pub struct C.wl_event_queue {}

pub const wl_marshal_flag_destroy = 1 << 0

fn C.wl_event_queue_destroy(queue &C.wl_event_queue)

fn C.wl_proxy_marshal_flags(&C.wl_proxy, u32, &C.wl_interface, u32, u32, ...) &C.wl_proxy
fn C.wl_proxy_marshal_array_flags(&C.wl_proxy, u32, &C.wl_interface, u32, u32, &C.wl_argument) &C.wl_proxy
fn C.wl_proxy_marshal(p &C.wl_proxy, opcode u32, ...)
fn C.wl_proxy_marshal_array(p &C.wl_proxy, opcode u32, args &C.wl_argument)
fn C.wl_proxy_create(factory &C.wl_proxy, interface, &C.wl_interface) &C.wl_proxy
fn C.wl_proxy_create_wrapper(proxy voidptr) voidptr
fn C.wl_proxy_wrapper_destroy(proxy_wrapper voidptr)
fn C.wl_proxy_marshal_constructor(proxy &C.wl_proxy, opcode u32, interface, &C.wl_interface, ...) &C.wl_proxy
fn C.wl_proxy_marshal_constructor_versioned(proxy &C.wl_proxy, opcode u32, interface, &C.wl_interface, version u32, ...) &C.wl_proxy
fn C.wl_proxy_marshal_array_constructor(proxy &C.wl_proxy, opcode u32, args &C.wl_argument, interface, &C.wl_interface) &C.wl_proxy
fn C.wl_proxy_marshal_array_constructor_versioned(proxy &C.wl_proxy, opcode u32, args &C.wl_argument, interface, &C.wl_interface, version u32) &C.wl_proxy
fn C.wl_proxy_destroy(proxy &C.wl_proxy)
fn C.wl_proxy_add_listener(proxy &C.wl_proxy, implementation voidptr, data voidptr) int
fn C.wl_proxy_get_listener(proxy &C.wl_proxy) voidptr
fn C.wl_proxy_add_dispatcher(proxy &C.wl_proxy, dispatcher_func C.wl_dispatcher_func_t, dispatcher_data voidptr, data voidptr) int
fn C.wl_proxy_set_user_data(proxy &C.wl_proxy, user_data voidptr)
fn C.wl_proxy_get_user_data(proxy &C.wl_proxy) voidptr
fn C.wl_proxy_get_version(proxy &C.wl_proxy) u32
fn C.wl_proxy_get_id(proxy &C.wl_proxy) u32
fn C.wl_proxy_set_tag(proxy &C.wl_proxy, tag &&char)
fn C.wl_proxy_get_tag(proxy &C.wl_proxy) &&char
fn C.wl_proxy_get_class(proxy &C.wl_proxy) &char
fn C.wl_proxy_get_interface(proxy &C.wl_proxy) &C.wl_interface
fn C.wl_proxy_get_display(proxy &C.wl_proxy) &C.wl_display
fn C.wl_proxy_set_queue(proxy &C.wl_proxy, queue &C.wl_event_queue)
fn C.wl_proxy_get_queue(proxy &C.wl_proxy) &C.wl_event_queue

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
