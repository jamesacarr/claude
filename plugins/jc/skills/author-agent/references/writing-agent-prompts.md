# Writing Agent Prompts

> Core principles, structure conventions, examples, and anti-patterns for writing effective agent prompts. Covers subagent, forked skill, and team member capabilities.

## Key Insight
Agent prompts should be task-specific, not generic. They define a specialized role with clear focus areas, workflows, and constraints.

**Critical**: Agent .md files use pure Markdown structure (no XML tags). Standardized headings improve parsing and token efficiency.

## Markdown Structure Rule
**Use Markdown headings (##, ###) to structure agent body.** Use semantic heading names.

Keep markdown formatting WITHIN content (bold, italic, lists, code blocks, links).

## Core Principles

| Principle | Bad | Good |
|-----------|-----|------|
| **Specificity** | "You are a helpful coding assistant" | "You are a React performance optimizer. Analyze components for hooks best practices, unnecessary re-renders, and memoization opportunities." |
| **Clarity** | "Help with tests" | "You are a test automation specialist. Write comprehensive test suites using the project's testing framework. Focus on edge cases and error conditions." |
| **Constraints** | No constraints specified | Use strong modal verbs (MUST, SHOULD, NEVER, ALWAYS) to reinforce critical boundaries |

## Canonical Example: Security Reviewer

```markdown
---
name: security-reviewer
description: Reviews code for security vulnerabilities. Use proactively after any code changes involving authentication, data access, or user input.
tools: Read, Grep, Glob, Bash
model: sonnet
---

## Role
You are a senior security engineer specializing in web application security.

## Focus Areas
- SQL injection vulnerabilities
- XSS (Cross-Site Scripting) attack vectors
- Authentication and authorization flaws
- Sensitive data exposure
- CSRF (Cross-Site Request Forgery)
- Insecure deserialization

## Constraints
- Focus only on security issues, not code style
- Provide actionable fixes, not vague warnings
- If no issues found, confirm the review was completed

## Workflow
1. Run git diff to identify recent changes
2. Read modified files focusing on data flow
3. Identify security risks with severity ratings
4. Provide specific remediation steps

## Severity Ratings
- **Critical**: Immediate exploitation possible, high impact
- **High**: Exploitation likely, significant impact
- **Medium**: Exploitation requires conditions, moderate impact
- **Low**: Limited exploitability or impact

## Output Format
For each issue found:
1. **Severity**: [Critical/High/Medium/Low]
2. **Location**: [File:LineNumber]
3. **Vulnerability**: [Type and description]
4. **Risk**: [What could happen]
5. **Fix**: [Specific code changes needed]
```

### Comparison: Examples by Role

| Role | Key Sections | Tools | Model |
|------|-------------|-------|-------|
| **Security Reviewer** | Focus Areas, Severity Ratings, Output Format | Read, Grep, Glob, Bash | sonnet |
| **Test Writer** | Testing Philosophy, Test Structure (AAA), Quality Criteria | Read, Write, Grep, Glob, Bash | sonnet |
| **Debugger** | Debugging Methodology (7 steps), Common Bug Patterns | Read, Edit, Bash, Grep, Glob | sonnet |

## Team Agent Prompts

Team members need additional sections beyond the standard subagent structure.

### Required: `## Team Behavior` Section

Every team agent must include a `## Team Behavior` section that covers:

```markdown
## Team Behavior

When spawned as a team member:
1. Read team config at `~/.claude/teams/{team-name}/config.json` to discover teammates
2. Check TaskList for assigned or available tasks
3. Claim unassigned tasks via TaskUpdate (set owner to your name)
4. Send status updates to team lead via SendMessage after completing tasks
5. After completing a task, check TaskList for next available work
6. Handle shutdown requests by approving via shutdown_response

When spawned as a standalone subagent (no team_name):
- Execute the task from the prompt
- Return results per I/O contract
- No team coordination
```

### Message Handling

Team agents must handle these message types:
- **Task assignments:** Team lead sends work via SendMessage → agent reads, claims task, executes
- **Status requests:** Team lead asks for progress → agent responds with current state
- **Shutdown requests:** Team lead sends `shutdown_request` → agent responds with `shutdown_response`
- **Peer messages:** Other teammates send coordination messages → agent processes and responds

### TaskList-Driven Workflow

Team agents should follow this loop:
1. Check `TaskList` for tasks assigned to them (or unclaimed tasks)
2. Claim a task via `TaskUpdate` (set `owner` and `status: in_progress`)
3. Execute the task
4. Mark complete via `TaskUpdate` (`status: completed`)
5. Send summary to team lead via `SendMessage`
6. Return to step 1

### Peer Discovery

Agents discover teammates by reading the team config:
```markdown
Read ~/.claude/teams/{team-name}/config.json

The config contains a `members` array with:
- `name`: Use this for messaging (SendMessage recipient)
- `agentId`: Internal ID (for reference only)
- `agentType`: Role/type of the agent
```

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| **Too Generic** | "You are a helpful assistant that helps with code" — no specialization | Specific role + domain: "You are a React performance optimizer specializing in hooks and memoization" |
| **No Workflow** | "You are a code reviewer. Review code for issues." — skips steps, inconsistent | Numbered workflow: git diff → read files → check for issues → provide feedback |
| **Unclear Trigger** | `description: Helps with testing` — too vague for automatic invocation | Include trigger keywords + when to use: `description: Creates comprehensive test suites. Use when new code needs tests or test coverage is insufficient.` |
| **Missing Constraints** | No constraints — agent might modify wrong code, run dangerous commands | Add `## Constraints` with MUST/NEVER/ALWAYS for hard boundaries |
| **Requires User Interaction** | Prompt includes "ask user", "present options", "wait for confirmation" | Move user interaction to main chat. See [agents.md](agents.md#execution-models) for execution models. |
| **Team Agent Missing Coordination** | Team agent has no `## Team Behavior`, doesn't poll TaskList | Add `## Team Behavior` section, include coordination tools, handle shutdown |

### Description Optimization

The `description` field is critical for automatic invocation. LLM agents use descriptions to make routing decisions.

**Description must be specific enough to differentiate from peer agents.**

| Quality | Example |
|---------|---------|
| Bad (too vague) | `description: Helps with testing` |
| Bad (not differentiated) | `description: Billing agent` |
| Good (specific triggers) | `description: Creates comprehensive test suites. Use when new code needs tests or test coverage is insufficient. Proactively use after implementing new features.` |
| Good (clear scope) | `description: Handles current billing statements and payment processing. Use when user asks about invoices, payments, or billing history (not for subscription changes).` |

**Tips**: Include trigger keywords matching common user requests. Specify when to use (not just what it does). Differentiate from similar agents. Include proactive triggers if agent should auto-invoke.

## Best Practices

Every agent prompt should include these sections (see canonical example above):

| Section | Purpose | Key Rule |
|---------|---------|----------|
| `## Role` | Specific expertise + domain | "You are a [role] specializing in [domain]" — never generic |
| `## Focus Areas` | Guide attention | 3-6 specific concerns |
| `## Constraints` | Prevent overreach | Use MUST/NEVER/ALWAYS for hard boundaries |
| `## Workflow` | Ensure consistency | Numbered steps, explicit sequence |
| `## Output Format` | Structured results | Define exact format consumers expect |
| `## Success Criteria` | Define "done" | Measurable completion conditions |
| `## Example` | Clarify complex behavior | Input → expected action → output |
| `## Team Behavior` | Team coordination | Required for team member capability agents |

**Extended thinking**: For complex reasoning (debugging, security analysis, architecture review), provide high-level guidance rather than prescriptive steps. Minimum thinking budget: 1024 tokens.

**Security constraints** (when relevant): environment awareness, safe operation boundaries, data handling rules. See `agents.md` Tool Security section for details.

## Testing Agents
See `testing-agents.md` for invocation patterns, scenario design, and evaluation criteria.

**Common fix patterns**:

| Symptom | Fix |
|---------|-----|
| Too broad | Narrow focus areas |
| Skips steps | Make workflow more explicit |
| Inconsistent output | Define output format more clearly |
| Oversteps bounds | Add/clarify constraints |
| Never auto-invoked | Improve description with trigger keywords |
| Doesn't coordinate in team | Add `## Team Behavior`, include coordination tools |
