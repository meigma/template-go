---
id: 008
title: Reproduce template-go-api session-015 tooling migration (mise + melange/apko + SLSA L3)
started: 2026-06-27
---

## 2026-06-27 19:21 — Kickoff
Goal for the session: not yet stated. Developer started a new session with
`/session-new`; awaiting the actual request before any substantive work.

Current state of the world:
- `master` is at `7cc9241` ("chore(deps): bump actions/setup-go from 6.4.0 to 6.5.0 (#29)"), clean, and in sync with `origin/master`.
- Last closed session was 007 (Dependabot PR cleanup): all open Dependabot PRs were merged or closed as obsolete; no `dependabot/*` branches remained.
- Open thread from 007: GitHub may still run stale npm Dependabot security-update jobs against the removed `/docs` npm surface (post-MkDocs/uv migration); dismiss/refresh those alerts rather than reintroducing Docusaurus package files.
- Template release shape is intact: GoReleaser for binaries, GitHub Actions-native multi-platform container publishing on native amd64/arm64 hosted runners, weekly Trivy drift scan, Release Please with bare `vX.Y.Z` tags.
- Docs are on MkDocs + `uv` (`docs/mkdocs.yml`, `docs/uv.lock`).

Plan: wait for the developer's request, then load any task-relevant skills and
set up an implementation worktree from the fetched default branch if code/config
changes are needed.

## 2026-06-27 19:25 — Request: reproduce template-go-api session 015 tooling migration
Developer wants to fully reproduce the session-015 tooling/release migration from
`~/code/meigma/template-go-api` (the downstream API fork of this repo) here in
`template-go`, scoped to what's present in this repo. First deliverable: initial
investigation + assessment (no implementation yet).

Located the source: repo is `~/code/meigma/template-go-api` (not `go-template-api`).
Session 015 there = "Swap dev tooling to mise + moon-system + melange/apko, add
SLSA L3, prove via a real release". Shipped across squash merges:
- #24 `7aac1e1` Proto → mise; moon runs `system` binaries; `mise.lock` (locked=true)
  replaces `checksum-url` + `sqlc.sha256` integrity.
- #25 `4098277` Dockerfile → melange/apko; keyless cosign + syft SBOM/provenance;
  native multi-arch (no QEMU); compose → prebuilt image.
- #26 `8d5007d` provenance isolated in reusable `attest.yml` → SLSA Build L3, keeps
  `gh attestation verify`.
- Fixes #29 `a8e1fc5` (packages:write on binary attest caller), #31 `4287c53`
  (mkdir -p apko sbom dir), #33 `dcc4a6c` (GHCR login in attest.yml).

Gap snapshot (template-go current surface):
- PRESENT: .prototools, .go-version, .nvmrc, Dockerfile, .dockerignore, moon.yml,
  ghd.toml, release-please-config.json; .moon/proto/ has ONLY golangci-lint.toml.
- ABSENT: mise.toml, mise.lock, melange.yaml, apko.yaml, compose.yaml.
- API-only surface NOT here: sqlc/goose/mockery tooling, postgres/compose stack,
  OpenAPI smoke tests — these parts of session 015 do not apply.
Workflows present: ci, docs-pages, release-dry-run, release-please, release,
security-scan. Scripts: configure_github_repo.py, stage_ghd_release_assets.py (+tests).

Dispatched two parallel Explore agents: (api-spec) extract the precise session-015
change spec from template-go-api; (base-inv) inventory template-go's current
tooling/release surface. Synthesizing assessment when they return.

## 2026-06-27 19:50 — Assessment delivered; decisions made; proceeding to implement
Both Explore agents returned full reports (captured in conversation). Assessment
delivered to the developer. Key framing: template-go is already on native amd64/arm64
runners + GitHub-native `actions/attest` (session 006), so the migration is precisely:
(1) Proto→mise lockfile integrity, (2) Docker/distroless→melange/apko (Wolfi, keyless
cosign + syft SBOM), (3) inline attest→isolated reusable `attest.yml` (SLSA L3).

Developer decisions (via AskUserQuestion):
- **Approach: implement as 3 mirrored PRs** (mise → melange/apko → SLSA attest),
  matching the API repo's #24/#25/#26 history. Each independently reviewable.
- **Validation: forced prerelease-tag rehearsal** after the PRs land (dry-run
  provably cannot reach attest.yml/apko publish; the 3 known fixes #29/#31/#33 are
  baked in upfront to minimize shakeout).

Out of scope (API-only, absent here): sqlc/goose/mockery tooling, postgres compose
stack + stack-up task, OpenAPI export/drift-guard, Cedar/metrics. So this repo's
mise.toml drops sqlc/mockery/goose; no compose.yaml; smoke tests stay --version/--message.

Local tooling: mise 2026.6.14 ✓, moon 2.3.5 ✓, cosign ✓; melange/apko NOT installed
locally (will come via mise.toml; only CI strictly needs them). master synced at 7cc9241.

PR-by-PR file plan (each in its own `wt` worktree off fetched master, squash-merged):
- PR1 build(tooling): new mise.toml+mise.lock; del .prototools/.nvmrc/.moon/proto/golangci-lint.toml;
  edit moon.yml (system toolchain, unwrap golangci-lint), .moon/toolchains.yml, docs/moon.yml,
  ci.yml+docs-pages.yml (jdx/mise-action, cache keys → mise.lock), .gitignore, README/CONTRIBUTING/DELETE_ME.
- PR2 build(release): new melange.yaml+apko.yaml; del Dockerfile/.dockerignore/.go-version;
  edit release.yml (melange-build matrix + apko publish, setup-go→go.mod, smoke --version/--message),
  release-dry-run.yml, security-scan.yml, release-please-config.json (extra-files), mise.toml (image-local
  task; NO stack-up), .gitignore. Bakes in fix #31 (mkdir -p sbom). Attestation stays INLINE here (mirrors #25).
- PR3 ci(release): new attest.yml (reusable; fix #33 GHCR login baked in); edit release.yml
  (attest-binaries/attest-image jobs use attest.yml; fix #29 packages:write on binary caller),
  release-dry-run.yml + ghd.toml + stage_ghd_release_assets.py (+test): signer_workflow/expected_signer
  → attest.yml; README/DELETE_ME verify commands.
- Then: forced prerelease-tag rehearsal.

Starting PR1 now.
