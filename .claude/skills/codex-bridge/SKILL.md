---
name: codex-bridge
description: Invoke Codex CLI for code review, analysis, challenge, or exploration. Returns a different model's (OpenAI) perspective on any codebase question.
---

# Codex

Invoke the Codex CLI (`codex`) for a different model's perspective.

## Before Using
1. Verify codex is available: `which codex`
2. If unavailable → report to requester, do not retry

## Usage

### Code Review
```bash
codex review --uncommitted
codex review --base main
codex review --commit <sha>
codex review --uncommitted "Focus on security and convention compliance"
```

### Analysis / Exploration
```bash
codex exec --sandbox read-only "<prompt describing the task>"
```

## Interpreting Output
- Codex uses a different model (OpenAI). Its perspective is genuinely different from yours.
- Where codex output disagrees with your assessment, present BOTH — don't resolve the tension, let the requester decide.
- Don't filter codex output — present it, then add your own analysis on top.
- If codex produces the same unhelpful output twice with different prompts → stop and report to requester.
