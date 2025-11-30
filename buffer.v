module main

import wl
import os

#flag -I/usr/include
#include <sys/mman.h>

fn C.mmap(__addr voidptr, __len usize, __prot int, __flag int, __fd int, __offset i32) voidptr
fn C.munmap(__addr voidptr, __len usize) int

@[heap]
struct Buffer {
	wl_buffer &C.wl_buffer
	data      voidptr
	width     i32
	height    i32
	stride    i32
	size      usize
	format    wl.Wl_shm_format
}

fn Buffer.new(shm &C.wl_shm, format wl.Wl_shm_format, width i32, height i32, stride i32) &Buffer {
	size := stride * height

	fd := 1 // TODO
	if fd == -1 {
		panic('Failed to create buffer')
	}

	data := C.mmap(unsafe { nil }, size, C.PROT_READ | C.PROT_WRITE, C.MAP_SHARED, fd,
		0)
	if data == C.MAP_FAILED {
		os.fd_close(fd)
		panic('Failed to map buffer')
	}

	pool := C.wl_shm_create_pool(shm, fd, size)
	buffer := C.wl_shm_pool_create_buffer(pool, 0, width, height, stride, u32(format))
	C.wl_shm_pool_destroy(pool)

	os.fd_close(fd)

	return &Buffer{
		wl_buffer: buffer
		data:      data
		width:     width
		height:    height
		stride:    stride
		size:      usize(size)
		format:    format
	}
}

fn (b Buffer) destroy() {
	C.munmap(b.data, b.size)
	C.wl_buffer_destroy(b.wl_buffer)
	// free(b)
}
