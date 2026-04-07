# Conventions

> Page formats, frontmatter schemas, citation model, code references, and vault structure.

## Contents

- [Vault Structure](#vault-structure)
- [Frontmatter](#frontmatter)
- [Citation Model](#citation-model)
- [Conflict Handling](#conflict-handling)
- [Code References](#code-references)
- [Tags](#tags)
- [Primary and Secondary Targets](#primary-and-secondary-targets)

## Vault

The wiki vault is named `wiki`. All CLI commands use `vault=wiki`:

```bash
obsidian vault=wiki search query="kafka"
obsidian vault=wiki create path="topics/Kafka.md" content="..."
```

## Vault Structure

```
wiki/
├── sources/          # one summary per ingested external source
├── projects/         # work and personal project pages
├── topics/           # concepts, technologies, domains
└── notes/            # catch-all — graduates into other folders
```

Single vault. No index file (Obsidian CLI handles search/navigation). No operation log (git history covers that). Structure grows organically within these top-level categories.

## Frontmatter

### Source Summary Pages (`sources/`)

```yaml
---
source: https://example.com/article
source_type: web | slack | code | pr | document | conversation
accessed: 2026-04-07T14:30:00Z
updated: 2026-04-07T14:30:00Z
author: Jane Smith
published: 2026-03-15
tags:
  - topic-tag
  - project-tag
---
```

| Field | Required | Notes |
|-------|----------|-------|
| `source` | Yes | URL, Slack thread link, repo URL, or `direct` |
| `source_type` | Yes | One of: `web`, `slack`, `code`, `pr`, `document`, `conversation` |
| `accessed` | Yes | When the source was ingested. UTC ISO 8601 via `mcp__time__get_current_time` |
| `updated` | Yes | Last modification. Update on every edit |
| `author` | If known | Original author |
| `published` | If known | Original publication date |
| `tags` | Yes | At least one topic or project tag |

### Wiki Pages (`projects/`, `topics/`, `notes/`)

```yaml
---
updated: 2026-04-07T14:30:00Z
tags:
  - project-name
  - technology
---
```

| Field | Required | Notes |
|-------|----------|-------|
| `updated` | Yes | Last modification. Update on every edit |
| `tags` | Yes | At least one tag for discoverability |

## Citation Model

Wikipedia-style inline citations. Every factual claim gets a footnote.

### Citing Source Summaries

```markdown
We use Kafka for the data pipeline due to cross-region replication
requirements. [^1]

[^1]: [[sources/Platform Architecture Review 2026-03]]
```

The source summary page links to the original URL/thread/PR. One hop to context, two hops to original.

### Citing Direct Knowledge

When the user states knowledge directly without an external source:

```markdown
Session tokens expire after 24 hours. [^1]

[^1]: Direct — James Carr, 2026-04-07
```

Only use inline direct citations for brief statements. If the user provides substantial knowledge (multiple paragraphs, detailed explanations), create a source summary page with `source: direct` and `source_type: conversation`.

### Unsourced Claims

```markdown
The service handles approximately 10k requests per second. [needs-source]
```

`[needs-source]` marks claims that lack a citation. Lint flags these.

## Conflict Handling

When new information contradicts an existing claim, do not silently overwrite. Add a callout:

```markdown
> [!conflict] Conflicting information
> **Existing claim:** Sessions stored in Redis with 24h TTL. [^1]
> **New claim:** Sessions migrated to Postgres-backed storage. [^2]
> Needs resolution.

[^1]: [[sources/Platform Architecture Review 2026-03]]
[^2]: [[sources/Slack Thread — Session Migration 2026-04]]
```

The user resolves conflicts. Once resolved, remove the callout and keep the correct claim with its citation.

## Code References

### Current Code (Verifiable)

Point to a *thing* (function, class, module), not a line number:

```markdown
See: `org/repo` — `src/middleware/auth.ts` → `validateJWT()`
```

Lint can verify: does the file exist? Does the symbol exist in it?

### Historical Code (Frozen Snapshot)

Use a GitHub permalink when intentionally pointing at a past state:

```markdown
See: [auth.ts at time of migration](https://github.com/org/repo/blob/abc123/src/auth.ts#L15-L42)
```

Mark clearly as historical so lint doesn't flag it as stale.

## Tags

Use tags consistently for discoverability:

- Project tags: `project-name` (e.g. `data-pipeline`, `auth-service`)
- Topic tags: topic name (e.g. `kafka`, `jwt`, `typescript`)
- Status tags: `status/active`, `status/archived`, `status/draft`

Prefer flat tags for topics and projects. Use nested tags only for orthogonal dimensions like status.

## Primary and Secondary Targets

Every ingest has:

- **Primary target** — the page most directly about the source content. Gets full detail, citations, and any new sections needed.
- **Secondary targets** — pages that should cross-reference the new information. Get a brief mention and a wikilink back to the primary page.

Example: ingesting a Slack thread about Project X's Kafka migration.
- Primary: `projects/Project X.md` — full detail about the migration
- Secondary: `topics/Kafka.md` — brief mention: "Used in [[projects/Project X]] for cross-region replication"
