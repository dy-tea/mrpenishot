import os
import flag
import strings { Builder }

@[xdoc: 'vscanner - Generate V bindings from Wayland protocol XML files']
@[version: '1.0.0']
struct Config {
	show_help   bool   @[long: help; short: h; xdoc: 'Show this help message']
	output_dir  string @[short: o; xdoc: 'Output directory (default: current directory)']
	skip_format bool   @[long: skip_format; xdoc: 'Skip formatting the output file with v fmt']
	verbose     bool   @[long: verbose; xdoc: 'Enable verbose output']
}

struct Protocol {
	name       string
	copyright  string
	interfaces []Interface
}

struct Interface {
	name        string
	version     int
	description string
	requests    []Message
	events      []Message
	enums       []Enum
}

struct Message {
	name          string
	description   string
	is_destructor bool
	args          []Arg
}

struct Arg {
	name           string
	typ            string
	interface_name string
	nullable       bool
	enum_name      string
	summary        string
}

struct Enum {
	name        string
	description string
	bitfield    bool
	entries     []EnumEntry
}

struct EnumEntry {
	name    string
	value   string
	summary string
}

fn main() {
	config, remaining := flag.to_struct[Config](os.args, skip: 1) or {
		eprintln('Error parsing flags: ${err}')
		eprintln('')
		eprintln(flag.to_doc[Config](
			description: 'Generate V language bindings from Wayland protocol XML files'
		) or { '' })
		exit(1)
	}

	if config.show_help {
		println(flag.to_doc[Config](
			description: 'Generate V language bindings from Wayland protocol XML files'
		) or { '' })
		println('
Usage:
  vscanner [options] <protocol.xml>

Examples:
  vscanner /usr/share/wayland/wayland.xml
  vscanner -o ./protocols /usr/share/wayland-protocols/unstable/xdg-output/xdg-output-unstable-v1.xml
  vscanner --verbose --skip-format my-protocol.xml
')
		exit(0)
	}

	mut xml_file := ''
	mut output_dir := config.output_dir

	if remaining.len == 0 {
		eprintln('Error: No XML file specified
Usage: vscanner [options] <protocol.xml>
Try: vscanner --help')
		exit(1)
	} else if remaining.len == 1 {
		xml_file = remaining[0]
		if output_dir == '' {
			output_dir = '.'
		}
	} else if remaining.len == 2 {
		xml_file = remaining[0]
		if output_dir == '' {
			output_dir = remaining[1]
		}
	} else {
		eprintln('Error: Too many arguments
Usage: vscanner [options] <protocol.xml>
       vscanner <protocol.xml> [output_dir]  (legacy)
Try: vscanner --help
')
		exit(1)
	}

	if config.verbose {
		println('Input file: ${xml_file}')
		println('Output directory: ${output_dir}')
	}

	if !os.exists(xml_file) {
		eprintln('Error: File `${xml_file}` not found')
		exit(1)
	}

	content := os.read_file(xml_file) or {
		eprintln('Error reading file: ${err}')
		exit(1)
	}

	protocol := parse_protocol(content)

	if !os.exists(output_dir) {
		if config.verbose {
			println('Creating output directory: ${output_dir}')
		}
		os.mkdir_all(output_dir) or {
			eprintln('Error creating directory: ${err}')
			exit(1)
		}
	}

	if config.verbose {
		println('Generating V code for protocol: ${protocol.name}')
	}
	v_code := generate_v_code(protocol)
	c_header := generate_c_header(protocol)
	c_code := generate_c_code(protocol)
	module_name := protocol.name.replace('-', '_')
	output_file := os.join_path(output_dir, '${module_name}.v')
	header_file := os.join_path(output_dir, '${module_name}-client-protocol.h')
	code_file := os.join_path(output_dir, '${module_name}-protocol.c')

	os.write_file(output_file, v_code) or {
		eprintln('Error writing file: ${err}')
		exit(1)
	}
	os.write_file(header_file, c_header) or {
		eprintln('Error writing header: ${err}')
		exit(1)
	}
	os.write_file(code_file, c_code) or {
		eprintln('Error writing code: ${err}')
		exit(1)
	}

	if !config.skip_format {
		if config.verbose {
			println('Formatting output file...')
		}
		result := os.execute('v fmt -w ${output_file}')
		if result.exit_code != 0 {
			eprintln('Warning: Error formatting file:')
			eprintln(result.output)
		}
	}

	println('Generated: ${output_file}')
}

fn parse_protocol(xml_content string) Protocol {
	protocol_name := extract_attr(xml_content, '<protocol', 'name')

	mut copyright := ''
	if copyright_start := xml_content.index('<copyright>') {
		if copyright_end := xml_content.index_after('</copyright>', copyright_start) {
			copyright = xml_content[copyright_start + 11..copyright_end].trim_space()
		}
	}

	mut interfaces := []Interface{}
	mut pos := 0
	for {
		start := xml_content.index_after('<interface', pos) or { break }
		end := xml_content.index_after('</interface>', start) or { break }
		interface_xml := xml_content[start - 10..end + 12]
		interfaces << parse_interface(interface_xml)
		pos = end + 12
	}

	return Protocol{
		name:       protocol_name
		copyright:  copyright
		interfaces: interfaces
	}
}

fn parse_interface(xml string) Interface {
	name := extract_attr(xml, '<interface', 'name')
	version_str := extract_attr(xml, '<interface', 'version')
	version := version_str.int()
	description := extract_attr(xml, '<description', 'summary')

	mut requests := []Message{}
	mut pos := 0
	for {
		start := xml.index_after('<request', pos) or { break }
		if end := xml.index_after('</request>', start) {
			request_xml := xml[start - 8..end + 10]
			requests << parse_message(request_xml)
			pos = end + 10
		} else {
			end := xml.index_after('/>', start - 8) or { break }
			request_xml := xml[start - 8..end + 2]
			requests << parse_message(request_xml)
			pos = end + 2
		}
	}

	mut events := []Message{}
	pos = 0
	for {
		start := xml.index_after('<event', pos) or { break }
		if end := xml.index_after('</event>', start) {
			event_xml := xml[start - 6..end + 8]
			events << parse_message(event_xml)
			pos = end + 8
		} else {
			end := xml.index_after('/>', start - 6) or { break }
			event_xml := xml[start - 6..end + 2]
			events << parse_message(event_xml)
			pos = end + 2
		}
	}

	mut enums := []Enum{}
	pos = 0
	for {
		start := xml.index_after('<enum', pos) or { break }
		end := xml.index_after('</enum>', start) or { break }
		enum_xml := xml[start - 5..end + 7]
		enums << parse_enum(enum_xml)
		pos = end + 7
	}

	return Interface{
		name:        name
		version:     version
		description: description
		requests:    requests
		events:      events
		enums:       enums
	}
}

fn parse_message(xml string) Message {
	mut name := extract_attr(xml, '<request', 'name')
	if name == '' {
		name = extract_attr(xml, '<event', 'name')
	}
	description := extract_attr(xml, '<description', 'summary')
	is_destructor := extract_attr(xml, '<request', 'type') == 'destructor'
		|| extract_attr(xml, '<event', 'type') == 'destructor'

	mut args := []Arg{}
	mut pos := 0
	for {
		start := xml.index_after('<arg', pos) or { break }
		end := xml.index_after('/>', start) or { break }
		arg_xml := xml[start - 4..end + 2]
		args << parse_arg(arg_xml)
		pos = end + 2
	}

	return Message{
		name:          name
		description:   description
		is_destructor: is_destructor
		args:          args
	}
}

fn parse_arg(xml string) Arg {
	allow_null := extract_attr(xml, '<arg', 'allow-null') == 'true'

	return Arg{
		name:           extract_attr(xml, '<arg', 'name')
		typ:            extract_attr(xml, '<arg', 'type')
		interface_name: extract_attr(xml, '<arg', 'interface')
		enum_name:      extract_attr(xml, '<arg', 'enum')
		nullable:       allow_null
		summary:        extract_attr(xml, '<arg', 'summary')
	}
}

fn parse_enum(xml string) Enum {
	name := extract_attr(xml, '<enum', 'name')
	bitfield := extract_attr(xml, '<enum', 'bitfield') == 'true'
	description := extract_attr(xml, '<description', 'summary')

	mut entries := []EnumEntry{}
	mut pos := 0
	for {
		start := xml.index_after('<entry', pos) or { break }
		tag_end := xml.index_after('>', start) or { break }
		entry_tag_content := xml[start - 6..tag_end + 1]

		entries << EnumEntry{
			name:    extract_attr(entry_tag_content, '<entry', 'name')
			value:   extract_attr(entry_tag_content, '<entry', 'value')
			summary: extract_attr(entry_tag_content, '<entry', 'summary')
		}

		pos = if closing_choice := xml.index_after('</entry>', tag_end) {
			closing_choice + 8
		} else {
			tag_end + 1
		}
	}

	return Enum{
		name:        name
		description: description
		bitfield:    bitfield
		entries:     entries
	}
}

fn extract_attr(xml string, tag string, attr string) string {
	tag_start := xml.index(tag) or { return '' }
	tag_end := xml.index_after('>', tag_start) or { return '' }
	if tag_end == -1 {
		return ''
	}
	tag_content := xml[tag_start..tag_end]

	attr_pattern := '${attr}="'
	attr_start := tag_content.index(attr_pattern) or { return '' }
	value_start := attr_start + attr_pattern.len
	value_end := tag_content.index_after('"', value_start) or { return '' }
	if value_end == -1 {
		return ''
	}

	return tag_content[value_start..value_end]
}

fn generate_v_code(protocol Protocol) string {
	mut out := Builder{}

	if protocol.copyright != '' {
		out.writeln('/*\n${protocol.copyright}\n*/\n')
	}

	out.writeln('@[has_globals]\n')

	module_name := protocol.name.replace('-', '_')
	out.writeln('module ${module_name}\n')
	out.writeln('import wl\n')

	// wayland ffi
	out.writeln('// Core libwayland FFI functions
#pkgconfig wayland-client
')

	if protocol.name != 'wayland' {
		out.writeln('#include "${module_name}-client-protocol.h"
#flag -I @VMODROOT/protocols/${module_name}
#flag @VMODROOT/protocols/${module_name}/${module_name}-protocol.c\n')
	} else {
		out.writeln('#include <wayland-client.h>\n')
	}

	out.writeln('// Core Wayland protocol functions
fn C.wl_proxy_add_listener(proxy voidptr, implementation voidptr, data voidptr) int
fn C.wl_proxy_marshal_flags(proxy voidptr, opcode u32, interface voidptr, flags u32, ...) voidptr
fn C.wl_proxy_get_user_data(proxy voidptr) voidptr
fn C.wl_proxy_set_user_data(proxy voidptr, data voidptr)
fn C.wl_proxy_get_version(proxy voidptr) u32
fn C.wl_proxy_destroy(proxy voidptr)
fn C.wl_display_roundtrip(display voidptr) int
fn C.wl_display_dispatch(display voidptr) int
fn C.wl_display_flush(display voidptr) int
fn C.wl_display_connect(name &char) voidptr
fn C.wl_display_disconnect(display voidptr)
')

	out.writeln('\n__global (\n')
	for iface in protocol.interfaces {
		interface_var_name := '${iface.name}_interface'
		out.writeln('    ${interface_var_name} voidptr\n')
	}
	out.writeln(')\n\n')
	for iface in protocol.interfaces {
		interface_var_name := '${iface.name}_interface'
		out.writeln('@[inline]
pub fn ${interface_var_name}_ptr() voidptr {
    return unsafe { voidptr(&C.${interface_var_name}) }
}\n')
	}

	// Generate interface name constants
	for iface in protocol.interfaces {
		interface_var_name := '${iface.name}_interface'
		out.writeln('pub const ${interface_var_name}_name = \'${iface.name}\'')
	}
	out.writeln('')

	for iface in protocol.interfaces {
		out.writeln(generate_interface(iface))
	}

	return out.str()
}

fn generate_interface_constant(iface Interface) string {
	mut out := Builder{}

	interface_var_name := '${iface.name}_interface'
	out.writeln('pub const ${interface_var_name} = wl.Interface{
    name: \'${iface.name}\'
    version: ${iface.version}
    method_count: ${iface.requests.len}')

	if iface.requests.len > 0 {
		out.writeln('    methods: [')
		for request in iface.requests {
			signature := get_signature(request.args)
			out.writeln('        wl.Message{
            name: \'${request.name}\'
            signature: \'${signature}\'
            types: ${generate_types_array(request.args)}
        }')
		}
		out.writeln('    ]')
	} else {
		out.writeln('    methods: []')
	}

	out.writeln('    event_count: ${iface.events.len}')

	if iface.events.len > 0 {
		out.writeln('    events: [')
		for event in iface.events {
			signature := get_signature(event.args)
			out.writeln('        wl.Message{
            name: \'${event.name}\'
            signature: \'${signature}\'
            types: ${generate_types_array(event.args)}
        }')
		}
		out.writeln('    ]')
	} else {
		out.writeln('    events: []')
	}

	out.writeln('}')

	return out.str()
}

fn generate_interface(iface Interface) string {
	mut out := Builder{}

	for enum_def in iface.enums {
		out.writeln(generate_enum(iface, enum_def))
	}

	out.writeln(generate_struct(iface))

	if iface.events.len > 0 {
		out.writeln2(generate_listener(iface), generate_add_listener(iface))
	}

	if iface.requests.len > 0 {
		out.writeln(generate_request_constants(iface))
	}

	for i, request in iface.requests {
		out.writeln(generate_request_method(iface, request, i))
	}

	out.writeln(generate_helper_methods(iface))

	return out.str()
}

fn generate_enum(iface Interface, enum_def Enum) string {
	mut out := Builder{}

	if enum_def.description != '' {
		out.writeln('// ${enum_def.description}')
	}

	struct_name := snake_to_pascal(iface.name)
	enum_name := '${struct_name}_${snake_to_pascal(enum_def.name)}'

	out.writeln('pub enum ${enum_name} {')
	if enum_def.entries.len == 0 {
		out.writeln('    _placeholder = 0')
	} else {
		for entry in enum_def.entries {
			entry_name := sanitize_enum_entry_name(entry.name)
			if entry.summary != '' {
				lines := entry.summary.trim_space().split('\n')
				for line in lines {
					out.writeln('    // ${line.trim_space()}')
				}
			}
			out.writeln('    ${entry_name} = ${entry.value}')
		}
	}
	out.writeln('}')

	return out.str()
}

fn sanitize_enum_entry_name(name string) string {
	mut result := name.to_lower().replace('-', '_')
	if result.len > 0 && result[0].is_digit() {
		result = '_' + result
	}
	return result.replace('.', '_').replace(' ', '_').replace('/', '_')
}

fn generate_types_array(args []Arg) string {
	if args.len == 0 {
		return '[]'
	}

	mut types := []string{}
	for arg in args {
		if arg.interface_name != '' {
			types << '\'${arg.interface_name}\''
		} else if arg.typ == 'new_id' || arg.typ == 'object' {
			types << "''"
		}
	}

	if types.len == 0 {
		return '[]'
	}

	return '[' + types.join(', ') + ']'
}

fn get_signature(args []Arg) string {
	mut sig := ''

	for arg in args {
		prefix := if arg.nullable { '?' } else { '' }

		if arg.typ == 'new_id' && arg.interface_name == '' {
			sig += 'su'
			continue
		}

		sig += prefix + match arg.typ {
			'int' { 'i' }
			'uint' { 'u' }
			'fixed' { 'f' }
			'string' { 's' }
			'object' { 'o' }
			'new_id' { 'n' }
			'array' { 'a' }
			'fd' { 'h' }
			else { '' }
		}
	}

	return sig
}

fn generate_struct(iface Interface) string {
	struct_name := snake_to_pascal(iface.name)

	mut out := Builder{}
	if iface.description != '' {
		out.writeln('// ${iface.description}')
	}
	out.writeln('pub struct ${struct_name} {
pub mut:
    proxy voidptr
}')

	return out.str()
}

fn generate_listener(iface Interface) string {
	struct_name := snake_to_pascal(iface.name)
	listener_type_name := '${struct_name}_Listener'

	mut out := Builder{}

	// Generate listener as array of function pointers
	out.writeln('// Listener for ${iface.name}
// Create with listener callbacks for each event
pub struct ${listener_type_name} {
pub mut:
    callbacks []voidptr
}

// Helper to create a listener with callbacks')
	out.write_string('pub fn ${listener_type_name.to_lower()}(')
	mut param_list := []string{}
	mut callback_sigs := []string{}
	for event in iface.events {
		method_name := event.name.replace('-', '_')
		mut params := ['data voidptr', 'obj voidptr']
		for arg in event.args {
			param_name := arg.name.replace('-', '_')
			param_type := arg_type_to_v(arg)
			params << '${param_name} ${param_type}'
		}
		params_str := params.join(', ')
		param_list << '${method_name} ?fn (${params_str}'
		callback_sigs << params_str
	}
	out.writeln(param_list.join('), ') + ')) ${listener_type_name} {
    mut callbacks := []voidptr{cap: ${iface.events.len}}
')
	for i, event in iface.events {
		method_name := event.name.replace('-', '_')
		callback_sig := callback_sigs[i]
		out.writeln('    ${method_name}_fn := ${method_name} or { fn (${callback_sig}) {} }
    callbacks << unsafe { voidptr(${method_name}_fn) }')
	}
	out.writeln('
    return ${listener_type_name}{
        callbacks: callbacks
    }
}

// Internal listener implementation
struct ${listener_type_name}_Impl {
mut:
    listener ${listener_type_name}
}')

	return out.str()
}

fn generate_add_listener(iface Interface) string {
	struct_name := snake_to_pascal(iface.name)
	listener_type_name := '${struct_name}_Listener'

	return 'pub fn (mut self ${struct_name}) add_listener(listener &${listener_type_name}, data voidptr) int {
    mut impl := &${listener_type_name}_Impl{
        listener: *listener
    }
    return C.wl_proxy_add_listener(self.proxy, impl.listener.callbacks.data, data)
}'
}

fn generate_request_constants(iface Interface) string {
	mut out := Builder{}

	for i, request in iface.requests {
		const_name := '${iface.name}_${request.name}'.to_lower()
		out.writeln('pub const ${const_name} = ${i}')
	}

	return out.str()
}

fn generate_helper_methods(iface Interface) string {
	struct_name := snake_to_pascal(iface.name)

	// Check if interface already has a destroy request
	has_destroy := iface.requests.any(it.name == 'destroy')

	mut code := 'pub fn (mut self ${struct_name}) set_user_data(data voidptr) {
    C.wl_proxy_set_user_data(self.proxy, data)
}

pub fn (self ${struct_name}) get_user_data() voidptr {
    return C.wl_proxy_get_user_data(self.proxy)
}

pub fn (self ${struct_name}) get_version() u32 {
    return C.wl_proxy_get_version(self.proxy)
}'

	if !has_destroy {
		code += '

pub fn (mut self ${struct_name}) destroy() {
    C.wl_proxy_destroy(self.proxy)
}'
	}

	return code
}

fn arg_type_to_c(arg Arg) string {
	return match arg.typ {
		'int' { 'int' }
		'uint' { 'u32' }
		'fixed' { 'int' }
		'string' { '&char' }
		'object' { 'voidptr' }
		'new_id' { 'voidptr' }
		'array' { 'voidptr' }
		'fd' { 'int' }
		else { 'voidptr' }
	}
}

fn arg_type_to_v(arg Arg) string {
	return match arg.typ {
		'int' {
			'int'
		}
		'uint' {
			'u32'
		}
		'fixed' {
			'int'
		}
		'string' {
			'&char'
		}
		'object' {
			'voidptr'
		}
		'new_id' {
			if arg.interface_name.starts_with('wl_') {
				'voidptr'
			} else if arg.interface_name != '' {
				'voidptr'
			} else {
				'voidptr'
			}
		}
		'array' {
			'voidptr'
		}
		'fd' {
			'int'
		}
		else {
			'voidptr'
		}
	}
}

fn generate_request_method(iface Interface, request Message, opcode int) string {
	struct_name := snake_to_pascal(iface.name)
	method_name := request.name.replace('-', '_')

	mut out := Builder{}
	if request.description != '' {
		lines := request.description.trim_space().split('\n')
		for line in lines {
			out.writeln('// ${line.trim_space()}')
		}
	}

	mut params := []string{}
	mut new_id_arg := Arg{}
	mut has_new_id := false
	mut call_args := []string{}

	for arg in request.args {
		if arg.typ == 'new_id' {
			has_new_id = true
			new_id_arg = arg
			if arg.interface_name == '' {
				params << 'iface voidptr'
				params << 'version u32'
				call_args << 'unsafe { voidptr(&C.wl_interface(iface).name) }'
				call_args << 'version'
			}
		} else {
			param_name := arg.name.replace('-', '_')
			param_type := arg_type_to_v(arg)
			params << '${param_name} ${param_type}'

			// for varargs, we need explicit casts
			call_args << match arg.typ {
				'string' { 'unsafe { voidptr(${param_name}) }' }
				else { param_name }
			}
		}
	}

	// Signature and Return Type
	new_id_arg_name := if new_id_arg.interface_name != '' {
		if new_id_arg.interface_name.starts_with('wl_') && !iface.name.starts_with('wl_') {
			' &protocols.wayland.${snake_to_pascal(new_id_arg.interface_name)}'
		} else {
			' &${snake_to_pascal(new_id_arg.interface_name)}'
		}
	} else {
		' voidptr'
	}

	out.writeln('pub fn (mut self ${struct_name}) ${method_name}(')
	out.write_string2(params.join(', '), ')')
	if has_new_id { out.write_string(new_id_arg_name) }
	out.writeln(' {')

	if has_new_id {
		if new_id_arg.interface_name != '' {
			out.write_string('    proxy := C.wl_proxy_marshal_flags(self.proxy, ${opcode}, ')
			if new_id_arg.interface_name.starts_with('wl_') && !iface.name.starts_with('wl_') {
				out.write_string('protocols.wayland.${new_id_arg.interface_name}_interface_ptr(), ')
			} else {
				out.write_string('${new_id_arg.interface_name}_interface_ptr(), ')
			}
			out.write_string('self.get_version(), ')
			out.write_string(if request.is_destructor { 'wl.wl_marshal_flag_destroy, ' } else { '0, ' })
			out.write_string('unsafe { nil }')
			out.write_string(if call_args.len > 0 { ', ${call_args.join(', ')}' } else { '' })
			out.writeln(')')

			out.writeln('    return &${new_id_arg_name.trim_space()[1..]}{
        proxy: proxy
    }')
		} else {
			out.write_string('    proxy := C.wl_proxy_marshal_flags(self.proxy, ${opcode}, iface, version, ')
			out.write_string(if request.is_destructor { 'wl.wl_marshal_flag_destroy' } else { '0' })
			out.write_string(if call_args.len > 0 { ', ${call_args.join(', ')}, unsafe { nil }' } else { ', unsafe { nil }' })
			out.writeln(')')
			out.writeln('    return proxy')
		}
	} else {
		out.write_string('    C.wl_proxy_marshal_flags(self.proxy, ${opcode}, unsafe { nil }, self.get_version(), ')
		out.write_string(if request.is_destructor { 'wl.wl_marshal_flag_destroy' } else { '0' })
		if call_args.len > 0 {
			out.write_string(', ${call_args.join(', ')}')
		}
		out.writeln(')')
	}

	out.writeln('}')
	return out.str()
}

fn snake_to_pascal(s string) string {
	parts := s.split('_')
	mut result := ''
	for part in parts {
		if part.len > 0 {
			result += part[0].ascii_str().to_upper() + part[1..]
		}
	}
	return result
}

fn generate_c_header(protocol Protocol) string {
	mut out := strings.Builder{}
	module_name := protocol.name.replace('-', '_')

	out.writeln('/* Generated by vscanner */
#ifndef ${module_name.to_upper()}_CLIENT_PROTOCOL_H
#define ${module_name.to_upper()}_CLIENT_PROTOCOL_H

#include <stdint.h>
#include <stddef.h>
#include "wayland-client.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Wayland type declarations */
extern const struct wl_interface wl_type_int;
extern const struct wl_interface wl_type_uint;
extern const struct wl_interface wl_type_fixed;
extern const struct wl_interface wl_type_string;
extern const struct wl_interface wl_type_object;
extern const struct wl_interface wl_type_new_id;
extern const struct wl_interface wl_type_array;
extern const struct wl_interface wl_type_fd;
')

	for iface in protocol.interfaces {
		out.writeln('extern const struct wl_interface ${iface.name}_interface;')
	}

	out.writeln('
#ifdef __cplusplus
}
#endif

#endif /* ${module_name.to_upper()}_CLIENT_PROTOCOL_H */
')

	return out.str()
}

fn generate_c_code(protocol Protocol) string {
	mut out := strings.Builder{}
	module_name := protocol.name.replace('-', '_')

	out.writeln('/* Generated by vscanner */
#include "${module_name}-client-protocol.h"
#include "../vscanner_wl_types.h"

// Forward declarations for external interfaces
')

	// Collect all interface names defined in this protocol
	mut defined_interfaces := map[string]bool{}
	for iface in protocol.interfaces {
		defined_interfaces[iface.name] = true
	}

	// Collect all referenced interface names
	mut referenced_interfaces := map[string]bool{}
	for iface in protocol.interfaces {
		for request in iface.requests {
			for arg in request.args {
				if arg.typ == 'new_id' || arg.typ == 'object' {
					if arg.interface_name != '' && !defined_interfaces[arg.interface_name] {
						referenced_interfaces[arg.interface_name] = true
					}
				}
			}
		}
		for event in iface.events {
			for arg in event.args {
				if arg.typ == 'new_id' || arg.typ == 'object' {
					if arg.interface_name != '' && !defined_interfaces[arg.interface_name] {
						referenced_interfaces[arg.interface_name] = true
					}
				}
			}
		}
	}

	// Output extern declarations for external interfaces
	for iface_name in referenced_interfaces.keys() {
		c_name := iface_name.replace('-', '_')
		out.writeln('extern const struct wl_interface ${c_name}_interface;')
	}
	out.writeln('')

	for iface in protocol.interfaces {
		out.writeln(generate_c_interface(iface))
	}

	return out.str()
}

fn generate_c_interface(iface Interface) string {
	mut out := strings.Builder{}

	// Generate type arrays for requests
	for i, request in iface.requests {
		types := generate_c_types(request.args)
		out.writeln('static const struct wl_interface *${iface.name}_request_${i}_types[] = {${types}};')
	}
	if iface.requests.len == 0 {
		out.writeln('static const struct wl_interface *${iface.name}_request_0_types[] = {0};')
	}
	out.writeln('')

	// Generate message arrays for requests
	if iface.requests.len > 0 {
		out.writeln('static const struct wl_message ${iface.name}_requests[${iface.requests.len}] = {')
		for i, request in iface.requests {
			signature := get_c_signature(request.args)
			out.writeln('\t{ "${request.name}", "${signature}", ${iface.name}_request_${i}_types },')
		}
		out.writeln('};\n')
	} else {
		out.writeln('static const struct wl_message ${iface.name}_requests[1] = {
\t{ "", "", ${iface.name}_request_0_types },
};\n')
	}

	// Generate type arrays for events
	for i, event in iface.events {
		types := generate_c_types(event.args)
		out.writeln('static const struct wl_interface *${iface.name}_event_${i}_types[] = {${types}};')
	}
	if iface.events.len == 0 {
		out.writeln('static const struct wl_interface *${iface.name}_event_0_types[] = {0};')
	}
	out.writeln('')

	// Generate message arrays for events
	if iface.events.len > 0 {
		out.writeln('static const struct wl_message ${iface.name}_events[${iface.events.len}] = {')
		for i, event in iface.events {
			signature := get_c_signature(event.args)
			out.writeln('\t{ "${event.name}", "${signature}", ${iface.name}_event_${i}_types },')
		}
		out.writeln('};\n')
	} else {
		out.writeln('static const struct wl_message ${iface.name}_events[1] = {
\t{ "", "", ${iface.name}_event_0_types },
};\n')
	}

	// Generate interface structure
	out.writeln('const struct wl_interface ${iface.name}_interface = {
\t"${iface.name}", ${iface.version},
\t${iface.requests.len}, ${iface.name}_requests,
\t${iface.events.len}, ${iface.name}_events,
};\n')

	return out.str()
}

fn get_c_signature(args []Arg) string {
	mut sig := ''
	for arg in args {
		prefix := if arg.nullable { '?' } else { '' }

		if arg.typ == 'new_id' && arg.interface_name == '' {
			sig += 'su'
			continue
		}

		sig += prefix + match arg.typ {
			'int' { 'i' }
			'uint' { 'u' }
			'fixed' { 'f' }
			'string' { 's' }
			'object' { 'o' }
			'new_id' { 'n' }
			'array' { 'a' }
			'fd' { 'h' }
			else { '' }
		}
	}
	return sig
}

fn generate_c_types(args []Arg) string {
	if args.len == 0 {
		return '0'
	}

	mut types := []string{}
	for arg in args {
		// Handle new_id arguments - these are return types that create new objects
		if arg.typ == 'new_id' {
			if arg.interface_name != '' {
				// Has a specific interface - reference it
				types << '&${arg.interface_name.replace('-', '_')}_interface'
			} else {
				types << 'NULL'  // for the interface name string
				types << 'NULL'  // for the version uint
			}
			continue
		}
		// Handle object arguments - may have an interface reference
		if arg.typ == 'object' {
			if arg.interface_name != '' {
				types << '&${arg.interface_name.replace('-', '_')}_interface'
			} else {
				types << 'NULL'
			}
			continue
		}
		// For primitive types, use NULL
		types << 'NULL'
	}

	return types.join(', ')
}
