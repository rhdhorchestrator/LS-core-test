# MCP on Lightspeed

## llamastack

First, we need llamastack working with a sample config from `run-llama-stack.yaml`, and we need it running:

```
podman-compose up llamastack
```

And we can run some tests:

List models from our inference to verify it's working:
```
$ -> llama::list_models
[DEBUG] GET http://localhost:8321/v1/models
vllm-inference/qwen3:4b
vllm-inference/all-minilm:latest
vllm-inference/qwen2.5:1.5b-instruct
vllm-inference/gemma3:27b-it-qat
vllm-inference/deepcoder:latest
vllm-inference/deepcoder:14b
vllm-inference/sikamikanikobg/OlympicCoder-7B:latest
vllm-inference/deepseek-r1:14b
vllm-inference/erwan2/DeepSeek-R1-Distill-Qwen-7B:latest
vllm-inference/qwen2.5-coder:7b
vllm-inference/deepseek-r1:8b
vllm-inference/phi3:latest
vllm-inference/llama3.1:latest
vllm-inference/codellama:13b
vllm-inference/llama3:8b
```

And we can see there are no tools registered yet:

```
$ -> llama::list_tools
[DEBUG] GET http://localhost:8321/v1/tool-runtime/list-tools
$ -> llama::list_toolgroups
[DEBUG] GET http://localhost:8321/v1/toolgroups
```

The same for agents:

```
$ -> llama::list_agents
[DEBUG] GET http://localhost:8321/v1/agents
```

## MCP server

For running MCP tools, we need a fake MCP server. To run it:

```
$ -> python mcp_server.py

╭─ FastMCP 2.0 ──────────────────────────────────────────────────────────────╮
│                                                                            │
│        _ __ ___ ______           __  __  _____________    ____    ____     │
│       _ __ ___ / ____/___ ______/ /_/  |/  / ____/ __ \  |___ \  / __ \    │
│      _ __ ___ / /_  / __ `/ ___/ __/ /|_/ / /   / /_/ /  ___/ / / / / /    │
│     _ __ ___ / __/ / /_/ (__  ) /_/ /  / / /___/ ____/  /  __/_/ /_/ /     │
│    _ __ ___ /_/    \__,_/____/\__/_/  /_/\____/_/      /_____(_)____/      │
│                                                                            │
│                                                                            │
│                                                                            │
│    🖥️  Server name:     Current Date and Time                               │
│    📦 Transport:       Streamable-HTTP                                     │
│    🔗 Server URL:      http://0.0.0.0:8000/mcp/                            │
│                                                                            │
│    📚 Docs:            https://gofastmcp.com                               │
│    🚀 Deploy:          https://fastmcp.cloud                               │
│                                                                            │
│    🏎️  FastMCP version: 2.10.6                                              │
│    🤝 MCP version:     1.12.4                                              │
│                                                                            │
╰────────────────────────────────────────────────────────────────────────────╯


[08/18/25 15:39:33] INFO     Starting MCP server 'Current Date and Time' with transport 'http' on                server.py:1448
                             http://0.0.0.0:8000/mcp/
INFO:     Started server process [277943]
INFO:     Waiting for application startup.
2025-08-18 15:39:33,668 - INFO - StreamableHTTP session manager started
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

The MCP server only has a dummy function like:

```
@mcp.tool()
def get_orchestrator_instances(session_id):
    logger.info(f"get_orchestrator_instances for session_id='{session_id}'")
    """
    Return the list of orchestrator instances registered in Backstage or RHDH (Red Hat Developer Hub)
    """
    return {
        'total': 5,
        'data': [
            {"name": "process_payment_refunds", "status": "RUNNING"},
            {"name": "sync_inventory_updates", "status": "READY"},
            {"name": "generate_monthly_reports", "status": "RUNNING"},
            {"name": "backup_customer_data", "status": "FAILED"},
            {"name": "send_welcome_emails", "status": "COMPLETED"}
        ]
    }

```

## lightspeed-stack

Now, we need to give information to Lightspeed, so we add the following to the Lightspeed config (config.yaml):

```
mcp_servers:
  - name: "server1"
    provider_id: "model-context-protocol"
    url: "http://host.docker.internal:8000/mcp/"
```

Now we just need to start the server:

```
podman-compose up lightspeed-stack
```

And we can see the tools in llamastack:

```
$ -> llama::list_toolgroups
[DEBUG] GET http://localhost:8321/v1/toolgroups
{
  "data": [
    {
      "identifier": "server1",
      "provider_resource_id": "server1",
      "provider_id": "model-context-protocol",
      "type": "tool_group",
      "mcp_endpoint": {
        "uri": "http://host.docker.internal:8000/mcp/"
      },
      "args": null
    }
  ]
}
$ -> llama::list_tools
[DEBUG] GET http://localhost:8321/v1/tool-runtime/list-tools
{
  "identifier": "get_orchestrator_instances",
  "provider_resource_id": null,
  "provider_id": "model-context-protocol",
  "type": "tool",
  "toolgroup_id": "server1",
  "description": "",
  "parameters": [
    {
      "name": "session_id",
      "parameter_type": "string",
      "description": "",
      "required": true,
      "default": null
    }
  ],
  "metadata": {
    "endpoint": "http://host.docker.internal:8000/mcp/"
  }
}

```

And on lightspeed-stack, the models:

```
$ -> ls::models  | jq '.models[].identifier'
[DEBUG] GET http://localhost:8080/v1/models
"vllm-inference/qwen3:4b"
"vllm-inference/all-minilm:latest"
"vllm-inference/qwen2.5:1.5b-instruct"
"vllm-inference/gemma3:27b-it-qat"
"vllm-inference/deepcoder:latest"
"vllm-inference/deepcoder:14b"
"vllm-inference/sikamikanikobg/OlympicCoder-7B:latest"
"vllm-inference/deepseek-r1:14b"
"vllm-inference/erwan2/DeepSeek-R1-Distill-Qwen-7B:latest"
"vllm-inference/qwen2.5-coder:7b"
"vllm-inference/deepseek-r1:8b"
"vllm-inference/phi3:latest"
"vllm-inference/llama3.1:latest"
"vllm-inference/codellama:13b"
"vllm-inference/llama3:8b"
```

Agents are still empty:

```
$ -> llama::list_agents
[DEBUG] GET http://localhost:8321/v1/agents
$ ->
```


## Running a test

Because our MCP mentions the state of the orchestrator, the idea is to list all orchestrator workflows. So, make this request:

```
I need to inform my manager about how many orchestrator workflows we have currently registered
```

And the output is like this:

```
$ -> ls::test
[DEBUG] POST http://localhost:8080/v1/query
🔗 Conversation: 40f8018c-1ba4-4893-9c6c-c57e49cdccc6
📝 Response:
<think>
Okay, let's see. The user wants to inform their manager about how many orchestrator workflows are currently registered.

First, I called the get_orchestrator_instances function twice with the same session_id "current_session". The response from both calls was the same: total 5 workflows with their names and statuses.

Wait, why did I call it twice? Maybe that's a mistake. But the tool responses are identical, so maybe the system just needs to process the data once. The user probably just needs the count and maybe a brief status summary.

Looking at the data, there are 5 workflows. The statuses are: 2 running, 1 ready, 1 failed, 1 completed. So the answer should mention the total number and perhaps the status distribution.

I should structure the response to the user's manager clearly. Start with the total number, then list the statuses with counts. But the user said "how many", so maybe just the total is enough, but they might want more context.

Wait, the user's message says "how many orchestrator workflows we have currently registered". The answer is 5. But the tool response shows 5 items. So the answer is 5. However, the manager might appreciate knowing the status distribution too.

So the response should be: "We currently have 5 orchestrator workflows registered. The status distribution is: 2 RUNNING, 1 READY, 1 FAILED, 1 COMPLETED."

But let me check the tool response again. The data has 5 entries, each with a name and status. So total is 5. The statuses are as listed.

Yes, so the answer is 5 workflows with the status breakdown. The user probably wants to know the count and maybe the status to assess health.

So I'll write that in a clear sentence for the manager.
</think>

We currently have **5 orchestrator workflows** registered. Here's the status breakdown:
- **2 RUNNING** (`process_payment_refunds`, `generate_monthly_reports`)
- **1 READY** (`sync_inventory_updates`)
- **1 FAILED** (`backup_customer_data`)
- **1 COMPLETED** (`send_welcome_emails`)

Let me know if you'd like further details!
```

We can see the details in llamastack as well:

```
$ -> llama::list_agents
[DEBUG] GET http://localhost:8321/v1/agents
{
  "agent_id": "8db55b18-930b-4623-8c0b-dac8642fd43e",
  "agent_config": {
    "sampling_params": {
      "strategy": {
        "type": "greedy"
      },
      "max_tokens": 0,
      "repetition_penalty": 1.0,
      "stop": null
    },
    "input_shields": [],
    "output_shields": [],
    "toolgroups": [],
    "client_tools": [],
    "tool_choice": null,
    "tool_prompt_format": null,
    "tool_config": {
      "tool_choice": "auto",
      "tool_prompt_format": null,
      "system_message_behavior": "append"
    },
    "max_infer_iters": 10,
    "model": "vllm-inference/qwen3:4b",
    "instructions": "You are a helpful assistant",
    "name": null,
    "enable_session_persistence": true,
    "response_format": null
  },
  "created_at": "2025-08-18T13:52:22.844249Z"
}
```


And all sessions in the API are:

```

$ -> curl http://localhost:8321/v1/agents/8db55b18-930b-4623-8c0b-dac8642fd43e/sessions -s | jq .
{
  "data": [
    {
      "session_id": "40f8018c-1ba4-4893-9c6c-c57e49cdccc6",
      "session_name": "3750c2d4-d26e-4635-be00-bb7f39c410ca",
      "turns": [],
      "started_at": "2025-08-18T13:52:22.863950Z"
    }
  ],
  "has_more": false,
  "url": "/v1/agents/{agent_id}/sessions"
}
```

With the details:

```
$ -> curl http://localhost:8321/v1/agents/8db55b18-930b-4623-8c0b-dac8642fd43e/session/40f8018c-1ba4-4893-9c6c-c57e49cdccc6 -s | jq .
{
  "session_id": "40f8018c-1ba4-4893-9c6c-c57e49cdccc6",
  "session_name": "3750c2d4-d26e-4635-be00-bb7f39c410ca",
  "turns": [
    {
      "turn_id": "14e8f8bb-229e-40ad-9751-582b6ec880f3",
      "session_id": "40f8018c-1ba4-4893-9c6c-c57e49cdccc6",
      "input_messages": [
        {
          "role": "user",
          "content": "I need to inform my manager about how many orchestator workflows we have currently registered",
          "context": null
        }
      ],
      "steps": [
        {
          "turn_id": "14e8f8bb-229e-40ad-9751-582b6ec880f3",
          "step_id": "54dfaa32-1fac-48ba-a94e-c4b66d721104",
          "started_at": "2025-08-18T13:52:22.912648Z",
          "completed_at": "2025-08-18T13:52:45.284369Z",
          "step_type": "inference",
          "model_response": {
            "role": "assistant",
            "content": "",
            "stop_reason": "end_of_turn",
            "tool_calls": [
              {
                "call_id": "call_7ma4awd7",
                "tool_name": "get_orchestrator_instances",
                "arguments": {
                  "session_id": "current_session"
                },
                "arguments_json": "{\"session_id\": \"current_session\"}"
              },
              {
                "call_id": "call_1mhp6tof",
                "tool_name": "get_orchestrator_instances",
                "arguments": {
                  "session_id": "current_session"
                },
                "arguments_json": "{\"session_id\": \"current_session\"}"
              }
            ]
          }
        },
        {
          "turn_id": "14e8f8bb-229e-40ad-9751-582b6ec880f3",
          "step_id": "479e9e04-1a38-4447-89ab-53c5784f1663",
          "started_at": "2025-08-18T13:52:45.321498Z",
          "completed_at": "2025-08-18T13:52:45.395513Z",
          "step_type": "tool_execution",
          "tool_calls": [
            {
              "call_id": "call_7ma4awd7",
              "tool_name": "get_orchestrator_instances",
              "arguments": {
                "session_id": "current_session"
              },
              "arguments_json": "{\"session_id\": \"current_session\"}"
            }
          ],
          "tool_responses": [
            {
              "call_id": "call_7ma4awd7",
              "tool_name": "get_orchestrator_instances",
              "content": [
                {
                  "type": "text",
                  "text": "{\"total\":5,\"data\":[{\"name\":\"process_payment_refunds\",\"status\":\"RUNNING\"},{\"name\":\"sync_inventory_updates\",\"status\":\"READY\"},{\"name\":\"generate_monthly_reports\",\"status\":\"RUNNING\"},{\"name\":\"backup_customer_data\",\"status\":\"FAILED\"},{\"name\":\"send_welcome_emails\",\"status\":\"COMPLETED\"}]}"
                }
              ],
              "metadata": null
            }
          ]
        },
        {
          "turn_id": "14e8f8bb-229e-40ad-9751-582b6ec880f3",
          "step_id": "cd55cb52-5c99-40da-a0b8-0c75aa2d442f",
          "started_at": "2025-08-18T13:52:45.430782Z",
          "completed_at": "2025-08-18T13:52:45.502980Z",
          "step_type": "tool_execution",
          "tool_calls": [
            {
              "call_id": "call_1mhp6tof",
              "tool_name": "get_orchestrator_instances",
              "arguments": {
                "session_id": "current_session"
              },
              "arguments_json": "{\"session_id\": \"current_session\"}"
            }
          ],
          "tool_responses": [
            {
              "call_id": "call_1mhp6tof",
              "tool_name": "get_orchestrator_instances",
              "content": [
                {
                  "type": "text",
                  "text": "{\"total\":5,\"data\":[{\"name\":\"process_payment_refunds\",\"status\":\"RUNNING\"},{\"name\":\"sync_inventory_updates\",\"status\":\"READY\"},{\"name\":\"generate_monthly_reports\",\"status\":\"RUNNING\"},{\"name\":\"backup_customer_data\",\"status\":\"FAILED\"},{\"name\":\"send_welcome_emails\",\"status\":\"COMPLETED\"}]}"
                }
              ],
              "metadata": null
            }
          ]
        },
        {
          "turn_id": "14e8f8bb-229e-40ad-9751-582b6ec880f3",
          "step_id": "28875cb3-f3f6-4312-9ea5-074af368d5ee",
          "started_at": "2025-08-18T13:52:45.514226Z",
          "completed_at": "2025-08-18T13:52:51.474411Z",
          "step_type": "inference",
          "model_response": {
            "role": "assistant",
            "content": "<think>\nOkay, let's see. The user wants to inform their manager about how many orchestrator workflows are currently registered.\n\nFirst, I called the get_orchestrator_instances function twice with the same session_id \"current_session\". The response from both calls was the same: total 5 workflows with their names and statuses.\n\nWait, why did I call it twice? Maybe that's a mistake. But the tool responses are identical, so maybe the system just needs to process the data once. The user probably just needs the count and maybe a brief status summary.\n\nLooking at the data, there are 5 workflows. The statuses are: 2 running, 1 ready, 1 failed, 1 completed. So the answer should mention the total number and perhaps the status distribution.\n\nI should structure the response to the user's manager clearly. Start with the total number, then list the statuses with counts. But the user said \"how many\", so maybe just the total is enough, but they might want more context.\n\nWait, the user's message says \"how many orchestrator workflows we have currently registered\". The answer is 5. But the tool response shows 5 items. So the answer is 5. However, the manager might appreciate knowing the status distribution too.\n\nSo the response should be: \"We currently have 5 orchestrator workflows registered. The status distribution is: 2 RUNNING, 1 READY, 1 FAILED, 1 COMPLETED.\"\n\nBut let me check the tool response again. The data has 5 entries, each with a name and status. So total is 5. The statuses are as listed.\n\nYes, so the answer is 5 workflows with the status breakdown. The user probably wants to know the count and maybe the status to assess health.\n\nSo I'll write that in a clear sentence for the manager.\n</think>\n\nWe currently have **5 orchestrator workflows** registered. Here's the status breakdown:  \n- **2 RUNNING** (`process_payment_refunds`, `generate_monthly_reports`)  \n- **1 READY** (`sync_inventory_updates`)  \n- **1 FAILED** (`backup_customer_data`)  \n- **1 COMPLETED** (`send_welcome_emails`)  \n\nLet me know if you'd like further details!",
            "stop_reason": "end_of_turn",
            "tool_calls": []
          }
        }
      ],
      "output_message": {
        "role": "assistant",
        "content": "<think>\nOkay, let's see. The user wants to inform their manager about how many orchestrator workflows are currently registered.\n\nFirst, I called the get_orchestrator_instances function twice with the same session_id \"current_session\". The response from both calls was the same: total 5 workflows with their names and statuses.\n\nWait, why did I call it twice? Maybe that's a mistake. But the tool responses are identical, so maybe the system just needs to process the data once. The user probably just needs the count and maybe a brief status summary.\n\nLooking at the data, there are 5 workflows. The statuses are: 2 running, 1 ready, 1 failed, 1 completed. So the answer should mention the total number and perhaps the status distribution.\n\nI should structure the response to the user's manager clearly. Start with the total number, then list the statuses with counts. But the user said \"how many\", so maybe just the total is enough, but they might want more context.\n\nWait, the user's message says \"how many orchestrator workflows we have currently registered\". The answer is 5. But the tool response shows 5 items. So the answer is 5. However, the manager might appreciate knowing the status distribution too.\n\nSo the response should be: \"We currently have 5 orchestrator workflows registered. The status distribution is: 2 RUNNING, 1 READY, 1 FAILED, 1 COMPLETED.\"\n\nBut let me check the tool response again. The data has 5 entries, each with a name and status. So total is 5. The statuses are as listed.\n\nYes, so the answer is 5 workflows with the status breakdown. The user probably wants to know the count and maybe the status to assess health.\n\nSo I'll write that in a clear sentence for the manager.\n</think>\n\nWe currently have **5 orchestrator workflows** registered. Here's the status breakdown:  \n- **2 RUNNING** (`process_payment_refunds`, `generate_monthly_reports`)  \n- **1 READY** (`sync_inventory_updates`)  \n- **1 FAILED** (`backup_customer_data`)  \n- **1 COMPLETED** (`send_welcome_emails`)  \n\nLet me know if you'd like further details!",
        "stop_reason": "end_of_turn",
        "tool_calls": []
      },
      "output_attachments": [],
      "started_at": "2025-08-18T13:52:22.906759Z",
      "completed_at": "2025-08-18T13:52:51.488820Z"
    }
  ],
  "started_at": "2025-08-18T13:52:22.863950Z"
}
```
