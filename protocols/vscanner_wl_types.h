/* Shared wayland type definitions for vscanner-generated protocols */
#ifndef VSCANNER_WL_TYPES_H
#define VSCANNER_WL_TYPES_H

#include <wayland-client.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Define wayland type descriptors */
static const struct wl_interface _vs_wl_type_int = { "int", 0, 0, 0, 0, 0 };
static const struct wl_interface _vs_wl_type_uint = { "uint", 0, 0, 0, 0, 0 };
static const struct wl_interface _vs_wl_type_fixed = { "fixed", 0, 0, 0, 0, 0 };
static const struct wl_interface _vs_wl_type_string = { "string", 0, 0, 0, 0, 0 };
static const struct wl_interface _vs_wl_type_object = { "object", 0, 0, 0, 0, 0 };
static const struct wl_interface _vs_wl_type_new_id = { "new_id", 0, 0, 0, 0, 0 };
static const struct wl_interface _vs_wl_type_array = { "array", 0, 0, 0, 0, 0 };
static const struct wl_interface _vs_wl_type_fd = { "fd", 0, 0, 0, 0, 0 };

/* Macros for type references */
#define vs_wl_type_int (&_vs_wl_type_int)
#define vs_wl_type_uint (&_vs_wl_type_uint)
#define vs_wl_type_fixed (&_vs_wl_type_fixed)
#define vs_wl_type_string (&_vs_wl_type_string)
#define vs_wl_type_object (&_vs_wl_type_object)
#define vs_wl_type_new_id (&_vs_wl_type_new_id)
#define vs_wl_type_array (&_vs_wl_type_array)
#define vs_wl_type_fd (&_vs_wl_type_fd)

#ifdef __cplusplus
}
#endif

#endif /* VSCANNER_WL_TYPES_H */
