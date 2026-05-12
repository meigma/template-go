# Welcome to the Meigma Go Template

This repository was generated from `template-go`, the standard starter for Meigma Go projects.
It is meant to give new repositories a working baseline on day one: a small Go CLI, Moon task orchestration, pinned CI, dependency automation, repository security defaults, and an enabled release pipeline that has already been exercised by the template application.

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
- Release workflows for Release Please, GoReleaser, checksums, SBOMs, and GitHub artifact attestations.
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

The release machinery is intentionally enabled in the template repository so the starter app proves Release Please, GoReleaser, container image builds, artifact validation, and attestations before generated projects inherit the setup.
When creating a new project, configure the release app credentials and tag-ruleset bypass for that repository, update the GHCR image name, then let the dry-run workflow pass before publishing the first release.

## First Setup Checklist

1. Rename the Go module:

   ```sh
   go mod edit -module github.com/meigma/YOUR_REPO
   ```

2. Rename the binary directory:

   ```sh
   mv cmd/template-go cmd/YOUR_BINARY
   ```

3. Replace template placeholders:

   ```sh
   rg "template-go|TEMPLATE_GO|github.com/meigma/template-go"
   ```

   Update Go imports, Moon metadata, GoReleaser config, Release Please config, `ghd.toml`, README text, docs text, and CLI environment variable prefixes.

4. Refresh module metadata:

   ```sh
   go mod tidy
   ```

5. Run the full local check:

   ```sh
   moon run root:check
   ```

6. Configure or remove releases:

   - Keep the enabled workflows if this project publishes binaries or a container image.
   - Delete the release workflows if this project will never publish releases.
   - Review `.goreleaser.yaml`, `release-please-config.json`, `Dockerfile`, `.github/workflows/release*.yml`, and repository release app settings before the first real release.
   - Keep and update `ghd.toml` if the binary should be installable through `ghd`.

7. Update project-facing docs:

   - Rewrite `README.md` for the actual project.
   - Review `CONTRIBUTING.md` and `SECURITY.md`.
   - Add a real license before publishing the repository.

8. Delete this file:

   ```sh
   rm DELETE_ME.md
   ```
