# Shared Schemas

These are contracts between Team Lead and agents. Agents should read this file when producing structured output.

## tasks.json (written by Architect, read by Team Lead)

```json
{
  "requirement_id": "<req-id>",
  "title": "<requirement title>",
  "understanding_summary": "<1-3 sentence summary for human review>",
  "status": "planned",
  "created_at": "<ISO>",
  "execution_plan": {
    "waves": [
      {
        "wave_id": 1,
        "task_ids": ["task-001"],
        "strategy": "sequential | parallel",
        "rationale": "<why this strategy>"
      }
    ]
  },
  "file_ownership": {
    "path/to/file.ts": ["task-001"]
  },
  "tasks": [
    {
      "id": "task-001",
      "title": "Short descriptive title",
      "description": "Detailed description",
      "type": "code | refactor | i18n | style | test",
      "owner_role": "coder",
      "depends_on": [],
      "complexity": "S | M | L",
      "model": "<requested model — see resolution rules below>",
      "files": ["path/to/file.ts"],
      "requires_verification": true,
      "expected_report_path": ".couch/requirements/<req-id>/test-reports/task-001.json",
      "acceptance_criteria": ["Specific testable criterion"],
      "verification": null
    }
  ]
}
```

`model`: requested model. Free-form string (current valid values: `sonnet`, `opus`). Team Lead resolves at spawn time per `config.json` `policy.model_resolution_priority`.
`owner_role`: agent role responsible. Default `coder`.
`requires_verification`: defaults by task type defined in `config.json` `policy.default_requires_verification_by_type`.
`expected_report_path`: populated by Architect. Points to the machine-readable verification JSON. Team Lead reads this path for wave exit checks — use `expected_report_path` from each task rather than scanning the directory. See workflow.md Wave Exit Checklist for the full procedure.
`verification`: `null` until Tester writes `.couch/requirements/<req-id>/test-reports/<task-id>.json`. Team Lead reads this JSON (not the markdown) for wave advancement decisions. See workflow.md Wave Exit Checklist for the full procedure.

### Validation rules (checked by Team Lead)

- Has `execution_plan.waves`, `file_ownership`, `tasks[]`
- No file conflicts in parallel waves
- No dangling `depends_on` references
- Tasks within the same parallel wave must not depend on each other
- All wave task IDs exist in tasks array
- `file_ownership` is a reverse index derived from each task's `files` array — every entry must correspond to that task's own `files`. Architect generates it for conflict checking; task `files` is the single source of truth
- Tasks with `requires_verification: true` must have acceptance criteria specific enough for Tester to verify

---

## requirement.md (written by Architect, read by Team Lead + Coder)

Location: `.couch/requirements/<req-id>/requirement.md`

Structure:
```
# Requirement: <title>

## Context
Why this work is needed. Background and motivation.

## Scope
### In scope
- ...
### Out of scope
- ...

## Acceptance Criteria
1. Specific, testable criterion
2. ...

## Assumptions
- What is assumed true but not verified
```

---

## SOUL File (written by human or Retrospective Agent, read by Team Lead at spawn)

Location: `.claude/skills/couch-potato/references/souls/<role>.md`

Structure:
```
## SOUL: [Name]
[One-sentence cognitive stance]

## What I attend to
## What I deprioritize
## In conflict
## Failure modes to avoid
```

SOUL types:
- **Permanent agent SOULs**: architect, coder, tester, researcher, retrospective — attached to permanent agent definitions
- **Temporary discussion SOULs**: challenger — used when Team Lead spawns temporary discussion agents

---

## Retrospective Report (written by Retrospective Agent, read by Team Lead)

Location: `.couch/retrospectives/<req-id>.md`

Structure:
```
# Retrospective: <req-id>

## Summary
One-paragraph assessment: what went well, what had friction, overall quality.

## Friction Analysis
For each friction point:
- **What happened**: <observation>
- **Classification**: systemic | exploratory
- **Root cause**: <why — name the system gap, not the agent>
- **Root cause file**: <which definition/SOUL was responsible>

## Tool Usage
- Did agents use their primary tools before forming conclusions?
- Were there instances of training-data reliance where docs should have been checked?

## SOUL Health
- Are SOULs producing genuinely different attention patterns?
- Convergence check: could you swap two SOULs' Thinking Patterns without changing output?

## Patterns Observed
Cross-reference with past retrospectives. First occurrence = note. Second occurrence = proposal.

## Improvement Proposals
Only if pattern occurs 2+ times across runs:
- **Target file**: <.claude/agents/*.md OR references/souls/*.md OR SKILL.md>
- **Section**: <specific section>
- **Current text**: <what's there now>
- **Proposed text**: <specific replacement>
- **Rationale**: <why, referencing the pattern across runs>

## Clean Run Notes
If no systemic issues: what worked well and what patterns to preserve.
```

---

## run.json (written by Team Lead, read by Team Lead)

Location: `.couch/requirements/<req-id>/run.json`

```json
{
  "requirement_id": "<req-id>",
  "phase": "understand | plan | approve | execute | review | complete",
  "understanding_confirmed": false,
  "plan_approved": false,
  "review_offered": false,
  "review_decision": null,
  "amendments": [],
  "escalations": []
}
```

Team Lead creates this at initialization and updates it at each phase gate. If Team Lead is unsure what phase the run is in, read this file.

---

## verification.json (written by Tester, read by Team Lead)

Location: `.couch/requirements/<req-id>/test-reports/<task-id>.json`

```json
{
  "task_id": "<task-id>",
  "status": "PASS | FAIL | BLOCKED",
  "verified_at": "<ISO>"
}
```

Tester writes this alongside the markdown report. Team Lead reads this file for wave advancement decisions — do not parse `## Status` from the markdown.

---

## Test Report (written by Tester, read by Coder + Team Lead)

Location: `.couch/requirements/<req-id>/test-reports/<task-id>.md`

Structure:
```
# Test Report: <task-id>

## Status: PASS | FAIL | BLOCKED

## Summary
One-paragraph assessment of what was tested and the outcome.

## Evidence
Screenshots, command output, or other proof of verification.

## Issues
For each issue found:
- **Severity**: critical | major | minor
- **Description**: what is wrong
- **Expected**: what should happen
- **Actual**: what happens instead
- **Reproduction**: steps to reproduce
```
