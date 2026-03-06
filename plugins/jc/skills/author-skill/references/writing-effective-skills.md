# Writing Effective Skills

> How to write skill instructions that actually change model behavior. Covers instruction style, content organization, and self-review.

## Explain Why, Not Just What

The single most impactful thing you can do: explain the reasoning behind every instruction.

Models are smart. They have good theory of mind. When given a reason, they go beyond rote compliance and adapt the principle to novel situations. When given only a mandate, they follow it literally or rationalize around it.

| Approach | Example | Effect |
|----------|---------|--------|
| **Why-first** (preferred) | "Use semantic commit messages because they make changelogs auto-generatable and help reviewers understand intent at a glance" | Model applies the principle even in edge cases |
| **Authority** (escalation) | "YOU MUST use semantic commit messages" | Model complies literally but may not generalize |

Start with reasoning. Escalate to authority language (MUST/NEVER) only when reasoning alone doesn't change behavior in TDD testing — and even then, pair it with the why.

## Keep It Lean

Every token in a skill loads on every invocation. After writing a draft:

- Read each section and ask: "If I remove this, does agent behavior change?" If not, cut it.
- Read the transcripts from test runs. If the model wastes time on steps the skill told it to do, remove those instructions.
- Each iteration should remove as much as it adds.

See references/token-efficiency.md for the full checklist.

## Generalize, Don't Overfit

You'll iterate on a few test cases, but the skill runs on thousands of prompts. Resist fiddly changes that fix one test but narrow the skill. If a stubborn issue persists, try a different framing or metaphor rather than piling on constraints.

## One Excellent Example

A single well-chosen example teaches the pattern. Three mediocre examples waste tokens repeating the same lesson. Choose the example that covers the most edge cases and shows the reasoning, not just the format.

**Defining output formats:**
```
## Report Structure
# [Title]
## Executive summary
## Key findings
## Recommendations
```

**Input → Output examples:**
```
## Commit Message Format
**Example:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

## Domain Organization

When a skill supports multiple frameworks or platforms, organize by variant:
```
cloud-deploy/
├── SKILL.md (workflow + selection logic)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```
The model reads only the relevant reference file, keeping context lean.

## Script Detection

During iteration, read subagent transcripts. If multiple test runs independently write similar helper scripts (e.g., every run creates a `validate_output.py`), that's a signal to bundle the script with the skill. Write it once in `scripts/`, and instruct the skill to use it.

## Self-Review

After writing or revising skill files, review with fresh eyes before finalizing:
- Does every instruction explain WHY, not just WHAT?
- Could any section be misinterpreted by a model following it literally?
- Is anything repeated across SKILL.md and workflow/reference files?
- Would removing any sentence change the model's behavior? If not, remove it.
