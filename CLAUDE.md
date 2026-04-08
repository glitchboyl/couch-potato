# CLAUDE.md

## Project Overview

Couch Potato Claude Code plugin — dual-workflow agent swarm (team-mode + multi-agent-mode) with `/couch-potato:init` and `/couch-potato:update` commands.

**Tech stack**: Markdown + JSON (documentation/template repository)
**Package manager**: N/A

## Structure

```
.
├── .claude-plugin/             # Plugin manifest + marketplace
│   ├── plugin.json
│   └── marketplace.json
├── skills/                     # /couch-potato:init + /couch-potato:update
├── hooks/                      # SessionStart + PreToolUse hooks
├── agents/                     # Agent definitions (architect, coder, ...)
├── references/                 # Workflow docs + mode variants + schemas
│   ├── team-mode/
│   ├── multi-agent-mode/
│   ├── schemas.md
│   ├── stacks.md
│   ├── claude-md-guide.md
│   └── config.schema.json
└── docs/                       # Design docs
```

Key paths:
- `.claude-plugin/plugin.json` — plugin manifest
- `skills/init/SKILL.md` — `/couch-potato:init` entry point
- `skills/update/SKILL.md` — `/couch-potato:update` entry point
- `references/team-mode/`, `references/multi-agent-mode/` — mode-specific workflow content

## Commands

```bash
# No build/dev/lint commands — this is a documentation package
```

## Conventions

- **Imports**: N/A
- **File placement**: Plugin components at repo root (`skills/`, `hooks/`, `agents/`, `references/`); only `plugin.json` + `marketplace.json` live in `.claude-plugin/`
- **Naming**: kebab-case for directories, lowercase for files
- **i18n**: none

## Hard Rules

- Template files are copied verbatim — placeholders like `<req-id>` are resolved at runtime by agents, not during setup
- Never store API keys in config.json

## Couch Potato

This project uses Couch Potato for AI-assisted development.

- Config: `.couch/config.json` — agent settings, model selection, team composition
- Requirements: `.couch/requirements/` — one subdirectory per requirement (gitignored)
- Agent output: agents read this CLAUDE.md to understand project conventions

### Build Commands (agent-readable)

```json
{
  "check_command": null,
  "lint_command": null,
  "dev_command": null,
  "build_command": null
}
```
