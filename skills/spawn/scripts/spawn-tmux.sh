#!/usr/bin/env bash
# spawn-tmux.sh — portable parallel-worktree + tmux spawner. Mac and WSL.
#
# Reproduces the /spawn workflow as a runnable artifact: for each slug it
# creates a git worktree on its own branch, opens one tmux pane per worktree
# (each launching Claude Code), tiles the panes, and attaches. No macOS-only
# AppleScript — the portable "open" is just attaching in your current terminal.
#
# Usage:
#   spawn-tmux.sh [options] <slug> [<slug> ...]
#
# Options:
#   --base <ref>        Base ref for new worktrees (default: auto-resolve
#                       origin/dev -> dev -> origin/main -> main -> HEAD)
#   --prefix <p>        Branch prefix (default: feat/)
#   --session <name>    tmux session name (default: basename of repo)
#   --prompt <text>     Initial prompt sent to every pane's claude (default: none)
#   --claude-cmd <cmd>  Launcher to run in each pane (default: $CLAUDE_CMD or "claude")
#   --install-deps      If tmux is missing, install it (apt on WSL, brew on Mac)
#   --no-attach         Create everything but don't attach (for scripting/tests)
#   -h, --help          Show this help
#
# Examples:
#   spawn-tmux.sh core-rules ui-and-flow ai-opponent
#   spawn-tmux.sh --base dev --prompt 'Read BRIEF.md and propose a task list' a b
set -euo pipefail

PREFIX="feat/"
BASE=""
SESSION=""
PROMPT=""
CLAUDE_CMD="${CLAUDE_CMD:-claude}"
INSTALL_DEPS=false
ATTACH=true
SLUGS=()

die() { echo "spawn-tmux: $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --base)       BASE="$2"; shift 2;;
        --prefix)     PREFIX="$2"; shift 2;;
        --session)    SESSION="$2"; shift 2;;
        --prompt)     PROMPT="$2"; shift 2;;
        --claude-cmd) CLAUDE_CMD="$2"; shift 2;;
        --install-deps) INSTALL_DEPS=true; shift;;
        --no-attach)  ATTACH=false; shift;;
        -h|--help)    sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
        -*)           die "unknown option: $1";;
        *)            SLUGS+=("$1"); shift;;
    esac
done

[[ ${#SLUGS[@]} -ge 1 ]] || die "need at least one slug (try --help)"
for s in "${SLUGS[@]}"; do
    [[ "$s" =~ ^[a-z0-9-]+$ ]] || die "invalid slug '$s' (use [a-z0-9-] only)"
done

# --- platform detect ------------------------------------------------------
if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then PLATFORM=wsl
elif [[ "$(uname -s)" == "Darwin" ]]; then PLATFORM=mac
else PLATFORM=linux; fi

# --- ensure tmux ----------------------------------------------------------
if ! command -v tmux >/dev/null 2>&1; then
    if $INSTALL_DEPS; then
        case "$PLATFORM" in
            wsl|linux) echo "Installing tmux (sudo apt)..."; sudo apt-get update -y && sudo apt-get install -y tmux;;
            mac)       echo "Installing tmux (brew)...";     brew install tmux;;
        esac
    else
        case "$PLATFORM" in
            wsl|linux) die "tmux not installed. Run: sudo apt install tmux   (or re-run with --install-deps)";;
            mac)       die "tmux not installed. Run: brew install tmux        (or re-run with --install-deps)";;
        esac
    fi
fi
command -v "$CLAUDE_CMD" >/dev/null 2>&1 || die "'$CLAUDE_CMD' not on PATH (set --claude-cmd or \$CLAUDE_CMD)"

# --- repo + base ref ------------------------------------------------------
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repo"
REPO=$(basename "$REPO_ROOT")
[[ -n "$SESSION" ]] || SESSION="$REPO"

resolve_base() {
    [[ -n "$BASE" ]] && { git rev-parse --verify "$BASE" >/dev/null 2>&1 && { echo "$BASE"; return; } || die "base ref '$BASE' not found"; }
    for ref in origin/dev dev origin/main main; do
        git rev-parse --verify "$ref" >/dev/null 2>&1 && { echo "$ref"; return; }
    done
    echo HEAD
}
BASE=$(resolve_base)
echo "spawn-tmux: repo=$REPO  base=$BASE  session=$SESSION  platform=$PLATFORM  slugs=${SLUGS[*]}"

# --- create worktrees -----------------------------------------------------
declare -a DIRS
for slug in "${SLUGS[@]}"; do
    dir="$REPO_ROOT/../$REPO-$slug"
    branch="$PREFIX$slug"
    if [[ -d "$dir" ]]; then
        echo "  worktree exists, reusing: $dir"
    elif git show-ref --verify --quiet "refs/heads/$branch"; then
        die "branch '$branch' already exists without a worktree — resolve manually"
    else
        git worktree add "$dir" -b "$branch" "$BASE" >/dev/null
        echo "  created worktree: $dir ($branch)"
    fi
    DIRS+=("$dir")
done

# --- build tmux panes -----------------------------------------------------
tmux kill-session -t "$SESSION" 2>/dev/null || true
launch="$CLAUDE_CMD"
[[ -n "$PROMPT" ]] && launch="$CLAUDE_CMD $(printf '%q' "$PROMPT")"

tmux new-session -d -s "$SESSION" -n build -c "${DIRS[0]}" "$launch"
for i in $(seq 1 $(( ${#DIRS[@]} - 1 )) ); do
    tmux split-window -t "$SESSION:build" -c "${DIRS[$i]}" "$launch"
    tmux select-layout -t "$SESSION:build" tiled >/dev/null
done
tmux select-layout -t "$SESSION:build" tiled >/dev/null
echo "spawn-tmux: ${#DIRS[@]} pane(s) launched in session '$SESSION'."

# --- attach (portable) ----------------------------------------------------
if $ATTACH; then
    exec tmux attach -t "$SESSION"
else
    echo "spawn-tmux: attach with -> tmux attach -t $SESSION"
fi
