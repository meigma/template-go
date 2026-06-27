---
id: 006
title: Native ARM Docker runners
date: 2026-05-19
status: complete
repos_touched: [template-go]
related_sessions: [002, 003, 005]
---

## Goal
Move the ARM container build path away from x64 emulation and onto a native GitHub-hosted ARM runner, while preserving the template's release evidence: multi-platform GHCR tag, BuildKit provenance/SBOM metadata, and GitHub-native image attestation.

## Outcome
The goal was met. PR #15 was opened, reviewed by the user, squash-merged, local `master` was fast-forwarded to the merge commit, the remote feature branch was deleted, and the Worktrunk worktree was removed. A manual `Release Dry Run` on `master` passed after merge and proved both native platform build jobs plus the aggregate required dry-run check.

## Key Decisions
- Split platform builds into a matrix job -> `linux/amd64` now runs on `ubuntu-24.04` and `linux/arm64` runs on `ubuntu-24.04-arm`.
- Publish per-platform images by digest and assemble the public tag afterward -> the final GHCR tag remains a single multi-platform manifest, and `actions/attest` still targets the pushed manifest digest.
- Keep `Container Image Dry Run` as the required aggregate check -> repository rules did not need to change, while the native platform jobs still fail the aggregate gate if either platform fails.
- Keep local amd64 smoke testing in the aggregate dry-run job -> dry runs still exercise runnable local Docker behavior without requiring registry publication.

## Changes
- `.github/workflows/release.yml` — split container publishing into native per-platform build jobs, digest artifact handoff, multi-platform manifest assembly, final smoke test, and final manifest attestation.
- `.github/workflows/release-dry-run.yml` — added native per-platform OCI archive validation and made the existing `Container Image Dry Run` job depend on those platform validations.
- `README.md` and `DELETE_ME.md` — updated generated-project release wording for native-runner container builds.
- `.journal/TECH_NOTES.md` — recorded the native amd64/arm64 hosted-runner release shape as durable project context.

## Open Threads
- The next real tag release should confirm the final GHCR release manifest digest verifies with `gh attestation verify "oci://${IMAGE_NAME}@${IMAGE_DIGEST}"`; the dry run proves the native runners and dry-run build path but intentionally does not publish the release manifest.

## References
- PR #15 — https://github.com/meigma/template-go/pull/15
- Squash merge commit — `802183a91f655b85a9a32f2f997c2b267d517133`
- Manual Release Dry Run — https://github.com/meigma/template-go/actions/runs/26139498812
- Prior Docker release hardening context — `.journal/002/SUMMARY.md`
- Prior CI caching context — `.journal/003/SUMMARY.md`
- Prior release script extraction context — `.journal/005/SUMMARY.md`
- GitHub hosted runner labels — https://docs.github.com/en/actions/reference/runners/github-hosted-runners
- Docker distributed multi-platform build pattern — https://docs.docker.com/build/ci/github-actions/multi-platform/

## Lessons
- `gh pr merge --squash --delete-branch` can merge the PR successfully but fail local cleanup when it tries to check out a branch already owned by another worktree. Verify PR state first, then explicitly delete the remote branch and remove the integrated Worktrunk worktree.
- Local Buildx attestation/export checks need a `docker-container` builder; the default `docker` driver rejects attestation output, while CI's `docker/setup-buildx-action` uses the appropriate builder shape.
