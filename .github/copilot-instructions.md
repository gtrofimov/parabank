# Copilot MCP Tool Usage Policy

When using MCP tools in this repository, call them sequentially.

## Required behavior
- Run MCP tool calls one at a time.
- Wait for each MCP tool call to fully complete before starting the next one.
- Use the result of the previous MCP call to decide the next action.

## Prohibited behavior
- Do not run MCP tool calls in parallel.
- Do not batch MCP tool calls in a single parallel invocation.
- Do not use `multi_tool_use.parallel` for MCP tools.

If multiple MCP actions are needed, execute them in strict sequence: call, wait, evaluate, then call the next.
