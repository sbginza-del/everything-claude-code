---
name: new-project
description: >-
  Scaffold a new software project from scratch: initialize git, set up a
  package manager, configure linting/testing/CI, write a CLAUDE.md, and
  produce a working skeleton ready for feature development.
  TRIGGER when: user says "start a new project", "scaffold", "create a new
  app/service/library", or asks to bootstrap a greenfield codebase.
  DO NOT TRIGGER when: the current directory already contains an established
  codebase with a package manifest and committed history.
origin: ECC
---

# New Project Scaffold

Bootstrap a greenfield project end-to-end: version control, package management,
tooling, tests, CI, and a CLAUDE.md that gives future Claude sessions instant
context.

## When to Use

- User wants to start a brand-new app, service, library, or CLI tool
- User says "scaffold", "bootstrap", "create a new project", or "initialize"
- The working directory is empty or contains only a README/LICENSE

**Do not use** when an established codebase with a package manifest and commit
history already exists — use `codebase-onboarding` instead.

## How It Works

The skill runs five phases in order. Each phase has a clear exit criterion
before moving to the next.

---

### Phase 1: Gather Intent

Ask (or infer from context) the minimum set of decisions needed to proceed:

| Question | Fallback if not specified |
|----------|--------------------------|
| Project name | Directory name |
| Language / runtime | TypeScript (Node.js) |
| Project type | Library (smallest footprint) |
| Package manager | npm |
| Testing framework | Vitest (TS/JS), pytest (Python), go test (Go) |
| Target Node.js version (if JS/TS) | LTS (`>=20`) |

Do **not** ask about CI provider, linting config, or Docker at this stage —
apply sensible defaults and document them in CLAUDE.md.

---

### Phase 2: Version Control

```bash
git init
git checkout -b main          # default branch = main
```

Create `.gitignore` immediately so generated files are never accidentally staged.

**Minimal `.gitignore` by language:**

```
# Node.js / TypeScript
node_modules/
dist/
.env
.env.local
*.tsbuildinfo
coverage/

# Python
__pycache__/
*.pyc
.venv/
dist/
*.egg-info/

# Go
/bin/
*.test
```

---

### Phase 3: Project Skeleton

Produce the smallest skeleton that compiles, passes a smoke test, and has a
working lint check. No extra files, no boilerplate comments.

#### Node.js / TypeScript (default)

```
<project>/
├── src/
│   └── index.ts          # single entry point
├── tests/
│   └── index.test.ts     # one passing smoke test
├── package.json
├── tsconfig.json
├── .eslintrc.json  (or eslint.config.js for ESLint v9+)
└── vitest.config.ts
```

**`package.json` scripts (minimum viable set):**

```json
{
  "scripts": {
    "build":  "tsc",
    "test":   "vitest run",
    "lint":   "eslint src tests",
    "typecheck": "tsc --noEmit"
  }
}
```

#### Python

```
<project>/
├── src/<package>/
│   └── __init__.py
├── tests/
│   └── test_smoke.py
├── pyproject.toml          # build backend: hatchling or flit
└── README.md
```

**`pyproject.toml` tool table (minimum viable):**

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]

[tool.ruff]
line-length = 100
```

#### Go

```
<project>/
├── cmd/<project>/
│   └── main.go
├── internal/
├── go.mod
└── go.sum
```

#### Other languages

Apply the same principle: one entry point, one test, one lint command, no
speculative directories.

---

### Phase 4: Tooling & CI

#### Linting / formatting

| Language | Tool | Config file |
|----------|------|-------------|
| TypeScript/JS | ESLint + Prettier | `eslint.config.js`, `.prettierrc` |
| Python | Ruff | `pyproject.toml [tool.ruff]` |
| Go | `gofmt` + `golangci-lint` | `.golangci.yml` |
| Markdown | markdownlint-cli | `.markdownlint.json` |

Keep lint config minimal — only rules that catch real bugs or enforce a single
consistent style. Avoid 50-rule config dumps.

#### GitHub Actions CI (`.github/workflows/ci.yml`)

Generate a `ci.yml` that runs on every push and pull-request to `main`:

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4        # or setup-python / setup-go
        with:
          node-version: "20"
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test
```

Adapt `setup-*` and run commands to the detected language. Do not add caching,
matrix builds, or deployment steps unless the user explicitly asks.

---

### Phase 5: CLAUDE.md

Write a `CLAUDE.md` at the project root that gives a fresh Claude Code session
everything it needs in under 60 lines.

```markdown
# CLAUDE.md

## Project

[One-sentence description of what this project does]

## Tech Stack

- Language: TypeScript (Node.js >=20)
- Package manager: npm
- Test runner: Vitest
- Linter: ESLint + Prettier

## Common Commands

\`\`\`bash
npm test          # run tests
npm run lint      # lint
npm run typecheck # type-check without emitting
npm run build     # compile to dist/
\`\`\`

## Structure

\`\`\`
src/       source files
tests/     test files (mirror src/ structure)
dist/      compiled output (git-ignored)
\`\`\`

## Conventions

- Commit style: conventional commits (feat, fix, docs, test, chore)
- Branch naming: feature/<slug>, fix/<slug>
- Keep PRs focused: one logical change per PR
\`\`\`
```

---

### Completion Checklist

Before reporting the scaffold as done, verify each item:

- [ ] `git init` completed, `.gitignore` committed
- [ ] `npm install` (or equivalent) exits 0
- [ ] `npm run build` exits 0
- [ ] `npm test` exits 0 with at least one passing test
- [ ] `npm run lint` exits 0 with no warnings
- [ ] `.github/workflows/ci.yml` present and valid YAML
- [ ] `CLAUDE.md` written, under 60 lines, describes real commands

If any item fails, fix it before moving on — do not hand the user a broken
scaffold.

---

## Anti-Patterns

- **Over-scaffolding**: Do not generate `docker-compose.yml`, Kubernetes
  manifests, Storybook, or any infrastructure files unless explicitly requested.
- **Placeholder comments**: Generated code must be real, runnable code.
  Remove `// TODO: implement` stubs.
- **Huge `package.json`**: Install only what Phase 3 actually uses. No
  speculative dependencies.
- **Config file bloat**: One lint rule file, not five. No `.editorconfig`
  unless the user asks.
- **Wrong default branch**: Always create `main`, never `master`.

## Examples

### Minimal TypeScript library

```
User: "Create a new TypeScript utility library called string-kit"
```

Phase 1 infers: name=`string-kit`, language=TypeScript, type=library, pm=npm.  
Phase 2 inits git.  
Phase 3 produces `src/index.ts` + `tests/index.test.ts` + config files.  
Phase 4 writes `eslint.config.js`, `.prettierrc`, `.github/workflows/ci.yml`.  
Phase 5 writes `CLAUDE.md`.  
Checklist passes → done.

### Python CLI tool

```
User: "Bootstrap a Python CLI called data-fetch"
```

Phase 1 infers: name=`data-fetch`, language=Python, type=CLI.  
Skeleton: `src/data_fetch/__init__.py` + `src/data_fetch/cli.py` (Click entry
point) + `tests/test_smoke.py`.  
Tooling: Ruff for lint, pytest for tests, hatchling build backend.  
CI: `setup-python@v5`, `pip install -e ".[dev]"`, `ruff check`, `pytest`.

### Go microservice

```
User: "Start a new Go service called invoice-api"
```

Phase 1 infers: name=`invoice-api`, language=Go.  
Skeleton: `cmd/invoice-api/main.go` (HTTP server, single `/health` route) +
`internal/` + `go.mod`.  
CI: `setup-go@v5`, `go vet ./...`, `go test ./...`.
