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

protocols_dir := './protocols'
vscanner_dir := './vscanner'
exe_name := 'mrpenishot'

if arguments().contains('clean') {
	cmd := 'rm -r ${protocols_dir}/*/'
	execute(cmd)
	println('❯ ${cmd}')
	return
}

program_installed('pkg-config')
program_installed('wayland-scanner')

pkg_installed('wayland-protocols', 1.41)
pkg_installed('wayland-client', none)
pkg_installed('pixman-1', none)
pkg_installed('libjxl', none)
pkg_installed('libpng16', none)

// build vscanner
sh('v ${vscanner_dir}')

wl_dir := sh('pkg-config --variable=pkgdatadir wayland-client').trim_space()
wl_proto_dir := sh('pkg-config --variable=pkgdatadir wayland-protocols').trim_space()

protocols := [
	wl_dir + '/wayland.xml',
	wl_proto_dir + '/staging/color-management/color-management-v1.xml',
	wl_proto_dir + '/staging/ext-image-capture-source/ext-image-capture-source-v1.xml',
	wl_proto_dir + '/staging/ext-image-copy-capture/ext-image-copy-capture-v1.xml',
	wl_proto_dir + '/staging/ext-foreign-toplevel-list/ext-foreign-toplevel-list-v1.xml',
	wl_proto_dir + '/unstable/xdg-output/xdg-output-unstable-v1.xml',
]

sh('mkdir -p ${protocols_dir}')

for protocol in protocols {
	name := base(protocol).replace('.xml', '').replace('-', '_')
	sh('${vscanner_dir}/vscanner ${protocol} ${protocols_dir}/${name}')

	// Generate C protocol files for non-core protocols
	if !protocol.contains('wayland.xml') {
		// Use module name (with underscores) for C files to match vscanner output
		header_file := '${protocols_dir}/${name}/${name}-client-protocol.h'
		code_file := '${protocols_dir}/${name}/${name}-protocol.c'
		sh('wayland-scanner client-header ${protocol} ${header_file}')
		sh('wayland-scanner private-code ${protocol} ${code_file}')
	}
}

if arguments().contains('install') {
	sh('v -prod .')
	user := sh('logname').trim_space()
	sh('chown ${user}:${user} ./${exe_name}')
	sh('chown -R ${user}:${user} ./${protocols_dir}')
	sh('cp ./${exe_name} /usr/local/bin/${exe_name}')
}
