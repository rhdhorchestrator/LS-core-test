# Lightspeed-Test Project

This project creates a Docker Compose setup with two main services:
- **llama-stack**: A LLaMA Stack instance connected to Ollama (port 8321)
- **lightspeed-stack**: A Lightspeed Stack instance for AI interactions (port 8080)

## Project Structure

```
├── docker-compose.yaml      # Main docker-compose configuration
├── config.yaml             # Lightspeed-stack configuration
├── run-llama-stack.yaml    # LLaMA stack runtime configuration
└── test-functions.sh       # Testing utility functions
```

## How to Start Services

### Using podman-compose

```bash
export OLLAMA_HOST="http://192.168.2.5:11434"
podman-compose up -d
```

### Check running services

```bash
podman-compose ps
```

**Output:**
```
CONTAINER ID  IMAGE                                            COMMAND     CREATED         STATUS                   PORTS                   NAMES
7099fbbad9a1  docker.io/llamastack/distribution-ollama:latest              23 seconds ago  Up 23 seconds (healthy)  0.0.0.0:8321->8321/tcp  llama-stack
8204fde2b4f3  quay.io/lightspeed-core/lightspeed-stack:latest              23 seconds ago  Up 12 seconds            0.0.0.0:8080->8080/tcp  lightspeed-stack
```

## Service Endpoints

### Port 8080 (Lightspeed-Stack)

The Lightspeed-Stack service provides the following functionality:

- **Service Info**: `GET /v1/info`
  ```json
  {
    "name": "Test LSCore",
    "version": "0.1.3"
  }
  ```

- **Configuration**: `GET /v1/config` - Returns complete service configuration
- **Available Models**: `GET /v1/models` - Lists available AI models
- **Query Endpoint**: `POST /v1/query` - Main AI interaction endpoint

### Port 8321 (LLaMA-Stack)

The LLaMA-Stack service provides:

- **Health Check**: `GET /v1/health`
  ```json
  {"status":"OK"}
  ```

- **Available Models**: `GET /v1/models`
  ```json
  {
    "data": [
      {
        "identifier": "gemma3:27b-it-qat",
        "provider_resource_id": "gemma3:27b-it-qat",
        "provider_id": "ollama",
        "type": "model",
        "metadata": {},
        "model_type": "llm"
      }
    ]
  }
  ```

- **Providers**: `GET /v1/providers` - Lists available providers (ollama, model-context-protocol, meta-reference)
- **Chat Completion**: `POST /v1/inference/chat-completion` - AI inference endpoint

## Test Functions

The `test-functions.sh` file contains utility functions for testing both services. To use them:

```bash
source test-functions.sh
```

### LLaMA-Stack Functions

| Function | Description |
|----------|-------------|
| `llama::list_models()` | List available models (identifiers only) |
| `llama::list_models_full()` | List available models (full details) |
| `llama::list_providers()` | List provider IDs |
| `llama::list_providers_full()` | List providers (full details) |
| `llama::list_tools()` | List available tools (may return error if tools not configured) |
| `llama::list_toolgroups()` | List available tools groups |
| `llama::chat_completion()` | Test chat completion with sample query |
| `llama::list_agents()` | List created agents in llamastack |

### Lightspeed-Stack Functions

| Function | Description |
|----------|-------------|
| `ls::info()` | Get service information |
| `ls::config()` | Get complete service configuration |
| `ls::models()` | List available models |
| `ls::test()` | Test query endpoint with sample request |
| `ls::stest()` | Test query endpoint with sample request (streaming) |
| `ls::conversation()` | Retrieve conversation request |

## Testing LLaMA-Stack with Functions

```bash
# Source the functions
source test-functions.sh

# List available models
llama::list_models
# Output: gemma3:27b-it-qat

# List providers
llama::list_providers
# Output: 
# ollama
# model-context-protocol
# meta-reference

# Test chat completion (may require Ollama to be running with the model)
llama::chat_completion
```

## Testing Lightspeed-Stack with Functions

```bash
# Source the functions
source test-functions.sh

# Get service info
ls::info
# Output: {"name": "Test LSCore", "version": "0.1.3"}

# Get full configuration
ls::config

# List available models
ls::models

# Test query endpoint
ls::test
```

## Configuration Details

### LLaMA-Stack Configuration
- **Model**: `gemma3:27b-it-qat`
- **Provider**: Ollama (requires external Ollama instance)
- **APIs**: inference, safety, tool_runtime, telemetry
- **Storage**: SQLite databases in `/tmp/`

### Lightspeed-Stack Configuration
- **Default Model**: `gemma3:27b-it-qat`
- **Default Provider**: `ollama`
- **Auth**: Disabled
- **Data Collection**: Feedback and transcripts enabled
- **MCP Server**: Configured for model-context-protocol

## Notes

- The LLaMA-Stack connects to an external Ollama instance (configure via `OLLAMA_HOST` environment variable)
- Both services use the `lightspeednet` bridge network for communication
- The Lightspeed-Stack waits for LLaMA-Stack to be healthy before starting
- Tool runtime endpoint may return errors if MCP servers are not properly configured
