# Plan Critique

> Task: validate-agents
> Reviewed: 2026-02-23T17:01:50Z
> Verdict: has objections

## Objections

### Objection 1: `set -euo pipefail` will cause premature exit on grep non-match

- **Category:** internal-consistency
- **Severity:** high
- **Affected tasks:** Task 1.1
- **Evidence:** Task 1.1 Action step 1 specifies `set -euo pipefail`. Step 7c specifies using `grep` on the filtered content to check for each required section heading. `grep` exits with code 1 when no match is found.
- **Problem:** With `set -e` active, the first `grep` that fails to find a required section (which is the *expected* path for missing sections) will terminate the script immediately instead of recording the missing section and continuing. This directly contradicts Success Criterion 7 ("reports all failures across all files before exiting") and the script's core purpose of detecting missing sections. An executor following the Action literally will produce a script that crashes on the first missing heading.
- **Suggestion:** Either (a) suppress `set -e` for the grep calls using `if ! grep ...` constructs, with the Action field specifying this pattern explicitly, or (b) use `set -uo pipefail` without `-e` and handle exit codes manually throughout. Option (a) is cleaner since `-e` is useful elsewhere. The Action field should specify the exact idiom for step 7c: `if ! echo "$filtered" | grep -q '^## Role[[:space:]]*$'; then missing+=("Role"); fi`.

### Objection 2: Negative test scenario 2 (code block immunity) does not test the critical failure path

- **Category:** internal-consistency
- **Severity:** medium
- **Affected tasks:** Task 2.1
- **Evidence:** Task 2.1 scenario 2 ("Code block immunity") creates a file with all 5 real H2 sections present PLUS a duplicate `## Success Criteria` inside a fenced code block, and expects PASS.
- **Problem:** This test only verifies that the real heading outside the code block is found. A naive script that does *not* strip code blocks would also pass this test, because the real `## Success Criteria` heading outside the code block satisfies the check regardless. The test does not exercise the actual failure path that code-block stripping exists to prevent: a required section heading that appears *only* inside a code block and nowhere else. Without testing this path, the most complex logic in the script (the state-machine code-block parser from Task 1.1 step 7a) has no verification that it works when it matters.
- **Suggestion:** Add a 7th scenario (or replace scenario 2) where a required section heading (e.g., `## Workflow`) exists *only* inside a fenced code block and does not appear as a real H2 anywhere in the file. The other 4 required sections should be present as real headings. Expected: exit code 1, output contains FAIL and lists the section that is only inside the code block. This directly validates Success Criterion 6.

### Objection 3: Task 1.1 Action does not specify frontmatter-skipping order relative to code-block stripping

- **Category:** internal-consistency
- **Severity:** medium
- **Affected tasks:** Task 1.1
- **Evidence:** Task 1.1 Action step 7a says "Strip fenced code blocks before scanning for headings" using a state-machine approach. Step 7b says "Skip YAML frontmatter: also skip lines between the opening `---` (first line) and the next `---` line." The steps are listed a then b, but the implementation must process lines top-to-bottom, and frontmatter appears at the top of every file.
- **Problem:** If an executor implements step 7a first (code-block state machine) and step 7b second (frontmatter skip) as separate passes, the frontmatter `---` lines will be processed by the code-block state machine on the first pass. While `---` lines don't match the backtick fence pattern so they wouldn't toggle code-block state, this two-pass approach is unnecessarily complex. More importantly, if an executor implements a single-pass reader (the natural approach for a state machine), they need to know that frontmatter processing comes *before* code-block processing in the line-by-line scan. The current ordering of a/b implies code blocks first, frontmatter second, which is backwards for a top-to-bottom reader.
- **Suggestion:** Reorder and merge steps 7a and 7b into a single-pass description. Specify a top-to-bottom line reader with three states: `in_frontmatter` (initial state if line 1 is `---`), `in_codeblock`, and `normal`. Transition from `in_frontmatter` to `normal` on the closing `---`. Then track code-block fences. Only collect lines in `normal` state for heading search.

### Objection 4: Missing `scripts/` directory creation

- **Category:** codebase-alignment
- **Severity:** medium
- **Affected tasks:** Task 1.1
- **Evidence:** ARCHITECTURE.md directory structure and STACK.md project structure show no `scripts/` directory exists in the repo. Task 1.1 Files affected lists `scripts/validate-agents.sh` but the Action does not mention creating the `scripts/` directory.
- **Problem:** The `scripts/` directory does not exist. An executor using the Write tool to create `scripts/validate-agents.sh` would likely have the directory created implicitly, but the plan's Action field is meant to be specific enough to act without interpretation (plan-schema.md line 92: "must not require the executor to make architectural decisions"). The `chmod +x` step is mentioned (step 10) but directory creation is not. This is minor but consistent with the Action specificity standard the plan otherwise meets well.
- **Suggestion:** Add a step 0 to the Action: "Create the `scripts/` directory at the project root if it does not exist." Or note it in the Action preamble.

## Observations

- The prior critique's Objection 1 (missing `VALIDATE_AGENTS_DIR` override) has been fully addressed -- Task 1.1 step 3 now includes the env var override and Task 2.1 references it cleanly.
- The prior critique's Objection 2 (ambiguous testing approaches) has been fully addressed -- Task 2.1 now commits to a single approach with 6 clearly numbered scenarios.
- The prior critique's Objection 3 (Task 2.2 redundancy) has been fully addressed -- Task 2.2 is gone; the re-verification is now the final step of Task 2.1.
- The prior critique's Objection 4 (fence annotation matching) has been partially addressed -- the Action now specifies "prefix match only" and "without a `$` end anchor," which is clear. Not re-raising.
- The plan correctly defers frontmatter validation (YAML fields) to future work, consistent with the task scope.
- The `\x60\x60\x60` hex escape notation for backticks is correct but unusual for bash. A comment in the generated script would help readability, but this is a stylistic preference and not an objection.
