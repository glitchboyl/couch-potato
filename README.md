# Couch Potato

A self-organizing agent swarm for [Claude Code](https://claude.com/claude-code). You describe what you want built — the swarm handles planning, implementation, testing, and review.

## What it does

Couch Potato adds a **Team Lead** skill and 5 specialized agents to your project:

| Agent | Role |
|-------|------|
| **Architect** | Analyzes codebase, plans task breakdowns, reviews results |
| **Coder** | Claims tasks, implements code, self-verifies |
| **Tester** | Verifies changes with evidence, challenges assumptions |
| **Researcher** | Finds docs, evaluates source trustworthiness |
| **Retrospective** | Post-run analysis, proposes system improvements |

The Team Lead orchestrates everything. You talk to the Team Lead; it spawns and coordinates the agents.

Each agent has a **SOUL** — a cognitive style definition that shapes how it thinks, what it prioritizes, and what it deliberately ignores. SOULs create genuine functional complementarity, not just role labels.

## How it works

```
You: "Add dark mode support"
         │
    ┌────▼────┐
    │Team Lead│  ← understands goal, builds team
    └────┬────┘
         │
    ┌────▼─────┐     ┌──────────┐
    │ Architect │────▶│ tasks.json│  ← plans tasks, maps dependencies
    └────┬─────┘     └──────────┘
         │
    ┌────▼────┐  ┌────────┐  ┌────────┐
    │ Coder 1 │  │Coder 2 │  │ Tester │  ← parallel execution
    └─────────┘  └────────┘  └────────┘
```

**Workflow**: Understand → Plan → Approve → Execute → Review → Complete

- Sequential gates with user approval at each phase
- Wave-based parallel execution with file ownership
- Built-in feedback loops (Correction Mode, Retrospective Agent)
- Cross-run learning via proposals log

## Install

### Workflow modes

Couch Potato installs in one of two modes depending on your environment:

**Team-mode** (recommended): agents communicate directly peer-to-peer using Claude Code's native agent teams feature. Requires Claude Code **v2.1.32+** with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set (in your environment or `.claude/settings.json`).

**Multi-agent-mode** (fallback): works on any Claude Code version. The main instance (Team Lead) is the sole orchestrator — all agent-to-agent discussion is relayed through main. No peer-to-peer agent threads; no parallel agent communication. Higher latency and higher main context usage than team-mode. The `/couch-potato:init` skill detects your environment and installs the right mode automatically.

### Persistent install (recommended)

Step 1 — Add the marketplace:

```bash
claude plugin marketplace add glitchboyl/couch-potato-setup
```

Or from a local clone:

```bash
claude plugin marketplace add ./couch-potato-setup
```

Step 2 — Install the plugin:

```bash
claude plugin install couch-potato@couch-potato-setup
```

No restart required after install. Run `/reload-plugins` in an active session to activate.

Step 3 — Run the init skill in your project:

```
/couch-potato:init
```

The init skill detects your environment (Claude Code version, agent teams flag), selects team-mode or multi-agent-mode, and installs workflow files, agent definitions, and config.

### Dev / session-scoped use

To load the plugin for a single session without installing:

```bash
claude --plugin-dir /path/to/couch-potato-setup
```

Then run `/couch-potato:init` in that session.

### Migrating from v3.1.0 (skill format)

If you installed Couch Potato v3.1.0 using the legacy skill format (`Read setup.md and follow it`), auto-migration to the plugin format (v3.2.0+) is **not supported** in this release. See `docs/plugin-migration-design.md` for the migration design. Manual steps: uninstall the old skill files from `.claude/skills/couch-potato/` and re-run the plugin install flow above.

### Installing v3.1.0 (legacy skill format)

> This is the legacy install path. Use the plugin install above for new installs.

1. Clone this repo somewhere accessible:
   ```bash
   git clone https://github.com/glitchboyl/couch-potato-setup.git
   ```

2. In your project, open Claude Code and say:
   ```
   Read ~/path/to/couch-potato-setup/setup.md and follow it
   ```

3. The installer will:
   - Auto-detect your tech stack, framework, and commands
   - Present an adaptation plan for your confirmation
   - Install skill files, agent definitions, and config
   - Optionally generate or patch your CLAUDE.md

4. Restart Claude Code to pick up new settings.

#### Manual setup (v3.1.0)

If auto-detection doesn't fit your project, ask for manual setup — you'll fill in the config values directly.

## Usage

After installation, invoke the swarm:

```
/couch-potato
```

Then describe what you want. The Team Lead handles the rest.

## What gets installed

```
.claude/
├── skills/couch-potato/       # Skill definition + references
│   ├── SKILL.md               # Team Lead instructions
│   └── references/
│       ├── workflow.md         # Phase gates
│       ├── protocol.md        # Spawn rules, initialization
│       ├── schemas.md          # Data contracts
│       └── souls/              # Agent cognitive styles
├── agents/                    # Agent definitions (5 files)
└── settings.json              # Agent Teams enabled

.couch/
├── config.json                # Project config (committed)
├── proposals_log.json         # Cross-run improvement tracking
├── retrospectives/            # Post-run analysis (committed)
└── requirements/              # Per-requirement state (gitignored)
```

## Supported stacks

Auto-detection works for:

- **Node.js** — Next.js, Nuxt, Angular, Vue, Svelte, Remix, Astro, Express, Fastify, Hono, NestJS
- **Python** — Django, Flask, FastAPI, Starlette
- **Go** — Gin, Echo, Fiber, Chi
- **Rust** — Actix Web, Axum, Rocket, Warp
- **Java/Kotlin** — Spring Boot, Quarkus, Micronaut
- **.NET** — ASP.NET Core

Monorepo detection: Turborepo, Nx, Lerna, pnpm/npm/yarn workspaces.

For unsupported stacks, use manual setup.

## Customization

- **SOULs** — Edit files in `.claude/skills/couch-potato/references/souls/` to change how agents think
- **Config** — Edit `.couch/config.json` to adjust policies (fast-track, verification defaults, model selection)
- **Agent definitions** — Edit files in `.claude/agents/` to change tool access or model defaults

## Design principles

1. **Conditions over counters** — Loops exit when the goal is met, not after N rounds
2. **Failure is input** — Error output drives the next attempt, not blind retries
3. **Think Failure First** — Verify assumptions before building
4. **Constraints > instructions** — Hard rules enforced by tooling where possible
5. **Improve the system** — Retrospective Agent identifies patterns and proposes specific changes

## Versioning

The `VERSION` file at the repo root holds the current release version. `CHANGELOG.md` tracks all notable changes per version. This project follows [Semantic Versioning](https://semver.org/). Releases are tagged `vX.Y.Z` in git.

## License

MIT
