# AI Dev Template

A reusable repo scaffold for AI-assisted development. Clone this for any new project to start with harness constraints and cost-conscious context management already in place, instead of rebuilding discipline from scratch each time.

## Goals

1. **Harness** — constrain what an AI coding agent can touch, require verification (tests) before accepting changes, and leave an audit trail of what changed and why.
2. **Cost discipline** — keep context small and relevant instead of re-explaining project state every session.
3. **Tool-agnostic** — instructions live in a format any AI coding agent can read (AGENTS.md), not locked to one vendor.

## Stack

Node/TypeScript. Test runner: Vitest (or Jest — pick one and be consistent; Vitest is lighter to configure for a small project). Linter/formatter: ESLint + Prettier.

## Structure to scaffold

```
project-root/
├── AGENTS.md              # primary instructions, tool-agnostic (see below)
├── CLAUDE.md               # thin pointer file: "See @AGENTS.md for project instructions"
├── .claude/
│   └── settings.json        # hooks config (see Enforcement notes below)
├── src/                     # project code, organized by module
├── tests/                   # mirrors src/ structure
├── docs/
│   ├── CONTEXT.md           # current task, decisions, open questions — pruned regularly
│   └── CHANGES.md           # log of AI-assisted changes
├── .eslintrc / eslint.config.js
├── .prettierrc
├── .gitignore
├── package.json             # includes test, lint, format scripts
└── vitest.config.ts (or jest.config.ts)
```

## AGENTS.md — content requirements

Plain markdown, no required schema. Keep it lean — per research on context file quality, commands/constraints/non-standard patterns improve agent behavior more than architecture prose, so skip a general "how this system works" section and favor concrete, verifiable rules.

Sections, in this order:

1. **Project overview** — one or two sentences: what this project is, primary language/framework and version.
2. **Build and test commands** — exact commands with flags (not vague tool names), e.g. `pytest tests/ -v`, not "run the tests."
3. **Code style guidelines** — only rules that differ from language defaults. Don't restate what a linter/formatter already enforces.
4. **Testing instructions** — how to run the full suite, how to run a single test, what (if anything) should be mocked.
5. **Boundaries** — explicit list of files/directories the agent should not modify without asking first (this is the core harness mechanism).
6. **Security considerations** — secrets handling, files to never read or commit.
7. **Commit/PR guidelines** — branch naming, commit message format if any.

Do not auto-generate this file via an agent's `/init` command and leave it as-is — LLM-generated context files tend to be over-broad and increase reasoning cost without improving outcomes. Use `/init` (if available) only as a rough first draft, then cut it down to concrete, verifiable rules.

## CLAUDE.md — content

Claude Code does not natively read AGENTS.md, so this file exists purely to point it there:

```markdown
# Claude Code Instructions

See @AGENTS.md for project instructions, conventions, and boundaries.
```

## docs/CONTEXT.md — template

This is the context-management piece (the "Obsidian-style" approach) — pull in only current, relevant state instead of re-explaining project history each session. Prune the "Recently Completed" section aggressively; this is where context bloat creeps in.

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

## Enforcement notes

The actual harness is the hooks, not AGENTS.md. These two mechanisms serve different roles:

| Mechanism | Role |
|---|---|
| AGENTS.md boundaries | Guides the model's choices (soft) |
| Hooks | Enforces outcomes at fixed lifecycle points (hard) |

Instructions in AGENTS.md/CLAUDE.md are text in the model's context window. The model is statistically likely to follow them, but there is no mechanism that forces compliance — context pressure or a long conversation can cause drift, and an agent can in principle ignore them entirely. Think of AGENTS.md as a policy document: it shapes behavior between enforcement points, but it is not a safety rail.

**Hooks are deterministic**: they run as shell commands at fixed lifecycle events and fire every time, with no exceptions. A hook that exits 2 on a failing test cannot be talked past — it blocks the tool call at the harness level, not the model level. For anything that must not be bypassed (committing without tests, touching a protected file), use a hook or a filesystem permission, not an instruction.

Two hooks to scaffold in `.claude/settings.json`, targeting this stack:

**1. Pre-commit quality gate (PreToolUse on Bash)** — blocks a `git commit` if lint/tests fail. Exit code 2 blocks the tool call and Claude sees the output, which typically causes it to fix the issue and retry.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/pre-commit-check.sh"
          }
        ]
      }
    ]
  }
}
```

`pre-commit-check.sh` should: read the pending Bash command from stdin (JSON), check if it starts with `git commit`, and if so run `npm run lint && npm run test` — exit 2 with the failure output on stdout/stderr if either fails, exit 0 otherwise.

**2. Auto-format on file write (PostToolUse on Edit|Write)** — keeps diffs clean so review isn't cluttered by formatting noise.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "f=$(jq -r '.tool_input.file_path'); npx prettier --write \"$f\" 2>/dev/null; true"
          }
        ]
      }
    ]
  }
}
```

Other notes:

- Target under ~200 lines for CLAUDE.md-equivalent instruction content; longer files consume more context and reduce adherence.
- If AGENTS.md instructions grow large for a specific area (e.g., a subsystem with unusual conventions), split into path-scoped files under `.claude/rules/` rather than growing one large file.
- Verify hook behavior on a throwaway commit before relying on it — a misconfigured PreToolUse hook can block all Bash usage, not just commits.

## How to use this template

1. Clone this repo for a new project.
2. Fill in AGENTS.md sections 1–4 and 6–7 with actual project specifics; leave section 5 (boundaries) intentionally strict until you have reason to loosen it.
3. Start every AI-assisted session by checking docs/CONTEXT.md is current; prune before adding.
4. After each AI-assisted change: run tests, review the diff, log it in docs/CHANGES.md.
