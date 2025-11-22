#!/usr/bin/env -S v

fn sh(cmd string) string {
  println('❯ ${cmd}')
  return execute_or_exit(cmd).output
}

source_dir := './src'
include_dir := './include'

if arguments().contains('clean') {
  cmd := 'rm -rf ${source_dir} ${include_dir}'
  execute('rm -rf ${source_dir} ${include_dir}')
  println('❯ ${cmd}')
  return
}

sh('which wayland-scanner')
sh('which pkg-config')

if sh('pkg-config --modversion wayland-protocols').f64() < 1.37 {
  println('wayland-protocols version must be >= 1.37')
  exit(1)
}

if sh('pkg-config --modversion pixman-1') == '' {
  println('pixman-1 not found')
  exit(1)
}

wl_proto_dir := sh('pkg-config --variable=pkgdatadir wayland-protocols').trim_space()

protocols := [
  './protocols/wlr-screencopy-unstable-v1.xml'
  wl_proto_dir + '/staging/ext-image-capture-source/ext-image-capture-source-v1.xml'
  wl_proto_dir + '/staging/ext-image-copy-capture/ext-image-copy-capture-v1.xml',
  wl_proto_dir + '/unstable/xdg-output/xdg-output-unstable-v1.xml',
]

sh('mkdir -p ${source_dir}')
sh('mkdir -p ${include_dir}')

for protocol in protocols {
  name := base(protocol).replace('.xml', '-protocol')
  sh('wayland-scanner private-code ${protocol} ${source_dir}/${name}.c')
  sh('wayland-scanner client-header ${protocol} ${include_dir}/${name}.h')
}
