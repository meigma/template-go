# Technical Notes

- The template intentionally exercises releases with its example app before generated projects inherit the setup. The nominal path is binary plus container, but generated projects may be binary-only, container-only, or pure libraries; `DELETE_ME.md` documents what to trim for each shape.
- GoReleaser is used for binary assets only. Container publishing is GitHub Actions-native through Docker actions, GHCR, native amd64/arm64 hosted runner builds, BuildKit provenance/SBOM metadata, and `actions/attest` against the pushed manifest digest.
- The scheduled security scan workflow is drift detection, not a required PR gate. It builds the local amd64 container image weekly/manual-only, scans high/critical fixed vulnerabilities with Trivy, and uploads SARIF to GitHub code scanning.
- Release Please must use bare `vX.Y.Z` tags here: keep `include-component-in-tag: false` and `force-tag-creation: true` in `release-please-config.json`.
- The tag-triggered release workflow resolves a pre-existing draft release without checkout. Keep `contents: write` on `resolve-release` and pass `--repo "$GITHUB_REPOSITORY"` to `gh release view`.
- The Dockerfile pins literal builder/runtime `FROM` references by digest so Dependabot's Docker ecosystem can refresh them. It validates the Go builder version against `.go-version`; when bumping Go, update `.go-version` and the builder `FROM` tag/digest together.
- Required default-branch checks are `ci`, `Binary Release Dry Run`, and `Container Image Dry Run`.
- CI uses GitHub-native caches for Go modules, Go build artifacts, golangci-lint, npm downloads, and BuildKit `type=gha` layer caches. Keep `.moon/toolchains.yml`, `.go-version`, and `go.mod` aligned; treat Moon remote cache as a later opt-in requiring a Bazel Remote Execution-compatible backend and credentials.
- GitHub-specific helper scripts live under `.github/scripts`. The release workflow uses `stage_ghd_release_assets.py` to validate `ghd.toml`, stage GoReleaser binary/SBOM/checksum assets, and verify release checksums before upload.
- Docs now use MkDocs plus `uv` (`docs/mkdocs.yml`, `docs/uv.lock`), not the old Docusaurus/npm package files. Obsolete Dependabot PRs or stale security-update jobs for `docs/package.json` / `docs/package-lock.json` should be closed or dismissed rather than reintroducing those files.
