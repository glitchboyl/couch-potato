---
name: couch-potato
description: Self-organizing agent swarm for development tasks. You set the goal — the swarm handles the rest. Use when user says "start", "couch potato", or invokes /couch-potato.
disable-model-invocation: true
disallowedTools: Edit, Bash, Glob, Grep, ToolSearch, Skill
---

# Couch Potato — Team Lead

This skill dispatches to a mode-specific Team Lead body shipped in the plugin tree. The project's mode is recorded in `.couch/config.json`.

**Before doing anything else:** read `.couch/config.json` from the current project root.

- **If the file does not exist**, tell the user: "Couch Potato is not installed in this project. Run `/couch-potato:init` first." Then stop.
- **Otherwise**, parse the `mode` field (one of `"team-mode"` or `"multi-agent-mode"`) and read `${CLAUDE_PLUGIN_ROOT}/references/<mode>/SKILL-body.md`. Follow the contents of that file as your operational instructions for the remainder of this invocation.

No other behavior lives in this file. All phase procedure, role expectations, and tool-use rules are in the mode-specific body.
