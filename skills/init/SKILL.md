---
name: couch-potato:init
description: Install the Couch Potato agent swarm into the current project. Detects environment capabilities and installs the appropriate workflow mode (team-mode or multi-agent-mode). Run once per project. If interrupted, re-run to resume.
---

# /couch-potato:init — Installation Skill

You are executing `/couch-potato:init`. Your job is to install the Couch Potato agent swarm into the user's current project. You will detect the environment, select the appropriate workflow mode, copy files from the plugin's reference tree to the project, and write `.couch/config.json`.

**Plugin root**: `${CLAUDE_PLUGIN_ROOT}` — all plugin-provided files are under this path.
**Plugin data dir**: `${CLAUDE_PLUGIN_DATA}` — user-owned, persistent across plugin updates. Never overwritten by plugin upgrades.

Do not implement beyond what is described here. If you discover a need to modify any file in `${CLAUDE_PLUGIN_ROOT}`, stop and notify the user — that directory is read-only from the skill's perspective.

---

## Step 0 — Resume Check

Before doing anything else, check whether `.couch/setup-state.json` exists in the current project.

- **If it exists**: a previous `/couch-potato:init` run was interrupted (the user was asked to upgrade Claude Code and restart). Read the file. Re-detect the current environment (Step 1). If detection now satisfies Case A or B, proceed directly to Step 3 (Install). Delete `setup-state.json` after successful completion.
- **If it does not exist**: proceed to Step 1.

**setup-state.json schema**:
```json
{
  "phase": "pre-install",
  "detected_at": "<ISO 8601 timestamp>",
  "note": "Waiting for Claude Code upgrade and restart. Re-run /couch-potato:init to continue."
}
```

---

## Step 1 — Environment Detection

Detect two things:

### 1a. Claude Code version

Run `claude --version` and parse the version string (e.g., `2.1.32`). Compare against the minimum required version for agent-teams: **v2.1.32**.

### 1b. Agent Teams flag

Check whether `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set. Look in:
1. The current shell environment (`env | grep CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`)
2. `.claude/settings.json` at key `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`
3. `.claude/settings.local.json` at key `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`

The flag is "set" if any of these sources has the value `"1"` or `1`.

Store both results and proceed to Step 2.

---

## Step 2 — Mode Selection (Three Cases)

### Case A — Version >= 2.1.32 AND agent teams flag is set

Install **team-mode** workflow. Proceed to Step 3 with `mode = "team-mode"`.

### Case B — Version >= 2.1.32 AND agent teams flag is NOT set

Prompt the user:

> Your Claude Code version supports agent teams, but the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` flag isn't enabled.
>
> Options:
> - **[Y] Enable flag**: I'll add it to `.claude/settings.json` now. No restart needed. Installs team-mode workflow (recommended — peer-to-peer agent coordination).
> - **[N] Skip flag**: Install multi-agent-mode workflow instead (hub-and-spoke; all agent communication relayed through main — higher latency, higher context usage).

- **If Y**: Write `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"` to `.claude/settings.json` (create if absent; deep-merge if present, preserving all existing keys). Then proceed to Step 3 with `mode = "team-mode"`.
- **If N**: Proceed to Step 3 with `mode = "multi-agent-mode"`. Inform the user about the limitations before proceeding (see Multi-Agent-Mode Limitations below).

### Case C — Version < 2.1.32

Detect the install method using the `which claude` path heuristic:

| Path pattern | Install method | Upgrade command |
|---|---|---|
| `~/.local/bin/claude` | Native (direct install) | `claude update` |
| `/opt/homebrew/bin/claude` or `/usr/local/bin/claude` | Homebrew | `brew upgrade claude-code` |
| Path contains `npm` or `node_modules` | npm (deprecated) | `npm update -g @anthropic-ai/claude-code` — also suggest migrating to native: `curl -fsSL https://claude.ai/install.sh \| bash` |
| WinGet-managed path on Windows | WinGet | `winget upgrade Anthropic.ClaudeCode` |
| Unknown | — | Present all options and ask user to identify |

Prompt the user:

> Agent team mode requires Claude Code v2.1.32+. Your current version is v{X}.
>
> Options:
> - **[Y] Upgrade now**: I'll show you the upgrade command. After upgrading, restart Claude Code and re-run `/couch-potato:init` — I'll resume where we left off.
> - **[N] Skip upgrade**: Install multi-agent-mode workflow instead (works on any Claude Code version).

- **If Y**:
  1. Write `.couch/setup-state.json` with schema shown in Step 0 (phase: "pre-install", detected_at: current ISO timestamp).
  2. Print the upgrade command for the detected install method (from table above).
  3. Print: "Run that command, restart Claude Code, then re-run `/couch-potato:init` — I'll resume."
  4. Stop. Do not proceed to Step 3.

- **If N**: Proceed to Step 3 with `mode = "multi-agent-mode"`. Inform the user about limitations.

### Multi-Agent-Mode Limitations

When installing multi-agent-mode, present this notice before proceeding:

> **Multi-agent-mode limitations**: In this mode, the main Claude instance relays all agent coordination. There is no peer-to-peer agent communication. This means: higher latency per task (each relay is a round-trip through main), higher main-context usage (all agent outputs accumulate), and no parallel agent threads. You can switch to team-mode later via `/couch-potato:update` if you upgrade Claude Code.

---

## Step 3 — Project Scan and Adaptation Plan

Before installing files, scan the project to build an adaptation plan. This drives config.json generation and mode-specific install decisions.

Run four parallel scans (or sequential if Agent tool is unavailable). Each scan is a focused read of project files.

### Scan A — Stack Detection
Read: `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`, `*.csproj`, lock files.
Detect: language, framework, package manager, monorepo status.
Ref: `${CLAUDE_PLUGIN_ROOT}/references/stacks.md` for heuristics.

### Scan B — Project Structure
Read: top-level directory listing (2 levels), manifest scripts sections.
Detect: check_command, lint_command, dev_command, dev_port, build_command, frontend_path.
Ref: `${CLAUDE_PLUGIN_ROOT}/references/stacks.md` Section 5 for defaults when commands can't be determined.

### Scan C — Claude Code Setup
Read: `.claude/`, `.claude/settings.json`, `.claude/settings.local.json`, `CLAUDE.md`, `AGENTS.md`.
Detect: existing settings, CLAUDE.md presence and quality assessment.
Ref: `${CLAUDE_PLUGIN_ROOT}/references/claude-md-guide.md` for the assessment rubric.

### Scan D — Existing Installation
Read: `.couch/`, `.claude/agents/`, `.claude/skills/`.
Detect: prior Couch Potato install, existing agents, codex CLI.

After all scans, compile results into an **adaptation plan** with these fields:

```json
{
  "stack_label": "string",
  "check_command": "string",
  "lint_command": "string",
  "dev_command": "string",
  "dev_port": "number",
  "build_command": "string",
  "frontend_path": "string",
  "claude_md_action": "skip | keep | patch | generate",
  "settings_target": "settings.json | settings.local.json",
  "agent_conflict_action": "none | merge | overwrite | skip | update | clean",
  "has_codex": "boolean",
  "confirmed": "boolean"
}
```

Present the plan to the user for confirmation. The user can confirm all, change individual items, or abort. Do not proceed to Step 4 if the user aborts.

---

## Step 4 — Install Files

With the confirmed adaptation plan and selected mode, install files to the project.

### 4a. Create target directories

Create if not present:
- `.claude/skills/couch-potato/`
- `.claude/skills/couch-potato/references/`
- `.claude/skills/couch-potato/references/souls/`
- `.claude/agents/`
- `.couch/requirements/`
- `.couch/retrospectives/`
- If `has_codex: true`: `.claude/skills/codex-bridge/`

### 4b. Copy mode-specific workflow files

Copy the selected mode's reference tree from `${CLAUDE_PLUGIN_ROOT}/references/<mode>/` to `.claude/skills/couch-potato/references/`:

- `${CLAUDE_PLUGIN_ROOT}/references/<mode>/workflow.md` → `.claude/skills/couch-potato/references/workflow.md`
- `${CLAUDE_PLUGIN_ROOT}/references/<mode>/protocol.md` → `.claude/skills/couch-potato/references/protocol.md`

### 4c. Copy shared references

- `${CLAUDE_PLUGIN_ROOT}/references/schemas.md` → `.claude/skills/couch-potato/references/schemas.md`

### 4d. Copy agent definitions

Copy ALL `.md` files from `${CLAUDE_PLUGIN_ROOT}/agents/` to `.claude/agents/`. If `agent_conflict_action = "merge"`, do NOT delete existing `.claude/agents/` files — only add/overwrite files present in the source. If `"overwrite"`, clear `.claude/agents/` first (after backing up).

### 4e. Generate SKILL.md from mode-specific body

Read `${CLAUDE_PLUGIN_ROOT}/references/<mode>/SKILL-body.md`. Write it verbatim to `.claude/skills/couch-potato/SKILL.md`. This file is **customizable** — if it already exists, prompt the user:

> An existing `.claude/skills/couch-potato/SKILL.md` was found. Overwrite it? [Y] Overwrite / [N] Keep existing

### 4f. Copy Codex bridge (conditional)

If `has_codex: true`, copy `${CLAUDE_PLUGIN_ROOT}/skills/codex-bridge/` to `.claude/skills/codex-bridge/`.

### 4g. Apply CLAUDE.md action

Follow the `claude_md_action` from the adaptation plan:
- `skip` or `keep`: no changes.
- `patch`: read existing CLAUDE.md, identify partial categories from Scan C assessment, generate missing sections from `${CLAUDE_PLUGIN_ROOT}/references/claude-md-guide.md` Section 2 template, present diff, write only on user approval.
- `generate`: generate complete CLAUDE.md from `${CLAUDE_PLUGIN_ROOT}/references/claude-md-guide.md` Section 2 template, present full output, write only on user approval.

After base CLAUDE.md is approved, append the Couch Potato section from `${CLAUDE_PLUGIN_ROOT}/references/claude-md-guide.md` Section 3 (skip if `## Couch Potato` heading already exists).

### 4h. Update .gitignore

Add if not already present (preceded by `# Couch Potato` comment block — skip entire append if block already exists):
```
# Couch Potato
.couch/requirements/
.couch/.staging/
```

Never remove or modify existing entries.

---

## Step 5 — SOUL Persistence

After files are installed, initialize the user's SOUL data directory.

**Rule**: if `${CLAUDE_PLUGIN_DATA}/souls/` already exists, do NOT overwrite any files in it. The user may have customized them.

**If `${CLAUDE_PLUGIN_DATA}/souls/` does NOT exist**:
Copy ALL `.md` files from `${CLAUDE_PLUGIN_ROOT}/references/<mode>/souls/` to `${CLAUDE_PLUGIN_DATA}/souls/`. This creates the user's editable copy of the SOULs.

This covers both modes:
- **team-mode**: copies architect, coder, tester, researcher, challenger, retrospective soul files.
- **multi-agent-mode**: copies the same files PLUS `team-lead.md` (the relay-focused Team Lead SOUL variant specific to multi-agent-mode).

Copy ALL `.md` files present — do not hardcode a list. Use glob `${CLAUDE_PLUGIN_ROOT}/references/<mode>/souls/*.md`.

---

## Step 6 — Write .couch/config.json

Write (or update) `.couch/config.json` with the following structure. If a `config.json` already exists and `agent_conflict_action = "merge"`, read existing values first and only fill missing fields from the plan.

```json
{
  "version": "3.2.0",
  "mode": "<mode>",
  "skill": "couch-potato",
  "stack": "<plan.stack_label — omit if not detected>",
  "server_ports": { "dev": "<plan.dev_port — omit if no dev server>" },
  "project_path": ".",
  "frontend_path": "<plan.frontend_path — omit if not detected or equals '.'> ",
  "check_command": "<plan.check_command>",
  "lint_command": "<plan.lint_command>",
  "build_command": "<plan.build_command>",
  "dev_command": "<plan.dev_command>",
  "policy": {
    "enable_fast_track": true,
    "review_prompt_required": true,
    "model_resolution_priority": ["user_override", "complexity_rule", "task_model", "agent_default"],
    "default_requires_verification_by_type": {
      "code": true,
      "refactor": true,
      "i18n": false,
      "style": false,
      "test": false
    }
  }
}
```

**Required fields from task-002 schema contract** (exact field names — tasks 008 and 009 share this contract):
- `"mode"`: string, one of `"team-mode"` or `"multi-agent-mode"` — records which workflow was installed
- `"version"`: string, semver — records the plugin version installed (`"3.2.0"` for this release)
- `"mode_switch_offered"`: boolean — NOT written by init; this field is written by the update skill (Case B) after it has offered a mode switch once. Init does not set it.

---

## Step 7 — Post-install Verification

Verify installation is complete:

1. `.claude/skills/couch-potato/SKILL.md` — must exist
2. `.claude/skills/couch-potato/references/workflow.md` — must exist
3. `.claude/skills/couch-potato/references/protocol.md` — must exist
4. `.claude/skills/couch-potato/references/schemas.md` — must exist
5. `.claude/agents/*.md` — must contain at least 5 files (architect, researcher, coder, tester, retrospective)
6. `.couch/config.json` — must exist and parse as valid JSON
7. `.couch/requirements/` — must exist as a directory
8. `.couch/retrospectives/` — must exist as a directory
9. If codex bridge installed: `.claude/skills/codex-bridge/SKILL.md` — must exist

If verification passes, proceed to Step 8.

If verification fails, report the specific failures and offer:
> [R] Retry verification | [F] Fix manually | [B] Rollback

---

## Step 8 — Cleanup and Handoff

1. Delete `.couch/setup-state.json` if it exists (successful completion).
2. Delete `.couch/.staging/` if it exists.
3. Present final message:

```
Couch Potato installed successfully.

Mode: <team-mode | multi-agent-mode>

Written files:
- .claude/skills/couch-potato/   (skill + references)
- .claude/agents/                (agent definitions)
- .couch/config.json             (project configuration)
- .couch/requirements/           (created, gitignored)
- .couch/retrospectives/         (created)
[if codex] - .claude/skills/codex-bridge/

SOULs define each agent's cognitive style — how they think, communicate, and make decisions.
Your customizable soul copies are at: ${CLAUDE_PLUGIN_DATA}/souls/

[if team-mode] Use /couch-potato to start your first requirement.
[if multi-agent-mode] Use /couch-potato to start your first requirement.
Note: you are running in multi-agent-mode. All agent coordination is relayed through main.
If you later upgrade Claude Code to v2.1.32+, run /couch-potato:update to switch to team-mode.

Please exit Claude Code and re-enter to pick up new settings.
```

---

## Error Handling

- **Phase 3 scan failure**: if a scan subagent fails, fall back to sequential scanning. If all scans fail, ask the user to fill in the adaptation plan manually (present empty template).
- **File write failure**: rollback written files. Remove any partial installs. Restore from backup if available. Report what failed.
- **User abort at any point**: stop immediately. Write no files (except any already completed before the abort point). Confirm to user that nothing was changed.
- **setup-state.json write failure**: do not exit. Warn the user that resume-after-restart won't work, and ask them to note the upgrade command manually.

---

## Language Routing

- **User-facing text**: match the user's language (detect from their messages or system locale). Default to English if unclear.
- **Internal operations**: all file paths, JSON keys, variable names remain in English.
- **Technical terms** (file paths, commands, version strings): always verbatim, never translated.
