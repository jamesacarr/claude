---
name: release
description: Bumps version, finalizes changelog, commits, tags, and pushes a release. Use when cutting a release or bumping a project version. Do NOT use for changelog generation (use jc:changelog).
$ARGUMENTS: Optional bump type (patch|minor|major), explicit version (e.g. 1.2.0), or omit to auto-detect
---

## Essential Principles

1. **Clean working tree required.** Never release with uncommitted changes — halt immediately if `git status --porcelain` returns output.
2. **CHANGELOG.md must exist.** If missing, tell the user to run `/jc:changelog` first and halt.
3. **Semantic versioning only.** All versions follow `MAJOR.MINOR.PATCH`.
4. **Atomic release.** One commit (`release: {version}`) + one annotated tag (`v{version}`) per release.

## Quick Start

| Invocation | Behavior |
|------------|----------|
| `/release patch` | Bump patch version |
| `/release minor` | Bump minor version |
| `/release major` | Bump major version |
| `/release 1.2.0` | Use explicit version |
| `/release` | Auto-detect from CHANGELOG.md, confirm with user |

## Process

### Step 1: Validate environment (main context)

Verify git repository. Run `git remote` — if output is empty, halt: "No git remote configured. Add one with `git remote add origin <url>`."

Run `git status --porcelain` — if output is non-empty, halt and tell user to commit or stash.

### Step 2: Detect manifest and current version (main context)

Scan the repository root for files containing a version field. Common examples:

| Manifest | Version field |
|----------|--------------|
| `package.json` | `"version": "x.y.z"` |
| `Cargo.toml` | `version = "x.y.z"` |
| `pyproject.toml` | `version = "x.y.z"` |

This list is not exhaustive — any manifest with a parseable semver version field is valid. If exactly one manifest is found, use it. If multiple are found, present the list to the user via AskUserQuestion and let them choose the **primary** manifest. Then ask whether secondary manifests should also be bumped to the same version in the release commit. If none found, halt with error.

### Step 3: Resolve target version (main context)

| Argument | Action |
|----------|--------|
| Explicit semver (e.g. `1.2.0`) | Validate > current version, then use directly |
| `patch`, `minor`, or `major` | Calculate from current version |
| Empty/omitted | Auto-detect from CHANGELOG.md (see below), then confirm via AskUserQuestion |

**Auto-detect logic:** Read `## [Unreleased]` section entries:

| Condition | Bump type |
|-----------|-----------|
| Any entry contains `**BREAKING**` | major |
| `### Added` section has entries | minor |
| Otherwise | patch |

Present detected bump type and calculated version to user for confirmation. If `### Changed` has entries, include them in the confirmation prompt so the user can assess whether they warrant a higher bump.

### Step 4: Verify CHANGELOG.md (main context)

If CHANGELOG.md exists but has no `## [Unreleased]` section, warn (empty release notes) and continue.

### Step 5: Spawn release subagent

Launch a single `general-purpose` subagent via the Task tool.

```
Task tool parameters:
  subagent_type: "general-purpose"
  prompt: |
    ## Task
    Execute a release: bump version, update changelog, commit, tag, push.

    ## Context
    - **Prior work:** Main context validated clean working tree, detected manifest, resolved version, verified CHANGELOG.md
    - **Key findings:** {any notes from main context, e.g. "user opted to sync secondary manifests" or "none"}
    - **Constraints:** Single atomic commit + tag. Do not modify files beyond those listed in Input.

    ## Input
    - Repository root: {repo-root}
    - Manifest: {manifest-path} (type: {manifest-type})
    - Current version: {current-version}
    - New version: {new-version}
    - Secondary manifests to sync: {list of paths, or "none"}

    ## Instructions

    ### Pre-flight
    Run `git status --porcelain` — if output is non-empty, halt: "Working tree is dirty. Aborting release."
    Run `git tag -l 'v{new-version}'` — if output is non-empty, halt: "Tag v{new-version} already exists."

    ### Bump version in manifest
    Edit {manifest-path} — update only the version field to {new-version}. Preserve all other content.
    If secondary manifests were provided, bump each one to {new-version} as well. Update internal dependency references between them if applicable.

    ### Update CHANGELOG.md
    1. Get today's date using `mcp__time__get_current_time` — never use the `date` command. Extract YYYY-MM-DD from ISO 8601.
    2. Insert `## [{new-version}] - {date}` on the line immediately after `## [Unreleased]`
    3. Move all category headings and entries from under Unreleased into the new version section
    4. Leave `## [Unreleased]` as an empty heading (no categories under it)
    5. Update comparison links at the bottom of the file:
       - `[Unreleased]` → compares `v{new-version}` to HEAD
       - `[{new-version}]` → compares `v{current-version}` to `v{new-version}`
       - Derive repo URL from `git remote get-url origin`. If the URL is SSH format (`git@host:org/repo.git`), convert to HTTPS (`https://host/org/repo`) for valid browser links.

    ### Commit and tag
    Stage only the manifest file(s) and CHANGELOG.md — do NOT use `git add -A`.
    Commit with message: `release: {new-version}` — never use `--no-gpg-sign`.
    Create annotated tag: `git tag -a 'v{new-version}' -m 'v{new-version}'`

    ### Push
    Run `git push` then `git push --tags` (separate commands).
    If `git push --tags` fails, report the error and provide the recovery command (e.g. `git push origin v{new-version}`) — do NOT attempt destructive remote operations like force-push or remote tag deletion.

    ## Expected Output
    Report: manifest(s) updated, changelog version section created, commit hash, tag name, push status.
```

### Step 6: Present results (main context)

Display the subagent's summary to the user.

## Success Criteria

- Clean working tree verified before any changes
- Version bumped in manifest file(s)
- CHANGELOG.md Unreleased entries moved to new version section with correct date
- Single commit with message `release: {version}`
- Annotated tag `v{version}` created
- Both commit and tag pushed to remote

## Related Skills

- `jc:changelog` — generates Unreleased entries from git history
