module main

import os
import rand
import protocols.wayland as wlp

#flag -I/usr/include
#include <sys/mman.h>

fn C.mmap(__addr voidptr, __len usize, __prot int, __flag int, __fd int, __offset i32) voidptr
fn C.munmap(__addr voidptr, __len usize) int
fn C.shm_open(__name &char, __oflag int, __mode u32) int
fn C.shm_unlink(__name &char) int

fn open_shm() int {
	base := '/mrpenishot-'
	mut retries := 100

	for {
		retries--

		name := base + rand.i8().str()
		fd := C.shm_open(name.str, C.O_RDWR | C.O_CREAT | C.O_EXCL, 600)
		if fd >= 0 {
			C.shm_unlink(name.str)
			return fd
		}

		if retries == 0 {
			break
		}
	}
	return -1
}

fn create_shm_file(size u64) int {
	fd := open_shm()
	if fd < 0 {
		return fd
	}

	if C.ftruncate(fd, size) < 0 {
		C.close(fd)
		return -1
	}

	return fd
}

@[heap]
struct Buffer {
mut:
	wl_buffer  &wlp.WlBuffer
	data       voidptr
	width      i32
	height     i32
	stride     i32
	size       usize
	shm_format wlp.WlShm_Format
}

fn Buffer.new(mut shm wlp.WlShm, format wlp.WlShm_Format, width i32, height i32, stride i32) &Buffer {
	size := stride * height

	fd := create_shm_file(u64(size))
	if fd == -1 {
		panic('Failed to create buffer')
	}

	data := C.mmap(unsafe { nil }, size, C.PROT_READ | C.PROT_WRITE, C.MAP_SHARED, fd,
		0)
	if data == C.MAP_FAILED {
		os.fd_close(fd)
		panic('Failed to map buffer')
	}

	mut pool := shm.create_pool(fd, size)
	buffer := pool.create_buffer(0, width, height, stride, u32(format))
	pool.destroy()

	os.fd_close(fd)

	return &Buffer{
		wl_buffer:  buffer
		data:       data
		width:      width
		height:     height
		stride:     stride
		size:       usize(size)
		shm_format: format
	}
}

fn (mut b Buffer) destroy() {
	C.munmap(b.data, b.size)
	b.wl_buffer.destroy()
	// free(b)
}
