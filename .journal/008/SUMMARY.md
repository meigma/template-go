---
id: 008
title: Reproduce template-go-api session-015 tooling migration (mise + melange/apko + SLSA L3) and port session-016 skills
date: 2026-06-27
status: complete
repos_touched: [template-go]
related_sessions: ["006", "007"]
---

## Goal
Fully reproduce the `template-go-api` session-015 tooling/release migration in
`template-go`, scoped to what this repo actually has: Proto → mise, Dockerfile →
melange/apko, and inline attestation → an isolated reusable workflow for SLSA
Build L3. Then (follow-up request) port the three tooling skills introduced in
that downstream repo's session 016.

## Outcome
**Met, and validated by a real release.** Four PRs merged to `master` (final
`9ba9263`):
- **#30** `build(tooling)` — Proto → mise.
- **#31** `build(release)` — Dockerfile → melange/apko (Wolfi, keyless cosign, syft SBOM).
- **#35** `ci(release)` — provenance → isolated `attest.yml` (SLSA L3). Supersedes
  **#32**, which GitHub auto-closed when its stacked base branch was deleted after
  #31 merged (see Lessons).
- **#36** `docs(skills)` — ported + adapted the mise/melange/apko skills.

The migration was proven by a **forced prerelease-tag rehearsal** (`v0.1.2-rc.1`)
that passed **on the first try** (no shakeout): GoReleaser binaries, melange apks
(amd64+arm64 native), apko multi-arch publish to GHCR, keyless cosign, and both
reusable `attest.yml` jobs all succeeded. Verified independently — `cosign verify`
OK (2 platform sigs), `gh attestation verify` against `attest.yml` OK, and the
**negative control** (verify against `release.yml`) correctly rejected (exit 1),
proving the SLSA-L3 signer isolation is real. All rehearsal artifacts (draft
release, tag, 9 GHCR versions) were then cleaned up; the prior `v0.1.1` package set
was preserved.

## Key Decisions
- **3 mirrored PRs (not one) matching the API's #24/#25/#26** → independently
  reviewable and bisectable; the release pipeline is high-risk to land blind.
- **Derive `mise.lock` from the API's proven lock minus goose/sqlc/mockery** rather
  than regenerating with `mise lock` → entries are content-identical across repos
  for the same `tool@version`, and this sidesteps the known `mise lock` macos-x64
  drop quirk.
- **Scope: skip what this repo lacks** → no sqlc/goose/mockery tooling, no postgres
  `compose.yaml`/`stack-up`, no OpenAPI smoke tests. Smoke tests stay `--version`/
  `--message`; the only mise task is `image-local`.
- **Bake the three session-015 release fixes in upfront** (#29 packages:write on the
  binary attest caller, #31 `mkdir -p sbom`, #33 GHCR login in `attest.yml`) → the
  tag-only path can't be exercised by dry-run, so pre-applying the known fixes was
  the way to avoid re-discovering them.
- **Two deliberate improvements over the API's session 015** (flagged to the dev):
  (1) **Kusari** flagged a HIGH cache-poisoning risk — `release.yml`'s mise-action
  steps used `cache: true`, letting a poisoned Actions cache taint the toolchain that
  builds/signs artifacts; set `cache: false` on the two publishing-pipeline steps
  (CI/dry-run/scan keep cache). (2) Removed the orphaned `docker` Dependabot ecosystem
  (no Dockerfile remains; the API left it stale).
- **Forced prerelease-tag rehearsal** to validate (dev chose this over dry-run-only).
- **Skills adapted, not copied** → verified every claim against this repo's actual
  `mise.toml`/`mise.lock`/`melange.yaml`/`apko.yaml`; force-added (`.agents/` is
  blanket-gitignored, matching existing committed skills); NOT added to `SKILLS.md`
  (task-specific, surveyed-and-loaded per task — mirrors the API's session-016 call).

## Changes
- **#30**: new `mise.toml`+`mise.lock`; deleted `.prototools`/`.nvmrc`/`.moon/proto/golangci-lint.toml`;
  `moon.yml`/`docs/moon.yml` → `system` toolchain (unwrap `proto run`); `.moon/toolchains.yml`
  stripped; `ci.yml`/`docs-pages.yml` → `jdx/mise-action` + `mise.lock` cache keys; `.gitignore`;
  README/CONTRIBUTING/DELETE_ME.
- **#31**: new `melange.yaml`+`apko.yaml`; deleted `Dockerfile`/`.dockerignore`/`.go-version`
  (setup-go → `go.mod`); `release.yml` (melange-build matrix + apko publish + cosign + syft),
  `release-dry-run.yml`, `security-scan.yml` → melange/apko; `release-please-config.json`
  `extra-files`; `mise.toml` `image-local` task; removed `docker` from `.github/dependabot.yml`;
  README/DELETE_ME. Later: `cache: false` hardening on the two `release.yml` mise-action steps.
- **#35**: new `.github/workflows/attest.yml`; `release.yml` `attest-binaries`/`attest-image`
  jobs; `ghd.toml`/`stage_ghd_release_assets.py`(+test)/`release-dry-run.yml` signer →
  `attest.yml`; README/DELETE_ME.
- **#36**: new `.agents/skills/{mise,melange,apko}/SKILL.md` + `references/*-commands.md`
  (6 files), adapted to this repo.

## Open Threads
- **`.gitignore` blanket-ignores `.agents/`** here, so committed skills require `git add -f`
  (the existing convention). The API repo refined its `.gitignore` to track `.agents/skills`
  normally — a worthwhile template improvement, deliberately left out of the skills PR's scope.
- **`attest.yml` pins `actions/attest@v4.1.0`** while `attest-build-provenance@v4.1.1`; open
  Dependabot **#33** (`actions/attest 4.1.0→4.1.1`) would align them. Also open: **#34**
  (`actions/cache 6.0.0→6.1.0`) and Release Please **#9** (`release 0.1.2`) — all routine,
  left for the maintainer.
- The base-image posture changed distroless → Wolfi (apko); intentional, vetted in session 015.

## References
- PRs: #30 `98f028b`, #31 `e9703a1`, #35 `2d57b10` (supersedes closed #32), #36 `9ba9263`.
- Rehearsal: tag `v0.1.2-rc.1`, run 28310464579, image digest
  `sha256:10622adffed8a1b091444a91c931d307fea5fabf13992dbf52c5733546740705` (deleted after verify).
- Source of truth: `template-go-api` `.journal/015/SUMMARY.md` (the migration) and
  `.journal/016/SUMMARY.md` (the skills, its PR #35 `e61e926`).
- Builds on: `.journal/006/SUMMARY.md` (native ARM runners — this repo was already there) and
  `.journal/007/SUMMARY.md` (Dependabot/stale-ecosystem lesson that motivated the docker-ecosystem removal).

## Lessons
- **Stacked PRs + squash merge are hostile to GitHub's auto-retarget.** Deleting a merged base
  branch **closes** the dependent PR (it does not retarget it), and a closed PR whose base is
  gone **cannot be reopened**. Correct order: retarget the dependent PR to the real default
  (`gh pr edit --base master`) and `git rebase --onto origin/master <old-base>` FIRST, then delete
  the old base branch. Here #32 got closed and had to be re-opened as #35.
- **`gh pr merge --delete-branch` leaves the remote branch** when the local branch is checked out
  in a worktree (local delete fails first, aborting the remote delete) — delete the remote
  explicitly with `git push origin --delete <branch>`.
- **Draft GitHub releases do not create the git tag.** In the real flow Release Please's
  `force-tag-creation` makes the tag, which triggers `release.yml` (`push: tags`). For a manual
  rehearsal, create the draft release AND push an annotated tag yourself (`git tag` defaults to
  annotated here — `-m` required).
- **`mise.lock` entries are content-identical across repos for the same `tool@version`**, so a
  subset lock can be derived by stripping unused tools rather than regenerating.
- **Kusari Inspector flags release-pipeline toolchain caching as a cache-poisoning risk** — a
  legitimate hardening the upstream session 015 missed.
