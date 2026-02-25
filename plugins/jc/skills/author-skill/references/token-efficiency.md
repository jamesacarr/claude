# Token Efficiency

> Token efficiency principles for skill authoring. Every token in a skill is loaded into context on every invocation — bloat compounds. Skills should be as lean as possible while remaining clear and complete.

## Principles

**1. Every Token Earns Its Place**

If removing a sentence doesn't change agent behavior, remove it. Skills are prompts, not documentation.

**2. Say It Once**

Never repeat the same instruction in different words. Pick the clearest phrasing, delete the rest. Cross-file duplication (SKILL.md echoing a workflow) is the most common violation. **Exception:** Never remove a section required by the skill's template — simplify its content instead.

**3. Prefer Structure Over Prose**

Tables and lists compress information. A 3-column table replaces paragraphs of if/then prose. Use tables for: mappings, decision logic, option comparisons. Use lists for: sequential steps, checklists.

**4. Eliminate Filler**

Remove: introductory phrases ("It's important to note that..."), hedging ("You might want to consider..."), obvious statements ("This is useful for..."), meta-commentary about the skill itself.

**5. Compress Examples**

One excellent example > three mediocre ones. Show the pattern, not every variation. Claude generalizes from a single good example.

**6. Use References for Detail**

If a section exceeds 20 lines of specialized content, extract to a reference file. SKILL.md should route, not teach.

**7. Headings Are Free Structure**

Markdown headings add semantic meaning without token waste. A `## Validation` heading replaces "The following section covers validation steps:" — saving tokens while improving parseability.

## Checklist

Token efficiency review — verify each item:

- [ ] No repeated instructions across files (SKILL.md, workflows, references)
- [ ] No filler phrases or hedging language
- [ ] Tables used where prose would be longer
- [ ] Examples are minimal and non-redundant (one per concept)
- [ ] No obvious statements ("This step is important because...")
- [ ] SKILL.md routes, doesn't re-teach workflow content
- [ ] Inline content that could be a reference is extracted (20+ line threshold)
- [ ] No narrative storytelling or session history
- [ ] Every sentence changes agent behavior — if removed, output would differ

## Common Waste Patterns

| Pattern | Example | Fix |
|---------|---------|-----|
| **Restating the obvious** | "This skill helps you create skills" | Delete |
| **Double instruction** | Rule in SKILL.md AND workflow | Keep in one place, reference from other. Never remove a required template section — simplify it |
| **Verbose conditions** | "If the user wants to X, and they have Y, then..." | Table with conditions → actions |
| **Example avalanche** | 5 examples showing same pattern | Keep best one, delete rest |
| **Meta-commentary** | "The following section explains how to..." | Delete, let the section speak |
| **Defensive hedging** | "You might want to consider checking..." | "Check X" |
| **History as content** | "In our testing we found that..." | Extract the finding, delete the story |
