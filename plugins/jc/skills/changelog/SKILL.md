---
name: changelog
description: Generates CHANGELOG.md entries from git history using Keep a Changelog 1.1.0 format. Use when the user wants to update the changelog or document recent changes. Do NOT use for version bumping or releasing (use jc:release).
---

# Changelog

## Essential Principles

1. **Keep a Changelog 1.1.0 format only.** Every entry follows the spec exactly -- categories, date format, link references. No deviations.
2. **Unreleased section only.** Never modify existing version sections. New entries go under `## [Unreleased]`. Version bumping is handled by the companion `jc:release` skill.
3. **Git history is the source of truth.** Derive entries from commits between the latest tag and HEAD. Do not invent entries or rely on memory.
4. **No duplicates.** Compare generated entries against existing Unreleased content before inserting.

## Quick Start

1. Validate git repo and check commit count (main context)
2. Spawn subagent to do all changelog work (Steps 2-9)
3. Present subagent's summary to user

## Process

### Step 1: Validate environment (main context)

Verify the working directory is a git repository. If not, halt and report the error.

Check commit count since the latest tag. If >100, warn the user and ask whether to proceed or limit scope. Only spawn the subagent after the user confirms.

### Step 2: Spawn changelog subagent

Launch a single `general-purpose` subagent via the Task tool. The subagent handles all remaining work: locating/creating CHANGELOG.md, collecting commits, categorizing, deduplicating, inserting entries, updating comparison links, and producing a summary.

```
Task tool parameters:
  subagent_type: "general-purpose"
  prompt: |
    ## Task
    Generate CHANGELOG.md entries from git history using Keep a Changelog 1.1.0 format.

    ## Context
    - **Prior work:** None — fresh changelog generation
    - **Constraints:** {maintenance_constraint}

    ## Input
    - Repository root: {absolute path to git repository root}

    ## Instructions

    ### Locate or create CHANGELOG.md

    Check the repository root for `CHANGELOG.md`.

    If it exists but has no `## [Unreleased]` section, insert one after the preamble
    (before the first version section, or at the end if no versions exist).

    If missing, create it with this exact structure:

    ```markdown
    # Changelog

    All notable changes to this project will be documented in this file.

    The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
    and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

    ## [Unreleased]
    ```

    ### Find the latest git tag

    ```bash
    git describe --tags --abbrev=0
    ```

    If no tags exist, all commits are in scope.

    ### Collect commits since the last tag

    With a tag: `git log {latest-tag}..HEAD --oneline --no-merges`
    Without tags: `git log --oneline --no-merges`

    ### Categorize commits

    Map conventional commit prefixes to Keep a Changelog categories:

    | Prefix | Category |
    |--------|----------|
    | `feat:`, `feat!:` | Added |
    | `fix:`, `fix!:` | Fixed |
    | `refactor:`, `refactor!:`, `perf:`, `perf!:` | Changed |
    | `deprecated:` | Deprecated |
    | `security:` | Security |
    | `revert:` | Removed |

    `!` indicates a breaking change. Append `**BREAKING**` to the entry text.

    **Skipped prefixes (internal/maintenance):** `chore:`, `ci:`, `docs:`, `style:`,
    `test:`, `build:`. Excluded by default. {include_maintenance_note}

    **Non-conventional commits:** Read the message content and assign best-fit category.
    Default to Changed when ambiguous.

    Strip the conventional commit prefix and scope from entry text. Write entries as
    clear, user-facing descriptions.

    ### Deduplicate against existing entries

    Read the current `## [Unreleased]` section. Skip any generated entry where a
    semantically equivalent entry already exists (same category, substantially similar
    description).

    ### Insert entries into Unreleased section

    Group by category in this order (include only non-empty categories):
    Added, Changed, Deprecated, Removed, Fixed, Security.

    Insert under `## [Unreleased]`, preserving existing entries. Each category is an
    `### {Category}` heading followed by `- Description` entries.

    ### Update comparison links

    At the bottom of CHANGELOG.md, ensure an `[Unreleased]` comparison link exists.
    Derive the repo URL from `git remote get-url origin`. Use the latest tag as the
    comparison base. If no tags exist, omit the link.

    Format: `[Unreleased]: https://{host}/{org}/{repo}/compare/{latest-tag}...HEAD`

    ### IMPORTANT RULES
    - NEVER modify existing version sections (e.g., `## [1.0.0]`). Only touch `## [Unreleased]`.
    - NEVER include `chore:`/`ci:`/`test:`/`docs:`/`style:`/`build:` commits unless told otherwise.
    - NEVER copy-paste raw commit messages. Rewrite as clean, user-facing descriptions.
    - NEVER bump the version or move Unreleased to a version section.

    ## Expected Output
    After writing the file, report:
    - Number of entries added per category
    - Number of commits skipped (maintenance prefixes)
    - Number of duplicates skipped
    - Any commits that were ambiguous to categorize
```

Before spawning, resolve placeholders:
- `{absolute path to git repository root}` — the resolved repo root path
- `{maintenance_constraint}` — "Include maintenance commits under Changed (user requested)" if the user explicitly asked, otherwise "Exclude maintenance commits (default)"
- `{include_maintenance_note}` — "Include maintenance commits under Changed — user explicitly requested." if the user asked, otherwise remove the placeholder

### Step 3: Present results (main context)

Display the subagent's summary to the user.

## Success Criteria

- CHANGELOG.md follows Keep a Changelog 1.1.0 format exactly
- Entries appear under `## [Unreleased]` only
- All non-maintenance commits since the latest tag are categorized
- No duplicate entries in the Unreleased section
- Entries are clean, user-facing descriptions (not raw commit messages)
- Existing version sections and entries are untouched
- `[Unreleased]` comparison link is present and correct

## Related Skills

- `jc:release` — handles version bumping: moves Unreleased entries into a new version section, creates the git tag, and updates comparison links
