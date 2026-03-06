---
name: release
description: Bumps version, finalizes changelog, commits, tags, and pushes a release. Use when cutting a release or bumping a project version. Do NOT use for changelog generation (use jc:changelog).
$ARGUMENTS: Optional bump type (patch|minor|major), explicit version (e.g. 1.2.0), or omit to auto-detect
---

# Release

## Essential Principles

1. **Clean working tree required.** Uncommitted changes would be silently excluded from the release commit, creating a mismatch between the tag and actual repo state — halt immediately if `git status --porcelain` returns output.
2. **CHANGELOG.md must exist.** The release process moves Unreleased entries into the version section; without a changelog there is nothing to finalize and the release ships with no notes — tell the user to run `/jc:changelog` first and halt.
3. **Semantic versioning only.** Auto-detect logic, comparison links, and tag names all depend on parseable three-part versions — all versions follow `MAJOR.MINOR.PATCH` (pre-release suffixes like `-rc.1` are out of scope).
4. **Atomic release.** CI systems and tools that filter by tags need a clean, unambiguous signal — one commit (`release: {version}`) + one annotated tag (`v{version}`) per release.

## Quick Start

| Invocation | Behavior |
|------------|----------|
| `/release patch` | Bump patch version |
| `/release minor` | Bump minor version |
| `/release major` | Bump major version |
| `/release 1.2.0` | Use explicit version |
| `/release` | Auto-detect from CHANGELOG.md, confirm with user |

## Process

### Step 1: Validate environment

**Context:** main

Verify git repository. Run `git remote` — if output is empty, halt: "No git remote configured. Add one with `git remote add origin <url>`."

Run `git status --porcelain` — if output is non-empty, halt and tell user to commit or stash.

### Step 2: Detect manifest and current version

**Context:** main

Scan the repository root for files containing a version field. Common examples:

| Manifest | Version field |
|----------|--------------|
| `package.json` | `"version": "x.y.z"` |
| `Cargo.toml` | `version = "x.y.z"` |
| `pyproject.toml` | `version = "x.y.z"` |

This list is not exhaustive — any manifest with a parseable semver version field is valid. If exactly one manifest is found, use it. If multiple are found, present the list to the user via AskUserQuestion and let them choose the **primary** manifest. Then ask whether secondary manifests should also be bumped to the same version in the release commit. If none found, halt with error.

### Step 3: Resolve target version

**Context:** main

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

Present detected bump type and calculated version to user for confirmation. If `### Changed` has entries, include them in the confirmation prompt so the user can assess whether they warrant bumping to `minor` instead of `patch`.

### Step 4: Verify CHANGELOG.md

**Context:** main

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
    Run `git tag -l 'v{new-version}'` — if output is non-empty, halt: "Tag v{new-version} already exists."

    ### Bump version in manifest
    Edit {manifest-path} — update only the version field to {new-version}. Preserve all other content.
    If secondary manifests were provided, bump each one to {new-version} as well. For internal dependency references between synced packages: update only exact-pinned versions (e.g. `"3.1.0"`) to the new version; leave semver ranges (`^`, `~`, `>=`) untouched when the range already satisfies the new version.

    ### Update CHANGELOG.md
    1. Get today's date using `mcp__time__get_current_time` — never use the `date` command. Extract YYYY-MM-DD from ISO 8601.
    2. Insert `## [{new-version}] - {date}` on the line immediately after `## [Unreleased]`
    3. Move all category headings and entries from under Unreleased into the new version section
    4. Leave `## [Unreleased]` as an empty heading (no categories under it)
    5. Update comparison links at the bottom of the file (or create the section if it does not exist):
       - `[Unreleased]` → compares `v{new-version}` to HEAD
       - `[{new-version}]` → compares `v{current-version}` to `v{new-version}`
       - Derive repo URL from `git remote get-url origin`. If the URL is SSH format (`git@host:org/repo.git`), convert to HTTPS (`https://host/org/repo`) for valid browser links.
       - If no comparison links section exists, create it at the bottom of the file with the above entries.

    ### Commit and tag
    Stage only the manifest file(s) and CHANGELOG.md — never `git add -A` because it stages untracked files that may not belong in a release commit.
    Commit with message: `release: {new-version}` — never use `--no-gpg-sign`.
    Create annotated tag: `git tag -a 'v{new-version}' -m 'v{new-version}'`

    ### Push
    Run `git push` then `git push --tags` (separate commands).
    If either push fails, report the error with the exact output, explain what exists locally vs remotely, and provide recovery steps — do NOT attempt automatic recovery (rebase, force-push, or remote tag deletion).

    ## Expected Output
    Report: manifest(s) updated, changelog version section created, commit hash, tag name, push status.
```

### Step 6: Present results

**Context:** main

Display the subagent's summary to the user.

## Related Skills

- `jc:changelog` — generates Unreleased entries from git history
