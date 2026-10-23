# terraform-platform

Catalog, conventions and tooling for the Olensys Terraform/OpenTofu module library.

- [Interface contract](docs/interface.md)
- [Conventions](docs/conventions.md)
- [AWS and Google pairs](docs/pairs.md)
- [Proposals](docs/proposals/README.md)

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/new-module.sh <name> <cloud> <description>` | Create a module repo from the template and seed `metadata.yaml` |
| `scripts/fleet.sh "<pr title>" <script>` | Run a script across every module repo and open PRs (needs `multi-gitter`) |
| `scripts/consumers.sh [module]` | Find consumers of a module under `$WORKSPACE` (default `$HOME/workspace`) |
| `scripts/catalog.py --write\|--check` | Regenerate or verify the table below |

## Catalog

<!-- BEGIN_CATALOG -->
<!-- END_CATALOG -->
