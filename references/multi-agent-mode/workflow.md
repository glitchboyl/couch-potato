# Couch Potato — Multi-Agent-Mode Workflow Reference

Part of the Couch Potato skill definition. See SKILL-body.md for the Team Lead operational manual.

---

## Limitations

**Read this before using multi-agent-mode.**

Multi-agent-mode uses a hub-and-spoke architecture: the main Claude instance (Team Lead) is the sole orchestrator. All agent-to-agent discussion is relayed through main. This means:

- **No peer-to-peer communication.** Agents cannot message each other directly. Every question, response, and result passes through Team Lead.
- **No parallel agent threads.** Agents run as one-shot subagents — spawned, completed, and terminated. They do not persist between invocations.
- **Higher latency.** Each agent invocation is sequential. Parallel execution waves run agents in sequence, not concurrently.
- **Higher main context usage.** All agent results land in the Team Lead context window. Long runs will consume context faster than team-mode.
- **No idle-agent reuse.** There is no agent registry. Every invocation spawns a fresh subagent with its own context.

If your environment supports agent teams (Claude Code v2.1.32+, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), prefer team-mode. Run `/couch-potato:init` and choose team-mode for better coordination.

---

## Workflow

These are sequential gates — what happens between them is agent judgment.

**Understand** — Your first reading is a hypothesis, not a conclusion.

Explore: keep asking user until ~90% understood. Route by type:
- Code-touching requirement → spawn Architect (one-shot subagent) for codebase context before presenting understanding to user. Read the result and synthesize before presenting. Discuss with user to clarify scope, constraints, desired outcome.
- Non-code requirement (external integration, process, config-only) → discuss with user directly. Spawn Architect only if structural questions arise.
- If stuck after multiple rounds → spawn additional one-shot subagents: Researcher for external unknowns. For discussions needing model diversity, spawn a temporary subagent with Challenger SOUL. If codex-bridge skill is installed, also include codex SKILL instructions.
- Spawn subagents sequentially. Read each result and incorporate before spawning the next.

Fast-track: if task is single-file, no architectural impact, and user explicitly confirms trivial → before dispatching, spawn Architect (one-shot) to assess blast radius across these factors — any "high risk" → escalate to normal Plan workflow:
- **Dependent count**: >5 files import/reference this file → high risk
- **Export surface**: >3 exports → shared module, high risk
- **File category**: shared utility, hook, store slice, layout, routing config, or provider → high risk
- **State coupling**: reads/writes Zustand stores, React Context, or global state → high risk
- **Render tree position**: layout, provider wrapper, or route-level component → high risk

Otherwise, skip Plan phase and dispatch directly to a fresh Coder subagent with: file path, acceptance criteria from user confirmation, and relevant context only. Still requires user approval of what will be done (inline, not via tasks.json). Fast-track completion: Coder result returned → read it → present to user for confirmation. No formal verification or test reports required.

Synthesize: combine user input + agent findings — weight disagreements and surprises over confirmations.

Present to user. Exit: user confirms understanding.

**Plan** — Requirement confirmed → spawn Architect (one-shot subagent) for task breakdown. Read the result: Architect produces `requirement.md` (canonical spec) and `tasks.json` (task plan). Confirm which agent roles are needed per task. Exit: both `requirement.md` and `tasks.json` received; `tasks.json` validated per references/schemas.md validation rules.

**Approve** — Present the plan to the user:
- Scope summary (1-2 sentences)
- Task list with title, description summary, and acceptance criteria for each task
- Number of execution tracks (note: in multi-agent-mode, parallel waves run sequentially)

Execution details (model assignments per task, wave strategy, file ownership) are available if the user asks — do not include by default. If the user wants to change which model handles a specific task, they can ask.

Exit: explicit user approval of the plan.

**Execute** — Create all tasks in TaskList with their dependencies. Execute waves in sequence:
1. For each task in the current wave, spawn one Coder subagent. In multi-agent-mode, spawn sequentially (one at a time) rather than concurrently. Read each result before spawning the next.
2. Pass each Coder: task description, file ownership, acceptance criteria, relevant context. Relay any escalations to the user with context and options.
3. After all Coders in the wave complete, run the Wave Exit Checklist (below) before proceeding.

Spawn support roles (Tester, Researcher) as needed — one-shot subagents, sequentially. Read each result and relay relevant findings to the next subagent's prompt.

Plan amendment — for in-execution corrections (not scope expansion):
1. Coder or Architect (via their result) identifies that the current plan needs adjustment.
2. Spawn Architect (one-shot) to produce a delta: what changes, what stays, and why.
3. Team Lead presents the delta to user for quick confirmation.
4. On approval, update TaskList and resume execution. On rejection, continue with the original plan.

### Wave Exit Checklist

Before advancing to the next wave (or exiting Execute after the final wave), verify ALL tasks in the current wave:

1. For each task in the wave:
   - If `requires_verification: true` → read the task's `expected_report_path` (a `.json` file). Must show `"status": "PASS"`.
   - If `requires_verification: false` → TaskList status `completed` is sufficient.
2. If any verified task shows `FAIL` or `BLOCKED` → do NOT advance. Present the failing report to the user and escalate.
3. If any task with `requires_verification: true` is missing its verification file → do NOT advance. The task is incomplete.
4. All tasks pass → proceed to the next wave (or exit Execute if this was the final wave).

**Review** — Ask user: "Would you like a formal review before wrapping up, or does this look good?" If review → spawn Architect (one-shot) to check against acceptance criteria. Read the result and present it to the user. Exit: review passed or user accepts as-is.

**Complete** — Present results (modified files, summaries, deviations). Remind user about `/commit`. If the run had any plan amendment, escalation, Correction Mode activation, or stagnation event (same result twice without new information), spawn Retrospective Agent (one-shot). Ask user whether to keep the session open for follow-up changes, or close it out — do not auto-close.

## Correction Mode

If user provides corrections after completion: create a new requirement (`req-<NNN>-fix-<M>`), spawn Coder (+ Tester if needed) as one-shot subagents. The fix prompt must record `parent_requirement_id: <original-req-id>`, `correction_reason`, and the `original_task_ids` being revisited. Include correction history and original context in spawn prompts. Fix, verify, present.

## Escalation

When a subagent result contains an escalation: present the situation to the user with context and options. You are a relay, not a decision-maker — the user decides.

Common triggers: agent disagreement on approach, scope change discovered mid-execution, user preference needed between viable alternatives, blocker that Researcher can't resolve.
