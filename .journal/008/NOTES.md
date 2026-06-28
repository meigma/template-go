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

## 2026-06-27 20:14 — PR1 + PR2 built, pushed, PRs open
Working in stacked `wt` worktrees off master: build/mise-tooling (PR1) →
build/melange-apko (PR2) → build/slsa-attest (PR3, next).

**PR1 #30** `build(tooling): replace proto with mise` — pushed, **CI green**
(`ci` moon-under-mise + `GitHub Pages` both pass). mise.lock derived from the API's
proven lock minus goose/sqlc/mockery (identical versions → identical entries).
Validated locally: full `moon run root:check` (format/lint/build/test) + docs:build
pass under the system toolchain with mise binaries.

**PR2 #31** `build(release): build the container image with melange + apko` — pushed
(stacked on build/mise-tooling). New melange.yaml/apko.yaml (CLI-adapted: ./cmd/template-go,
template-go binary, --version/--message smoke tests, NO openapi). release.yml:
melange-build matrix → apko publish + keyless cosign + syft SBOM + attest-build-provenance/
attest-sbom; setup-go→go.mod; **#31 fix (mkdir -p sbom) baked in**. release-dry-run.yml +
security-scan.yml → melange/apko. Deleted Dockerfile/.dockerignore/.go-version. mise.toml
image-local task (no stack-up — no compose here). **Deliberate divergence from session 015**:
removed the orphaned `docker` Dependabot ecosystem (API left it stale; session-007 lesson).
Validated locally end-to-end: `mise run image-local` builds apk + assembles image; runs as
**uid 65532**, entrypoint /usr/bin/template-go, --version stamping + --message both pass.

**Stacking caveat**: PRs based on non-master branches do NOT trigger the branch-filtered
`ci`/`GitHub Pages`/`release-dry-run` workflows. PR31/PR32 CI activates only after each base
squash-merges to master (GitHub auto-retargets). So local validation carries PR2/PR3 until
merge. Plan: build PR3, present all 3, let developer review/merge sequentially (PR30→31→32),
then forced prerelease-tag rehearsal. Required check job names preserved
(`Binary Release Dry Run`, `Container Image Dry Run`).

## 2026-06-27 20:21 — PR3 built; all 3 PRs open and stacked
**PR3 #32** `ci(release): generate provenance in an isolated reusable workflow (SLSA L3)`
— pushed (stacked on build/melange-apko). New `.github/workflows/attest.yml` (reusable,
isolated OIDC → SLSA Build L3; #33 GHCR login baked in). release.yml: binary job →
contents-only + uploads checksums artifact; new `attest-binaries` job (uses attest.yml,
**#29 packages:write baked in**); inline image-provenance step → new `attest-image` job;
cosign sign + syft SBOM attestation stay in-job. signer_workflow→attest.yml in ghd.toml,
stage_ghd_release_assets.py (+test), release-dry-run.yml. README/DELETE_ME updated.
Validated: YAML parses, job DAG well-formed (verified via python), stage-script unit
tests pass (6/6 incl. wrong-signer + attest.yml-signer cases). Container job keeps
id-token/attestations (cosign + inline attest-sbom).

**All three PRs open, stacked:**
- #30 build/mise-tooling → master — **CI green** (ci + GitHub Pages).
- #31 build/melange-apko → build/mise-tooling — local validation only (stacked; CI activates on retarget). Image built + smoke-tested locally.
- #32 build/slsa-attest → build/melange-apko — local validation only (YAML + DAG + stage tests).

**Next:** developer reviews/merges #30 → #31 → #32 (each retargets to master + runs CI as
its base merges). Then forced prerelease-tag rehearsal to exercise the tag-only
attest/publish path (dry-run can't reach it). NOTE: a pre-existing Release Please PR #9
(`release 0.1.2`) is open; after these merge, Release Please reconciles changelog +
melange.yaml/apko.yaml x-release-please-version markers — relevant when picking the
rehearsal tag. Awaiting developer direction on merge + rehearsal execution.

## 2026-06-27 20:35 — All 3 PRs merged to master; paused before rehearsal
Developer chose "I merge them sequentially." Done:
- **#30 merged** (squash → master `98f028b`). Required checks green.
- **#31**: retargeted to master, **rebased** (dropped redundant PR1 commit via the
  cherry-pick skip), force-pushed. CI ran on master base. **Kusari flagged a HIGH
  cache-poisoning risk**: melange-build + container-image-release ran jdx/mise-action
  with `cache: true` (a poisoned Actions cache could taint the toolchain that
  builds/signs real artifacts). Fixed: `cache: false` on both publishing-pipeline
  mise-action steps (CI/dry-run/scan keep cache — they don't publish). New commit;
  Kusari then **pass**. **Deliberate divergence #2 from session 015** (the API's
  release.yml uses cache:true; Kusari evidently didn't flag it there). #31 merged
  (squash → master `e9703a1`).
- **#32 auto-CLOSED** when I deleted its base branch `build/melange-apko` after #31
  merged (GitHub closes PRs whose base branch is deleted; can't reopen with base
  gone). Rebased `build/slsa-attest` onto master with `git rebase --onto origin/master
  8b2de39` (replays only the PR3 commit; combines cleanly with the kusari-fixed PR2
  base), force-pushed, and opened a **fresh PR #35** (build/slsa-attest → master)
  superseding #32. CI green incl. Kusari. **#35 merged** (squash → master `2d57b10`).

Final master: 7cc9241 → 98f028b (#30 mise) → e9703a1 (#31 melange/apko) → 2d57b10
(#35 SLSA L3 attest). master CI green (CI + Release Please success; CodeQL/Pages
finishing). All build/* branches + worktrees removed.

**LESSON**: when squash-merging a STACK, GitHub does NOT auto-retarget/keep dependent
PRs — deleting a merged base branch closes the dependent PR. Safer next time: retarget
the dependent PR to master FIRST (gh pr edit --base master), rebase --onto, THEN delete
the old base branch. Also `gh pr merge --delete-branch` leaves the remote branch when the
local branch is in a worktree (local delete fails first) — delete the remote explicitly.

**Open PRs (not mine)**: release-please #9 (release 0.1.2), dependabot #33 (actions/attest
4.1.0→4.1.1 — note: PR3 introduced actions/attest@4.1.0), #34 (actions/cache 6.0.0→6.1.0).

**PAUSED before the forced prerelease-tag rehearsal** (developer asked to pause). Rehearsal
plan to confirm with developer: pick a prerelease tag (e.g. v0.2.0-rc.1); resolve-release
WAITS for a draft release, so create a draft GH release for that tag, push the tag → release.yml
runs the full publish+attest path (GoReleaser binaries, melange apks, apko publish to GHCR,
cosign sign, attest.yml provenance, syft SBOM attest). Then verify with cosign verify +
gh attestation verify --signer-workflow …/attest.yml, and clean up the throwaway tag/release/
GHCR image. This PUBLISHES a real image + tag — needs explicit go-ahead.

## 2026-06-27 20:55 — Rehearsal PASSED first try + verified + cleaned up. TASK COMPLETE.
Developer approved rehearsal with tag **v0.1.2-rc.1**. Executed:
- GOTCHA: `gh release create --draft` makes an UNTAGGED draft (no git tag until publish).
  In the real flow release-please's `force-tag-creation` makes the tag. For the rehearsal,
  created the draft release (backs tag_name v0.1.2-rc.1), then created+pushed an annotated
  tag at master HEAD (`git -c tag.gpgSign=false tag -a … -m …`; plain `git tag` errored
  "no tag message" — annotated is the default here). Tag push triggered release.yml (the
  faithful `push: tags` path).
- **release.yml run 28310464579: ALL JOBS SUCCESS, first try** — resolve-release, binary-
  release-assets, attest-binaries (attest.yml), melange-build amd64+arm64, container-image-
  release (apko publish + cosign + syft + attest-sbom), attest-image (attest.yml),
  release-inspection-summary. No shakeout (the #29/#31/#33 + Kusari fixes held).
- **Cryptographic verification** (image digest sha256:10622adf…, multi-arch amd64+arm64):
  - `cosign verify` (cert-identity release.yml) → OK, 2 platform signatures.
  - `gh attestation verify oci://… --signer-workflow …/attest.yml` → OK; provenance signer =
    `…/attest.yml@refs/tags/v0.1.2-rc.1` (SLSA-L3 isolated signer confirmed).
  - NEGATIVE control: verify against `…/release.yml` signer → exit 1 (correctly rejected) —
    proves the attest.yml isolation is real.
  - Draft release had all 9 assets (4 bins + 4 SBOMs + checksums); binary provenance verifies
    against attest.yml (exit 0).
- **Cleanup**: deleted draft release + git tag (local+remote); deleted the 9 rehearsal GHCR
  versions (created 2026-06-28; the multi-arch index, platform manifests, cosign sig +
  provenance/SBOM referrers). Preserved the 2026-05-12 v0.1.1 package set. master clean at
  2d57b10, no v0.1.2-rc.1 tag anywhere.

OUTCOME: session-015 tooling migration FULLY REPRODUCED in template-go, merged to master
(#30/#31/#35), and proven by a verified release rehearsal. Two deliberate improvements over
the API's session 015: Kusari-driven `cache: false` in the publishing pipeline, and removal
of the orphaned docker Dependabot ecosystem. Left for the developer: routine dependabot PRs
(#33 actions/attest 4.1.0→4.1.1 — note attest.yml pins 4.1.0; #34 actions/cache), and the
release-please PR #9. Session work complete; awaiting any further direction or session-close.

## 2026-06-27 21:12 — Follow-up: ported session-016 tooling skills (mise/melange/apko)
Developer asked to copy over the skills introduced in template-go-api session 016
(its PR #35 `e61e926`, `docs(skills)`: mise, melange, apko under `.agents/skills/`,
6 files). Done as PR **#36** (`docs/tooling-skills` worktree), CI green
(.agents-only diff; ci/Pages/CodeQL/Kusari pass, dry-runs skip), CLEAN/MERGEABLE.

NOT a blind copy — adapted to template-go's actual config (verified against
mise.toml/mise.lock/melange.yaml/apko.yaml):
- mise SKILL: this repo's 8 tools (go, python, golangci-lint, uv, moon, melange,
  apko, cosign); dropped sqlc/goose/mockery; REMOVED the API-only sqlc-no-checksum
  caveat (every pinned tool here has a checksum); corrected the provenance subset
  (github-attestations: uv/golangci-lint/python; cosign: cosign; none: go/melange/
  apko/moon); single `image-local` task (no stack-up).
- melange/apko SKILLs: template-go binary+image names, /usr/bin/template-go
  entrypoint, --version/--message smoke test (no openapi), no embedded SQL/Cedar,
  no compose.
- references: swapped sqlc→golangci-lint examples, dropped stack-up, "embedded SQL
  migrations and Cedar policies"→"module source", compose retag note generalized.

Conventions mirrored from session 016: force-added (`.agents/` is blanket-gitignored
here, like the existing git/worktrunk/session-* skills); NOT added to .journal/SKILLS.md
(task-specific, surveyed-and-loaded per task). Flagged as a follow-up: template-go's
.gitignore still blanket-ignores `.agents/` (force-add workaround); the API repo refined
its .gitignore to track `.agents/skills` normally — a worthwhile template improvement,
left out of scope. #36 awaiting developer review/merge.

## 2026-06-27 21:20 — Close
Developer: "LGTM please merge and close out this session." All four session PRs
merged to master (`9ba9263`):
- #30 `98f028b` build(tooling): Proto → mise
- #31 `e9703a1` build(release): Dockerfile → melange/apko (+ Kusari cache:false; - docker Dependabot ecosystem)
- #35 `2d57b10` ci(release): isolated attest.yml (SLSA L3) — superseded auto-closed #32
- #36 `9ba9263` docs(skills): mise/melange/apko skills

Local `master` fast-forwarded to `9ba9263`; all `build/*` + `docs/tooling-skills`
worktrees removed; only `master` + `journal/jmgilman` remain. Migration proven by the
verified `v0.1.2-rc.1` rehearsal (now cleaned up). No journal contamination on master
(`git ls-files .journal` empty). SUMMARY.md written; INDEX row 008 → complete;
TECH_NOTES.md revised for the mise/melange/apko/attest.yml end-state (the old
Dockerfile/.go-version/BuildKit notes were stale).

Handoff / open (maintainer): routine Dependabot PRs #33 (`actions/attest 4.1.0→4.1.1`
— would align attest.yml, which pins 4.1.0) and #34 (`actions/cache`); Release Please
#9 (`release 0.1.2`); and the optional `.gitignore` `.agents/skills` carve-out (force-add
convention vs the API repo's normal tracking). Session complete.
