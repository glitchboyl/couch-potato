#!/bin/sh
# restrict_write_path.sh — PreToolUse hook for the Write tool
#
# Purpose: Restrict Team Lead Write access to orchestration-only paths.
#   Allowed: the project's own .couch/ directory and any .claude/ directory.
#   Blocked: all other paths (source files, manifests, etc.)
#
# Input JSON schema (Claude Code PreToolUse, via stdin):
#   {
#     "cwd": "/absolute/path/to/project",
#     "tool_name": "Write",
#     "tool_input": {
#       "file_path": "/absolute/path/to/file",
#       "content": "..."
#     }
#   }
#
# Matching strategy:
#   - .couch/ is cwd-anchored: only "$CWD"/.couch/* is allowed, not arbitrary paths
#     containing ".couch/" as a substring (prevents /tmp/evil.couch/x.sh bypass).
#   - .claude/ is broadly matched: */.claude/* covers ~/.claude/teams/, project-local
#     .claude/, and any other .claude/ directory. The home-dir path varies per machine
#     so broad matching is intentional and safe — all .claude/ paths are approved.
#
# Fail-closed behavior:
#   - If FILE_PATH is empty or "null" (jq missing key) → exit 2 (block)
#   - If CWD is empty or "null" (cannot anchor) → exit 2 (block)
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
