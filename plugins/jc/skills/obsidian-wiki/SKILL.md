---
name: obsidian-wiki
description: Maintains a personal knowledge wiki in Obsidian — ingesting sources, answering queries, and auditing for staleness. Use when adding knowledge to the wiki (from web pages, Slack, code, PRs, conversations), querying the wiki, or running lint/maintenance. Do NOT use for Obsidian CLI operations (use use-obsidian) or Obsidian Markdown syntax (use obsidian-markdown).
---

# obsidian-wiki

## Essential Principles

- **Every claim needs a citation** — cite source summary pages or direct knowledge per `references/conventions.md`. Unsourced claims are marked `[needs-source]` and flagged by lint
- **Source summaries are the citation target** — external sources get a summary page in `sources/`; citations point there, not to the original URL. One hop to context, two hops to original
- **Primary and secondary targets** — every ingest has one primary page (gets full detail) and zero or more secondary pages (get a brief mention with a wikilink back). Keeps topic pages focused
- **Flag conflicts, don't silently overwrite** — when new information contradicts existing claims, add a `> [!conflict]` callout with both claims and their sources for the user to resolve
- **Confirm with user before mutations** — creating pages, updating existing pages, moving files. Present what will change before doing it
- **Vault name is `wiki`** — all CLI commands use `vault=wiki`. Run `obsidian vault vault=wiki` to verify
- **Use Obsidian CLI for all vault operations** — read the `use-obsidian` skill for CLI details
- **Use defuddle for web page extraction** — read the `use-defuddle` skill for CLI details
- **Use Obsidian Markdown conventions** — wikilinks, callouts, frontmatter, tags. Read the `obsidian-markdown` skill for syntax details

## Intake

What would you like to do?

1. **Ingest** — add knowledge from a source (web page, Slack thread, PR, code repo, document), or tell me something directly
2. **Query** — search the wiki and synthesise an answer
3. **Lint** — audit for staleness, unsourced claims, orphans, and graduation candidates

## Routing

| Response | Workflow |
|----------|----------|
| 1, "ingest", "add", "save", "clip", "file", "tell", "note", "remember" | `workflows/ingest.md` |
| 2, "query", "search", "find", "ask the wiki", "what does the wiki say" | `workflows/query.md` |
| 3, "lint", "audit", "check", "maintain", "review" | `workflows/lint.md` |

## References

- **Conventions** (page formats, frontmatter, citations, code references, vault structure): `references/conventions.md`
