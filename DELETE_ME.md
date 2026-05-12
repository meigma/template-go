# Welcome to the Meigma Go Template

This repository was generated from `template-go`, the standard starter for Meigma Go projects.
It is meant to give new repositories a working baseline on day one: a small Go CLI by default, Moon task orchestration, pinned CI, dependency automation, repository security defaults, and an enabled release pipeline that has already been exercised by the template application.

Delete this file after you finish the first-repository setup checklist below.
It is only here to orient the initial project owner.

## What This Template Provides

- A minimal Go module at `github.com/meigma/template-go`.
- A Cobra/Viper CLI skeleton under `cmd/template-go` and `internal/cli`.
- Moon tasks for `format`, `lint`, `build`, `test`, and `check`.
- `golangci-lint` wired through Proto and Moon.
- CI that delegates to `moon ci --summary minimal` with pinned actions and minimal token permissions.
- Dependabot coverage for GitHub Actions, Go modules, and the docs npm project.
- Docusaurus docs scaffolding under `docs/`.
- Repository settings for signed commits, squash-only merges, immutable releases, private vulnerability reporting, and protected tags.
- Release workflows for Release Please, GoReleaser binary assets, GHCR container images, checksums, SBOMs, and GitHub artifact attestations.
- A root `ghd.toml` package manifest so released binaries can be installed with `ghd`.

## How It Works

Moon is the main entrypoint for local development and CI:

```sh
moon run root:check
```

That aggregate check runs the Go formatter/linter/build/tests plus the docs typecheck and build.
The GitHub Actions CI workflow runs the same path through:

```sh
moon ci --summary minimal
```

The release machinery is intentionally enabled in the template repository so the starter app proves Release Please, GoReleaser binary releases, container image builds, artifact validation, and attestations before generated projects inherit the setup.
The nominal generated-project path is a CLI or service with both downloadable binaries and a container image. If the new project is binary-only, container-only, or a pure Go library, trim the release files as described below before the first release.

## First Setup Checklist

1. Rename the Go module:

   ```sh
   go mod edit -module github.com/meigma/YOUR_REPO
   ```

2. Choose the project shape.

   Most applications should keep both the binary and container paths. For other shapes:

   - Binary plus container: keep the default layout and update names.
   - Binary only: keep GoReleaser and `ghd.toml`; remove the container release jobs and Dockerfile if the project will not ship images.
   - Container only: keep the Dockerfile and container jobs; remove GoReleaser release assets and `ghd.toml` if users should not install a standalone binary.
   - Library only: remove the CLI, Dockerfile, GoReleaser, `ghd.toml`, and publish workflow pieces. Keep Release Please only if the library should still get changelogs, tags, and draft GitHub releases.

3. For a binary-producing project, rename the binary directory:

   ```sh
   mv cmd/template-go cmd/YOUR_BINARY
   ```

   For a library-only project, delete `cmd/template-go`, remove or rewrite `internal/cli`, and remove Cobra/Viper dependencies that are no longer used.

4. Replace template placeholders:

   ```sh
   rg "template-go|TEMPLATE_GO|github.com/meigma/template-go"
   ```

   Update Go imports, Moon metadata, README text, docs text, and CLI environment variable prefixes. For release-bearing projects, also update `.goreleaser.yaml`, `release-please-config.json`, `ghd.toml`, `Dockerfile`, and `.github/workflows/release*.yml` as applicable.

5. Refresh module metadata:

   ```sh
   go mod tidy
   ```

6. Configure releases for the chosen shape.

   For the nominal binary plus container case:

   - Update `.goreleaser.yaml`: `project_name`, build `id`, `main`, binary name, archive name template, and any linked package paths.
   - Update `ghd.toml`: `provenance.signer_workflow`, package name, description, asset patterns, and installed binary path.
   - Update `Dockerfile`: binary path, labels, default `SOURCE`, and runtime command if this is a service instead of a CLI.
   - Update `.github/workflows/release.yml`: `IMAGE_NAME`, binary validation names, container labels, summary commands, and verification examples.
   - Update `.github/workflows/release-dry-run.yml`: binary validation names, local container image name, and smoke-test commands.
   - Update `.github/repository-settings.toml` only if required status-check names change.

   For binary-only projects:

   - Keep `.goreleaser.yaml`, `ghd.toml`, `Release Please`, `Binary Release Dry Run`, and the binary asset portions of `release.yml`.
   - Remove the `container-image-release` job, container verification summary text, and `Container Image Dry Run`.
   - Remove `Dockerfile` and `.dockerignore` if no container build remains.
   - Remove `Container Image Dry Run` from required branch checks.

   For container-only projects:

   - Keep `Release Please`, `Container Image Dry Run`, `container-image-release`, `Dockerfile`, and `.dockerignore`.
   - Remove `.goreleaser.yaml`, `ghd.toml`, `binary-release-assets`, binary verification summary text, and `Binary Release Dry Run`.
   - Change `container-image-release` so it depends only on `resolve-release`.
   - Remove `Binary Release Dry Run` from required branch checks.

   For library-only projects:

   - Keep Release Please if version tags and changelogs are useful.
   - Delete `.github/workflows/release.yml`, `.github/workflows/release-dry-run.yml`, `.goreleaser.yaml`, `ghd.toml`, `Dockerfile`, and `.dockerignore` unless the library publishes some other artifact.
   - Remove release dry-run checks from `.github/repository-settings.toml`.
   - If the library should not create releases at all, delete `.github/workflows/release-please.yml`, `release-please-config.json`, `.release-please-manifest.json`, and `CHANGELOG.md`.

   In every release-bearing project, configure the release app credentials, protected-tag bypass, and repository package permissions before the first release. Run the release dry-run workflow after these edits and before merging the first release PR.

7. Run the full local check:

   ```sh
   moon run root:check
   ```

8. Update project-facing docs:

   - Rewrite `README.md` for the actual project.
   - Review `CONTRIBUTING.md` and `SECURITY.md`.
   - Add a real license before publishing the repository.

9. Delete this file:

   ```sh
   rm DELETE_ME.md
   ```
