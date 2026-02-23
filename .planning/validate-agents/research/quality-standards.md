# Quality & Standards Research

> Task: Add a validate-agents script that checks all agent .md files have required sections (Role, Constraints, Workflow, Output Format, Success Criteria)
> Last researched: 2026-02-23T16:52:27Z

## Security

**Low risk.** The script reads local `.md` files and outputs validation results. No user input beyond file paths, no network access, no credential handling.

Key considerations:
- **Path traversal:** The script should only read from `plugins/jc/agents/` — it must not follow symlinks or accept arbitrary paths. Glob the known directory rather than accepting user-supplied paths
- **No secret exposure:** Agent files may reference `.env` or credential patterns in their Constraints sections. The validator reads headings only, so no risk of leaking secrets in output
- **No write operations:** The script is read-only. It must never modify agent files

## Performance

**Negligible concern.** The corpus is 8 agent files (currently 100-300 lines each). Even a naive line-by-line scan completes in milliseconds. No caching, parallelism, or optimisation needed.

Considerations if the corpus grows:
- Glob the directory once rather than hardcoding filenames, so new agents are automatically included
- Avoid reading entire files into memory if files grow very large — but at current sizes this is not a concern

## Accessibility

Not applicable (no UI changes). This is a CLI validation script producing text output.

## Testing Strategy

- **Test types needed:** Unit tests (if the implementation language supports them) and integration-level manual tests. Given this codebase has no test runner (per `.planning/codebase/TESTING.md`), the primary testing approach will be manual invocation of the script against the actual agent files, plus crafting deliberately broken test fixtures.

- **Key test cases:**

  | Test Case | Why |
  |-----------|-----|
  | All 8 current agents pass validation | Baseline correctness — the script should pass on the existing, known-good corpus |
  | Agent missing `## Role` is flagged | Validates detection of each required section |
  | Agent missing `## Constraints` is flagged | Same |
  | Agent missing `## Workflow` is flagged — but `team-leader.md` uses `## Lifecycle` instead | Critical edge case: `team-leader.md` has no `## Workflow` heading. The validator must either (a) treat `## Lifecycle` as an acceptable substitute, or (b) explicitly exempt `team-leader.md` from the Workflow check. See edge cases below |
  | Agent missing `## Output Format` is flagged | Validates detection |
  | Agent missing `## Success Criteria` is flagged | Validates detection |
  | Agent with extra sections still passes | No false positives on sections beyond the required set |
  | Agent with `## Success Criteria` appearing inside a code block is NOT counted | Headings inside fenced code blocks (common in Output Format sections) must not satisfy the check |
  | Non-agent `.md` files in the directory are excluded | The directory only contains `team-*.md` files currently, but if non-agent files appear, they should be excluded |
  | Empty file is flagged with all sections missing | Boundary case |
  | Script exit code is non-zero when any agent fails | CI integration requirement |

- **Mocking approach:** No mocking needed. The script operates on real files. For negative test cases, create temporary fixture files with missing sections (in `$TMPDIR` or a test fixtures directory).

- **Edge cases to cover:**
  1. **`team-leader.md` has `## Lifecycle` instead of `## Workflow`** — this is the most important edge case. All 7 other agents have `## Workflow`, but the leader does not. The CONVENTIONS.md documents the canonical agent structure as including `## Workflow`, but the leader is a special case. The validator needs a design decision here (see Standards Checklist item 4)
  2. **`## Success Criteria` appears twice** in `team-verifier.md` (lines 155 and 250) — the first is inside the Output Format template, the second is the real one. Both are top-level `## ` headings, not inside code blocks. The validator should find at least one, so this is not a problem, but the duplicate occurrence is worth noting
  3. **Headings inside code blocks** — agents like `team-researcher.md` have `## ` headings inside markdown code blocks (e.g., the Output Format templates). A naive regex scan of `^## Section` will count these. The validator must either parse code block boundaries or use a simpler heuristic (e.g., only count headings outside of triple-backtick fences)
  4. **YAML frontmatter** — all agent files start with `---` frontmatter. The validator should skip frontmatter and not confuse `---` with section markers

- **Existing test patterns:** No automated test framework exists in this repo (per `TESTING.md`). The validation script itself becomes the first automated check. If implemented as a shell script, it should exit non-zero on failure for CI integration. If implemented as a more structured script, it should follow the error reporting pattern from `plugins/jc/docs/agent-io-contract.md` (structured `## Result` / `## Summary` / `## Details` output)

## Standards Checklist

1. Script must validate all `.md` files matching `team-*.md` in `plugins/jc/agents/` — discovered via glob, not hardcoded list
2. Script must check for these 5 required top-level `## ` sections: Role, Constraints, Workflow, Output Format, Success Criteria
3. Section detection must ignore headings inside fenced code blocks (triple-backtick regions) to avoid false positives from Output Format template examples
4. Script must handle `team-leader.md` which uses `## Lifecycle` instead of `## Workflow` — either accept `Lifecycle` as a Workflow equivalent, or document the exemption. Current CONVENTIONS.md (`/Users/jamescarr/Git/jamesacarr/claude/.planning/codebase/CONVENTIONS.md`, line 65) lists `## Workflow` as canonical but `team-leader.md` (`/Users/jamescarr/Git/jamesacarr/claude/plugins/jc/agents/team-leader.md`, line 51) uses `## Lifecycle`. **Recommendation:** accept `## Workflow` OR `## Lifecycle` for the Workflow check, since the leader's lifecycle serves the same structural purpose
5. Script must exit with non-zero status when any agent fails validation
6. Script must produce clear, actionable output: which file failed and which sections are missing
7. Script must correctly handle YAML frontmatter (skip lines between opening and closing `---`)
8. Script must not produce false positives on agent files that currently exist — all 8 agents must pass on the current corpus (assuming item 4 is addressed)
9. Script must not modify any files — read-only operation
10. Script output should follow the structured error reporting convention from `plugins/jc/docs/agent-io-contract.md` if feasible (summary + details), to be consistent with the codebase's error handling pattern
11. Script must be runnable from the project root without additional dependencies (since the project has no package manager or build tools per `STACK.md`)
