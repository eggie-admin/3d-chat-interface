# SPDX-License-Identifier: MIT
extends Control

const AI_BASE := "http://127.0.0.1:8797/api/ai"
const MAX_PROMPT := 4096

@onready var request: HTTPRequest = $HTTPRequest
@onready var status_label: Label = $Status
@onready var results: RichTextLabel = $Results
@onready var query: LineEdit = $Query

func _ready() -> void:
    request.timeout = 12.0
    request.request_completed.connect(_on_request_completed)

func search_rss() -> void:
    if request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        return
    var q := query.text.strip_edges()
    if q.is_empty() or q.length() > 300:
        status_label.text = "RSS QUERY REJECTED"
        return
    var url := AI_BASE + "/rss/search?q=" + q.uri_encode() + "&limit=8"
    status_label.text = "RSS SEARCHING"
    request.request(url)

func _on_request_completed(result_code: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result_code != HTTPRequest.RESULT_SUCCESS or response_code != 200 or body.size() > 1048576:
        status_label.text = "AI/RSS OFFLINE"
        return
    var packet = JSON.parse_string(body.get_string_from_utf8())
    if typeof(packet) != TYPE_DICTIONARY:
        status_label.text = "BAD AI/RSS JSON"
        return
    results.clear()
    for item in packet.get("items", []):
        if typeof(item) == TYPE_DICTIONARY:
            results.append_text("[b]%s[/b]\n%s\n\n" % [
                _escape(str(item.get("title", ""))),
                _escape(str(item.get("summary", "")).left(800))
            ])
    status_label.text = "AI/RSS READY"

func _escape(text: String) -> String:
    return text.replace("[", "\\[").replace("]", "\\]")
