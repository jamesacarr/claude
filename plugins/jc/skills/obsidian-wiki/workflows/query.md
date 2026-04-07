# Query

> Search the wiki and synthesise an answer from existing knowledge. Optionally file valuable answers back as new wiki pages.

## Prerequisites

- Wiki vault initialised
- Read `references/conventions.md` for citation format

## Steps

### Step 1: Understand the Question

Determine what the user is asking and what kind of answer they need:

- **Factual lookup** — "What auth method does Project X use?" → find the specific page, return the answer with citation
- **Synthesis** — "How do our services handle authentication?" → find multiple pages, synthesise across them
- **Comparison** — "What are the differences between Project X and Project Y's approaches to caching?" → find both pages, compare
- **Exploration** — "What do we know about Kafka?" → find the topic page and everything linked to it

### Step 2: Search the Wiki

Use Obsidian CLI to find relevant pages:

```bash
obsidian vault=wiki search query="<key terms>"
obsidian vault=wiki tags name="<relevant-tag>" --verbose
obsidian vault=wiki backlinks file="<known relevant page>"
```

Strategy:
1. Search by key terms from the question
2. If the question mentions a known project/topic, go directly to that page
3. Check backlinks and outgoing links from found pages to discover related content
4. Read the most promising pages

**If no relevant pages are found:** Tell the user the wiki has no information on this topic. Offer to ingest a source right now — "I can add knowledge about this if you have a source (URL, Slack thread, etc.) or can tell me directly." Bridge to the ingest workflow.

### Step 3: Synthesise Answer

Compose an answer from the wiki content. Rules:

- **Cite your sources** — reference the wiki pages you drew from: "According to [[projects/Project X]], ..."
- **Flag gaps** — if the wiki doesn't have enough information to fully answer, say so explicitly. Suggest what sources could be ingested to fill the gap
- **Flag staleness** — if the relevant pages have old `updated` dates, note this: "This information was last updated on X and may be outdated"
- **Note conflicts** — if the pages contain `> [!conflict]` callouts relevant to the answer, surface them

### Step 4: Offer to File the Answer

If the answer involved meaningful synthesis (not just a simple lookup), offer to file it back into the wiki:

"This comparison could be useful as a wiki page. Want me to save it as `topics/Authentication Patterns.md`?"

If the user agrees, follow the same conventions as ingest:
- Proper frontmatter with `updated` timestamp
- Citations pointing to the wiki pages used as sources
- Tags for discoverability
- Wikilinks to related pages

## Success Criteria

- Answers cite specific wiki pages
- Knowledge gaps and staleness are surfaced, not hidden
- Conflicts from wiki pages are mentioned in the answer
- Valuable synthesis offered back as wiki pages
