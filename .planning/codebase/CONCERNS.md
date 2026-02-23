# Concerns

> Last mapped: 2026-02-23T16:43:10Z

## Tech Debt

| Area | Description | Files | Severity |
|------|------------|-------|----------|
| Incomplete integration testing | Steps 26-33 in the implementation plan are unchecked — the E2E workflow, pause/resume, failure handling, critique loop, wave review, status/cleanup, debug, and team leader flows have never been validated end-to-end | `.claude/docs/plans/2026-02-21-jc-agents-skills.md` (lines 222-244) | high |
| Agent Teams experimental dependency | The Team Leader agent relies on `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. If this feature changes or is removed, the entire Agent Team coordination model breaks. The skills workflow is the fallback but the team-leader agent would need significant rework | `plugins/jc/agents/team-leader.md` | high |
| Git pathspec bug pattern | A bug was found and fixed where `-- ':!.planning/'` without a leading `. ` always returns 0 commits, making staleness checks silently wrong. The fix was applied to the plan skill, status skill, and team leader — but any new code that copies the old pattern will reintroduce this | `plugins/jc/skills/plan/SKILL.md` (line 54), `plugins/jc/skills/status/SKILL.md` (line 43), `plugins/jc/agents/team-leader.md` (line 181) | medium |
| Worktree cwd propagation unvalidated | The design assumes teammates spawned after `EnterWorktree` inherit the lead's cwd. This has not been validated (deferred to Step 33). If it does not hold, execution teammates would operate in the wrong directory | `plugins/jc/agents/team-leader.md` (lines 125, 269-276), `.claude/docs/plans/2026-02-21-jc-agents-skills.md` (line 968) | medium |
| Hardcoded staleness threshold | The 50-commit threshold for codebase map staleness is an arbitrary heuristic. No mechanism exists to tune it per-project. Repos with high commit velocity will trigger constant regeneration prompts; slow repos will drift silently | `plugins/jc/skills/plan/SKILL.md` (lines 42-57), `plugins/jc/agents/team-leader.md` (line 181) | low |
| Plugin version at 0.0.1 | Version has not been bumped since initial creation despite 23+ feature steps completed. No versioning strategy or changelog exists | `plugins/jc/.claude-plugin/plugin.json` (line 4) | low |

## Known Pitfalls

- **Systematic failure detection is fuzzy** — The team leader's detection of "same root cause across tasks" is a general instruction, not a precise algorithm. Risk of false positives (pausing for unrelated failures) and false negatives (missing real patterns). Affects: `plugins/jc/agents/team-leader.md` (lines 147-150, 253-257). Mitigation: keep expectations realistic; treat this as a hint mechanism, not a reliable detector. Needs calibration from real-world runs (Step 33)
- **Error cascade from poor research** — If a researcher produces low-quality output, it propagates through planner to executor. The research gate in `plugins/jc/skills/plan/SKILL.md` checks file presence only, not content quality. Mitigation: the critique loop catches some issues, but garbage-in-garbage-out remains a risk. Watch for plans with vague Action fields — that is the symptom
- **PLAN.md crash mid-write** — If the implement skill crashes while updating PLAN.md frontmatter, the document could be in an inconsistent state. Affects: `plugins/jc/skills/implement/SKILL.md`. Mitigation: the resume flow in Step 1b (RECOVER) treats `in_progress` tasks without verification reports as needing re-verification, not re-execution. This is defensive but not bulletproof — a corrupted frontmatter section would break parsing entirely
- **Worktree resume requires user action** — When a session dies mid-implementation, the new session starts in the main tree. The implement skill cannot programmatically switch into an existing worktree — it must prompt the user to `claude --cwd {path}`. Affects: `plugins/jc/skills/implement/SKILL.md` (Step 1a, ROUTE). Mitigation: clear user prompt with exact command. UX friction is unavoidable with current tooling
- **Collaborative planning may rubber-stamp or deadlock** — Two planner teammates (Author + Critic) may agree too easily or get stuck on subjective differences. The 3-round cap with user escalation prevents infinite loops but does not guarantee quality. Affects: `plugins/jc/agents/team-planner.md` (Agent Team Behavior section). Mitigation: real-world testing in Step 33 will calibrate

## Fragile Areas

- **Plan schema consumers** — The plan schema (`plugins/jc/docs/plan-schema.md`) is consumed by 5 different agents/skills: implement skill, status skill, verifier agent, reviewer agent, and planner agent. Any change to field names, status values, or document structure requires updating all consumers simultaneously. Files: `plugins/jc/docs/plan-schema.md`, `plugins/jc/skills/implement/SKILL.md`, `plugins/jc/skills/status/SKILL.md`, `plugins/jc/agents/team-verifier.md`, `plugins/jc/agents/team-reviewer.md`, `plugins/jc/agents/team-planner.md`
- **Agent I/O contract** — All skill-to-agent communication depends on the I/O contract format (`plugins/jc/docs/agent-io-contract.md`). Every skill that spawns agents uses this exact section structure. Changing the contract requires updating all skill prompt templates: `plugins/jc/skills/map/SKILL.md`, `plugins/jc/skills/research/SKILL.md`, `plugins/jc/skills/plan/SKILL.md`, `plugins/jc/skills/implement/SKILL.md`, `plugins/jc/skills/debug/SKILL.md`
- **Implement skill state machine** — The most complex component in the system. Multiple interleaved state transitions, retry counters, worktree management, and PLAN.md status updates. Any modification risks breaking resume/recovery. File: `plugins/jc/skills/implement/SKILL.md`

## Do Not Touch

- **PLAN.md status fields at runtime** — Only the implement skill's state machine should modify PLAN.md frontmatter and task/wave status during execution. The status skill explicitly refuses to modify state. Direct edits break resume, recovery, and retry tracking. See anti-patterns in: `plugins/jc/skills/status/SKILL.md` (lines 99-103), `plugins/jc/skills/implement/SKILL.md` (lines 229-243)
- **`.planning/codebase/` from cleanup** — The cleanup skill must never list, offer, or remove codebase map files. This is a hard constraint in: `plugins/jc/skills/cleanup/SKILL.md` (Essential Principle 2, line 12)

### Prescriptive Guidance

- **When adding a new field to PLAN.md:** Update `plugins/jc/docs/plan-schema.md` first, then grep all 5 consumers listed under Fragile Areas and update each one. Test with the status skill to confirm parsing still works
- **When modifying the agent I/O contract:** Update `plugins/jc/docs/agent-io-contract.md`, then update all skill prompt templates that spawn agents. Search for `## Task` / `## Context` / `## Input` / `## Expected Output` patterns across all SKILL.md files
- **When copying git staleness check patterns:** Always use `-- . ':!.planning/'` (with the leading dot), never `-- ':!.planning/'` alone. The pathspec without `. ` silently returns zero commits
- **When adding new skills that spawn agents:** Follow the I/O contract format exactly. Use `subagent_type` matching the agent's `name` frontmatter field. Include absolute paths for project root and planning directory
- **When modifying the implement skill:** Ensure every state transition updates PLAN.md. Test the resume path (Step 1a/1b) after changes — the state machine's crash recovery depends on status being written before advancing
- **Do not rely on Agent Teams stability:** Always ensure the skills workflow covers the same lifecycle as the team leader. The skills path is the tested, reliable fallback
