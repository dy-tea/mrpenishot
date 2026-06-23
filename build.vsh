#!/usr/bin/env -S v

import os
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

fn pkg_installed(name string, version ?string) {
	ins_str := sh('pkg-config --modversion ${name}')
	ins := ins_str.trim_space().split('.').map(|x| x.int())
	if ins.len == 0 {
		err('package `${name}` not found')
	} else {
		if ver := version {
			exp := ver.split('.').map(|x| x.int())
			if exp.len != ins.len {
				err('package version lengths `${ver}` and `${ins_str}` differ')
			}
			for i in 0 .. ins.len {
				if ins[i] > exp[i] {
					return
				}
			}
			err('package `${name}` version must be >= ${ver}')
		}
	}
}

exe_name := 'mrpenishot'

program_installed('pkg-config')

pkg_installed('pixman-1', none)
pkg_installed('libjxl', none)
pkg_installed('libpng16', '2.5.0')

if arguments().contains('install') {
	sh('v -prod .')
	user := sh('logname').trim_space()
	sh('chown ${user}:${user} ./${exe_name}')
	sh('cp ./${exe_name} /usr/local/bin/${exe_name}')
}
