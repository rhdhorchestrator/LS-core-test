#!/bin/bash

# Lightspeed Stack API Testing Functions
# Usage: source test-functions.sh

LLAMASTACK_BASE_URL="${LLAMASTACK_BASE_URL:-http://localhost:8321}"
LIGHTSPEED_BASE_URL="${LIGHTSPEED_BASE_URL:-http://localhost:8080}"
LLAMA_MODEL="${LLAMA_MODEL:-qwen3:4b}"
LLAMA_PROVIDER="${LLAMA_PROVIDER:-google-vertex}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Debug and utility functions
debug_print() {
    echo -e "${BLUE}[DEBUG]${NC} $1" >&2
}

info_print() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

warn_print() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

error_print() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Reusable curl function with debug capabilities
api_curl() {
    local method="$1"
    local url="$2"
    local content_type="${3:-application/json}"
    local data="$4"
    local extra_args="${5:-}"

    local curl_args=(
        -X "$method"
        -H "accept: application/json"
    )

    if [ "$content_type" != "none" ]; then
        curl_args+=(-H "content-type: $content_type")
    fi

    if [ -n "$data" ]; then
        curl_args+=(-d "$data")
    fi

    if [ "$CURL_DEBUG" = "1" ]; then
        curl_args+=(-v)
        debug_print "Full curl command: curl ${curl_args[*]} $extra_args $url"
    else
        curl_args+=(-s)
    fi

    if [ -n "$extra_args" ]; then
        curl_args+=($extra_args)
    fi

    curl "${curl_args[@]}" "$url"
}

# Interactive model and provider selection
select_model() {
    info_print "Fetching available models..."
    local models=($(llama::list_models))

    if [ ${#models[@]} -eq 0 ]; then
        error_print "No models found. Is the llama stack running?"
        return 1
    fi

    echo -e "\n${CYAN}Available models:${NC}"
    for i in "${!models[@]}"; do
        echo "  $((i+1)). ${models[$i]}"
    done

    echo -n "Select a model (1-${#models[@]}) [current: $LLAMA_MODEL]: "
    read -r choice

    if [ -n "$choice" ] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#models[@]} ]; then
        LLAMA_MODEL="${models[$((choice-1))]}"
        info_print "Model set to: $LLAMA_MODEL"
    else
        info_print "Keeping current model: $LLAMA_MODEL"
    fi
}

select_provider() {
    info_print "Fetching available providers..."
    local providers=($(llama::list_providers))

    if [ ${#providers[@]} -eq 0 ]; then
        error_print "No providers found. Is the llama stack running?"
        return 1
    fi

    echo -e "\n${CYAN}Available providers:${NC}"
    for i in "${!providers[@]}"; do
        echo "  $((i+1)). ${providers[$i]}"
    done

    echo -n "Select a provider (1-${#providers[@]}) [current: $LLAMA_PROVIDER]: "
    read -r choice

    if [ -n "$choice" ] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#providers[@]} ]; then
        LLAMA_PROVIDER="${providers[$((choice-1))]}"
        info_print "Provider set to: $LLAMA_PROVIDER"
    else
        info_print "Keeping current provider: $LLAMA_PROVIDER"
    fi
}

configure_model() {
    echo -e "\n${MAGENTA}=== Model Configuration ===${NC}"
    echo "Current model: $LLAMA_MODEL"
    echo "Current provider: $LLAMA_PROVIDER"
    echo
    echo "1. Select model interactively"
    echo "2. Select provider interactively"
    echo "3. Set model manually"
    echo "4. Set provider manually"
    echo "5. Show current configuration"
    echo "6. Exit"
    echo
    echo -n "Choose an option (1-6): "
    read -r choice

    case $choice in
        1) select_model ;;
        2) select_provider ;;
        3) 
            echo -n "Enter model name: "
            read -r model_name
            if [ -n "$model_name" ]; then
                LLAMA_MODEL="$model_name"
                info_print "Model set to: $LLAMA_MODEL"
            fi
            ;;
        4)
            echo -n "Enter provider name: "
            read -r provider_name
            if [ -n "$provider_name" ]; then
                LLAMA_PROVIDER="$provider_name"
                info_print "Provider set to: $LLAMA_PROVIDER"
            fi
            ;;
        5)
            echo -e "\n${CYAN}Current Configuration:${NC}"
            echo "  Model: $LLAMA_MODEL"
            echo "  Provider: $LLAMA_PROVIDER"
            echo "  Llama Stack URL: $LLAMASTACK_BASE_URL"
            echo "  Lightspeed URL: $LIGHTSPEED_BASE_URL"
            ;;
        6) info_print "Configuration unchanged" ;;
        *) warn_print "Invalid option" ;;
    esac
}

llama::list_models() {
    debug_print "GET ${LLAMASTACK_BASE_URL}/v1/models"
    api_curl GET "${LLAMASTACK_BASE_URL}/v1/models" | jq -r '.data[].provider_resource_id'
}

llama::list_models_full() {
    debug_print "GET ${LLAMASTACK_BASE_URL}/v1/models (full)"
    api_curl GET "${LLAMASTACK_BASE_URL}/v1/models" | jq -r '.'
}

llama::list_providers() {
    debug_print "GET ${LLAMASTACK_BASE_URL}/v1/providers"
    api_curl GET "${LLAMASTACK_BASE_URL}/v1/providers" | jq -r '.data[].provider_id'
}

llama::list_providers_full() {
    debug_print "GET ${LLAMASTACK_BASE_URL}/v1/providers (full)"
    api_curl GET "${LLAMASTACK_BASE_URL}/v1/providers" | jq -r '.data[]'
}

llama::list_tools() {
    debug_print "GET ${LLAMASTACK_BASE_URL}/v1/tool-runtime/list-tools"
    api_curl GET "${LLAMASTACK_BASE_URL}/v1/tool-runtime/list-tools" | jq -r '.data[]'
}

llama::list_toolgroups() {
    debug_print "GET ${LLAMASTACK_BASE_URL}/v1/toolgroups"
    api_curl GET "${LLAMASTACK_BASE_URL}/v1/toolgroups" | jq -r '.'
}

llama::list_agents() {
    debug_print "GET ${LLAMASTACK_BASE_URL}/v1/agents"
    api_curl GET "${LLAMASTACK_BASE_URL}/v1/agents" | jq -r '.data[]'
}

llama::chat_completion() {
    local prompt="${1:-how much space I have on my disk?}"
    local model="${2:-$LLAMA_MODEL}"

    debug_print "POST ${LLAMASTACK_BASE_URL}/v1/inference/chat-completion"
    debug_print "Using model: $model"
    debug_print "Prompt: $prompt"

    local data='{
        "model_id": "'$model'",
        "messages": [
            {
                "role": "user",
                "content": "'$(echo "$prompt" | sed 's/"/\\\\"'/g)'"
            }
        ],
        "stream": false
    }'

    api_curl POST "${LLAMASTACK_BASE_URL}/v1/inference/chat-completion" "application/json" "$data"
}


ls::info() {
    debug_print "GET ${LIGHTSPEED_BASE_URL}/v1/info"
    api_curl GET "${LIGHTSPEED_BASE_URL}/v1/info" | jq .
}


ls::config() {
    debug_print "GET ${LIGHTSPEED_BASE_URL}/v1/config"
    api_curl GET "${LIGHTSPEED_BASE_URL}/v1/config" | jq .
}

ls::models() {
    debug_print "GET ${LIGHTSPEED_BASE_URL}/v1/models"
    api_curl GET "${LIGHTSPEED_BASE_URL}/v1/models" | jq .
}

CHUCK_WORKFLOW_REQUEST=$(cat <<EOF
Create a new workflow, which each morning get a random joke from 'https://api.chucknorris.io/jokes/random | jq \".value\"' and send it to the channel in this API:

curl -d '{\"message\": \"the chuck norris joke\", \"user\": \"bot\"}' http://api.acalustra.com/funfact
EOF
)

# JSON escape function for proper handling of quotes and special characters
json_escape() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/g' | tr -d '\n' | sed 's/\\n$//'
}


ls::test_with_prompt() {
    local custom_query="$1"
    local model="${2:-${LLAMA_MODEL}}"
    local provider="${3:-${LLAMA_PROVIDER}}"

    if [ -z "$custom_query" ]; then
        error_print "Please provide a prompt as the first argument"
        echo "Usage: ls::test_with_prompt 'your prompt here' [model] [provider]"
        return 1
    fi

    local escaped_query=$(json_escape "$custom_query")

    debug_print "POST ${LIGHTSPEED_BASE_URL}/v1/query"
    debug_print "Query: $custom_query"
    debug_print "Model: $model, Provider: $provider"

    local data="{
        \"attachments\": [],
        \"model\": \"${model}\",
        \"no_tools\": false,
        \"provider\": \"${provider}\",
        \"query\": \"${escaped_query}\"
    }"

    api_curl POST "${LIGHTSPEED_BASE_URL}/v1/query" "application/json" "$data" | jq -r '
"🔗 Conversation: " + .conversation_id + "\n" +
"📝 Response:\n" + .response'
}

CHUCK_WORKFLOW_REQUEST=$(cat <<EOF
Create a new workflow, which each morning get a random joke from 'https://api.chucknorris.io/jokes/random | jq ".value"' and send it to the channel in this API:

curl -d '{"message": "the chuck norris joke", "user": "bot"}' http://api.acalustra.com/funfact
EOF
)

ls::test_chuck() {
    ls::test_with_prompt "$CHUCK_WORKFLOW_REQUEST"
}


ls::test() {
    local query="I need to inform my manager about how many orchestrator workflows we're currently running"
    ls::test_with_prompt "${query}"
}

ls::conversations() {
    debug_print "GET ${LIGHTSPEED_BASE_URL}/v1/conversations"
    api_curl GET "${LIGHTSPEED_BASE_URL}/v1/conversations" | jq .
}


ls::conversation() {
    local id="$1"

    if [ -z "$id" ]; then
        error_print "Please provide a conversation ID"
        echo "Usage: ls::conversation <conversation_id>"
        return 1
    fi

    debug_print "GET ${LIGHTSPEED_BASE_URL}/v1/conversations/$id"
    api_curl GET "${LIGHTSPEED_BASE_URL}/v1/conversations/$id" | jq .
}
