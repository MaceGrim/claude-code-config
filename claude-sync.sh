#!/usr/bin/env bash
# claude-sync.sh — the ONE supported way to update Claude Code config on a
# machine. Pulls the repo, re-runs the installer (deploys into ~/.claude), and
# runs doctor. Run it from anywhere; it locates its own repo via BASH_SOURCE.
#
# Why this exists: `git pull` alone does NOT update ~/.claude — install.sh
# copies files in. Forgetting the reinstall is the #1 cause of the two
# machines silently drifting. This makes pull+install+check a single action.
#
# Usage:
#   ./claude-sync.sh            # pull + install + doctor   (normal update)
#   ./claude-sync.sh --check    # pull + doctor only, no reinstall (dry health)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "claude-sync must live inside the claude-code-config git repo." >&2
    exit 1
fi

MODE="${1:-full}"
echo "[claude-sync] repo:   $SCRIPT_DIR"
echo "[claude-sync] branch: $(git rev-parse --abbrev-ref HEAD)"

echo "[claude-sync] pulling (ff-only)..."
git pull --ff-only

if [[ "$MODE" == "--check" ]]; then
    echo "[claude-sync] --check: skipping install"
else
    echo "[claude-sync] installing into ~/.claude ..."
    ./install.sh
fi

echo "[claude-sync] running doctor..."
# doctor returns non-zero on missing-required / drift; surface it but don't
# abort the script so the summary always prints.
./doctor.sh --repo "$SCRIPT_DIR" || true

echo "[claude-sync] done."
