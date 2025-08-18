#!/bin/bash

# Lightspeed Stack API Testing Functions
# Usage: source test-functions.sh

LLAMASTACK_BASE_URL="${LLAMASTACK_BASE_URL:-http://localhost:8321}"
LIGHTSPEED_BASE_URL="${LIGHTSPEED_BASE_URL:-http://localhost:8080}"
LLAMA_MODEL="${LLAMA_MODEL:-qwen3:4b}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

debug_print() {
    echo -e "${BLUE}[DEBUG]${NC} $1" >&2
}

llama::list_models() {
    debug_print "GET ${LLAMASTACK_BASE_URL}/v1/models"
    curl -X 'GET' -s \
        "${LLAMASTACK_BASE_URL}/v1/models" \
        -H 'accept: application/json' | jq -r '.data[].identifier'
}

llama::list_models_full() {
    debug_print "GET ${LLAMASTACK_BASE_URL}/v1/models (full)"
    curl -X 'GET' -s \
        "${LLAMASTACK_BASE_URL}/v1/models" \
        -H 'accept: application/json' | jq -r '.'
}

llama::list_providers() {
    debug_print "GET ${LLAMASTACK_BASE_URL}/v1/providers"
    curl -X 'GET' -s \
        "${LLAMASTACK_BASE_URL}/v1/providers" \
        -H 'accept: application/json' | jq -r '.data[].provider_id'
}

llama::list_providers_full() {
    debug_print "GET ${LLAMASTACK_BASE_URL}/v1/providers (full)"
    curl -X 'GET' -s \
        "${LLAMASTACK_BASE_URL}/v1/providers" \
        -H 'accept: application/json' | jq -r '.data[]'
}

llama::list_tools() {
    debug_print "GET ${LLAMASTACK_BASE_URL}/v1/tool-runtime/list-tools"
    curl -X 'GET' -s \
        "${LLAMASTACK_BASE_URL}/v1/tool-runtime/list-tools" \
        -H 'accept: application/json' | jq -r '.data[]'
}

llama::list_toolgroups() {
    debug_print "GET ${LLAMASTACK_BASE_URL}/v1/toolgroups"
    curl -X 'GET' -s \
        "${LLAMASTACK_BASE_URL}/v1/toolgroups" \
        -H 'accept: application/json' | jq -r '.'
}

llama::list_agents() {
    debug_print "GET ${LLAMASTACK_BASE_URL}/v1/agents"
    curl -X 'GET' -s \
        "${LLAMASTACK_BASE_URL}/v1/agents" \
        -H 'accept: application/json' | jq -r '.data[]'
}
llama::chat_completion() {
    debug_print "POST ${LLAMASTACK_BASE_URL}/v1/inference/chat-completion"
    curl -X 'POST' -s \
        "${LLAMASTACK_BASE_URL}/v1/inference/chat-completion" \
        -H 'accept: application/json' \
        -H 'content-type: application/json' \
        -d '{
            "model_id": "gemma3:27b-it-qat",
            "messages": [
                {
                    "role": "user",
                    "content": "how much space I have on my disk?"
                }
            ],
            "stream": false
        }'
}

llama::chat_completion() {
    debug_print "POST ${LLAMASTACK_BASE_URL}/v1/inference/chat-completion"
    curl -X 'POST' -s \
        "${LLAMASTACK_BASE_URL}/v1/inference/chat-completion" \
        -H 'accept: application/json' \
        -H 'content-type: application/json' \
        -d '{
            "model_id": "gemma3:27b-it-qat",
            "messages": [
                {
                    "role": "user",
                    "content": "how much space I have on my disk?"
                }
            ],
            "stream": false
        }'
}


ls::info() {
    debug_print "GET ${LIGHTSPEED_BASE_URL}/v1/info"
    curl -s \
        "${LIGHTSPEED_BASE_URL}/v1/info" \
        -H 'accept: application/json' \
        -H 'content-type: application/json' | jq .
}


ls::config() {
    debug_print "GET ${LIGHTSPEED_BASE_URL}/v1/config"
    curl -s \
        "${LIGHTSPEED_BASE_URL}/v1/config" \
        -H 'accept: application/json' \
        -H 'content-type: application/json' | jq .
}

ls::models() {
    debug_print "GET ${LIGHTSPEED_BASE_URL}/v1/models"
    curl -s \
        "${LIGHTSPEED_BASE_URL}/v1/models" \
        -H 'accept: application/json' \
        -H 'content-type: application/json' | jq .
}

ls::test() {
    debug_print "POST ${LIGHTSPEED_BASE_URL}/v1/query"
    curl -s \
        "${LIGHTSPEED_BASE_URL}/v1/query" \
        -H 'accept: application/json' \
        -H 'content-type: application/json' \
        -d "{
              \"attachments\": [],
              \"model\": \"${LLAMA_MODEL}\",
              \"no_tools\": false,
              \"provider\": \"vllm-inference\",
              \"query\": \"I need to inform my manager about how many orchestator workflows we have currently registered\"
            }" | jq -r '
"🔗 Conversation: " + .conversation_id + "\n" +
"📝 Response:\n" + .response'
}


ls::stest() {
    debug_print "POST ${LIGHTSPEED_BASE_URL}/v1/query"
    curl -s \
        "${LIGHTSPEED_BASE_URL}/v1/streaming_query" \
        -H 'accept: application/json' \
        -H 'content-type: application/json' \
        -d "{
              \"attachments\": [],
              \"model\": \"${LLAMA_MODEL}\",
              \"no_tools\": false,
              \"provider\": \"vllm-inference\",
              \"query\": \"I need to inform my manager about how many orchestator workflows we have currently registered\"
            }"
}

ls::conversations() {
    debug_print "GET ${LIGHTSPEED_BASE_URL}/v1/conversations"
    curl -s \
        "${LIGHTSPEED_BASE_URL}/v1/conversations" \
        -H 'accept: application/json' \
        -H 'content-type: application/json' | jq .
}


ls::conversation() {
    local id=$1;
    debug_print "GET ${LIGHTSPEED_BASE_URL}/v1/conversations/$id";
    curl -s \
        "${LIGHTSPEED_BASE_URL}/v1/conversations/$id" \
        -H 'accept: application/json' \
        -H 'content-type: application/json' | jq .
}

