# Claude Code multi-account profile launchers
#
# Source this from ~/.bashrc (Linux/WSL) or ~/.zshrc (macOS):
#   source ~/.claude/claude-profiles.sh
#
# Uses HOME override to isolate credentials and session state per account.
# Shared config (commands, skills, hooks) is symlinked from canonical ~/.claude/.
# Setup: bash ~/.claude/setup-profiles.sh

_claude_with_profile() {
  local profile="$1"
  shift
  local profile_dir="$HOME/.claude-profiles/$profile"
  if [ ! -d "$profile_dir" ]; then
    echo "Profile '$profile' not found. Run: bash ~/.claude/setup-profiles.sh" >&2
    return 1
  fi
  CLAUDE_PROFILE="$profile" HOME="$profile_dir" command claude "$@"
}

claude-work() {
  _claude_with_profile work "$@"
}

claude-personal() {
  _claude_with_profile personal "$@"
}

claude-work-dsp() {
  if [[ "$1" == "-c" ]]; then
    shift
    _claude_with_profile work --dangerously-skip-permissions --continue "$@"
  elif [[ "$1" == "-r" ]]; then
    shift
    _claude_with_profile work --dangerously-skip-permissions --resume "$@"
  else
    _claude_with_profile work --dangerously-skip-permissions "$@"
  fi
}

claude-personal-dsp() {
  if [[ "$1" == "-c" ]]; then
    shift
    _claude_with_profile personal --dangerously-skip-permissions --continue "$@"
  elif [[ "$1" == "-r" ]]; then
    shift
    _claude_with_profile personal --dangerously-skip-permissions --resume "$@"
  else
    _claude_with_profile personal --dangerously-skip-permissions "$@"
  fi
}
