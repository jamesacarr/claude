# Lint

> Audit the wiki for staleness, unsourced claims, broken references, orphans, and graduation candidates.

## Prerequisites

- Wiki vault `wiki` exists
- Read `references/conventions.md` for expected formats

## Steps

### Step 1: Scope the Audit

Ask the user (or infer from context):

| Scope | What to check |
|-------|---------------|
| Full vault | All checks below across all pages |
| Single page | All checks for one specific page |
| Specific check | Run one check type across the vault (e.g. "just check for unsourced claims") |

### Step 2: Run Checks

#### Unsourced Claims

Search for `[needs-source]` markers across the wiki:

```bash
obsidian vault=wiki search query="needs-source"
```

Report: page name, claim text, and count per page. Pages with high `[needs-source]` counts are the highest priority.

#### Unresolved Conflicts

Search for conflict callouts:

```bash
obsidian vault=wiki search query="[!conflict]"
```

Report: page name, both claims, and their sources. These need user resolution.

#### Staleness (Confidence Decay)

Check `updated` frontmatter dates across all wiki pages. Flag pages that haven't been updated within the threshold:

| Folder | Threshold |
|--------|-----------|
| `projects/` | 90 days |
| `topics/` | 180 days |
| `sources/` | No threshold (summaries are point-in-time) |
| `notes/` | 60 days |

Read flagged pages and assess: is the content likely still accurate, or does it need review? Present findings with context, not just a list of dates.

#### Code Reference Verification

Search for code references (the `org/repo` — `path` → `symbol()` pattern):

```bash
obsidian vault=wiki search query="→"
```

For each code reference found, verify:
1. Does the referenced file still exist? (Check via `gh` or local filesystem if the repo is available)
2. Does the symbol still exist in that file? (Search for it)

Report broken references with the wiki page they appear on.

#### Orphan and Dead End Detection

```bash
obsidian vault=wiki orphans
obsidian vault=wiki deadends
obsidian vault=wiki unresolved
```

- **Orphans** — pages with no incoming links. May indicate disconnected knowledge that should be linked from somewhere
- **Dead ends** — pages with no outgoing links. May indicate pages that should cross-reference related topics
- **Unresolved links** — wikilinks pointing to pages that don't exist. Either create the page or fix the link

#### Source Link Reachability

For source summary pages with URLs, optionally check if the original source is still accessible. This is slow and network-dependent — only run if the user explicitly requests it.

#### Notes Graduation

Check pages in `notes/` for graduation candidates:

```bash
obsidian vault=wiki files folder="notes"
```

For each note, check:
- **Inbound links** — `obsidian vault=wiki backlinks file="<note>"`. If 3+ inbound links, suggest graduation
- **Update frequency** — if the `updated` field has been modified 3+ times (check git history), suggest graduation

Suggest a destination folder based on content:
- Mentions a specific project → `projects/`
- Covers a concept or technology → `topics/`

Present as suggestions, not automatic moves.

### Step 3: Report

Present findings grouped by check type, ordered by priority:

1. **Unresolved conflicts** (need user decision)
2. **Unsourced claims** (need citations or verification)
3. **Broken code references** (need updating)
4. **Stale pages** (need review)
5. **Orphans and dead ends** (need linking)
6. **Unresolved links** (need pages or fixes)
7. **Graduation candidates** (optional improvement)

For each finding, include: the page name, what was found, and a suggested action.

### Step 4: Fix with Approval

Offer to fix issues that have clear resolutions:

- Broken code references → update the path/symbol if the new location is known
- Unresolved links → create stub pages or fix the link
- Dead ends → suggest wikilinks to add

Always present changes before making them. Do not auto-fix conflicts or remove `[needs-source]` markers — those require user judgement.

## Success Criteria

- All check types run (or scoped subset as requested)
- Findings grouped by priority and presented with context
- Suggested actions are specific and actionable
- No auto-fixes without user approval
- Conflicts and unsourced claims surfaced, not silently resolved
