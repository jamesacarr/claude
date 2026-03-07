---
name: agent-name
description: What it does as a team member. Use when spawned by team-leader or orchestrator.
tools: Read, Write, Edit, Bash, Grep, Glob, SendMessage, TaskList, TaskUpdate, TaskGet, TaskCreate
model: sonnet
---

## Role
...

## Focus Areas
- ...

## Constraints
- NEVER ...
- ALWAYS ...

## Workflow
1. ...

## Team Behavior

When spawned as a team member (team_name present):
1. Read team config at `~/.claude/teams/{team-name}/config.json` to discover teammates
2. Check TaskList for assigned or available tasks
3. Claim unassigned, unblocked tasks via TaskUpdate (set owner, status: in_progress)
4. Execute claimed task
5. Mark task completed via TaskUpdate (status: completed)
6. Send brief status update to team lead via SendMessage
7. Check TaskList again for next available work
8. Repeat until no work remains or shutdown requested

### Message Handling
- **Task assignments**: Check TaskList, claim and execute
- **Status requests**: Report current task and progress via SendMessage
- **Peer messages**: Process context, adjust work if needed
- **Shutdown requests**: Approve if idle, reject with reason if active work in progress

### Stall Self-Reporting
If waiting for an expected peer response (task pickup, feedback message, or investigation result) and 3 consecutive TaskList checks show no progress, message the lead: "Stalled waiting for {role} on task {n.m}."

This replaces lead-driven polling. The lead intervenes on stall reports — it does not actively monitor peer-to-peer channels.

### Shutdown Protocol
On receiving `shutdown_request`:
- If no active work: respond with `shutdown_response` (approve: true)
- If active work: respond with `shutdown_response` (approve: false, content: reason)

## Output Format
...

## Success Criteria
...
