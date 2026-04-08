#!/bin/sh
# restrict_read_path.sh — PreToolUse hook for the Read tool
#
# Purpose: Restrict Team Lead Read access to orchestration-only paths.
#   Allowed: the project's own .couch/ directory and any .claude/ directory.
#   Blocked: all other paths (source files, CLAUDE.md, manifests, etc.)
#
# Input JSON schema (Claude Code PreToolUse, via stdin):
#   {
#     "cwd": "/absolute/path/to/project",
#     "tool_name": "Read",
#     "tool_input": {
#       "file_path": "/absolute/path/to/file"
#     }
#   }
#
# Allowed patterns:
#   1. "$CWD"/.couch/* — the project's own .couch/ directory (cwd-anchored prefix).
#      This prevents bypass paths like /tmp/evil.couch/secret.txt which contain
#      ".couch/" as a substring but are NOT the project's orchestration directory.
#   2. */.claude/* — any path under a .claude/ directory. This covers:
#      - ~/.claude/teams/<req-id>/config.json (home-dir team state)
#      - ~/.claude/skills/ (installed skill files)
#      - .claude/agents/ (project-local agent definitions)
#      The home-dir path varies per machine, so broad substring matching is intentional.
#
# Fail-closed behavior:
#   - If FILE_PATH is empty or "null" (jq missing key) → exit 2 (block)
#   - If CWD is empty or "null" (cannot anchor .couch/) → exit 2 (block)
#   - Any non-matching path → exit 2 (block)
#   - Only exact matches of the allowed patterns → exit 0 (allow)

INPUT=$(cat)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd')
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path')

# Fail-closed guards: must check before case statement
[ -z "$FILE_PATH" ] || [ "$FILE_PATH" = "null" ] && exit 2
[ -z "$CWD" ] || [ "$CWD" = "null" ] && exit 2

case "$FILE_PATH" in
  "$CWD"/.couch/*|*/.claude/*) exit 0 ;;
  *) exit 2 ;;
esac
