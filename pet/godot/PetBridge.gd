extends Node

signal pet_state_updated(state: Dictionary)
signal pet_request_failed(message: String)

@export var base_url := "http://127.0.0.1:8772"

var _state_request: HTTPRequest
var _event_request: HTTPRequest


func _ready() -> void:
    _state_request = HTTPRequest.new()
    _event_request = HTTPRequest.new()
    add_child(_state_request)
    add_child(_event_request)
    _state_request.request_completed.connect(_on_state_done)
    _event_request.request_completed.connect(_on_event_done)


func refresh_state() -> void:
    var err := _state_request.request(base_url + "/api/pet/state")
    if err != OK:
        pet_request_failed.emit("state request could not start: %s" % err)


func emit_event(event_name: String) -> void:
    var headers := PackedStringArray(["Content-Type: application/json"])
    var body := JSON.stringify({"event": event_name})
    var err := _event_request.request(
        base_url + "/api/pet/event",
        headers,
        HTTPClient.METHOD_POST,
        body
    )
    if err != OK:
        pet_request_failed.emit("event request could not start: %s" % err)


func _decode(body: PackedByteArray) -> Dictionary:
    var parsed = JSON.parse_string(body.get_string_from_utf8())
    return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _on_state_done(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
        pet_state_updated.emit(_decode(body))
    else:
        pet_request_failed.emit("state request failed: HTTP %s" % response_code)


func _on_event_done(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
        pet_state_updated.emit(_decode(body))
    else:
        pet_request_failed.emit("event request failed: HTTP %s" % response_code)
