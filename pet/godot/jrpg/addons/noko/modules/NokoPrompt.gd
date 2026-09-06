# Copyright 2025 Nathanne Isip
# This file is part of Noko (https://github.com/nthnn/noko)
# This code is licensed under MIT license (see LICENSE for details)

class_name NokoPrompt

const NetUtils = preload("./utils/NetUtils.gd")

static func generate(
    parent: Node,
    server: Dictionary,
    model: String,
    prompt: String,
    suffix: String = "",
    image: Dictionary = {},
    options: Dictionary = {},
    use_ssl: bool = true
)-> Dictionary:
    if (!server.has("host") or !server.has("port")):
        push_error("Server host name and port number must be defined")
        return {"result": HTTPRequest.RESULT_CANT_CONNECT}

    var data = {
        "model": model,
        "prompt": prompt,
        "suffix": suffix,
        "stream": false,
        "options": options
    }

    if image.size() != 0:
        data["images"] = image

    var response = await NetUtils.send_post_request(
        parent,
        server["host"] + ":" + str(server["port"]) + "/api/generate",
        {
            "User-Agent": "noko-godot/0.0.1",
            "Content-Type": "application/json"
        },
        data,
        use_ssl
    )

    if response.get("result", HTTPRequest.RESULT_CANT_CONNECT) == HTTPRequest.RESULT_SUCCESS:
        return response

    push_error("Error trying to generate response")
    return response

static func chat(
    parent: Node,
    server: Dictionary,
    model: String,
    messages: Array,
    suffix: String = "",
    image: Dictionary = {},
    options: Dictionary = {},
    use_ssl: bool = true
)-> Dictionary:
    if (!server.has("host") or !server.has("port")):
        push_error("Server host name and port number must be defined")
        return {"result": HTTPRequest.RESULT_CANT_CONNECT}

    var data = {
        "model": model,
        "messages": messages,
        "suffix": suffix,
        "stream": false,
        "options": options
    }

    if image.size() != 0:
        data["images"] = image

    var response = await NetUtils.send_post_request(
        parent,
        server["host"] + ":" + str(server["port"]) + "/api/chat",
        {
            "User-Agent": "noko-godot/0.0.1",
            "Content-Type": "application/json"
        },
        data,
        use_ssl
    )

    if response.get("result", HTTPRequest.RESULT_CANT_CONNECT) == HTTPRequest.RESULT_SUCCESS:
        return response

    push_error("Error trying to generate response")
    return response
