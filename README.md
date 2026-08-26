# AI Dev Template

A reusable repo scaffold for AI-assisted development. Clone this for any new project to start with harness constraints and cost-conscious context management already in place, instead of rebuilding discipline from scratch each time.

## Goals

1. **Harness** — constrain what an AI coding agent can touch, require verification (tests) before accepting changes, and leave an audit trail of what changed and why.
2. **Cost discipline** — keep context small and relevant instead of re-explaining project state every session.
3. **Agent-agnostic** — enforcement lives at the container and git level, not inside any one agent's config. Instructions live in AGENTS.md, readable by any agent.

## Structure

```
project-root/
├── AGENTS.md                        # primary instructions, agent-agnostic
├── CLAUDE.md                        # thin pointer: "See @AGENTS.md"
├── docker-compose.yml               # container sandbox + egress proxy
├── .devcontainer/
│   ├── devcontainer.json            # devcontainer entrypoint (uses compose)
│   ├── Dockerfile                   # workspace image (language-agnostic base)
│   ├── Dockerfile.proxy             # tinyproxy image
│   ├── tinyproxy.conf               # proxy config: FilterDefaultDeny + domain allowlist
│   └── proxy-entrypoint.sh          # populates filter file at proxy startup
├── .githooks/
│   ├── pre-commit                   # quality gate (lint + test) + secret file block
│   └── pre-push                     # blocks force push to main/master
├── hooks/
│   ├── allowed-domains.txt          # egress allowlist (base domains; extend per project)
│   ├── config                       # TEST_CMD and LINT_CMD — fill in per project
│   └── install.sh                   # sets core.hooksPath and makes hooks executable
├── .claude/
│   └── settings.json                # Claude-specific layer: deny list + auto-formatter
├── src/                             # project code
├── tests/                           # mirrors src/
├── docs/
│   ├── CONTEXT.md                   # current task, decisions, open questions — pruned each session
│   └── CHANGES.md                   # log of AI-assisted changes
└── .gitignore
```

## Enforcement layers

The harness has three layers, from hardest to softest:

### 1. Container (hard)

`docker-compose.yml` runs two services:

- **workspace** — capability-dropped (`--cap-drop=ALL`), non-root user (`agent`), no direct internet access. The agent works here.
- **proxy** — tinyproxy with `FilterDefaultDeny Yes` and a per-domain allowlist. All outbound HTTP/HTTPS from the workspace routes through it.

The workspace container has no path to the internet except through the proxy, so domain enforcement happens at the hostname level and handles DNS churn correctly (unlike iptables, which resolves IPs once at startup and goes stale).

Base allowlist (`hooks/allowed-domains.txt`):
```
github.com
api.github.com
objects.githubusercontent.com
api.anthropic.com
```

To add a domain: append it to `hooks/allowed-domains.txt` and run `docker compose build proxy && docker compose up -d proxy`.

### 2. Git hooks (medium)

`hooks/install.sh` sets `core.hooksPath .githooks` so hooks fire for any agent that uses git — no agent-specific config required.

**`.githooks/pre-commit`**
- Blocks staged files matching secret patterns (`.env`, `*.pem`, `*.key`, `*secret*`, `*credential*`, etc.)
- Runs `LINT_CMD` then `TEST_CMD` from `hooks/config`; exits 1 with output on failure
- If `hooks/config` is unconfigured, warns and exits 0 (graceful degradation)

**`.githooks/pre-push`**
- Detects force push to `main`/`master` by checking whether the remote sha is an ancestor of the local sha
- Exits 1 with a message if so

### 3. Instructions (soft)

AGENTS.md guides agent behavior between the above checkpoints. Instructions are text in the model's context window — the model is statistically likely to follow them, but cannot be forced to. Think of AGENTS.md as a policy document, not a safety rail. For anything that must not be bypassed, use a hook or the container, not an instruction.

### Claude Code layer (optional)

`.claude/settings.json` adds two Claude-specific enhancements on top of the above:

- **`permissions.deny`** — blocks destructive Bash patterns (`rm -rf *`, `git reset --hard`, `git push --force`, piping to `bash`/`sh`)
- **Auto-formatter** — runs `prettier --write` on every file after an Edit or Write tool call

This layer is additive. The core harness (container + git hooks) works without it.

## AGENTS.md — content requirements

Plain markdown, no required schema. Sections, in this order:

1. **Project overview** — one or two sentences: what this project is, primary language/framework and version.
2. **Build and test commands** — exact commands with flags. Also fill in `hooks/config` so the pre-commit gate knows what to run.
3. **Code style guidelines** — only rules that differ from language defaults.
4. **Testing instructions** — full suite, single test, what to mock.
5. **Boundaries** — files/directories the agent must not modify without confirmation. Default: `.devcontainer/`, `.githooks/`, `hooks/`, `docker-compose.yml`, `.gitignore`, CI/infra files.
6. **Security considerations** — secrets handling, files to never read or commit.
7. **Commit/PR guidelines** — branch naming, commit message format.

Do not auto-generate this file via an agent's `/init` command and leave it as-is. Use `/init` only as a rough first draft, then cut it down to concrete, verifiable rules.

## docs/CONTEXT.md — template

Pull in only current, relevant state instead of re-explaining project history each session. Prune "Recently Completed" aggressively — this is where context bloat creeps in.

```markdown
## Current Task
(one paragraph — what you're working on right now)

## Decisions Made
- decision — why

## Open Questions
-

## Recently Completed
(keep this short — prune old entries)
```

## docs/CHANGES.md — format

One line per AI-assisted change. This is the audit trail that makes "I review every diff" a demonstrable habit rather than a claim.

```
YYYY-MM-DD | Short description of change | Diff reviewed: yes/no | Tests passed: yes/no
```

## How to use this template

1. Clone this repo for a new project.
2. Fill in `AGENTS.md` sections 1–4 and 6–7 with project specifics; leave section 5 (boundaries) strict until you have reason to loosen it.
3. Set `TEST_CMD` and `LINT_CMD` in `hooks/config`.
4. Add any required domains to `hooks/allowed-domains.txt` (e.g. `registry.npmjs.org`, `pypi.org`).
5. Open in a devcontainer (`Reopen in Container` in VS Code or Claude Code) — `postCreateCommand` runs `hooks/install.sh` automatically.
6. Start every AI-assisted session by checking `docs/CONTEXT.md` is current; prune before adding.
7. After each AI-assisted change: run tests, review the diff, log it in `docs/CHANGES.md`.

## Extending for a specific language

Language-specific variants should:
- Swap the workspace base image in `.devcontainer/Dockerfile` (e.g. `node:22-slim`, `python:3.12-slim`)
- Add package manager domains to `hooks/allowed-domains.txt`
- Fill in `hooks/config` with real test and lint commands
- Add language tooling (`package.json`, `pyproject.toml`, etc.) to the project root

The devcontainer, proxy, git hooks, and AGENTS.md structure stay unchanged.
