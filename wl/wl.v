module wl

pub struct Interface {
pub:
	name         string
	version      int
	method_count int
	methods      []Message
	event_count  int
	events       []Message
}

pub struct Message {
pub:
	name      string
	signature string
	types     []string
}
