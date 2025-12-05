import os
import flag

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
	module_name := protocol.name.replace('-', '_')
	output_file := os.join_path(output_dir, '${module_name}.v')

	os.write_file(output_file, v_code) or {
		eprintln('Error writing file: ${err}')
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
		end := xml.index_after('/>', start) or { break }
		entry_xml := xml[start - 6..end + 2]
		entries << EnumEntry{
			name:    extract_attr(entry_xml, '<entry', 'name')
			value:   extract_attr(entry_xml, '<entry', 'value')
			summary: extract_attr(entry_xml, '<entry', 'summary')
		}
		pos = end + 2
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
	mut out := ''

	if protocol.copyright != '' {
		out += '/*\n${protocol.copyright}\n*/\n\n'
	}

	module_name := protocol.name.replace('-', '_')
	out += 'module ${module_name}\n\n'
	out += 'import wl\n\n'

	if protocol.name == 'wayland' {
		out += '#pkgconfig wayland-client\n'
		out += '#include <wayland-client-protocol.h>\n\n'
	} else {
		out += '#pkgconfig wayland-client\n'
		out += '#include <wayland-client.h>\n'
		out += '#include "${module_name}-client-protocol.h"\n'
		out += '#flag -I @VMODROOT/protocols/${module_name}\n'
		out += '#flag @VMODROOT/protocols/${module_name}/${module_name}-protocol.c\n\n'
	}
	for iface in protocol.interfaces {
		interface_var_name := '${iface.name}_interface'
		out += '@[inline]\n'
		out += 'pub fn ${interface_var_name}_ptr() voidptr {\n'
		out += '\treturn unsafe { voidptr(&C.${interface_var_name}) }\n'
		out += '}\n\n'
	}
	for iface in protocol.interfaces {
		interface_var_name := '${iface.name}_interface'
		out += 'pub const ${interface_var_name}_name = \'${iface.name}\'\n'
	}
	out += '\n'

	for iface in protocol.interfaces {
		out += generate_interface(iface)
		out += '\n'
	}

	return out
}

fn generate_interface_constant(iface Interface) string {
	mut out := ''

	interface_var_name := '${iface.name}_interface'

	out += 'pub const ${interface_var_name} = wl.Interface{\n'
	out += '\tname: \'${iface.name}\'\n'
	out += '\tversion: ${iface.version}\n'
	out += '\tmethod_count: ${iface.requests.len}\n'

	if iface.requests.len > 0 {
		out += '\tmethods: [\n'
		for request in iface.requests {
			signature := get_signature(request.args)
			out += '\t\twl.Message{\n'
			out += '\t\t\tname: \'${request.name}\'\n'
			out += '\t\t\tsignature: \'${signature}\'\n'
			out += '\t\t\ttypes: ${generate_types_array(request.args)}\n'
			out += '\t\t}\n'
		}
		out += '\t]\n'
	} else {
		out += '\tmethods: []\n'
	}

	out += '\tevent_count: ${iface.events.len}\n'

	if iface.events.len > 0 {
		out += '\tevents: [\n'
		for event in iface.events {
			signature := get_signature(event.args)
			out += '\t\twl.Message{\n'
			out += '\t\t\tname: \'${event.name}\'\n'
			out += '\t\t\tsignature: \'${signature}\'\n'
			out += '\t\t\ttypes: ${generate_types_array(event.args)}\n'
			out += '\t\t}\n'
		}
		out += '\t]\n'
	} else {
		out += '\tevents: []\n'
	}

	out += '}\n'

	return out
}

fn generate_interface(iface Interface) string {
	mut out := ''

	for enum_def in iface.enums {
		out += generate_enum(iface, enum_def)
		out += '\n'
	}

	out += generate_struct(iface)
	out += '\n'

	if iface.events.len > 0 {
		out += generate_listener(iface)
		out += '\n'
		out += generate_add_listener(iface)
		out += '\n'
	}

	if iface.requests.len > 0 {
		out += generate_request_constants(iface)
		out += '\n'
	}

	for i, request in iface.requests {
		out += generate_request_method(iface, request, i)
		out += '\n'
	}

	out += generate_helper_methods(iface)

	return out
}

fn generate_enum(iface Interface, enum_def Enum) string {
	mut out := ''

	if enum_def.description != '' {
		out += '// ${enum_def.description}\n'
	}

	struct_name := snake_to_pascal(iface.name)
	enum_name := '${struct_name}_${snake_to_pascal(enum_def.name)}'

	out += 'pub enum ${enum_name} {\n'
	if enum_def.entries.len == 0 {
		out += '\t_placeholder = 0\n'
	} else {
		for entry in enum_def.entries {
			entry_name := sanitize_enum_entry_name(entry.name)
			if entry.summary != '' {
				out += '\t// ${entry.summary}\n'
			}
			out += '\t${entry_name} = ${entry.value}\n'
		}
	}
	out += '}\n'

	return out
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

	mut out := ''
	if iface.description != '' {
		out += '// ${iface.description}\n'
	}
	out += 'pub struct ${struct_name} {\n'
	out += 'pub mut:\n'
	out += '\tproxy voidptr\n'
	out += '}\n'

	return out
}

fn generate_listener(iface Interface) string {
	_ := snake_to_pascal(iface.name) // unused
	listener_name := 'C.${iface.name}_listener'

	mut out := ''
	out += 'pub struct ${listener_name} {\n'

	for event in iface.events {
		method_name := event.name.replace('-', '_')

		mut params := ['voidptr']
		params << 'voidptr'

		for arg in event.args {
			param_type := arg_type_to_c(arg)
			params << param_type
		}

		if event.description != '' {
			out += '\t// ${event.description}\n'
		}
		out += '\t${method_name} fn (${params.join(', ')})\n'
	}

	out += '}\n'

	return out
}

fn generate_add_listener(iface Interface) string {
	struct_name := snake_to_pascal(iface.name)
	listener_name := 'C.${iface.name}_listener'

	mut out := ''
	out += 'pub fn (mut self ${struct_name}) add_listener(listener &${listener_name}, data voidptr) int {\n'
	out += '\treturn C.wl_proxy_add_listener(unsafe { &C.wl_proxy(self.proxy) }, unsafe { voidptr(listener) }, data)\n'
	out += '}\n'

	return out
}

fn generate_request_constants(iface Interface) string {
	mut out := ''

	for i, request in iface.requests {
		const_name := '${iface.name}_${request.name}'.to_lower()
		out += 'pub const ${const_name} = ${i}\n'
	}

	return out
}

fn generate_helper_methods(iface Interface) string {
	struct_name := snake_to_pascal(iface.name)
	mut out := ''

	// set_user_data
	out += 'pub fn (mut self ${struct_name}) set_user_data(data voidptr) {\n'
	out += '\tC.wl_proxy_set_user_data(unsafe { &C.wl_proxy(self.proxy) }, data)\n'
	out += '}\n\n'

	// get_user_data
	out += 'pub fn (self ${struct_name}) get_user_data() voidptr {\n'
	out += '\treturn C.wl_proxy_get_user_data(unsafe { &C.wl_proxy(self.proxy) })\n'
	out += '}\n\n'

	// get_version
	out += 'pub fn (self ${struct_name}) get_version() u32 {\n'
	out += '\treturn C.wl_proxy_get_version(unsafe { &C.wl_proxy(self.proxy) })\n'
	out += '}\n\n'

	return out
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
			'string'
		}
		'object' {
			'voidptr'
		}
		'new_id' {
			if arg.interface_name != '' {
				'&${snake_to_pascal(arg.interface_name)}'
			} else {
				'voidptr'
			}
		}
		'array' {
			'&u32'
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

	mut out := ''
	if request.description != '' {
		out += '// ${request.description}\n'
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

			call_args << match arg.typ {
				'object' {
					param_name
				}
				'string' {
					'voidptr(${param_name}.str)'
				}
				else {
					param_name
				}
			}
		}
	}

	out += 'pub fn (mut self ${struct_name}) ${method_name}('
	out += params.join(', ')
	out += ')'

	if has_new_id {
		out += if new_id_arg.interface_name != '' {
			' &${snake_to_pascal(new_id_arg.interface_name)}'
		} else {
			' voidptr'
		}
	}

	out += ' {\n'

	if request.is_destructor {
		out += '\tC.wl_proxy_marshal_flags(unsafe { &C.wl_proxy(self.proxy) }, ${opcode}, unsafe { nil }, '
		out += 'C.wl_proxy_get_version(unsafe { &C.wl_proxy(self.proxy) }), wl.wl_marshal_flag_destroy'
		if call_args.len > 0 {
			out += ', ${call_args.join(', ')}'
		}
		out += ')\n'
	} else if has_new_id {
		if new_id_arg.interface_name != '' {
			out += '\tproxy := C.wl_proxy_marshal_flags(unsafe { &C.wl_proxy(self.proxy) }, ${opcode}, '
			out += '${new_id_arg.interface_name}_interface_ptr(), '
			out += 'C.wl_proxy_get_version(unsafe { &C.wl_proxy(self.proxy) }), 0, unsafe { nil }'
			out += if call_args.len > 0 {
				', ${call_args.join(', ')}'
			} else {
				''
			}
		} else {
			out += '\tproxy := C.wl_proxy_marshal_flags(unsafe { &C.wl_proxy(self.proxy) }, ${opcode}, '
			out += 'unsafe { &C.wl_interface(iface) }, version, 0'
			out += if call_args.len > 0 {
				', ${call_args.join(', ')}, unsafe { nil }'
			} else {
				', unsafe { nil }'
			}
		}
		out += ')\n'

		if new_id_arg.interface_name != '' {
			out += '\treturn &${snake_to_pascal(new_id_arg.interface_name)}{\n'
			out += '\t\tproxy: proxy\n'
			out += '\t}\n'
		} else {
			out += '\treturn proxy\n'
		}
	} else {
		out += '\tC.wl_proxy_marshal_flags(unsafe { &C.wl_proxy(self.proxy) }, ${opcode}, unsafe { nil }, '
		out += 'C.wl_proxy_get_version(unsafe { &C.wl_proxy(self.proxy) }), 0'
		if call_args.len > 0 {
			out += ', ${call_args.join(', ')}'
		}
		out += ')\n'
	}

	out += '}\n'

	return out
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
