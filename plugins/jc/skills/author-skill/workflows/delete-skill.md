# Delete Skill

> Delete or deprecate an existing skill, checking for dependents and cleaning up references.

## Goal

Safely remove or deprecate a skill while preserving referential integrity across the skill set.

## Prerequisites

None.

## Steps

### Step 1: Select the Skill (Main)

```bash
ls {skills-dir}/
```

Present numbered list, ask: "Which skill should be deleted or deprecated?"

### Step 2: Read and Assess (Main)

Read the entire skill. Determine:
- **Is it actively used?** Check if other skills reference it via cross-references.
- **Is it project-level or global?** `.claude/skills/` (project) vs `{skills-dir}/` (global).
- **Is it redundant?** Another skill covers the same ground.
- **Is it stale?** Content no longer applies (deprecated API, retired tool).

Report findings and confirm intent: "Delete permanently or deprecate (rename to mark inactive)?"

### Step 3: Check for Dependents (Main)

Use the Grep tool to search for references across all skill contexts:
- Pattern: `{skill-name}`
- Glob: `*.md`
- Search each location separately:
  1. `{skills-dir}/` (current context)
  2. `~/.claude/skills/` (global — skip if same as current)
  3. Any plugin skills directories discovered during path resolution

If other skills reference this one: list them with their context (project/global/plugin) and ask whether to update or remove those references.

### Step 4: Execute (Main)

**Delete permanently:**
```bash
rm -r {skills-dir}/{skill-name}/
```

**Deprecate (soft removal):**
Rename directory to signal inactive status:
```bash
mv {skills-dir}/{skill-name} {skills-dir}/_deprecated-{skill-name}
```
Prepend to SKILL.md description: `"DEPRECATED: "` — this prevents matching during skill discovery.

### Step 5: Clean Up References (Main)

Remove or update any cross-references found in step 3. Check routing tables and reference tables in other skills.

## Validation

Grep for the deleted skill name across `{skills-dir}/` — zero matches expected.

## Rollback

- **Deleted permanently:** Restore from git (`git checkout -- {skills-dir}/{skill-name}/`).
- **Deprecated:** Rename back (`mv {skills-dir}/_deprecated-{skill-name} {skills-dir}/{skill-name}`) and remove the `DEPRECATED:` prefix from the description.
