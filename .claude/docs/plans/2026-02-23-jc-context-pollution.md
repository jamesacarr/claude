---
created: 2026-02-23T18:37:54Z
updated: 2026-02-24T17:25:36Z
status: draft
feature: JC Plugin - Reduce Context Pollution (verify-completion + status)
---

# JC Plugin: Reduce Context Pollution — Implementation Plan

## Resume Protocol

1. Read this plan from the top — skim the steps checklist to find the first `- [ ]`
2. Read the files listed in the step's **Pre-read** section
3. Execute the step using `/jc:author-skill`
4. Mark the step `- [x]` in this file
5. Stage and commit both the work **and** this updated plan in one commit
6. Repeat — or stop at any step boundary when context is getting full

**When pausing:** The last commit always contains the current progress state. To resume in a new session, just read this file and continue from the first unchecked step.

## Mandatory Tooling

- **All skill editing** MUST use `/jc:author-skill`. Do NOT write skill files directly.

## Commit Convention

[Conventional Commits](https://www.conventionalcommits.org/) with scope `jc`:

| Type | Use |
|------|-----|
| `refactor(jc)` | Skill changes |
| `docs(jc)` | Plan file updates |
| `chore(jc)` | Smoke tests, validation |

## Problem

Two skills run all their work inline in the main context:

| Skill | Pollution Source | Severity |
|-------|-----------------|----------|
| **verify-completion** | Runs all evidence collection (test suites, commands, file checks) directly in main context | High |
| **status** | Directory scanning, frontmatter parsing, git staleness checks all run inline | Medium |

## Approach

Delegate the work to a generic agent via the Task tool. The agent does all the heavy lifting and returns a compact structured result. Main context sees only the summary.

No existing agents are modified. No new agents are created. The skills spawn generic (`general-purpose`) agents with inline prompts.

---

## Steps

### Step 1: Commit plan

- [x] Commit this plan file to git.

  Commit: `docs(jc): add context pollution reduction plan`

---

### Step 2: Refactor verify-completion skill — delegate evidence collection

- [x] Modify `skills/verify-completion/SKILL.md` to spawn a generic agent for evidence collection.

  **Pre-read:**
  - `plugins/jc/skills/verify-completion/SKILL.md` — current skill to modify

  **You MUST use `/jc:author-skill` to modify this skill.** Do NOT edit the file directly.

  **Current behavior:** The skill's Process (Steps 1-4) runs directly in main context — listing criteria, running tests, executing commands, inspecting files, classifying results.

  **New behavior:** Spawn a `general-purpose` agent to do evidence collection. Agent returns a structured summary. Main context only sees the summary.

  **Important:** This is self-verification ("am I done?"), NOT independent verification of another agent's work. `team-verifier` is the wrong tool — it expects plan task structure from the implement pipeline. Use a generic agent.

  **Skill flow:**
  1. Collect success criteria from the user's request or plan
  2. Spawn `general-purpose` agent with:
     - Success criteria list
     - **Full verification methodology embedded in the prompt** — the agent IS the one "running it itself," so it must carry the complete methodology: evidence over confidence, verify every criterion, flag unverifiable, anti-patterns (no "looks good" without proof, no skipping criteria). Do NOT reference the skill's methodology section — inline the principles into the agent prompt
     - Instruction: return a structured result in this exact format:
       ```
       ## Result
       PASS | PARTIAL | FAIL

       ## Summary
       {n}/{total} criteria verified

       ## Criteria
       | Criterion | Status | Evidence |
       |-----------|--------|----------|
       | {text} | VERIFIED / PARTIALLY VERIFIED / UNVERIFIED / FAILED | {1-line evidence} |
       ```
  3. Parse agent result
  4. Present the agent's table to the user as-is
  5. If FAILED: no raw test output — the table's Evidence column is sufficient

  **Unchanged:** Methodology principles, anti-patterns, classification logic (VERIFIED / PARTIALLY VERIFIED / UNVERIFIED / FAILED). What changes is where they run, not what they are.

  Commit: `refactor(jc): delegate verify-completion evidence collection to agent`

---

### Step 3: Test verify-completion skill

- [ ] Run `/jc:verify-completion` on completed work.

  **Pre-read:**
  - `plugins/jc/skills/verify-completion/SKILL.md`

  **Verify:**
  - Main context shows only the structured summary table
  - No raw test output or command output in main context
  - PASS/PARTIAL/FAIL classification is accurate
  - Every criterion from the plan has an entry (none silently skipped)
  - UNVERIFIED criteria are flagged with reason

  If issues found, fix via `/jc:author-skill`.

  Commit: `chore(jc): validate verify-completion delegation`

---

### Step 4: Refactor status skill — delegate scanning

- [x] Modify `skills/status/SKILL.md` to spawn a generic agent for directory scanning.

  **Pre-read:**
  - `plugins/jc/skills/status/SKILL.md` — current skill to modify

  **You MUST use `/jc:author-skill` to modify this skill.** Do NOT edit the file directly.

  **Current behavior:** The skill's Process (Steps 1-4) runs directly in main context — listing directories, parsing frontmatter, running git commands, formatting the report.

  **New behavior:** Spawn a `general-purpose` agent that does all the scanning and returns the formatted report. Main context presents it as-is.

  **Skill flow:**
  1. Spawn `general-purpose` agent with the full scanning instructions from the current Process section (Steps 1-3). The agent prompt must include:
     - Directory scanning logic (`.planning/` structure)
     - Phase detection table (how to determine phase from directory contents)
     - PLAN.md frontmatter fields to extract (status, wave progress, task counts, pause reason)
     - Codebase map health check (6 expected files)
     - Map staleness calculation (two-step git log — no variable interpolation)
     - Report format (current Step 4 format)
     - **"NEVER modify any file"** — the read-only absolute must carry into the agent prompt
  2. Present the agent's report to the user as-is

  **Unchanged:** Read-only constraint, report format, all information currently reported. The agent produces the exact same output the skill currently produces inline.

  Commit: `refactor(jc): delegate status scanning to agent`

---

### Step 5: Test status skill

- [ ] Run `/jc:status` with multiple task directories in `.planning/`.

  **Pre-read:**
  - `plugins/jc/skills/status/SKILL.md`

  **Verify:**
  - Main context shows only the compact report (no intermediate tool calls visible)
  - Codebase map staleness is calculated correctly
  - All task directories are reported with correct phase
  - Verification and review report existence is noted
  - No files in `.planning/` were modified

  If issues found, fix via `/jc:author-skill`.

  Commit: `chore(jc): validate status delegation`

---

## Impact Assessment

| Component | Change | Risk |
|-----------|--------|------|
| `verify-completion` skill | Wrap evidence collection in generic agent spawn | Low — methodology unchanged, just runs in a subagent |
| `status` skill | Wrap scanning in generic agent spawn | Low — read-only, no state changes |
| Existing agents | No changes | None |
| Implement skill | No changes | None |
| Team-leader / Agent Teams | No changes | None |

## Context Pollution: Before vs After

| Scenario | Before | After |
|----------|--------|-------|
| `/jc:verify-completion`, 5 criteria | Full test output + 5 evidence-gathering tool calls inline | 1 summary table |
| `/jc:status`, 3 tasks | Directory listing + 3 frontmatter parses + 2 git commands inline | 1 compact report |
