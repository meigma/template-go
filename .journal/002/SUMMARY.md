---
id: 002
title: Docker release hardening
date: 2026-05-12
status: complete
repos_touched: [this-repo]
related_sessions: [001]
---

## Goal
Review and harden the template Dockerfile and Docker release flow, especially around security, correctness, provenance, SBOMs, and the foundation inherited by generated projects.

## Outcome
The goal was met. PR #8 was reviewed, approved, squash-merged, the local default branch was fast-forwarded, the session worktree was removed, and the release/container security improvements are now on `master`.

## Key Decisions
- Keep the GitHub artifact attestation and enable BuildKit provenance/SBOM → they cover different evidence surfaces: workflow/source/digest identity versus image build metadata and package inventory.
- Do not add QEMU arm64 smoke testing → the user explicitly rejected it because of CI runtime cost; the template still builds multi-platform images.
- Digest-pin Docker base images and add Dependabot Docker coverage → digest pinning improves reproducibility, but needs an automated update lane.
- Add scheduled container scanning as drift detection → weekly/manual Trivy scans catch newly disclosed vulnerabilities without making PR CI slower or noisier.
- Bump Go from `1.26.2` to `1.26.3` → local Trivy scanning found fixed high-severity Go stdlib CVEs in `1.26.2`.

## Changes
- `.github/workflows/release.yml` — hardened manual tag handling, kept checkout tag selection out of direct shell interpolation, enabled BuildKit `provenance: mode=max` and `sbom: true` for container publishing.
- `.github/workflows/release-dry-run.yml` — exercised BuildKit provenance/SBOM settings in dry-run via local OCI export without pushing images.
- `Dockerfile` — pinned Go builder and distroless runtime images by digest using literal `FROM` references, while preserving the `.go-version` builder-version guard.
- `.github/dependabot.yml` — added Docker ecosystem monitoring for base-image updates.
- `.github/workflows/security-scan.yml` — added weekly/manual container vulnerability scanning with pinned actions, minimal permissions, local amd64 image build, Trivy HIGH/CRITICAL fixed-vulnerability scan, and SARIF upload.
- `.go-version` / `go.mod` — bumped the Go version to `1.26.3`.
- `README.md` / `DELETE_ME.md` — documented digest-pinned base images, BuildKit container attestations/SBOMs, Dependabot coverage, and security scan keep/remove guidance for generated projects.
- `.journal/TECH_NOTES.md` — recorded durable release-flow invariants for future sessions.

## Open Threads
- No QEMU-backed arm64 runtime smoke exists by explicit choice. The template still builds arm64 images, but runtime execution is only covered for amd64.
- The scheduled security scan will begin producing GitHub code scanning results once the workflow runs on the default branch.

## References
- PR #8: https://github.com/meigma/template-go/pull/8
- Prior release lifecycle session: `.journal/001/SUMMARY.md`

## Lessons
- BuildKit image provenance/SBOM is not redundant with GitHub's generic attestation; keeping both gives consumers better supply-chain evidence.
- Digest-pinned base images should not be introduced without a refresh mechanism, especially in a template repo.
- A scheduled image scan can immediately catch base language/runtime vulnerability drift that regular PR tests do not exercise.
