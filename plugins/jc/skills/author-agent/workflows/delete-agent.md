# Delete Agent

> Delete or deprecate an existing agent, checking for dependents and cleaning up references.

## Goal

Safely remove or deprecate an agent while preserving referential integrity across the agents directory.

## Prerequisites

None.

## Steps

### Step 1: Select the Agent (Main)

If not already specified, list available agents:
```bash
ls {agents-dir}/*.md 2>/dev/null
```

`{agents-dir}` was resolved during path resolution — see SKILL.md.

Present numbered list, ask: "Which agent should be deleted or deprecated?"

### Step 2: Read and Assess (Main)

Read the agent file. Determine:
- **Is it actively referenced?** Check if skills, other agents, or orchestration workflows reference it by name.
- **Is it a dedicated `subagent_type`?** Search for `subagent_type.*{name}` in the codebase — direct invocations will break.
- **Is it a team member?** Check if any team leader agent or skill spawns it with `team_name`. Breaking team composition may affect workflows.
- **Is it redundant?** Another agent covers the same ground.
- **Is it stale?** Content no longer applies (retired workflow, replaced by built-in agent).

Report findings and confirm intent: "Delete permanently or deprecate (rename to mark inactive)?"

### Step 3: Check for Dependents (Main)

Search for references:
- Pattern: `{agent-name}`
- Paths: `{agents-dir}/`, skills directory, project root (for orchestration scripts)
- Glob: `*.md`

If other files reference this agent: list them and ask whether to update or remove those references.

For team agents, also check:
- Team config files that may list this agent
- Skills that spawn this agent as a teammate

### Step 4: Execute (Main)

**Delete permanently:**
```bash
rm {agents-dir}/{agent-name}.md
```

**Deprecate (soft removal):**
Rename file to signal inactive status:
```bash
mv {agents-dir}/{agent-name}.md {agents-dir}/_deprecated-{agent-name}.md
```
Prepend to description: `"DEPRECATED: "` — this prevents matching during automatic routing.

### Step 5: Cache Invalidation

Agents are cached during sessions (Essential Principle #5). After deletion:
- The deleted agent may still be invocable in the current session
- Inform user: "Restart your Claude Code session to fully clear the cached agent"

### Step 6: Clean Up References (Main)

Remove or update any cross-references found in Step 3.

## Validation

Search for the deleted agent name across `{agents-dir}/` and the skills directory — zero matches expected (excluding deprecation markers).

## Rollback

- **Deleted permanently:** Restore from git (`git checkout -- {agents-dir}/{agent-name}.md`).
- **Deprecated:** Rename back and remove the `DEPRECATED:` prefix from the description.
