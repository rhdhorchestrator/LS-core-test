#!/bin/bash

# Lightspeed Stack API Testing Functions
# Usage: source test-functions.sh

LLAMASTACK_BASE_URL="${LLAMASTACK_BASE_URL:-http://localhost:8321}"
LIGHTSPEED_BASE_URL="${LIGHTSPEED_BASE_URL:-http://localhost:8080}"

llama::list_models() {
    curl -X 'GET' -s \
        "${LLAMASTACK_BASE_URL}/v1/models" \
        -H 'accept: application/json' | jq -r '.data[].identifier'
}

llama::list_models_full() {
    curl -X 'GET' -s \
        "${LLAMASTACK_BASE_URL}/v1/models" \
        -H 'accept: application/json' | jq -r '.'
}

llama::list_providers() {
    curl -X 'GET' -s\
        "${LLAMASTACK_BASE_URL}/v1/providers" \
        -H 'accept: application/json' | jq -r '.data[].provider_id'
}

llama::list_providers_full() {
    curl -X 'GET' -s\
        "${LLAMASTACK_BASE_URL}/v1/providers" \
        -H 'accept: application/json' | jq -r '.data[]'
}

llama::list_tools() {
    curl -X 'GET' -s \
        "${LLAMASTACK_BASE_URL}/v1/tool-runtime/list-tools" \
        -H 'accept: application/json' | jq -r '.data[]'
}

llama::chat_completion() {
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
    curl -s \
        "${LIGHTSPEED_BASE_URL}/v1/info" \
        -H 'accept: application/json' \
        -H 'content-type: application/json' | jq .
}


ls::config() {
    curl -s \
        "${LIGHTSPEED_BASE_URL}/v1/config" \
        -H 'accept: application/json' \
        -H 'content-type: application/json' | jq .
}

ls::models() {
    curl -s \
        "${LIGHTSPEED_BASE_URL}/v1/models" \
        -H 'accept: application/json' \
        -H 'content-type: application/json' | jq .
}

ls::test() {
    curl -s \
        "${LIGHTSPEED_BASE_URL}/v1/query" \
        -H 'accept: application/json' \
        -H 'content-type: application/json' \
        -d '
            {
              "attachments": [],
              "model": "gemma3:27b-it-qat",
              "no_tools": false,
              "provider": "vllm-inference",
              "query": "write a deployment yaml for the mongodb image"
            }
        '
}
