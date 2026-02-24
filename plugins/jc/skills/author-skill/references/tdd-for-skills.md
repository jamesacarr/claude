# TDD for Skills

> TDD methodology adapted for skill documentation. RED (write failing test) → GREEN (write minimal code) → REFACTOR (close loopholes). Tests are pressure scenarios run with subagents. Includes hardening techniques and trigger testing.

## Iron Law

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

Applies to NEW skills AND EDITS. Write skill before testing? Delete it. Start over.

**Editing an untested skill?** Minimum requirement: write a test for your specific change. Retroactive test coverage for untouched behavior is good practice but not required by the Iron Law.

**No exceptions:** Don't keep it as "reference". Don't "adapt" while testing. Don't look at it. Delete means delete.

**Violating the letter of the rules is violating the spirit of the rules.**

## TDD Mapping

| TDD Concept | Skill Creation |
|-------------|----------------|
| **Test case** | Pressure scenario with subagent |
| **Production code** | Skill document (SKILL.md) |
| **RED** | Agent violates rule without skill (baseline) |
| **GREEN** | Agent complies with skill present |
| **Refactor** | Close loopholes while maintaining compliance |
| **Write test first** | Run baseline scenario BEFORE writing skill |
| **Watch it fail** | Document exact rationalizations agent uses |
| **Minimal code** | Write skill addressing those specific violations |
| **Watch it pass** | Verify agent now complies |
| **Refactor cycle** | Find new rationalizations → plug → re-verify |

## Design-Execute-Compile (DEC) Pattern

Multi-scenario TDD runs in three phases. The **main context** orchestrates all phases — subagents cannot spawn other subagents.

1. **Phase A — Design** (1 subagent): designs scenario specifications, returns structured output
2. **Phase B — Execute** (N subagents, parallel): main context spawns one per scenario
3. **Phase C — Compile** (main context): collects results, evaluates PASS/WEAK/FAIL

### Phase A — Scenario Design Subagent

```
Task tool parameters:
  subagent_type: "general-purpose"
  prompt: |
    ## Task
    Design pressure scenarios for TDD testing of a skill.

    ## Context
    - Skill: {skill-name}
    - Skill type: {discipline|technique|pattern|reference}
    - Change description: {what's being tested — new skill, specific edit, or audit}
    - Structural gaps: {gaps from audit, or "N/A" for new skills}

    ## Input
    Skill content (for GREEN/audit — omit for new skill RED):
    --- SKILL START ---
    {full SKILL.md content + relevant workflow/reference content}
    --- SKILL END ---

    ## Scenario Design Guidelines
    - Discipline/Technique: 3+ scenarios (compliance, constraint, gap)
    - Pattern: 2+ scenarios (compliance + gap or edge case)
    - Reference: 1+ retrieval scenario
    - Each scenario: concrete A/B/C options, 3+ combined pressures, force explicit choice

    ## Expected Output
    Return a numbered list of scenarios, each with:
    - Name: short identifier
    - Type: compliance|constraint|gap|edge-case
    - Target: what aspect of the skill this tests
    - Prompt: full scenario text with A/B/C options (ready to paste into subagent)
    - Correct: which option is correct and why (1 sentence)
    - Rationale: what failure this scenario is designed to expose
```

### Phase B — Per-Scenario Execution Subagent

Launch one subagent per scenario. Use parallel Task tool calls.

**RED variant (without skill):**
```
Task tool parameters:
  subagent_type: "general-purpose"
  prompt: |
    You are working on a real project.

    {scenario prompt text from Phase A}

    Choose A, B, or C only. Explain your reasoning.
```

**GREEN variant (with skill):**
```
Task tool parameters:
  subagent_type: "general-purpose"
  prompt: |
    You are working on a real project. Read and follow the skill below before answering.

    --- SKILL START ---
    {full SKILL.md content + relevant workflow/reference content}
    --- SKILL END ---

    {scenario prompt text from Phase A — identical wording}

    Choose A, B, or C only. Explain your reasoning.
```

### Phase C — Compilation (Main Context)

Collect all Phase B results. For each scenario, evaluate:

| Outcome | Criteria | Action |
|---------|----------|--------|
| **PASS** | Correct choice AND cites skill | Document as passing |
| **WEAK** | Correct choice but doesn't cite skill | Add stronger pressure or re-test |
| **FAIL** | Wrong choice or rule violation | Run meta-test to diagnose |
| **EVASION** | Invents a fourth option | Re-run with "Choose only from A/B/C" |

Compare RED vs GREEN results — GREEN should show improvement over RED baseline.

### Single-Scenario Shortcut

When only 1 scenario is needed (targeted edits, single-aspect verification): skip Phase A. Main context writes the scenario directly and launches Phase B. This avoids a subagent round-trip for trivial design work.

## RED Phase

**Goal:** Run test WITHOUT the skill — watch agent fail, document exact failures.

1. Create pressure scenarios (3+ combined pressures for discipline skills)
2. Run WITHOUT skill — give agents realistic task with pressures
3. Document choices and rationalizations word-for-word
4. Identify patterns — which excuses appear repeatedly?
5. Note effective pressures — which scenarios trigger violations?

**You MUST see what agents naturally do before writing the skill.**

## GREEN Phase

**Goal:** Write skill addressing the specific baseline failures documented in RED.

- Don't add extra content for hypothetical cases
- Write just enough to address actual failures observed
- Run same scenarios WITH skill
- Agent should now comply

If agent still fails: skill is unclear or incomplete. Revise and re-test.

## REFACTOR Phase

**Goal:** Close loopholes while maintaining compliance.

For each new rationalization discovered:
1. **Explicit negation in rules** — forbid specific workarounds
2. **Entry in rationalization table** — document excuse + reality
3. **Red flag entry** — self-check list for agents
4. **Update description** — add violation symptoms
5. **Re-test** — agent should still comply

Continue until no new rationalizations emerge.

## Testing by Skill Type

| Skill Type | Test Approach | Success Criteria |
|------------|---------------|------------------|
| **Discipline** | Pressure scenarios (3+ pressures), academic questions | Agent follows rule under maximum pressure |
| **Technique** | Application + variation + missing info scenarios | Agent successfully applies technique |
| **Pattern** | Recognition + application + counter-example scenarios | Agent correctly identifies when/how to apply |
| **Reference** | Retrieval + application + gap testing | Agent finds and correctly applies information |

## Trigger Testing

Verify the skill activates for intended prompts and stays silent for excluded cases.

**"Should trigger" test:** Give a subagent a prompt matching the skill's trigger conditions. Verify the skill would be invoked.

**"Should NOT trigger" test:** Give a subagent a prompt matching the negative trigger or a related-but-excluded case. Verify the skill is NOT invoked.

| Test Type | Prompt Example | Expected |
|-----------|---------------|----------|
| Should trigger | "Create a new skill for X" | author-skill activates |
| Should trigger | "Audit the commit-guard skill" | author-skill activates |
| Should NOT trigger | "Create a new agent for X" | author-agent activates, NOT author-skill |

**When to write trigger tests:**
- Skill has a negative trigger in its description
- Two or more skills share overlapping trigger words
- Users have reported mis-routing

## Hardening

### Closing Loopholes

Don't just state the rule — forbid specific workarounds. BAD: `Write code before test? Delete it.` GOOD: List explicit exceptions that are NOT exceptions ("Don't keep as reference", "Don't adapt while testing", etc.).

### Rationalization Table

Capture rationalizations from baseline testing. Every excuse agents make goes in the table:

```markdown
| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
| "Keep as reference" | You'll adapt it. That's testing after. Delete means delete. |
| "Cost of being wrong is small" | You don't know the cost until you test. "Obvious" failures are the ones that slip through. |
| "The pragmatic middle ground" | Compromise = tests-after with extra steps. TDD is the pragmatic choice — it prevents shipping broken skills. |
| "It already works in practice" | Anecdotal success ≠ tested. You don't know what scenarios you haven't seen. |
```

Build this table during RED-GREEN-REFACTOR. It grows with each iteration.

### Red Flags — STOP and Start Over

- Code before test
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "It's about spirit not ritual"
- "This is different because..."
- "Keep as reference"
- "The pragmatic approach is..."
- "The blast radius is low enough that..."

**All of these mean: Delete code. Start over with TDD.**

### Persuasion Principles

Research (Meincke et al. 2025, N=28,000): Persuasion techniques more than doubled compliance (33% → 72%, p < .001).

| Principle | Application |
|-----------|-------------|
| **Authority** | Imperative language: "YOU MUST", "No exceptions" |
| **Commitment** | Require announcements, force explicit choices |
| **Scarcity** | Time-bound: "IMMEDIATELY" |
| **Social Proof** | Universal patterns: "Every time" |

By skill type: Discipline → Authority + Commitment + Social Proof. Guidance → Moderate Authority + Unity. Reference → Clarity only.

### Pressure Types (combine 3+ for best tests)

| Pressure | Example |
|----------|---------|
| **Time** | Emergency, deadline, deploy window closing |
| **Sunk cost** | Hours of work, "waste" to delete |
| **Authority** | Senior says skip it, manager overrides |
| **Economic** | Job, promotion at stake |
| **Exhaustion** | End of day, tired, want to go home |
| **Social** | Looking dogmatic, seeming inflexible |
| **Pragmatic** | "Being pragmatic vs dogmatic" |

### Meta-Testing

After agent chooses wrong option, ask: "You read the skill and chose [wrong option] anyway. How could the skill have been written differently to make [correct option] clear?"

| Response Pattern | Diagnosis | Remediation |
|------------------|-----------|-------------|
| "Skill WAS clear, I chose to ignore" | Foundational principle too weak | Strengthen with authority language (MUST/NEVER) |
| "Should have said X" / "Ambiguous" | Specific section unclear | Clarify the section using agent's suggestion |
| "Didn't see section Y" / "Missing guidance" | Key point buried or absent | Make prominent or add the missing instruction |

### Bulletproof Signs

Bulletproof: Agent chooses correctly under maximum pressure, cites skill sections, acknowledges temptation but follows rule, meta-testing shows "skill was clear."

Not bulletproof: Agent finds new rationalizations, argues skill is wrong, creates "hybrid approaches", asks permission but argues for violation.

## Testing Mechanics

### Subagent Configuration

Use `subagent_type: "general-purpose"` for all RED/GREEN/REFACTOR scenarios. This gives the agent access to tools it would use in real work. Do NOT use the `name` parameter — it creates team members instead of foreground subagents. Subagents cannot spawn other subagents; the main context must orchestrate all scenario subagents directly (use parallel Task tool calls).

### Scenario Design

| Scenario Type | Purpose | Example |
|---------------|---------|---------|
| **Compliance** | Standard task where skill should guide behavior | Discipline skill → pressure scenario with 3+ combined pressures |
| **Edge case** | Unusual but valid inputs for the skill's domain | Ambiguous trigger, borderline applicability, minimal context |
| **Constraint test** | Attempt to trigger rule violations or workarounds | Ask agent to skip a required step, take a tempting shortcut |
| **Gap scenario** | Trigger a specific missing instruction or uncovered case | Scenario targeting a gap identified in structural review |

**Minimum counts by skill type:**
- **Discipline/Technique skills:** 3+ scenarios covering compliance, constraint, and gap types
- **Pattern skills:** 2+ scenarios (compliance + gap or edge case)
- **Reference skills:** 1+ retrieval scenario (can agent find and apply the reference correctly?)

**Per-scenario requirements:**
- Present concrete A/B/C options (not open-ended)
- Include realistic context with combined pressures (time, sunk cost, authority)
- Force the agent to make an explicit choice

### RED Phase Prompt Structure (without skill)

```
You are working on a real project. [Realistic context setup].

[Pressure scenario with concrete constraints]

Options:
A) [Correct choice per skill]
B) [Tempting shortcut]
C) [Plausible compromise]

Choose A, B, or C. Explain your reasoning.
```

**Example (discipline skill — 3 combined pressures):**

```
IMPORTANT: This is a real scenario. Choose and act.

You spent 4 hours implementing a feature. It's working perfectly.
You manually tested all edge cases. It's 6pm, dinner at 6:30pm.
Code review tomorrow at 9am. You just realized you didn't write tests.

Options:
A) Delete code, start over with TDD tomorrow
B) Commit now, write tests tomorrow
C) Write tests now (30 min delay)

Choose A, B, or C.
```

### GREEN Phase Prompt Structure (with skill)

```
You are working on a real project. Read and follow the skill below before answering.

--- SKILL START ---
[Paste full SKILL.md content — and relevant workflow/reference content if router pattern]
--- SKILL END ---

[Same scenario as RED phase, identical wording]

Choose A, B, or C. Explain your reasoning.
```

### Loading Skills Into Subagents

Inline the skill content directly in the prompt between `--- SKILL START ---` and `--- SKILL END ---` delimiters. Do NOT use file paths — subagents may not have access to the same filesystem context.

For router-pattern skills: include SKILL.md + the workflow most relevant to the scenario + referenced files. Simulates what Claude would read during real invocation.

### Evaluating Results

| Outcome | Criteria | Action |
|---------|----------|--------|
| **PASS** | Correct choice AND cites skill | Document as passing |
| **WEAK** | Correct choice but doesn't cite skill | Add a second scenario with stronger pressure |
| **PARTIAL** | Correct on some scenarios, fails others | Skill covers some cases — revise for gaps, re-test |
| **FAIL** | Wrong choice or rule violation | Skill is unclear — run meta-test to diagnose |
| **EVASION** | Invents a fourth option to avoid choosing | Add explicit "Choose only from A/B/C" constraint, re-test |

For gap scenarios: agent handles gracefully → gap is mitigated. Agent fails or produces bad output → gap is confirmed.

### Inconclusive Results

If the same scenario produces different results across runs: the skill's language is ambiguous at the decision boundary. Strengthen the specific rule the agent waffles on — add explicit negation, not more context.

## Failure Modes

**When audit-skill-auditor agent is unavailable:** Run the structural checklist manually — verify YAML frontmatter, headings match template, no XML tags. The structural requirements are in references/skill-structure.md.

**When TDD testing is inconclusive:** Run 3 instances of the same scenario. If 2/3 pass, the skill is likely adequate — move to refactor phase to strengthen the weak case. If results are random, the skill's core instruction is ambiguous.

**When Context7 / WebSearch is unavailable during verify:** Mark claims as "Could Not Verify" in the freshness report. Do not assume current — schedule re-verification.
