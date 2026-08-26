# Agent Instructions

## 1. Project Overview

[FILL IN] — one or two sentences: what this project is, primary language/framework and version.

## 2. Build and Test Commands

[FILL IN] — exact commands with flags, not vague tool names.

Also fill in `hooks/config` so the pre-commit gate runs the right commands:
```sh
TEST_CMD="[your test command]"
LINT_CMD="[your lint command]"
```

## 3. Code Style Guidelines

[FILL IN] — only rules that differ from language defaults or what the linter enforces.

## 4. Testing Instructions

[FILL IN] — how to run the full suite, how to run a single test, what (if anything) should be mocked.

## 5. Boundaries

Do not modify any of the following without explicit confirmation from the user:

- `.devcontainer/` — container sandbox config; changes here affect the security boundary
- `.githooks/` — enforcement hooks; changes here weaken the harness
- `hooks/` — hook scripts and domain allowlist
- `docker-compose.yml` — network isolation config
- `.gitignore` — modifying this could expose secrets
- CI/CD config files (`.github/`, `.gitlab-ci.yml`, etc.)
- Infrastructure or deployment files

## 6. Security Considerations

- Never read, print, or commit files matching: `.env`, `*.env`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*secret*`, `*credential*`, `*token*`
- Treat any file matching the above patterns as sensitive even if the contents look benign
- Always run inside the devcontainer — do not bypass it to work directly on the host
- To extend network access, add a domain to `hooks/allowed-domains.txt` and rebuild the proxy container (`docker compose build proxy`) — do not modify `tinyproxy.conf` directly

## 7. Commit and PR Guidelines

[FILL IN] — branch naming convention, commit message format if any.

Defaults if not specified:
- Branch naming: `type/short-description` (e.g. `feat/add-auth`, `fix/null-pointer`)
- Commits: conventional commits format (`feat:`, `fix:`, `chore:`, `docs:`, etc.)
- Every AI-assisted change gets logged in `docs/CHANGES.md` after review
