#!/usr/bin/env python3
"""Render the module catalog table into README.md.

Usage:
  python3 scripts/catalog.py --write   rewrite the table between the README markers
  python3 scripts/catalog.py --check   exit 1 if the README table would change

Requires only the Python 3 standard library and an authenticated `gh` on PATH.
Repos that do not exist yet (404) are rendered with maturity "planned".
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ORG = "Olensys"
ROOT = Path(__file__).resolve().parent.parent
BEGIN = "<!-- BEGIN_CATALOG -->"
END = "<!-- END_CATALOG -->"
HEADER = ["Module", "Cloud", "Tier", "Maturity", "Description", "Pairs with", "Latest tag"]


def parse_catalog(path):
    """Parse lines like `  - { name: x, cloud: y, tier: z, phase: 0 }`."""
    repos = []
    for line in path.read_text().splitlines():
        m = re.match(r"^\s*-\s*\{(.*)\}\s*$", line)
        if not m:
            continue
        entry = {}
        for part in m.group(1).split(","):
            k, _, v = part.partition(":")
            entry[k.strip()] = v.strip()
        repos.append(entry)
    return repos


def parse_metadata(text):
    """Parse the flat metadata.yaml schema (top-level scalars; inline lists/maps kept as text)."""
    out = {}
    for line in text.splitlines():
        if not line.strip() or line.lstrip().startswith("#") or line[0] in " \t":
            continue
        k, sep, v = line.partition(":")
        if not sep:
            continue
        v = v.strip()
        if " #" in v:
            v = v.split(" #", 1)[0].strip()
        if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
            v = v[1:-1]
        out[k.strip()] = None if v in ("null", "~", "") else v
    return out


def gh_api(endpoint, raw=False):
    """Return (status, stdout). status is 'ok', 'missing' (404) or raises RuntimeError."""
    cmd = ["gh", "api", endpoint]
    if raw:
        cmd[2:2] = ["-H", "Accept: application/vnd.github.raw"]
    try:
        p = subprocess.run(cmd, capture_output=True, text=True)
    except FileNotFoundError:
        sys.exit("error: gh CLI not found on PATH")
    if p.returncode == 0:
        return "ok", p.stdout
    err = p.stderr + p.stdout
    if "404" in err or "Not Found" in err:
        return "missing", ""
    raise RuntimeError(f"gh api {endpoint} failed: {err.strip()}")


def latest_tag(name):
    status, out = gh_api(f"repos/{ORG}/{name}/tags?per_page=1")
    if status != "ok":
        return "-"
    m = re.search(r'"name"\s*:\s*"([^"]+)"', out)
    return m.group(1) if m else "-"


def row_for(repo):
    name = repo["name"]
    status, text = gh_api(f"repos/{ORG}/{name}/contents/metadata.yaml", raw=True)
    if status == "missing":
        repo_status, _ = gh_api(f"repos/{ORG}/{name}")
        maturity = "planned" if repo_status == "missing" else "unknown"
        return [f"`{name}`", repo["cloud"], repo["tier"], maturity, "", "", "-"]
    md = parse_metadata(text)
    pairs = md.get("pairs_with")
    return [
        f"[`{name}`](https://github.com/{ORG}/{name})",
        md.get("cloud") or repo["cloud"],
        md.get("tier") or repo["tier"],
        md.get("maturity") or "unknown",
        (md.get("description") or "").replace("|", "\\|"),
        f"`{pairs}`" if pairs else "",
        latest_tag(name),
    ]


def render(repos):
    lines = ["| " + " | ".join(HEADER) + " |", "|" + "|".join("---" for _ in HEADER) + "|"]
    for repo in repos:
        lines.append("| " + " | ".join(row_for(repo)) + " |")
    return "\n".join(lines)


def splice(readme, table):
    if BEGIN not in readme or END not in readme:
        sys.exit(f"error: README.md is missing {BEGIN} / {END} markers")
    head, rest = readme.split(BEGIN, 1)
    _, tail = rest.split(END, 1)
    return f"{head}{BEGIN}\n{table}\n{END}{tail}"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--write", action="store_true")
    g.add_argument("--check", action="store_true")
    args = ap.parse_args()

    repos = parse_catalog(ROOT / "catalog" / "catalog.yaml")
    if not repos:
        sys.exit("error: no repos found in catalog/catalog.yaml")
    try:
        table = render(repos)
    except RuntimeError as e:
        sys.exit(f"error: {e}")
    readme_path = ROOT / "README.md"
    current = readme_path.read_text()
    updated = splice(current, table)
    if args.write:
        if updated != current:
            readme_path.write_text(updated)
            print("README.md updated")
        else:
            print("README.md already up to date")
        return 0
    if updated != current:
        print("README.md catalog table is out of date; run: python3 scripts/catalog.py --write", file=sys.stderr)
        return 1
    print("README.md catalog table is up to date")
    return 0


if __name__ == "__main__":
    sys.exit(main())
