---
name: ruflow
description: Orchestrate multi-agent Claude swarms using Ruflow (ruflo). Use for deploying parallel agent pipelines, cost-aware model routing, persistent shared memory, and enterprise-grade security across distributed Claude agent workloads.
origin: ECC
---

# Ruflow

Use this skill when coordinating multiple Claude agents in parallel, building autonomous multi-step pipelines, or replacing ad-hoc agent wiring with a production-ready orchestration layer.

## When to Activate

- User wants to run 10+ agents simultaneously on a complex task
- Building a multi-phase pipeline (plan → code → test → security → deploy)
- Need persistent shared memory across agents and sessions
- Routing tasks to different Claude model tiers to reduce API cost
- Enforcing PII handling, audit trails, or security policies across agent runs
- User says "spin up a swarm", "run agents in parallel", "orchestrate multiple agents"

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  Ruflow Orchestrator             │
│                                                 │
│  ┌───────────┐  ┌───────────┐  ┌─────────────┐ │
│  │  Swarm    │  │  Memory   │  │  Security   │ │
│  │  Router   │  │  Layer    │  │  Pipeline   │ │
│  └─────┬─────┘  └─────┬─────┘  └──────┬──────┘ │
│        │              │               │         │
│        ▼              ▼               ▼         │
│  ┌─────────────────────────────────────────┐    │
│  │            Agent Pool (60+)             │    │
│  │                                         │    │
│  │  planner  coder  tester  reviewer  sec  │    │
│  └─────────────────────────────────────────┘    │
│        │              │               │         │
│        ▼              ▼               ▼         │
│  ┌─────────────────────────────────────────┐    │
│  │           Model Tier Router             │    │
│  │  Haiku (simple) → Sonnet → Opus (hard)  │    │
│  └─────────────────────────────────────────┘    │
└─────────────────────────────────────────────────┘
```

## Installation

```bash
npm install -g ruflo@latest
ruflo init
```

Or use as a Claude Code plugin by adding to `~/.claude.json`:

```json
{
  "plugins": ["ruflo"]
}
```

## Core Concepts

### Swarm Definition

Define agents with roles, system prompts, and tool access:

```javascript
const swarm = ruflo.createSwarm({
  name: "feature-pipeline",
  agents: [
    { role: "planner",   model: "claude-opus-4-7",    tools: ["read", "search"] },
    { role: "coder",     model: "claude-sonnet-4-6",  tools: ["read", "edit", "bash"] },
    { role: "tester",    model: "claude-sonnet-4-6",  tools: ["bash", "read"] },
    { role: "reviewer",  model: "claude-haiku-4-5",   tools: ["read"] },
    { role: "security",  model: "claude-haiku-4-5",   tools: ["read", "search"] }
  ]
})
```

### Parallel Execution

Launch multiple agents concurrently — phases wait for all agents in the prior phase:

```javascript
await swarm.run({
  phases: [
    { agents: ["planner"],            input: featureSpec },
    { agents: ["coder", "security"],  input: "$planner.output" },
    { agents: ["tester", "reviewer"], input: "$coder.output" }
  ]
})
```

### Shared Memory

All agents in a swarm read from and write to a shared memory layer that persists across sessions:

```javascript
// Any agent can write
await ruflo.memory.set("feature.spec", parsedSpec)

// Any agent can read
const spec = await ruflo.memory.get("feature.spec")

// Query the knowledge graph
const related = await ruflo.memory.search("authentication patterns")
```

### Model Routing

Route by task complexity to reduce cost (up to 75% savings):

```javascript
const router = ruflo.createRouter({
  rules: [
    { match: "classify|label|format",  model: "claude-haiku-4-5" },
    { match: "implement|refactor",     model: "claude-sonnet-4-6" },
    { match: "architect|root-cause",   model: "claude-opus-4-7" }
  ],
  fallback: "claude-sonnet-4-6"
})
```

## Workflow Patterns

### Feature Pipeline

```
Input: feature spec
  ↓ planner        → task breakdown, acceptance criteria
  ↓ coder (×N)     → parallel implementation per subtask
  ↓ tester         → generate + run tests
  ↓ reviewer       → code quality check
  ↓ security       → vulnerability scan
Output: PR-ready branch
```

### Continuous Monitoring Swarm

```javascript
ruflo.schedule("0 * * * *", async () => {
  await swarm.run({
    phases: [
      { agents: ["health-checker"],  input: { endpoints: monitoredUrls } },
      { agents: ["alerter"],         input: "$health-checker.failures",
        condition: "$health-checker.failures.length > 0" }
    ]
  })
})
```

### SONA (Self-Learning) Loop

Ruflow's self-optimizing agent architecture learns from prior runs:

```javascript
const sona = ruflo.createSONALoop({
  extractPatterns: true,   // extract reusable patterns after each run
  updateSkills: true,      // update agent skill definitions automatically
  pruneFailures: true      // remove patterns that led to failures
})
```

## Security Configuration

Ruflow includes a 14-type security detection pipeline. Configure in `ruflo.config.json`:

```json
{
  "security": {
    "pii": { "detect": true, "redact": true },
    "auditLog": { "enabled": true, "path": "./logs/audit.jsonl" },
    "allowedTools": ["read", "edit", "bash", "search"],
    "blockedPatterns": ["rm -rf", "DROP TABLE", "eval("],
    "maxAgentConcurrency": 20
  }
}
```

## ECC Integration

When using Ruflow inside an ECC project, wire agents to ECC skills:

```javascript
const swarm = ruflo.createSwarm({
  agents: [
    { role: "coder",    skill: "ecc:agentic-engineering" },
    { role: "reviewer", skill: "ecc:agent-eval" },
    { role: "tester",   skill: "ecc:ai-regression-testing" }
  ]
})
```

Ruflow agents can also call ECC slash commands:

```javascript
await agent.run("/code-review --strict")
await agent.run("/tdd feature-spec.md")
```

## Cost Discipline

Track per-swarm execution:

```javascript
ruflo.on("swarm:complete", (stats) => {
  console.log(`Agents: ${stats.agentCount}`)
  console.log(`Tokens: ${stats.totalTokens}`)
  console.log(`Cost:   $${stats.estimatedCost}`)
  console.log(`Saved:  ${stats.savingsPct}% vs naive routing`)
})
```

Target: keep complex feature pipelines under $0.50 by routing simple subtasks to Haiku.

## Constraints

- Swarm concurrency cap defaults to 20 agents; raise with `maxAgentConcurrency` only if API quota allows.
- SONA loop requires at least 5 prior runs before patterns stabilize — don't rely on it for first-run correctness.
- Shared memory is eventually consistent across concurrent agents; use phase barriers rather than polling for coordination.
- Security pipeline adds ~50ms overhead per agent turn; disable only in local dev, never in production.
- All agents inherit the user's Claude API key — scope tool permissions narrowly to limit blast radius.
