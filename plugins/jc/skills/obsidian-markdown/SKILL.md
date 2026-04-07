---
name: obsidian-markdown
description: Writes Obsidian-flavoured Markdown with wikilinks, embeds, callouts, properties, tags, and other Obsidian-specific syntax. Use when creating or editing notes in an Obsidian vault, adding wikilinks, embedding content, writing callouts, formatting YAML frontmatter in notes, or using any Obsidian-specific markdown syntax. Do NOT use for Obsidian CLI operations (use use-obsidian).
---

# obsidian-markdown

## Essential Principles

- **Wikilinks for internal, standard links for external** — use `[[Note Name]]` for notes within the vault (Obsidian tracks renames automatically) and `[text](url)` for external URLs only
- **Properties go in YAML frontmatter** — always at the very top of the file, fenced by `---`. Never write raw YAML mid-document
- **Tags use `#` prefix** — `#tag` in body text or `tags:` list in frontmatter. Nested tags use `/`: `#project/active`
- **Embeds are wikilinks with `!` prefix** — `![[Note]]` inlines a note, `![[image.png]]` renders an image. This is distinct from standard markdown image syntax

## Quick Start

```markdown
---
tags:
  - project
  - active
aliases:
  - Alt Name
cssclasses:
  - wide-page
---

# Note Title

Link to [[Another Note]] or [[Another Note|custom display text]].
Link to a heading: [[Note#Section Heading]].
Link to a block: [[Note#^block-id]].

![[Embedded Note]]
![[image.png|300]]

> [!info] Title here
> Callout content.

> [!warning]- Collapsed by default
> Hidden until expanded.

This has a ==highlighted phrase== and a %%hidden comment%%.

Task list:
- [ ] Incomplete task
- [x] Completed task
- [/] In progress
```

## Internal Links (Wikilinks)

| Syntax | Result |
|--------|--------|
| `[[Note Name]]` | Link to note |
| `[[Note Name\|Display Text]]` | Link with custom text |
| `[[Note Name#Heading]]` | Link to heading |
| `[[Note Name#^block-id]]` | Link to block |
| `[[#Heading]]` | Link to heading in current note |
| `[[#^block-id]]` | Link to block in current note |

Block IDs are added with `^block-id` at the end of a paragraph. Manual: `Paragraph text ^my-block-id`. Obsidian also auto-generates them when you link to a block via the UI.

## Embeds

| Syntax | Result |
|--------|--------|
| `![[Note Name]]` | Embed full note |
| `![[Note Name#Heading]]` | Embed specific section |
| `![[image.png]]` | Embed image |
| `![[image.png\|300]]` | Embed image with width (px) |
| `![[image.png\|300x200]]` | Embed image with width and height |
| `![[audio.mp3]]` | Embed audio player |
| `![[video.mp4]]` | Embed video player |
| `![[document.pdf]]` | Embed PDF |
| `![[document.pdf#page=3]]` | Embed PDF at specific page |
| `![[document.pdf#height=400]]` | Embed PDF with custom height |

Embed search results with a query block:

````markdown
```query
tag:#project status:done
```
````

## Callouts

```markdown
> [!type] Optional title
> Content inside the callout.
```

Collapsible callouts use `+` (expanded) or `-` (collapsed) after the type:

```markdown
> [!faq]- Click to expand
> Hidden content.
```

| Type | Aliases |
|------|---------|
| `note` | — |
| `abstract` | `summary`, `tldr` |
| `info` | — |
| `todo` | — |
| `tip` | `hint`, `important` |
| `success` | `check`, `done` |
| `question` | `help`, `faq` |
| `warning` | `caution`, `attention` |
| `failure` | `fail`, `missing` |
| `danger` | `error` |
| `bug` | — |
| `example` | — |
| `quote` | `cite` |

Callouts can be nested by adding `>` levels.

## Properties (Frontmatter)

```yaml
---
tags:
  - status/draft
  - topic/design
aliases:
  - Alternative Name
cssclasses:
  - wide-page
created: 2026-04-07
---
```

| Property | Type | Purpose |
|----------|------|---------|
| `tags` | list | Categorisation — same as inline `#tags` |
| `aliases` | list | Alternative names for wikilink resolution |
| `cssclasses` | list | CSS classes applied to the note |
| `publish` | checkbox | Include/exclude from Obsidian Publish |

Property values support: `text`, `list`, `number`, `checkbox`, `date` (`YYYY-MM-DD`), `datetime` (`YYYY-MM-DDThh:mm`), `links` (`related: "[[Other Note]]"`).

## Tags

```markdown
#tag
#nested/tag
#status/draft
```

Tags in frontmatter `tags:` list and inline `#tags` are equivalent — Obsidian merges them.

Tag rules: may contain letters (any language), numbers (not as first character), `-`, `_`, `/` (for nesting). No spaces. Case-insensitive in search.

## Additional Syntax

| Syntax | Result |
|--------|--------|
| `==highlighted==` | Highlighted text |
| `%%hidden comment%%` | Comment (invisible in reading view) |
| `$e = mc^2$` | Inline LaTeX math |
| `$$\sum_{i=1}^{n} x_i$$` | Block LaTeX math (on its own line) |
| `[^1]` + `[^1]: text` | Footnote reference and definition |
| `~~strikethrough~~` | Strikethrough text |

Mermaid diagrams use fenced code blocks with `mermaid` language identifier.

## Success Criteria

- `[[wikilinks]]` used for all internal vault links, never `[text](relative-path.md)`
- Properties placed in YAML frontmatter at file top, never mid-document
- Embed syntax (`![[]]`) used for inlining content, not standard markdown images for vault files
- Callout syntax matches Obsidian format (`> [!type]`), not other markdown flavours
