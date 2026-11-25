module main

import os
import rand
import wayland.protocols.wayland as wl

@[heap]
struct Buffer {
mut:
	wl_buffer  wl.WlBuffer
	width      int
	height     int
	stride     int
	shm_format u32
	mapping    &os.Mmap = unsafe { nil }
	file       os.File
	data       []u8
}

fn Buffer.new(mut shm wl.WlShm, format u32, width int, height int, stride int) &Buffer {
	if width <= 0 || height <= 0 || stride <= 0 {
		panic('buffer size must be positive, got ${width}x${height} (stride ${stride})')
	}

	size := stride * height
	path := shm_file_path()
	mut mapping := os.mmap_create(path, u64(size)) or {
		panic('failed to map buffer: ${err}')
	}
	mut file := os.open_file(path, 'r+') or {
		mapping.close()
		os.rm(path) or {}
		panic('failed to open buffer file: ${err}')
	}
	os.rm(path) or {}

	mut pool := shm.create_pool(file.fd, i32(size)) or {
		file.close()
		mapping.close()
		panic('create_pool failed: ${err}')
	}
	buffer := pool.create_buffer(0, width, height, stride, format) or {
		pool.destroy() or {}
		file.close()
		mapping.close()
		panic('create_buffer failed: ${err}')
	}
	pool.destroy() or {}

	return &Buffer{
		wl_buffer:  buffer
		width:      width
		height:     height
		stride:     stride
		shm_format: format
		mapping:    mapping
		file:       file
		data:       unsafe { mapping.bytes() }
	}
}

fn (mut b Buffer) pixels() []u8 {
	return b.data
}

fn (b &Buffer) size() int {
	return b.stride * b.height
}

fn (mut b Buffer) copy_from(other &Buffer) {
	copy(mut b.data, other.data)
}

fn (mut b Buffer) destroy() {
	if b.data.len == 0 {
		return
	}
	b.wl_buffer.destroy() or {}
	b.mapping.close()
	b.file.close()
	b.data = []u8{}
}

fn shm_file_path() string {
	runtime := os.getenv('XDG_RUNTIME_DIR')
	dir := if runtime != '' { runtime } else { os.temp_dir() }
	return os.join_path(dir, 'mrpenishot-${os.getpid()}-${rand.u64():x}')
}
