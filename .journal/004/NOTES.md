---
id: 004
title: Template continuation
started: 2026-05-19
---

## 2026-05-19 09:13 — Kickoff
Goal for the session: continue work on `template-go` today. The user asked me to get ready and wait for the concrete work request.

Current state of the world: project startup context has been read. Required `git` and `worktrunk` skills are loaded. The last three closed sessions were `001` release lifecycle, `002` Docker release hardening, and `003` CI caching. Durable notes say the template currently uses GoReleaser for binary assets, GitHub Actions-native container publishing with BuildKit provenance/SBOM and `actions/attest`, weekly/manual Trivy drift scanning, bare `vX.Y.Z` Release Please tags, digest-pinned Docker bases, required checks `ci`, `Binary Release Dry Run`, and `Container Image Dry Run`, plus GitHub-native CI caches. Recent memory outside the repo journal also records a 2026-05-18 environment-management research pass: hybrid Moon-managed Go/Node plus possible Nix auxiliary tooling is feasible, and `direnv + proto activate` was validated as a lightweight devshell-like workflow.

Repository state: the main checkout is on `master` at `389956ae5d24f258d33d77b95e17ce7b869fa3bc` (`ci: add GitHub Actions caching (#11)`) with a clean working tree. `wt list --format=json` shows only the main worktree. `wt config show --full` confirms worktrees resolve under `{{ repo_path }}/.wt/{{ branch | sanitize }}`; shell integration is not active, so future automation should use explicit worktree paths after `wt switch`.

Plan: wait for the user's actual request. If code or config changes are needed, inspect Worktrunk state again, create a dedicated `.wt/...` worktree for the branch, and work there.

## 2026-05-19 09:26 — Implementation start
- User approved the plan to gate `Release Dry Run` jobs so expensive release rehearsals only execute on Release Please PR branches and manual dispatches.
- Loaded task-relevant `github-actions`, `configuring-release-please`, and `gh-cli` skills in addition to required `git`/`worktrunk` context.
- Re-checked Worktrunk state: only the clean `master` worktree exists, and Worktrunk config still resolves new worktrees under `.wt/`.
- Next: create a dedicated `feat/gate-release-dry-runs` worktree, update only `.github/workflows/release-dry-run.yml`, validate, commit, push, open a PR, and confirm the dry-run jobs skip on the implementation PR.

## 2026-05-19 09:27 — Workflow edit
- Created Worktrunk branch/worktree `feat/gate-release-dry-runs` at `.wt/feat-gate-release-dry-runs`.
- Updated only `.github/workflows/release-dry-run.yml`: added a workflow comment explaining broad PR trigger plus job skipping, and added the same job-level guard to both release dry-run jobs: manual dispatch always runs; PRs only run when `github.head_ref` starts with `release-please--`.
- Validation so far: YAML parse passed and `actionlint .github/workflows/release-dry-run.yml` passed.
- `moon run root:check` passed. It printed existing docs npm audit output for two moderate vulnerabilities during `docs:install`, but the task completed successfully and this change does not touch docs dependencies.
- `git diff --check` passed.
- Next: commit, push, open PR, and verify GitHub checks.

## 2026-05-19 09:29 — PR verification
- Committed `a05bb4992f1987ae744c93efd2643372a57fa71d` with subject `ci: gate release dry runs to release-please PRs`.
- Pushed branch `feat/gate-release-dry-runs` and opened PR #13: https://github.com/meigma/template-go/pull/13.
- PR checks settled as intended: `ci` passed, `Kusari Inspector` passed, `Binary Release Dry Run` was skipped, and `Container Image Dry Run` was skipped.
- `gh pr view 13` reports `mergeStateStatus: CLEAN`. `gh pr checks 13 --required` returned `no required checks reported on the 'feat/gate-release-dry-runs' branch`, so verification used the full status check rollup plus clean merge state.
- Worktree branch is clean and tracking `origin/feat/gate-release-dry-runs`.

## 2026-05-19 09:44 — PR merged
- User approved with `LGTM. Please merge.`
- Ran `gh pr merge 13 --squash --delete-branch --match-head-commit a05bb4992f1987ae744c93efd2643372a57fa71d`; GitHub completed the squash merge but the local cleanup step failed because `master` is already checked out in the main worktree.
- Verified PR #13 is merged at squash commit `d421cc5ead9e227698da5a7d48358ad17e25d4aa`.
- Deleted remote branch `feat/gate-release-dry-runs`, fast-forwarded local `master` to `d421cc5`, and removed the feature worktree with `wt remove --foreground --format=json feat/gate-release-dry-runs`.
- Final Worktrunk state: only the clean `master` worktree remains, with `origin/master` aligned.

## 2026-05-19 09:47 — ARM runner feasibility pass
- User asked to briefly assess splitting ARM artifact builds onto a separate ARM runner instead of relying on QEMU.
- Current state: `.goreleaser.yaml` cross-builds `darwin/linux` for `amd64/arm64` with `CGO_ENABLED=0`; this is Go cross-compilation, not QEMU. Docker builds use `FROM --platform=$BUILDPLATFORM` and `GOOS=$TARGETOS GOARCH=$TARGETARCH`, so the compile stage is also cross-compiled from the build platform. Current release workflows build multi-platform OCI images with Buildx and smoke only the loaded `linux/amd64` image.
- GitHub docs now show standard hosted Linux ARM runners for public repos via `ubuntu-24.04-arm` / `ubuntu-22.04-arm`; `meigma/template-go` is public.
- Assessment: the lowest-risk next slice would be an ARM-native container smoke job on `ubuntu-24.04-arm` in `release-dry-run.yml`, gated like the existing release dry-run jobs. Full release splitting is feasible but more invasive because it requires per-platform image builds, digest artifact handoff, manifest creation, final manifest digest attestation, and verification that BuildKit provenance/SBOM behavior remains acceptable.
- Binary splitting is not worth doing first: GoReleaser already builds pure-Go arm64 binaries without QEMU, and splitting GoReleaser output would complicate checksums, SBOMs, `artifacts.json`, and release upload flow. If native binary proof is desired, add a separate ARM smoke/validation job rather than changing artifact production.
