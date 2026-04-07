# Ingest

> Add knowledge from any source type into the wiki. Creates or updates source summaries, project pages, and topic pages with citations.

## Prerequisites

- Wiki vault `wiki` exists with `sources/`, `projects/`, `topics/`, `notes/` folders
- Read `references/conventions.md` for frontmatter, citation format, and primary/secondary target rules

## Steps

### Step 1: Identify Source Type

Determine the source type from what the user provides:

| User provides | Source type | Extractor |
|---------------|-----------|-----------|
| URL to web page/article | `web` | `defuddle parse <url> --md` |
| Slack thread link or channel reference | `slack` | Slack MCP tools (`slack_read_thread`, `slack_read_channel`) |
| GitHub PR/issue URL or reference | `pr` | `gh pr view`, `gh issue view` |
| File path to PDF/document | `document` | `Read` tool (with `pages` param for PDFs) |
| Repository path or URL | `code` | `Read`, `Grep`, `Glob`, git history (consider `/jc:map` for comprehensive analysis) |
| Verbal/typed knowledge (no external source) | `conversation` | None — the user's statement is the content |

### Step 2: Extract Content

Run the appropriate extractor to get the raw content. For web pages, also extract metadata:

```bash
defuddle parse <url> --json    # title, author, published, content
```

For Slack threads, capture: participants, key decisions, links shared, timestamps.

For code repos, focus on: what it does, tech stack, architecture decisions, key conventions, gotchas.

### Step 3: Find Related Wiki Pages

Search the wiki for pages that might need updating:

```bash
obsidian vault=wiki search query="<key terms from source>"
obsidian vault=wiki tags
obsidian vault=wiki files folder="projects"
obsidian vault=wiki files folder="topics"
```

Read candidate pages to understand existing content before deciding what to update.

### Step 4: Identify Targets

Determine the **primary target** (gets full detail) and **secondary targets** (get a brief mention with wikilink).

- If the source is mainly about a project → primary is the project page
- If the source is mainly about a concept/technology → primary is the topic page
- If unclear → primary goes in `notes/`, can graduate later

Present the plan to the user: "I'll create/update X as the primary page, and add cross-references to Y and Z. Does that look right?"

### Step 5: Create or Update Source Summary

**Skip this step for brief direct knowledge** (single statements from the user — cite inline instead).

For all other sources, create a source summary page in `sources/`:

```bash
obsidian vault=wiki create path="sources/<Title>.md" content="..."
```

The summary page contains:
- Frontmatter per conventions (source, source_type, accessed, updated, author, published, tags)
- A concise summary of the key information
- Notable quotes or data points
- Wikilinks to related wiki pages

If a source summary already exists (re-ingest or updated source), read the existing summary, update it with new information, and update the `updated` timestamp.

### Step 6: Update Primary Target

Read the existing page (if it exists). Integrate the new information:

- Add new sections or update existing ones with the new knowledge
- Add citations pointing to the source summary page (or inline for direct knowledge)
- If new information **contradicts** existing claims, add a `> [!conflict]` callout per conventions — do not silently overwrite
- Update the `updated` frontmatter field
- Add relevant tags if not already present

If the page doesn't exist, create it with proper frontmatter and the new content.

### Step 7: Update Secondary Targets

For each secondary target page:

- Add a brief mention of the new information with a wikilink back to the primary page
- Add a citation if the mention includes a factual claim
- Update the `updated` frontmatter field

If a secondary target page doesn't exist and the information is substantial enough, create it. Otherwise, skip — don't create stub pages for every tangential mention.

### Step 8: Confirm

Report to the user:
- Source summary created/updated (with link)
- Primary page created/updated (with link)
- Secondary pages updated (with links)
- Any conflicts flagged
- Any `[needs-source]` markers added (for claims extracted from the source that the LLM couldn't verify)

## Source-Specific Guidance

### Web Pages

Use `defuddle parse <url> --json` to get content and metadata in one call. Derive the source summary title from the article title. If defuddle returns empty content, fall back to `WebFetch`.

### Slack Threads

Capture the thread context: who said what, what was decided, what actions were taken. Slack threads often contain decisions mixed with discussion — distil the decisions and outcomes, cite the thread.

### Code Repositories

Don't try to capture everything. Focus on:
- What the project does (one paragraph)
- Key architectural decisions and their rationale
- Gotchas and tribal knowledge
- Current initiatives (if known)

Use code references in the wiki page: `org/repo` — `path/to/file.ts` → `functionName()`.

### Re-Ingesting an Updated Source

When a source has been previously ingested and has changed (updated article, repo after significant work, etc.):

1. Read the existing source summary
2. Extract the new content
3. Compare old summary to new extraction — note what changed
4. Update the source summary with new/changed information and refresh the `updated` timestamp
5. Check wiki pages that cite this summary — if any cited claims are now contradicted, add `> [!conflict]` callouts on those pages

### Direct Knowledge

If the user states a single fact: update the relevant page directly with an inline citation (`Direct — Name, date`). No source summary needed.

If the user provides substantial knowledge (multiple facts, explanations, history): create a source summary with `source: direct` and `source_type: conversation`, then update wiki pages citing that summary.

## Success Criteria

- Source summary exists for external sources and links to the original
- Primary page updated with full detail and citations
- Secondary pages cross-referenced with wikilinks
- Conflicts flagged, not silently overwritten
- All new claims have citations or `[needs-source]` markers
- Frontmatter `updated` timestamps refreshed on all modified pages
