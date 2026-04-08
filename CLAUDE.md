# CLAUDE.md

## Project Overview

Couch Potato setup package — contains templates, agent definitions, and reference docs for installing the Couch Potato agent swarm into projects.

**Tech stack**: Markdown + JSON (documentation/template repository)
**Package manager**: N/A

## Structure

```
.
├── setup.md                    # Setup entry point
├── references/                 # Setup flow documentation
│   ├── init-flow.md
│   ├── install-flow.md
│   ├── stacks.md
│   └── claude-md-guide.md
└── templates/                  # Files copied during installation
    ├── config.schema.json
    ├── agents/
    ├── skill/
    └── skills/codex-bridge/
```

Key paths:
- `setup.md` — main entry point for AI-driven setup
- `references/` — detailed flow instructions for init and install phases
- `templates/` — all files that get copied into target projects

## Commands

```bash
# No build/dev/lint commands — this is a documentation package
```

## Conventions

- **Imports**: N/A
- **File placement**: Templates go in `templates/`, reference docs in `references/`
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
