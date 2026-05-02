---
name: agent-memory
description: Persistent cross-session memory for Claude agents using a knowledge graph. Store entities, observations, and relations that survive across sessions so agents can recall project context, user preferences, and past decisions.
origin: ECC
---

# Agent Memory Skill

Gives Claude agents durable, queryable memory across sessions via the MCP memory knowledge graph.

## When to Activate

- An agent needs to remember facts between sessions (project conventions, user preferences, recurring decisions)
- You want Claude to recall what was discussed or decided in a previous session without re-explaining
- Building agents that accumulate knowledge over time (codebases, domain rules, team norms)
- Storing and retrieving research, findings, or resolved issues for future reference
- Tracking which approaches were tried and whether they succeeded

## Core Concepts

The memory system is a **knowledge graph** with three primitives:

| Primitive | Description | Example |
|-----------|-------------|---------|
| **Entity** | A named node with a type | `{ name: "project-auth", entityType: "component" }` |
| **Observation** | A fact attached to an entity | `"Uses JWT with 1h expiry"` |
| **Relation** | A directed edge between entities | `project-auth → depends_on → postgres-db` |

Observations accumulate on entities over time. Relations express how entities connect.

## Tool Reference

| Tool | Purpose |
|------|---------|
| `mcp__memory__create_entities` | Create one or more named entities |
| `mcp__memory__add_observations` | Add facts to existing entities |
| `mcp__memory__create_relations` | Link two entities with a relation type |
| `mcp__memory__search_nodes` | Fuzzy-search entities and observations by query |
| `mcp__memory__open_nodes` | Retrieve specific entities by exact name |
| `mcp__memory__read_graph` | Read the full graph (use sparingly on large graphs) |
| `mcp__memory__delete_observations` | Remove stale or incorrect facts |
| `mcp__memory__delete_relations` | Remove a relation between two entities |
| `mcp__memory__delete_entities` | Remove an entity and all its observations |

## Session Pattern

At the **start** of a session, recall relevant context:

```
1. search_nodes("project name or domain")
2. open_nodes(["key entity names you expect"])
3. Incorporate recalled facts into your working context
```

At the **end** of a session (or after a significant decision), persist new knowledge:

```
1. create_entities for any new subjects introduced
2. add_observations for facts learned this session
3. create_relations to connect new entities to existing ones
```

## Entity Naming Conventions

Use kebab-case, scoped names to avoid collisions:

```
<project>-<subject>          # project-auth, project-db
user-<preference-domain>     # user-code-style, user-testing-prefs
decision-<topic>-<date>      # decision-db-schema-2026-04
error-<package>-<symptom>    # error-prisma-connection-timeout
```

## Common Entity Types

| Type | Use for |
|------|---------|
| `project` | Top-level project facts, stack, conventions |
| `component` | Subsystems, services, modules |
| `preference` | User preferences, communication style |
| `decision` | Architectural or design decisions with rationale |
| `pattern` | Reusable patterns discovered in this codebase |
| `person` | Team members and their domains |
| `issue` | Known bugs or recurring problems |
| `dependency` | External libraries with project-specific notes |

## Example: Storing Project Context

```javascript
// Start of a new project
create_entities([
  { name: "my-app", entityType: "project",
    observations: ["Next.js 15 + Prisma + PostgreSQL", "Deployed on Vercel", "Uses pnpm"] }
])

create_entities([
  { name: "my-app-auth", entityType: "component",
    observations: ["NextAuth.js v5", "GitHub + Google providers", "Sessions stored in DB"] }
])

create_relations([
  { from: "my-app-auth", to: "my-app", relationType: "part_of" }
])
```

## Example: Storing a User Preference

```javascript
create_entities([
  { name: "user-code-style", entityType: "preference",
    observations: [
      "Prefers functional over class-based components",
      "Always wants explicit return types in TypeScript",
      "Dislikes long comment blocks"
    ] }
])
```

## Example: Recording a Decision

```javascript
create_entities([
  { name: "decision-state-management-2026-04", entityType: "decision",
    observations: [
      "Chose Zustand over Redux for lighter bundle",
      "Rejected React Context for perf-sensitive lists",
      "Revisit if app grows past 10 slices"
    ] }
])
```

## Example: Session Recall

```javascript
// At session start for "my-app"
const results = await search_nodes("my-app")
// Returns entities matching "my-app": project facts, components, decisions

const nodes = await open_nodes(["my-app", "my-app-auth", "user-code-style"])
// Returns full entity details with all observations
```

## Hygiene Rules

- **Delete stale observations** when facts change — don't let contradictions accumulate
- **Keep observations atomic** — one fact per observation, not paragraphs
- **Prefer `search_nodes` over `read_graph`** — the full graph grows large over time
- **Scope entity names** to project or domain so multi-project graphs stay navigable
- **Add observations incrementally** during a session rather than one large batch at the end

## Integration with Hooks

To auto-recall memory at session start, add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "node ~/.claude/skills/agent-memory/recall.js"
      }]
    }]
  }
}
```

A `recall.js` script can call `search_nodes` with the current working directory name and inject results as a system note.

## What to Remember vs. What to Skip

**Do remember:**
- Project stack, conventions, and constraints
- User preferences that affect every session
- Architectural decisions and their rationale
- Recurring errors and their resolutions
- Team member names and ownership areas

**Skip:**
- Ephemeral task state (todos, in-progress work)
- Facts that change every session (current branch, active PR)
- Information already in the codebase (read it fresh)
- One-time fixes for transient external issues
