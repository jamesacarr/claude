---
name: test-driven-development
description: Enforces RED-GREEN-REFACTOR TDD process discipline. Use when implementing features or bugfixes. Do NOT use for test quality guidance alone (use jc:test).
---

## Essential Principles

Every behavior starts with a failing test. No exceptions.

1. **RED first.** Write a failing test before any implementation. The test must fail for the right reason (missing behavior, not syntax error). Run it. See it fail.
2. **GREEN minimally.** Write the minimum code to pass the failing test. Nothing more.
3. **REFACTOR safely.** Clean up code while tests stay green. No new behavior during REFACTOR.
4. **Small cycles.** One behavior per RED-GREEN-REFACTOR cycle. If the cycle takes more than a few minutes, the step is too big.
5. **Run tests constantly.** After every RED, GREEN, and REFACTOR step. No silent assumptions.

For test quality (naming, assertions, mock discipline): follow `jc:test`.

## Quick Start

Before starting:
- **Test suite exists?** If no test runner is configured, set one up first
- **New feature?** Identify the simplest behavior → write a failing test → implement
- **Bugfix?** Write a test that reproduces the defect → confirm it fails → fix it

## Process

### RED — Write Failing Test

1. Identify the next behavior (one observable outcome)
2. Write a test for it (follow `jc:test` for naming, assertions, mocking)
3. Run the test suite
4. **Confirm the test fails for the right reason** — missing implementation, not import error or typo. If the failure is a compile/syntax error, fix that first before treating the test as RED
5. If the test passes without new code, it's already implemented — move to the next behavior or to verification

### GREEN — Make It Pass

1. Write the minimum code to make the failing test pass
2. Run the test suite — all tests must pass
3. Do not add code "while you're here" — only what the test demands
4. Ugly code is fine. Duplication is fine. You will refactor next

### REFACTOR — Clean Up

1. Restructure implementation and test code for clarity
2. Run tests after each change — must stay green
3. **No new behavior.** If you spot missing behavior, note it and start a new RED cycle
4. If refactoring breaks a test, undo and try a smaller step

Return to RED for the next behavior. Continue until done criteria are met.

### Phase Rules

| Boundary | Rule | Violation |
|----------|------|-----------|
| RED → GREEN | Test must be failing before writing implementation | Writing implementation without a failing test |
| GREEN → REFACTOR | All tests must be passing before refactoring | Refactoring while tests are red |
| REFACTOR → RED | No new behavior added during refactoring | Adding untested behavior during cleanup |

**Interleaving is not TDD.** Writing tests and implementation simultaneously skips the RED phase. You never see the test fail, so you never confirm it tests the right thing. Each phase has a purpose — RED validates the test, GREEN validates the implementation, REFACTOR improves the design.

## Rationalizations

| Excuse | Reality |
|--------|---------|
| "I know exactly what this should do" | Confidence is not evidence. The RED phase catches test design errors, not just implementation errors |
| "Too simple to need test-first" | Simple code breaks. A 5-line function with an off-by-one is still a bug. RED phase takes 30 seconds |
| "I'll write tests and code together" | Interleaving = never seeing the test fail = never knowing if the test actually detects the bug. A test that has never been red is unverified |
| "Just this once, for the trivial fix" | Every exception becomes the rule. The one-line fix that was "obviously correct" is the one that ships a regression |
| "Refactoring is a natural time to add features" | REFACTOR changes structure, not behavior. Adding behavior during refactor means untested behavior in production |

## Anti-Patterns

- **Gold plating in GREEN:** Adding extra functionality beyond what the failing test requires
- **Phantom GREEN:** Claiming GREEN without running the tests
- **Scope creep in REFACTOR:** "While I'm here, I'll also add..." — start a new RED cycle instead
- **Mega-cycles:** RED-GREEN-REFACTOR spanning many behaviors. Break it down — one behavior per cycle

## Success Criteria

- [ ] Every new behavior started with a failing test (RED)
- [ ] Failing tests failed for the right reason (missing behavior, not syntax/import errors)
- [ ] Implementation was minimal to pass each test (GREEN)
- [ ] No new behavior was added during REFACTOR
- [ ] Tests run after every phase transition
- [ ] Test quality follows `jc:test` principles
