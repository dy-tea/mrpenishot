#!/usr/bin/env -S v

import term

fn sh(cmd string) string {
	println('❯ ${cmd}')
	return execute_or_exit(cmd).output
}

fn err(msg string) {
	println(term.fail_message(msg))
	exit(1)
}

fn program_installed(name string) {
	if sh('which ${name}') == '' {
		err('program `${name}` not found')
	}
}

fn pkg_installed(name string, version ?f64) {
	ins := sh('pkg-config --modversion ${name}').f64()
	if ins == 0 {
		err('package `${name}` not found')
	} else {
		if ver := version {
			if ins < ver {
				err('package `${name}` version must be >= ${ver}')
			}
		}
	}
}

source_dir := './src'
include_dir := './include'

if arguments().contains('clean') {
	cmd := 'rm -rf ${source_dir} ${include_dir}'
	execute(cmd)
	println('❯ ${cmd}')
	return
}

program_installed('wayland-scanner')
program_installed('pkg-config')

pkg_installed('wayland-protocols', 1.37)
pkg_installed('wayland-client', none)
pkg_installed('pixman-1', none)

wl_proto_dir := sh('pkg-config --variable=pkgdatadir wayland-protocols').trim_space()

protocols := [
	'./protocols/wlr-screencopy-unstable-v1.xml',
	wl_proto_dir + '/staging/ext-image-capture-source/ext-image-capture-source-v1.xml',
	wl_proto_dir + '/staging/ext-image-copy-capture/ext-image-copy-capture-v1.xml',
	wl_proto_dir + '/staging/ext-foreign-toplevel-list/ext-foreign-toplevel-list-v1.xml',
	wl_proto_dir + '/unstable/xdg-output/xdg-output-unstable-v1.xml',
]

sh('mkdir -p ${source_dir}')
sh('mkdir -p ${include_dir}')

for protocol in protocols {
	name := base(protocol).replace('.xml', '-protocol')
	sh('wayland-scanner public-code ${protocol} ${source_dir}/${name}.c')
	sh('wayland-scanner client-header ${protocol} ${include_dir}/${name}.h')
}
