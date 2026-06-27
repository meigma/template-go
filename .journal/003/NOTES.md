---
id: 003
title: Maximize CI caching
started: 2026-05-12
---

## 2026-05-12 19:51 — Kickoff
Goal for the session: focus on maximal caching to speed up CI.

Current state of the world: the last two closed sessions expanded and hardened the template release lifecycle. The repo now has binary and container release rehearsals, GoReleaser binary release flow, GitHub Actions-native container publishing with BuildKit provenance/SBOMs, digest-pinned Docker bases with Dependabot coverage, scheduled Trivy scanning, Go `1.26.3`, and required default-branch checks for `ci`, `Binary Release Dry Run`, and `Container Image Dry Run`.

Plan: wait for the user's concrete request before making substantive changes. Expected next step is to inspect the current GitHub Actions workflows and build surfaces, then prototype targeted caching improvements before broadening them.

## 2026-05-12 20:32 — Caching research assessment
- Researched current Moon v2, GitHub Actions cache, and Docker BuildKit/GitHub Actions cache docs.
- Inspected current workflows and Moon task graph. `ci.yml` uses `moonrepo/setup-toolchain` with `cache-base: default_branch`; release jobs use `actions/setup-go` cache; Docker jobs do not export/import BuildKit cache across runs.
- Recent GitHub run evidence: CI run `25772665778` spent ~30s in `Setup Moon Toolchain` and ~67s in `moon ci`; inside Moon, `root:lint` was ~59s, `root:test`/`root:build` were ~52s, and `docs:install` was ~56s. Release dry-run run `25772706852` spent ~70s in GoReleaser and ~80s across Docker dry-run build steps. Release run `25768786911` spent ~88s in GoReleaser and ~48s in container build/push.
- Important local finding: `.moon/toolchains.yml` still pins Go `1.26.2`, while `.go-version` and `go.mod` are `1.26.3`; the CI log shows Moon skipping setup for `go:1.26.2` and then Go downloading `go1.26.3` during `root:build`/`root:test`. Fixing this should be an early low-risk win.
- Moon caching assessment: `root:format`, `root:lint`, `root:test`, `root:check`, `docs:install`, and `docs:typecheck` currently set `cache: false`; only `root:build` and `docs:build` are cacheable. Remote Moon cache is the clean cross-run answer for task outputs, but requires Depot or a Bazel Remote Execution-compatible cache service/token. Manual `.moon/cache/{hashes,outputs}` persistence is documented as possible but fragile without invalidation.
- GitHub Actions dependency cache assessment: add explicit caches for Go module/build cache, golangci-lint cache, and npm's download cache around `moon ci`; keep `node_modules` out of generic Actions cache initially.
- Docker assessment: convert raw `docker build`/`docker buildx build` shell steps to `docker/build-push-action` where practical and add `cache-from/cache-to` with `type=gha,mode=max,scope=...`; consider registry-backed cache for release publishing if tag/default-branch cache access is unreliable. BuildKit cache mounts in the Dockerfile are not persisted by the normal GitHub Actions BuildKit cache; `buildkit-cache-dance` is available but should be a second pass after layer cache export/import.

## 2026-05-12 21:54 — Implementation pass
- Created Worktrunk branch `feat/session-003-ci-caching` at `.wt/feat-session-003-ci-caching`.
- Started the first implementation pass: aligned Moon's Go toolchain version to `1.26.3`, added pinned `actions/cache@v5.0.3` dependency caches around `moon ci`, converted cacheable Docker dry-run/security-scan builds to `docker/build-push-action`, added BuildKit `type=gha` cache scopes for dry-run/release/security-scan container builds, and documented Moon remote cache as a later opt-in.
- Next: run workflow linting and the local Moon check, then fix any concrete failures before committing.

## 2026-05-12 21:55 — Local validation
- Validation passed in `.wt/feat-session-003-ci-caching`: `actionlint`, `git diff --check`, `moon run root:check --summary minimal`, and `moon ci --summary minimal`.
- `moon ci` showed local cache behavior for `root:build` and `docs:build`; GitHub-hosted cache restore/save behavior still needs PR workflow evidence after the branch is pushed.
- Next: commit, push, open the PR, and inspect the first GitHub Actions run for cache restore/export log lines and timing changes.

## 2026-05-12 22:01 — PR validation
- Committed `ci: add GitHub Actions caching` (`e9da67a`) on `feat/session-003-ci-caching`, pushed it, opened PR #11, and marked it ready for review after validation passed.
- First PR run passed and warmed caches: `ci` 1m37s, `Binary Release Dry Run` 1m29s, `Container Image Dry Run` 1m51s. Logs showed GitHub Actions cache saves for Go modules, Go build cache, golangci-lint, and npm downloads, plus BuildKit `gha` cache import/export.
- Warm rerun passed: `ci` 54s with dependency cache hits and `moon ci` down to ~14s; `Binary Release Dry Run` 24s with GoReleaser down to ~6s; `Container Image Dry Run` 1m44s with BuildKit cache hits but still dominated by the three Docker build/export steps.
- Open thread: Docker warm-cache savings are modest because the dry-run still intentionally performs test, loaded smoke image, and multi-platform OCI archive builds. Further Docker savings would require reducing redundant build shapes or adding a second-pass cache-mount strategy such as `buildkit-cache-dance`.

## 2026-05-12 22:26 — Close
- User reviewed PR #11 and said LGTM. Squash-merged it on GitHub as `389956a` and deleted the remote session branch.
- Fast-forwarded local `master` to `389956a`, removed the Worktrunk worktree `.wt/feat-session-003-ci-caching`, and verified only the clean main worktree remains.
- Wrote `.journal/003/SUMMARY.md`, added session 003 to `.journal/INDEX.md`, and updated `.journal/TECH_NOTES.md` with the durable CI caching note.
