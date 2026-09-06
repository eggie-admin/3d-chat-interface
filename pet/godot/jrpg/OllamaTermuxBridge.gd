extends Node

signal status_changed(up: bool, detail: Dictionary)
signal chat_completed(text: String, payload: Dictionary)
signal request_failed(operation: String, message: String)

const NokoPromptAPI = preload("res://addons/noko/modules/NokoPrompt.gd")
const NokoModelAPI = preload("res://addons/noko/modules/NokoModel.gd")
const NokoRunnerAPI = preload("res://addons/noko/modules/NokoRunner.gd")

const BASE_URL := "http://127.0.0.1:11434"
const SERVER := {"host": "http://127.0.0.1", "port": 11434}
const DEFAULT_MODEL := "qwen2.5:0.5b"
const REQUEST_TIMEOUT_SECONDS := 12.0

var model := DEFAULT_MODEL
var last_status: Dictionary = {
    "up": false,
    "endpoint": BASE_URL,
    "adapter": "noko"
}


func _ready() -> void:
    probe()


func probe() -> void:
    _probe_with_noko()


func _probe_with_noko() -> void:
    var response: Dictionary = await NokoModelAPI.list_model(self, SERVER, false)
    if _response_ok(response):
        var body: Dictionary = response.get("body", {})
        var models: Array = body.get("models", [])
        last_status = {
            "up": true,
            "endpoint": BASE_URL,
            "adapter": "noko",
            "model_count": models.size(),
            "selected_model": model
        }
        status_changed.emit(true, last_status)
        return

    _request_json("probe_fallback", "/api/tags", HTTPClient.METHOD_GET, {})


func runner_version() -> String:
    return await NokoRunnerAPI.version(self, SERVER, false)


func chat(prompt: String, system_prompt: String = "") -> void:
    var clean_prompt := prompt.strip_edges()
    if clean_prompt.is_empty():
        request_failed.emit("chat", "prompt required")
        return

    var messages: Array = []
    var clean_system := system_prompt.strip_edges()
    if not clean_system.is_empty():
        messages.append({"role": "system", "content": clean_system})
    messages.append({"role": "user", "content": clean_prompt})
    _chat_with_noko(messages)


func _chat_with_noko(messages: Array) -> void:
    var response: Dictionary = await NokoPromptAPI.chat(
        self,
        SERVER,
        model,
        messages,
        "",
        {},
        {"temperature": 0.2},
        false
    )

    if _response_ok(response):
        var body: Dictionary = response.get("body", {})
        var message: Dictionary = body.get("message", {})
        var text := String(message.get("content", ""))
        if not text.is_empty():
            chat_completed.emit(text, body)
            return

    _request_json(
        "chat_fallback",
        "/api/chat",
        HTTPClient.METHOD_POST,
        {
            "model": model,
            "stream": false,
            "messages": messages,
            "options": {"temperature": 0.2}
        }
    )


func set_model(next_model: String) -> bool:
    var candidate := next_model.strip_edges()
    if candidate.is_empty() or candidate.length() > 96:
        return false
    model = candidate
    return true


func _response_ok(response: Dictionary) -> bool:
    return (
        int(response.get("result", HTTPRequest.RESULT_CANT_CONNECT)) == HTTPRequest.RESULT_SUCCESS
        and int(response.get("response_code", 0)) >= 200
        and int(response.get("response_code", 0)) < 300
        and typeof(response.get("body", null)) == TYPE_DICTIONARY
    )


func _request_json(operation: String, path: String, method: int, payload: Dictionary) -> void:
    var req := HTTPRequest.new()
    req.timeout = REQUEST_TIMEOUT_SECONDS
    add_child(req)
    req.request_completed.connect(_on_request_completed.bind(operation, req))

    var headers := PackedStringArray(["Content-Type: application/json"])
    var body := JSON.stringify(payload) if method == HTTPClient.METHOD_POST else ""
    var err := req.request(BASE_URL + path, headers, method, body)
    if err != OK:
        req.queue_free()
        request_failed.emit(operation, "request failed to start: %s" % error_string(err))


func _on_request_completed(
    result: int,
    code: int,
    _headers: PackedStringArray,
    body: PackedByteArray,
    operation: String,
    req: HTTPRequest
) -> void:
    req.queue_free()

    if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
        if operation == "probe_fallback":
            last_status = {
                "up": false,
                "endpoint": BASE_URL,
                "adapter": "noko+fallback",
                "http_code": code,
                "result": result
            }
            status_changed.emit(false, last_status)
        request_failed.emit(operation, "Ollama request failed: HTTP %d / result %d" % [code, result])
        return

    var parsed = JSON.parse_string(body.get_string_from_utf8())
    if typeof(parsed) != TYPE_DICTIONARY:
        request_failed.emit(operation, "Ollama returned invalid JSON")
        return

    var data: Dictionary = parsed
    match operation:
        "probe_fallback":
            var models: Array = data.get("models", [])
            last_status = {
                "up": true,
                "endpoint": BASE_URL,
                "adapter": "direct-fallback",
                "model_count": models.size(),
                "selected_model": model
            }
            status_changed.emit(true, last_status)
        "chat_fallback":
            var message: Dictionary = data.get("message", {})
            var text := String(message.get("content", ""))
            if text.is_empty():
                request_failed.emit("chat", "Ollama chat response did not contain message.content")
                return
            chat_completed.emit(text, data)
        _:
            request_failed.emit(operation, "unknown bridge operation")
