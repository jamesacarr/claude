# Testing

> Last mapped: 2026-02-23T16:43:08Z

This codebase is a Claude Code plugin system (Markdown-based skills and agents). It contains no runtime source code and therefore no traditional test framework (no unit tests, test runner, or coverage tooling). Testing is performed through manual integration tests defined in the implementation plan.

## Test Framework

- Runner: none configured — no `package.json`, `vitest.config.*`, or test runner config exists
- The codebase defines test *philosophy* (via `plugins/jc/skills/test/SKILL.md` and `plugins/jc/skills/test-driven-development/SKILL.md`) but these are prescriptive guides for target codebases, not tests for this repo

## Test Organisation

- No automated test directories exist
- Integration test specifications are defined in `.claude/docs/plans/2026-02-21-jc-agents-skills.md` (Appendix C, Steps 24-33)
- Tests are executed manually by invoking skills and agents against target repos

## Integration Test Plan

Tests are defined in `.claude/docs/plans/2026-02-21-jc-agents-skills.md` under "Integration Testing" (Steps 24-33):

| Test | Status | What It Validates |
|------|--------|-------------------|
| Step 24: Map skill | Complete | Brownfield mapping, regeneration prompt |
| Step 25: Gate enforcement | Complete | Plan-without-map, plan-without-research, stale map detection |
| Step 26: E2E workflow | Pending | Full `/jc:map` -> `/jc:research` -> `/jc:plan` -> `/jc:implement` chain |
| Step 27: Pause/resume | Pending | Abort mid-wave, resume from worktree |
| Step 28: Failure handling | Pending | Retry exhaustion, escalation options |
| Step 29: Critique loop | Pending | Weak plan triggers objections, revision addresses them |
| Step 30: Wave review | Pending | Convention check after wave completion |
| Step 31: Status & cleanup | Pending | Accurate reporting, selective directory removal |
| Step 32: Debug | Pending | Root cause identification, session logging |
| Step 33: Team leader | Pending | Full Agent Team lifecycle |

## Test Quality Philosophy

Defined in `plugins/jc/skills/test/SKILL.md` — these principles apply when agents write tests in target codebases:

1. **Real code over mocks** — mock only external services, non-deterministic inputs, or expensive I/O
2. **Assert on behavior, not internals** — return values, thrown errors, observable side effects
3. **One behavior per test** — "and" in the test name means split it
4. **Names describe behavior** — test name states what the code does as a behavioral sentence
5. **No duplicate coverage** — each test verifies something unique

Anti-patterns reference: `plugins/jc/skills/test/references/testing-anti-patterns.md`

## TDD Process

Defined in `plugins/jc/skills/test-driven-development/SKILL.md` — enforced by the executor agent (`plugins/jc/agents/team-executor.md`):

1. **RED** — write failing test first, confirm it fails for the right reason
2. **GREEN** — write minimum code to make the test pass
3. **REFACTOR** — improve code quality, tests stay green, no new behavior

Phase boundaries are strict:
- RED -> GREEN: test must be failing before writing implementation
- GREEN -> REFACTOR: all tests must pass before refactoring
- REFACTOR -> RED: no new behavior added during refactoring

## Verification

Defined in `plugins/jc/skills/verify-completion/SKILL.md`:

- Every completion claim requires evidence (test output, command output, file verification)
- Each success criterion gets its own evidence entry
- Criteria that cannot be verified are flagged as UNVERIFIED, not silently skipped
- Verifier always runs tests itself — never trusts executor claims

## Coverage

- No coverage tooling configured for this repo
- For target codebases: coverage expectations are captured in `.planning/codebase/TESTING.md` by the mapper agent when mapping that codebase

### Prescriptive Guidance

- This repo has no automated tests to run. Validation is through manual integration testing via the skill/agent invocation chain
- When writing tests in target codebases (as the executor agent), follow the test quality principles in `plugins/jc/skills/test/SKILL.md` and the TDD process in `plugins/jc/skills/test-driven-development/SKILL.md`
- New integration test specifications should be added to the implementation plan document following the format in `.claude/docs/plans/2026-02-21-jc-agents-skills.md` (Appendix C)
- The executor agent (`plugins/jc/agents/team-executor.md`) enforces TDD discipline via preloaded skills: `jc:test` and `jc:test-driven-development`
- Mock discipline gate: before mocking, ask "What happens if I use the real thing?" If nothing bad, don't mock. Before asserting on a mock, ask "Am I testing real behavior or mock wiring?" See `plugins/jc/skills/test/references/testing-anti-patterns.md` for detailed examples
