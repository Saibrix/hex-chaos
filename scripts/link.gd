class_name Link
extends Node

# Connection between two phones. In the web build this talks to window.Link, which is
# defined in web/shell.html (WebRTC with a code/QR swap, no server).
# Elsewhere (editor, desktop) there is no online link, only the local test game.

signal opened(is_host: bool)
signal message(data: Dictionary)
signal closed
signal cancelled

var connected := false
var is_host := false


static func available() -> bool:
	return OS.has_feature("web")


func start_host() -> void:
	_js("Link.openHost()")


func start_join() -> void:
	_js("Link.openJoin()")


func send(data: Dictionary) -> void:
	if connected:
		_js("Link.send(" + JSON.stringify(JSON.stringify(data)) + ")")


func close() -> void:
	connected = false
	if available():
		_js("Link.close()")


func _js(code: String) -> Variant:
	if not available():
		return null
	return JavaScriptBridge.eval(code, true)


func _process(_delta: float) -> void:
	if not available():
		return
	var raw = _js("Link.poll()")
	if typeof(raw) != TYPE_STRING or raw == "":
		return
	var events = JSON.parse_string(raw)
	if typeof(events) != TYPE_ARRAY:
		return
	for ev in events:
		match ev.get("e", ""):
			"open":
				connected = true
				is_host = ev.get("host", false)
				opened.emit(is_host)
			"msg":
				var data = JSON.parse_string(ev.get("d", ""))
				if typeof(data) == TYPE_DICTIONARY:
					message.emit(data)
			"close":
				if connected:
					connected = false
					closed.emit()
			"cancel":
				cancelled.emit()
