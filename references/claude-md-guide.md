# CLAUDE.md Assessment and Generation Guide

Reference for the Couch Potato setup init phase. Read this file when evaluating whether a project has a usable CLAUDE.md and when generating one from scratch.

---

## 1. Assessment Rubric

After reading the project's `CLAUDE.md` (or `AGENTS.md`, `.claude/README.md` — check all three locations), score each category:

### Categories

| Category | What to look for | Score |
|----------|-----------------|-------|
| **Project structure** | Directory layout described, key paths named | complete / partial / minimal |
| **Build commands** | Check, lint, dev, and build commands listed | complete / partial / minimal |
| **Coding conventions** | Import order, file placement rules, naming conventions | complete / partial / minimal |
| **Tech stack** | Language, framework, package manager explicitly stated | complete / partial / minimal |
| **File placement rules** | Where to put components, stores, hooks, API calls | complete / partial / minimal |

### Score Definitions

- **complete** — The information is present and accurate. No action needed for this category.
- **partial** — Some information is present but key details are missing or outdated. Flag for user review.
- **minimal** — The category is absent or has only a passing mention. Must be filled in before Couch Potato can operate reliably.

### Overall Readiness

| Result | Action |
|--------|--------|
| All 5 categories = complete | CLAUDE.md is ready. Proceed with setup. |
| 1-2 categories = partial | Patch missing sections. Present changes to user for approval. |
| Any category = minimal, or no CLAUDE.md | Generate from scratch using Section 2 template. Present to user for approval before saving. |

### CLAUDE.md Location Priority

Check in this order:
1. `CLAUDE.md` (project root)
2. `AGENTS.md` (project root)
3. `.claude/README.md`

If none exists, generate from scratch.

---

## 2. Minimal Generation Template

Use this template when generating a new CLAUDE.md. Fill every `<placeholder>` from the project scan before presenting to the user. Do not leave placeholders unfilled.

Present the generated file to the user and wait for explicit approval before writing it.

```markdown
# CLAUDE.md

## Project Overview

<One sentence describing what the project does and its primary users.>

**Tech stack**: <Language> + <Framework>
**Package manager**: <pnpm | npm | yarn | bun | pip | poetry | uv | cargo | go modules>

## Structure

```
<Paste the top-level directory tree here, 2 levels deep max.>
```

Key paths:
- `<path>` — <what it contains>
- `<path>` — <what it contains>

## Commands

```bash
<check_command>       # Type-check / test
<lint_command>        # Lint (auto-fix if available)
<dev_command>         # Start dev server (port <port>)
<build_command>       # Production build
```

## Conventions

- **Imports**: <import order or aliasing rules if detected>
- **File placement**: <where to put new components, stores, API calls>
- **Naming**: <file and function naming conventions if detected>
- **i18n**: <i18n library and usage pattern if present, else "none">

## Hard Rules

- <Rule 1 inferred from existing code or config>
- <Rule 2 inferred from existing code or config>
```

### Filling Placeholders from Scan

| Placeholder | Source |
|------------|--------|
| Project description | `package.json` `description`, `README.md` first paragraph, or `pyproject.toml` `[tool.poetry] description` |
| Tech stack | Manifest + lock file scan (see `stacks.md`) |
| Directory tree | Run `ls` two levels deep from project root |
| Key paths | Identify `src/`, `app/`, `lib/`, `components/`, `api/` or equivalent |
| Commands | Read `package.json` `scripts`, `Makefile`, `justfile`, or `pyproject.toml` `[tool.taskipy]` |
| Import rules | Check `tsconfig.json` `paths`, `eslint` import order rules, existing file headers |
| File placement | Observe where existing components, hooks, and stores live |
| Naming | Observe existing file and function names (camelCase, PascalCase, snake_case) |
| i18n | Look for `i18next`, `react-i18next`, `next-intl`, `gettext`, `babel`, etc. |

---

## 3. Couch Potato Compatibility Additions

After the user approves the base CLAUDE.md, append this section. It links the project's CLAUDE.md to the Couch Potato configuration so agents can find build commands and project conventions reliably.

```markdown
## Couch Potato

This project uses Couch Potato for AI-assisted development.

- Config: `.couch/config.json` — agent settings, model selection, team composition
- Requirements: `.couch/requirements/` — one subdirectory per requirement (gitignored)
- Agent output: agents read this CLAUDE.md to understand project conventions

### Build Commands (agent-readable)

```json
{
  "check_command": "<check_command>",
  "lint_command": "<lint_command>",
  "dev_command": "<dev_command>",
  "build_command": "<build_command>"
}
```
```

### Notes on the Compatibility Section

- The JSON block under "Build Commands" is redundant with the Commands section above, but kept machine-readable so agents can parse it without interpreting prose.
- `.couch/requirements/` must be added to `.gitignore`. If not already present, add it during setup.
- `.couch/config.json` should NOT be gitignored (it contains project-level agent configuration, not secrets). API keys must never be stored in `config.json`.
- If the project already has a `.couch/config.json`, read it before appending this section to avoid duplicating fields.
