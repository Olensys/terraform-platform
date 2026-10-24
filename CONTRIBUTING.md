# Contributing

This repository holds the catalog, conventions and tooling for the Olensys module library. The same flow applies to every repository in the library.

1. Branch from `main`.
2. Write [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `chore:`, with `!` or a `BREAKING CHANGE:` footer for breaking changes.
3. Open a pull request against `main`.
4. A PR merges after one approval from a maintainer and a green `ci` check.
5. Merge with squash; the PR title becomes the commit message, so it must be a conventional commit.
6. release-please opens a release PR from the conventional commits on `main`; maintainers merge it to cut the release.

## Rules enforced by rulesets

- Direct pushes and force pushes to `main` are blocked.
- Existing `v*` tags cannot be moved or deleted.

## Policy

- Tags are created only by release-please; never create or move a tag by hand. (This is policy, not enforced by a ruleset.)
- Maintainers: never run `scripts/protect-main.sh` from a checkout that is behind main.

## Before you open a PR

- Run the repository's checks locally: `terraform fmt -check -recursive`, `terraform validate`, `terraform test`, `tflint` and `trivy config .`.
- Update the module README with `terraform-docs` when inputs or outputs change.
- See [docs/conventions.md](docs/conventions.md) for naming, interface and release conventions, and [docs/runbooks/test-accounts.md](docs/runbooks/test-accounts.md) for the integration test accounts.
