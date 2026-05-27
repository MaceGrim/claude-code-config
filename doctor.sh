#!/usr/bin/env bash
# doctor.sh — read-only parity preflight for claude-code-config.
#
# Checks: platform, required/optional external tools (+ versions vs
# tool-versions.txt), installed-vs-repo commit drift, and plugin presence
# vs plugins.txt. Exits non-zero if a REQUIRED tool is missing or the install
# is behind the repo. Never mutates anything.
#
# Usage:
#   ./doctor.sh                 # check using files in ~/.claude (installed)
#   ./doctor.sh --repo <dir>    # also compare ~/.claude commit to repo HEAD
set -uo pipefail

CLAUDE_DIR="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR=""
if [[ "${1:-}" == "--repo" && -n "${2:-}" ]]; then REPO_DIR="$2"; fi
# If run from inside the repo, default REPO_DIR to it.
if [[ -z "$REPO_DIR" ]] && git -C "$SCRIPT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    REPO_DIR="$SCRIPT_DIR"
fi

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'
fail=0
ok()   { echo "  ${GREEN}OK${NC}    $1"; }
warn() { echo "  ${YELLOW}WARN${NC}  $1"; }
bad()  { echo "  ${RED}FAIL${NC}  $1"; fail=1; }
hdr()  { echo; echo "${BLUE}== $1 ==${NC}"; }

# Pick the canonical spec files: prefer repo, fall back to installed copies.
spec_file() {
    local name="$1"
    if [[ -n "$REPO_DIR" && -f "$REPO_DIR/$name" ]]; then echo "$REPO_DIR/$name"
    elif [[ -f "$CLAUDE_DIR/$name" ]]; then echo "$CLAUDE_DIR/$name"
    elif [[ -f "$SCRIPT_DIR/$name" ]]; then echo "$SCRIPT_DIR/$name"
    fi
}

# ver_ge A B  -> 0 (true) if A >= B, using version sort. Best-effort.
ver_ge() {
    [[ "$1" == "$2" ]] && return 0
    local smaller
    smaller=$(printf '%s\n%s\n' "$1" "$2" | sort -V 2>/dev/null | head -n1)
    [[ "$smaller" == "$2" ]]
}
# Pull a dotted version number out of a tool's --version / -V output.
detect_ver() {
    local t="$1" out
    out=$("$t" --version 2>&1 || true); [[ -z "$out" ]] && out=$("$t" -V 2>&1 || true)
    echo "$out" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1
}

# --- Platform -------------------------------------------------------------
hdr "Platform"
uname_s=$(uname -s 2>/dev/null || echo unknown)
if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
    echo "  Windows + WSL  ($uname_s)"; PLATFORM=wsl
elif [[ "$uname_s" == "Darwin" ]]; then
    echo "  macOS  ($uname_s)"; PLATFORM=mac
else
    echo "  $uname_s"; PLATFORM=other
fi
echo "  shell: ${SHELL:-?}   HOME: $HOME"

# --- Tools ----------------------------------------------------------------
hdr "Tools (vs tool-versions.txt)"
tv=$(spec_file tool-versions.txt)
if [[ -z "$tv" ]]; then
    warn "tool-versions.txt not found — skipping tool checks"
else
    while read -r name minv req _rest; do
        [[ -z "$name" || "$name" == \#* ]] && continue
        if ! command -v "$name" >/dev/null 2>&1; then
            if [[ "$req" == required ]]; then bad "$name missing (required)"
            else warn "$name missing (optional)"; fi
            continue
        fi
        v=$(detect_ver "$name")
        if [[ "$minv" != "-" && -n "$v" ]] && ! ver_ge "$v" "$minv"; then
            warn "$name $v  (< min $minv)"
        else
            ok "$name ${v:-present}"
        fi
    done < "$tv"
fi

# --- Install freshness -----------------------------------------------------
hdr "Install freshness"
stamp="$CLAUDE_DIR/.installed-commit"
if [[ -f "$stamp" ]]; then
    installed=$(<"$stamp")
    echo "  installed at: $installed"
    if [[ -n "$REPO_DIR" ]]; then
        repo_head=$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || echo "?")
        echo "  repo HEAD:    $repo_head"
        if [[ "$installed" != "$repo_head" ]]; then
            bad "install is behind/ahead of repo — run claude-sync"
        else
            ok "install matches repo HEAD"
        fi
    else
        warn "no repo dir given (use --repo) — cannot compare to repo HEAD"
    fi
else
    warn "no .installed-commit stamp — run install.sh (via claude-sync) to create it"
fi

# --- Plugins ---------------------------------------------------------------
hdr "Plugins (vs plugins.txt)"
pf=$(spec_file plugins.txt)
if [[ -z "$pf" ]]; then
    warn "plugins.txt not found"
else
    # Best-effort: report presence under ~/.claude/plugins. Plugin install is
    # manual, so absence is informational (WARN), never a hard FAIL.
    while read -r kind pname _src; do
        [[ -z "$kind" || "$kind" == \#* || "$kind" != plugin ]] && continue
        if compgen -G "$CLAUDE_DIR/plugins/*$pname*" >/dev/null 2>&1; then
            ok "plugin $pname present"
        else
            warn "plugin $pname not detected under ~/.claude/plugins (install via /plugins)"
        fi
    done < "$pf"
fi

# --- Summary ---------------------------------------------------------------
hdr "Summary"
if [[ "$fail" -eq 0 ]]; then
    echo "  ${GREEN}All required checks passed.${NC}"
else
    echo "  ${RED}Required checks failed — see FAIL lines above.${NC}"
fi
exit "$fail"
