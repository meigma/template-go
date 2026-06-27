---
id: 003
title: Maximize CI caching
date: 2026-05-12
status: complete
repos_touched: [template-go]
related_sessions: [001, 002]
---

## Goal
Speed up GitHub Actions CI minutes with a first-pass, GitHub-native caching layer across Moon-driven CI and Docker builds, without adding a new external cache vendor or repository secrets.

## Outcome
The goal was met. PR #11 landed with explicit Go/npm/golangci-lint dependency caches around `moon ci`, BuildKit `gha` cache import/export for Docker workflows, and the Moon Go toolchain aligned to Go `1.26.3`. First-run CI warmed the caches, then a manual rerun confirmed warm-cache hits and faster representative timings.

## Key Decisions
- Use GitHub-native cache primitives first -> avoids new billing, credentials, and vendor setup while still reducing CI minutes immediately.
- Cache npm's download cache instead of `docs/node_modules` -> keeps `npm ci` authoritative and reproducible while avoiding repeated package downloads.
- Keep BuildKit cache scopes distinct per workflow -> limits churn between dry-run, release, and security-scan container builds.
- Defer Moon remote cache -> it is the clean task-output cache path, but requires Depot or another Bazel Remote Execution-compatible backend plus credentials.

## Changes
- `.moon/toolchains.yml` — aligned Moon's Go toolchain from `1.26.2` to `1.26.3`.
- `.github/workflows/ci.yml` — added GitHub Actions caches for Go modules, Go build artifacts, golangci-lint, and npm downloads before `moon ci`.
- `.github/workflows/release-dry-run.yml` — converted cacheable Docker dry-run builds to `docker/build-push-action` and added BuildKit `gha` cache import/export.
- `.github/workflows/release.yml` — added BuildKit `gha` cache import/export to the release container build.
- `.github/workflows/security-scan.yml` — converted the scan image build to `docker/build-push-action` with a security-scan cache scope.
- `README.md` and `DELETE_ME.md` — documented GitHub-hosted dependency caches and Moon remote cache as an optional follow-up.

## Open Threads
- Docker dry-run warm-cache savings are modest because the workflow intentionally performs test, loaded smoke image, and multi-platform OCI archive builds. Further gains likely require reducing redundant Docker build shapes or evaluating a cache-mount strategy such as `buildkit-cache-dance`.
- The scheduled/manual security scan workflow was statically validated but not manually dispatched during this session.

## Lessons
- The Moon Go toolchain drift was a concrete avoidable cost: `.moon/toolchains.yml` must move with `.go-version` and `go.mod` so Go does not download a second toolchain during CI tasks.
- BuildKit's GitHub Actions cache restores layer metadata well, but it does not by itself persist `RUN --mount=type=cache` directories from the Dockerfile.

## References
- PR: https://github.com/meigma/template-go/pull/11
- Session 001: `.journal/001/SUMMARY.md`
- Session 002: `.journal/002/SUMMARY.md`
