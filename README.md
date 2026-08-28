# 3D Chat Interface with Godot 4 & Gemma AI

A fun, privacy-first 3D chat interface running Godot 4 in headless mode with local Gemma AI LLM integration.

## Features

- **Godot 4 Headless**: Lightweight 3D engine without display dependencies
- **Local Gemma AI**: Privacy-respecting LLM running locally (no cloud required)
- **Interactive 3D Chat**: Messages trigger 3D animations and visual responses
- **Extensible Architecture**: Easy to add new 3D effects and integrations

## Requirements

- Godot 4.x (headless build)
- Ollama or similar (for running Gemma AI locally)
- Python 3.10+ (for additional tooling if needed)
- 8GB+ RAM (recommended for local LLM)

## Quick Start

### 1. Install Godot 4 Headless

```bash
# Download Godot 4 headless from godotengine.org or build from source
export GODOT_BIN="./godot4-headless"
```

### 2. Set Up Local Gemma AI

```bash
# Install Ollama (https://ollama.ai)
curl -fsSL https://ollama.ai/install.sh | sh

# Pull Gemma AI model
ollama pull gemma:7b
# or gemma:2b for lighter variant

# Start Ollama server
ollama serve
```

### 3. Run the Chat Interface

```bash
# In another terminal, run Godot headless
$GODOT_BIN --headless --script chat_server.gd
```

### 4. Connect and Chat

```bash
# Use the CLI client or API
python client.py
```

## Architecture

```
3d-chat-interface/
├── godot/                    # Godot 4 project
│   ├── project.godot
│   ├── scenes/
│   │   └── ChatVisualizer.tscn
│   ├── scripts/
│   │   ├── chat_server.gd   # Main headless server
│   │   ├── gemma_client.gd  # Ollama integration
│   │   └── 3d_effects.gd    # Visual effects
│   └── resources/
├── python/                   # Python utilities
│   ├── client.py            # CLI client
│   ├── gemma_api.py         # Gemma API wrapper
│   └── requirements.txt
└── docs/
    └── setup.md
```

## API

### Local WebSocket Server (via Godot)

The Godot server exposes a WebSocket interface:

```
ws://localhost:8080/chat
```

**Message Format:**
```json
{
  "message": "Hello, how are you?",
  "metadata": {
    "animation": "bounce",
    "color": "#FF6B6B"
  }
}
```

**Response:**
```json
{
  "response": "I'm doing great! Thanks for asking.",
  "3d_effect": "expand_sphere",
  "duration": 2.5
}
```

## Configuration

Create `.env` file:

```env
OLLAMA_HOST=http://localhost:11434
GEMMA_MODEL=gemma:7b
GODOT_PORT=8080
LOG_LEVEL=debug
```

## Performance Tips

- Use `gemma:2b` for faster responses on lower-end hardware
- Enable GPU acceleration if available
- Adjust context window size in `gemma_client.gd`

## Contributing

Contributions welcome! Feel free to add new 3D effects, animation sequences, or improve the Gemma integration.

## License

MIT
