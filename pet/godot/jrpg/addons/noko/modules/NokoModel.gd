# Copyright 2025 Nathanne Isip
# This file is part of Noko (https://github.com/nthnn/noko)
# This KAI 9000 vendored copy is modified under the MIT license.

class_name NokoModel

const NetUtils = preload("./utils/NetUtils.gd")
const _UA := {"User-Agent": "noko-godot/0.0.1"}
const _JSON_HEADERS := {
    "User-Agent": "noko-godot/0.0.1",
    "Content-Type": "application/json"
}

static func _valid_server(server: Dictionary) -> bool:
    return server.has("host") and server.has("port")

static func _url(server: Dictionary, path: String) -> String:
    return String(server["host"]) + ":" + str(server["port"]) + path

static func _post(
    parent: Node,
    server: Dictionary,
    path: String,
    body: Dictionary,
    use_ssl: bool
)-> Dictionary:
    if not _valid_server(server):
        push_error("Server host name and port number must be defined")
        return {"result": HTTPRequest.RESULT_CANT_CONNECT}
    return await NetUtils.send_post_request(
        parent,
        _url(server, path),
        _JSON_HEADERS,
        body,
        use_ssl
    )

static func _get(
    parent: Node,
    server: Dictionary,
    path: String,
    use_ssl: bool
)-> Dictionary:
    if not _valid_server(server):
        push_error("Server host name and port number must be defined")
        return {"result": HTTPRequest.RESULT_CANT_CONNECT}
    return await NetUtils.send_get_request(
        parent,
        _url(server, path),
        _UA,
        {},
        use_ssl
    )

static func load_generate_model(
    parent: Node,
    server: Dictionary,
    model: String,
    use_ssl: bool = true
)-> bool:
    var response = await _post(parent, server, "/api/generate", {"model": model}, use_ssl)
    return response.get("result", HTTPRequest.RESULT_CANT_CONNECT) == HTTPRequest.RESULT_SUCCESS

static func unload_generate_model(
    parent: Node,
    server: Dictionary,
    model: String,
    use_ssl: bool = true
)-> bool:
    var response = await _post(
        parent,
        server,
        "/api/generate",
        {"model": model, "keep_alive": 0},
        use_ssl
    )
    return response.get("result", HTTPRequest.RESULT_CANT_CONNECT) == HTTPRequest.RESULT_SUCCESS

static func load_chat_model(
    parent: Node,
    server: Dictionary,
    model: String,
    use_ssl: bool = true
)-> bool:
    var response = await _post(
        parent,
        server,
        "/api/chat",
        {"model": model, "messages": []},
        use_ssl
    )
    return response.get("result", HTTPRequest.RESULT_CANT_CONNECT) == HTTPRequest.RESULT_SUCCESS

static func unload_chat_model(
    parent: Node,
    server: Dictionary,
    model: String,
    use_ssl: bool = true
)-> bool:
    var response = await _post(
        parent,
        server,
        "/api/chat",
        {"model": model, "messages": [], "keep_alive": 0},
        use_ssl
    )
    return response.get("result", HTTPRequest.RESULT_CANT_CONNECT) == HTTPRequest.RESULT_SUCCESS

static func create_model(
    parent: Node,
    server: Dictionary,
    model: String,
    from: String = "",
    system: String = "",
    template: String = "",
    quantize: String = "",
    messages: Array = [],
    files: Dictionary = {},
    license: Array = [],
    adapters: Dictionary = {},
    parameters: Dictionary = {},
    use_ssl: bool = true
)-> Dictionary:
    var request_body: Dictionary = {"model": model}
    if from != "": request_body["from"] = from
    if system != "": request_body["system"] = system
    if template != "": request_body["template"] = template
    if quantize != "": request_body["quantize"] = quantize
    if not messages.is_empty(): request_body["messages"] = messages
    if not files.is_empty(): request_body["files"] = files
    if not license.is_empty(): request_body["license"] = license
    if not adapters.is_empty(): request_body["adapters"] = adapters
    if not parameters.is_empty(): request_body["parameters"] = parameters
    return await _post(parent, server, "/api/create", request_body, use_ssl)

static func list_model(
    parent: Node,
    server: Dictionary,
    use_ssl: bool = true
)-> Dictionary:
    return await _get(parent, server, "/api/tags", use_ssl)

static func fetch_model_info(
    parent: Node,
    server: Dictionary,
    model: String,
    use_ssl: bool = true
)-> Dictionary:
    return await _post(
        parent,
        server,
        "/api/show",
        {"model": model, "verbose": true},
        use_ssl
    )

static func copy_model(
    parent: Node,
    server: Dictionary,
    source: String,
    destination: String,
    use_ssl: bool = true
)-> Dictionary:
    return await _post(
        parent,
        server,
        "/api/copy",
        {"source": source, "destination": destination},
        use_ssl
    )

static func delete_model(
    parent: Node,
    server: Dictionary,
    model: String,
    use_ssl: bool = true
)-> Dictionary:
    return await _post(parent, server, "/api/delete", {"model": model}, use_ssl)

static func pull_model(
    parent: Node,
    server: Dictionary,
    model: String,
    use_ssl: bool = true
)-> Dictionary:
    return await _post(
        parent,
        server,
        "/api/pull",
        {"model": model, "stream": false},
        use_ssl
    )

static func push_model(
    parent: Node,
    server: Dictionary,
    model: String,
    use_ssl: bool = true
)-> Dictionary:
    return await _post(
        parent,
        server,
        "/api/push",
        {"model": model, "stream": false},
        use_ssl
    )
