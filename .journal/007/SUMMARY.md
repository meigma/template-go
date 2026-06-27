---
id: 007
title: Dependabot PR cleanup
date: 2026-06-27
status: complete
repos_touched: [template-go]
related_sessions: [006]
---

## Goal
Systematically process every open Dependabot PR in `meigma/template-go`: update each PR branch to current `master`, merge green PRs after CI passed, fix or otherwise resolve failing PRs, and verify `master` CI after each merge.

## Outcome
The goal was met. Dependabot PRs #27, #28, and #29 were updated as needed, verified green, squash-merged, and local `master` was fast-forwarded after each merge. Dependabot PRs #22 and #23 were closed as obsolete with comments because they only targeted the removed Docusaurus/npm docs surface.

Final `master` is `7cc9241779a3a11af22d10f7cc285eb18c2d8a91`. The final push workflows passed: `CI` run 28297538170, `GitHub Pages` run 28297538171, `Release Please` run 28297538175, and CodeQL run 28297728640. No open Dependabot PRs or `dependabot/*` branches remained at closeout.

## Key Decisions
- Merge the GitHub Actions Dependabot PRs one at a time -> this kept each `master` verification attributable to a single dependency bump.
- Rebase stale PR branches before merging -> #28 and #29 became stale after earlier merges, so their checks were refreshed before squash merge.
- Close #22 and #23 instead of forcing a no-op merge -> both PRs changed only `docs/package.json` and `docs/package-lock.json`, which no longer exist after the MkDocs/uv migration.
- Record stale npm Dependabot security-update failures as an open thread -> current `.github/dependabot.yml` already uses `uv` for `/docs`, but GitHub still ran stale npm security-update jobs against `/docs` and failed with `dependency_file_not_found`.

## Changes
- `template-go/.github/workflows/ci.yml` - updated via PR #27 and #28 for newer GitHub Actions dependencies.
- `template-go/.github/workflows/docs-pages.yml` - updated via PR #27 and #28 for newer GitHub Actions dependencies.
- `template-go/.github/workflows/release-dry-run.yml` - updated via PR #27 and #29 for newer GitHub Actions dependencies.
- `template-go/.github/workflows/release.yml` - updated via PR #27 and #29 for newer GitHub Actions dependencies.
- `template-go/.github/workflows/security-scan.yml` - updated via PR #27 for newer GitHub Actions dependencies.
- `template-go/.journal/007/NOTES.md` - recorded the Dependabot cleanup checkpoints and handoff state.

## Open Threads
- GitHub's Dependabot security-update service still attempted stale npm updates for the removed `/docs` npm package surface after closeout and failed with `/docs not found`. The dependency graph updates for the current Go and uv ecosystems succeeded; if those old npm alerts remain visible, dismiss or refresh them in GitHub rather than resurrecting the Docusaurus package files.

## References
- PR #27 - https://github.com/meigma/template-go/pull/27
- PR #28 - https://github.com/meigma/template-go/pull/28
- PR #29 - https://github.com/meigma/template-go/pull/29
- Obsolete PR #22 - https://github.com/meigma/template-go/pull/22
- Obsolete PR #23 - https://github.com/meigma/template-go/pull/23
- Final `CI` run - https://github.com/meigma/template-go/actions/runs/28297538170
- Final `GitHub Pages` run - https://github.com/meigma/template-go/actions/runs/28297538171
- Final `Release Please` run - https://github.com/meigma/template-go/actions/runs/28297538175
- Final CodeQL run - https://github.com/meigma/template-go/actions/runs/28297728640

## Lessons
- When Dependabot PRs target a dependency surface that no longer exists, closing them as obsolete is cleaner than reintroducing removed files just to satisfy a stale update branch.
- GitHub can continue to run stale Dependabot security-update jobs after package files are removed; inspect the update logs before assuming `.github/dependabot.yml` still contains the old ecosystem.
