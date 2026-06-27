---
id: 001
title: Expand template release lifecycle
date: 2026-05-12
status: complete
repos_touched: [this-repo]
related_sessions: []
---

## Goal
Expand `template-go` from a starter repo with dormant release assets into a template that proves its own production release lifecycle with the example application. The work covered a production Dockerfile, enabled release automation, GitHub App release credentials, workflow-native container publishing, live release validation, and generated-project setup guidance.

## Outcome
The goal was met. The repository now has a production Dockerfile, enabled Release Please and release workflows, binary and container release dry runs, GitHub-native attestations, required branch checks for the release rehearsals, and refreshed setup docs for binary, container, mixed, and library-only generated projects.

The full lifecycle was exercised on `v0.1.1`: Release Please created the release path, binary assets and SBOMs were uploaded to a draft release, the GHCR image was published, binary and OCI attestations verified, and Release Please later recognized `v0.1.1` as the latest release with no unreleased commits.

## Key Decisions
- Keep GoReleaser binary-only -> GitHub Actions owns container build, push, and attestation so GitHub-native provenance remains the authoritative container provenance path.
- Use a separate container dry-run job -> pull requests now catch Dockerfile, build-arg, multi-platform build, and smoke-test failures without pushing GHCR images.
- Publish only immutable container tags -> the release workflow publishes `ghcr.io/meigma/template-go:vX.Y.Z` and avoids `latest`, bare versions, and moving major/minor tags.
- Keep draft-release inspection -> binary assets and container image are produced before human publication of the draft GitHub release; GHCR has no draft state, so images become available during the tag workflow.
- Preserve generated-project flexibility -> `DELETE_ME.md` now treats binary plus container as the nominal case but documents binary-only, container-only, and pure-library cleanup paths.

## Changes
- `.go-version` — added Go version source for local/tooling consistency.
- `Dockerfile` — added multi-stage BuildKit Dockerfile with `test` target, static Go binary build, `.go-version` validation, distroless non-root runtime, release metadata args, and OCI labels.
- `.dockerignore` — excluded Git state, Worktrunk state, journal/agent files, build artifacts, docs output, and local environment files from Docker context.
- `.github/workflows/release-please.yml` — enabled Release Please with GitHub App token credentials.
- `.github/workflows/release.yml` — enabled and split release workflow into release resolution, binary asset publishing, container image publishing, and inspection summary jobs.
- `.github/workflows/release-dry-run.yml` — enabled and split release rehearsal into `Binary Release Dry Run` and `Container Image Dry Run`.
- `.github/repository-settings.toml` — added release-app tag bypass, disabled tag status checks, and required `ci`, `Binary Release Dry Run`, and `Container Image Dry Run` on the default branch.
- `release-please-config.json` — set manifest mode to use bare `vX.Y.Z` tags and force tag creation for draft releases.
- `.release-please-manifest.json` and `CHANGELOG.md` — bumped and recorded `template-go 0.1.1`.
- `.goreleaser.yaml` and `ghd.toml` — retained binary release metadata as the source for binary assets and `ghd` installation.
- `scripts/configure_github_repo.py` — changed GitHub App actor resolution to `GET /apps/{slug}` so ruleset app bypass resolution works with the available `gh` token.
- `README.md` — documented container build/test usage and the enabled binary-plus-container release layer.
- `DELETE_ME.md` — refreshed generated-project setup guidance for binary plus container, binary-only, container-only, and library-only projects.
- Repository settings/secrets — set `MEIGMA_RELEASE_APP_ID` and `MEIGMA_RELEASE_APP_PRIVATE_KEY` on `meigma/template-go` from the `homelab` 1Password vault item.

## Open Threads
- The `v0.1.1` GitHub release is still a draft by design. It has verified assets and attestations and is ready for manual inspection/publication.
- `actions/create-github-app-token` emitted a deprecation warning for `app-id`; a future cleanup should switch the workflow to the `client-id` input and the corresponding repository variable.
- The release workflow is still specialized for the template app's binary/container shape. Generated repos should trim it according to their artifact shape before their first release.

## References
- PR #1 — https://github.com/meigma/template-go/pull/1
- PR #2 — https://github.com/meigma/template-go/pull/2
- PR #4 — https://github.com/meigma/template-go/pull/4
- PR #5 — https://github.com/meigma/template-go/pull/5
- PR #6 — https://github.com/meigma/template-go/pull/6
- PR #7 — https://github.com/meigma/template-go/pull/7
- Release workflow run `25768786911` — passed full `v0.1.1` binary/container release.
- Draft release `v0.1.1` — https://github.com/meigma/template-go/releases/tag/v0.1.1
- Release Please manifest docs — https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md

## Lessons
- Release Please manifest mode defaults to component-prefixed tags. For this template's desired `vX.Y.Z` tags, keep `include-component-in-tag: false`.
- Draft GitHub releases do not automatically provide a normal Git tag soon enough for tag-triggered workflows unless the tag is forced/created. Keep `force-tag-creation: true` for this draft-release model.
- A GitHub Actions job without checkout has no implicit `gh` repository context. Use `--repo "$GITHUB_REPOSITORY"` for `gh release view` in no-checkout jobs.
- The release resolver needs enough token scope to read draft release state. In this repository, `contents: write` was required for the resolver job to see drafts.
