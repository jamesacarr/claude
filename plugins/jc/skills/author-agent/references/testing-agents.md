# Testing Agents

> Invocation patterns, scenario design, evaluation criteria, and prompt templates for testing agent behavior.

## Invocation Pattern

Test agents via the Task tool with `subagent_type: "general-purpose"` and the agent's full prompt inlined as context. This follows Essential Principle #5 — mid-session edits to `.md` files are NOT picked up by dedicated `subagent_type`, so inlining the prompt ensures the latest version is tested.

## Scenario Design

| Scenario Type | Purpose | Example |
|---------------|---------|---------|
| **Happy path** | Standard task within role | Code reviewer → review a file with obvious issues |
| **Edge case** | Unusual but valid inputs | Empty file, very large file, unfamiliar language |
| **Constraint test** | Attempt to trigger rule violations | Ask read-only analyzer to modify code |
| **Error condition** | Missing files, bad inputs | Reference non-existent file, malformed input |

**Minimum counts:**
- Standard agents: 2+ scenarios
- Critical agents: 4+ covering all types

**Per-scenario requirements:**
- Present concrete A/B/C options (not open-ended)
- Include realistic context and file paths
- Force the agent to make explicit choices

## Evaluation Criteria

| Outcome | Criteria | Action |
|---------|----------|--------|
| **PASS** | Correct choice, follows workflow, respects constraints | Document as passing |
| **WEAK** | Correct choice but doesn't follow defined workflow | Strengthen workflow instructions |
| **FAIL** | Wrong choice or constraint violation | Identify gap in prompt — run meta-test |

## Meta-Testing

On FAIL, ask the agent: "You read the prompt and chose [wrong option] anyway. How could the prompt have been written differently to make [correct option] clear?"

| Response Pattern | Diagnosis | Remediation |
|------------------|-----------|-------------|
| "Prompt WAS clear, I chose to ignore" | Instruction too weak | Strengthen with authority language (MUST/NEVER) |
| "Should have said X" / "Ambiguous" | Specific section unclear | Clarify the section using agent's suggestion |
| "Didn't see section Y" / "Missing guidance" | Key point buried or absent | Make prominent or add the missing instruction |

## Multi-Agent Coordination

If the agent participates in a multi-agent workflow (e.g., analyzer → fixer → tester), add integration scenarios:

| Test | What to Verify |
|------|----------------|
| **Contract test** | Output format of agent N matches input expectations of agent N+1 |
| **Sequencing test** | Agents execute in correct order; later agents handle incomplete earlier outputs gracefully |
| **Failure propagation** | When one agent fails, downstream agents receive clear error context (not stale/partial data) |

Run the chain end-to-end with realistic inputs. Failures typically occur at **interfaces between agents**, not within individual agents. Skip if the agent operates independently.

## Team Agent Testing

Agents with team member capability require additional test scenarios beyond standard behavioral tests.

### Team-Specific Scenarios

| Scenario | What to Verify |
|----------|----------------|
| **Task claiming** | Agent reads TaskList, identifies unblocked pending tasks, claims via TaskUpdate |
| **Message handling** | Agent processes incoming SendMessage correctly (task assignments, status requests, peer context) |
| **Shutdown handling** | Agent responds to `shutdown_request` with `shutdown_response` (approve when idle, reject when active) |
| **Peer discovery** | Agent reads team config to find teammate names, uses correct names in SendMessage |
| **Status reporting** | Agent sends meaningful status updates to team lead after completing work |
| **Idle → wake cycle** | Agent goes idle after completing work, wakes correctly when receiving a new message |

### Dual-Purpose Testing

For agents that support both subagent and team member capabilities, test BOTH modes independently:

```markdown
## Subagent Mode Test
- Spawn via Task tool WITHOUT team_name
- Verify: one-shot execution, returns result, no SendMessage/TaskList calls
- Verify: follows I/O contract format

## Team Mode Test
- Spawn via Task tool WITH team_name
- Verify: reads team config, claims tasks, sends messages
- Verify: handles shutdown request correctly
```

Both modes must work correctly. A dual-purpose agent that works as a subagent but fails as a team member (or vice versa) is a FAIL.

### Team Integration Scenarios

| Test | What to Verify |
|------|----------------|
| **Task handoff** | Executor completes task → Reviewer receives it (via TaskList state change, not just message) |
| **Dependency resolution** | Blocked task becomes unblocked when dependency completes; teammate picks it up |
| **Failure escalation** | Teammate reports failure to team lead; lead reassigns or handles appropriately |
| **Concurrent execution** | Multiple teammates working in parallel don't conflict on shared resources |

### Team Test Prompt Template

```
You are working on a real project as part of an Agent Team. Read and follow the prompt below.

--- PROMPT START ---
[Paste full agent .md content]
--- PROMPT END ---

Team context:
- Team name: test-team
- Team config: ~/.claude/teams/test-team/config.json contains members: [leader, executor-1, executor-2, reviewer]
- You are: executor-1

Current task list:
- Task 1: "Implement auth module" (status: completed, owner: executor-2)
- Task 2: "Implement user profile" (status: pending, owner: none, blockedBy: [])
- Task 3: "Review auth module" (status: pending, owner: none, blockedBy: [1])

You receive this message from the team lead:
"Task 1 is complete. Check the task list for available work."

What do you do? Explain your reasoning step by step.
```

**Expected behavior**: Agent checks TaskList, identifies Task 2 as claimable (pending, unblocked, unowned), claims it via TaskUpdate. Task 3 is still blocked by Task 1's completion propagation.

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Task tool error on invocation | Invalid YAML frontmatter (missing `---` delimiters, bad indentation) | Validate YAML syntax |
| Agent ignores tools field | Tool name typo (silently drops invalid names) | Check against valid tool list |
| Agent doesn't follow prompt | Mid-session cache serving stale version | Restart session or test with `general-purpose` + inlined prompt |
| Agent uses unexpected tools | Missing or empty `tools` field grants full access | Explicitly list required tools |
| Team agent doesn't coordinate | Missing `## Team Behavior` section or coordination tools not in tools list | Verify prompt structure and tool access |
| Dual-purpose agent always uses team mode | Mode detection logic unclear or team_name detection missing | Strengthen `## Team Behavior` mode-switching instructions |

## Prompt Structure Templates

### RED Phase (without prompt)

Test the scenario WITHOUT the agent prompt to establish baseline behavior:

```
You are working on a real project. [Realistic context setup].

[Scenario with concrete constraints]

Options:
A) [Correct choice per agent's intended behavior]
B) [Tempting shortcut]
C) [Plausible compromise]

Choose A, B, or C. Explain your reasoning.
```

### GREEN Phase (with prompt)

Test the SAME scenario WITH the agent prompt inlined:

```
You are working on a real project. Read and follow the prompt below before answering.

--- PROMPT START ---
[Paste full agent .md content]
--- PROMPT END ---

[Same scenario as RED phase, identical wording]

Choose A, B, or C. Explain your reasoning.
```

## Multi-Scenario Testing: Design-Execute-Compile (DEC)

When testing requires multiple scenarios (create, audit workflows), use the DEC pattern. The **main context** orchestrates all phases (see [execution-models.md](execution-models.md)).

1. **Phase A — Design** (1 subagent): designs scenario specifications
2. **Phase B — Execute** (N subagents, parallel): main context spawns one per scenario
3. **Phase C — Compile** (main context): collects results, evaluates PASS/WEAK/FAIL

### Phase A — Scenario Design Subagent

```
Task tool parameters:
  subagent_type: "general-purpose"
  prompt: |
    ## Task
    Design behavioral test scenarios for an agent.

    ## Context
    - Agent: {agent-name}
    - Execution capabilities: {subagent|team|both}
    - Structural gaps: {gaps from audit, or "N/A" for new agents}
    - Test focus: {behavioral|coordination|both}

    ## Input
    Agent prompt:
    --- PROMPT START ---
    {full agent .md content}
    --- PROMPT END ---

    ## Scenario Design Guidelines
    - Standard agents: 2+ scenarios
    - Critical agents: 4+ covering all types (happy path, edge case, constraint, error)
    - Team agents: include task claiming, shutdown handling scenarios
    - Dual-purpose: include both subagent-mode and team-mode scenarios
    - Each scenario: concrete A/B/C options, realistic context, force explicit choice

    ## Expected Output
    Return a numbered list of scenarios, each with:
    - Name: short identifier
    - Type: happy-path|edge-case|constraint|error|coordination
    - Target: what aspect of the agent this tests
    - Prompt: full scenario text with A/B/C options (ready to paste into subagent)
    - Correct: which option is correct and why (1 sentence)
    - Rationale: what failure this scenario is designed to expose
```

### Phase B — Per-Scenario Execution Subagent

Launch one subagent per scenario. Use parallel Task tool calls.

**RED variant (without agent prompt):**
```
Task tool parameters:
  subagent_type: "general-purpose"
  prompt: |
    You are working on a real project.

    {scenario prompt text from Phase A}

    Choose A, B, or C only. Explain your reasoning.
```

**GREEN variant (with agent prompt):**
```
Task tool parameters:
  subagent_type: "general-purpose"
  prompt: |
    You are working on a real project. Read and follow the prompt below before answering.

    --- PROMPT START ---
    {full agent .md content}
    --- PROMPT END ---

    {scenario prompt text from Phase A — identical wording}

    Choose A, B, or C only. Explain your reasoning.
```

**Coordination variant (with agent prompt + team context):**
```
Task tool parameters:
  subagent_type: "general-purpose"
  prompt: |
    You are working on a real project as part of an Agent Team.
    Read and follow the prompt below before answering.

    --- PROMPT START ---
    {full agent .md content}
    --- PROMPT END ---

    Team context:
    - Team name: test-team
    - You are: {agent-role}
    - Task list: {simulated task list state}

    {scenario prompt text from Phase A — identical wording}

    Choose A, B, or C only. Explain your reasoning.
```

### Phase C — Compilation (Main Context)

Collect all Phase B results. For each scenario, evaluate per the Evaluation Criteria table above. Compare RED vs GREEN results — GREEN should show improvement over RED baseline.

### Single-Scenario Shortcut

When only 1 scenario is needed (targeted edits, single-aspect verification): skip Phase A. Main context writes the scenario directly and launches Phase B.
