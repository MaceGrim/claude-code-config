# Cross-machine parity — Mac ⇄ Windows+WSL

How to keep the Claude Code experience **identical** across Mason's two
machines, and how to set up / update each. Read this first if you're a Claude
session asked to "get this running on the other machine."

## Mental model

- **The repo is the source of truth.** `~/.claude/` is a *rebuilt install*, not
  the repo. `install.sh` copies repo → `~/.claude/` (skills are `rm -rf`'d and
  re-copied, so removed-upstream files don't linger).
- **`git pull` alone does NOT update `~/.claude`.** You must re-run the
  installer after pulling. Forgetting that is the #1 cause of the two machines
  silently drifting — so we wrap pull+install+check into one command.
- **One command to update: `claude-sync.sh`.** It pulls, installs, and runs the
  doctor. Make it the *only* way you update config. Don't hand-run `git pull`.
- **Credentials and per-profile state never sync** (by design). You log in
  separately on each machine; `~/.claude-profiles/{work,personal}` projects /
  tasks / cache are per-machine.

## What lives where

| File | Role |
|------|------|
| `install.sh` | Deploy repo → `~/.claude`; stamps `.installed-commit`. |
| `claude-sync.sh` | **The update command**: `git pull` → `install.sh` → `doctor.sh`. |
| `doctor.sh` | Read-only preflight: platform, tools+versions, install freshness, plugins. |
| `tool-versions.txt` | Expected external tools (doctor reads it). |
| `plugins.txt` | Canonical plugin/marketplace list (manual install, but drift is detectable). |
| `.gitattributes` | Forces `eol=lf` so shell shebangs never get CRLF-mangled. |
| `setup-profiles.sh` | Creates `~/.claude-profiles/{work,personal}`, symlinks shared config + home dotfiles. |
| `claude-profiles.sh` | Shell funcs: `claude-personal`, `claude-personal-dsp`, etc. |

## First-time setup

Steps are identical except the shell-rc file and the clone location. Do these
once per machine.

### Mac

```sh
# 1. Clone (zsh)
git clone https://github.com/MaceGrim/claude-code-config.git ~/GitHub/claude-code-config
cd ~/GitHub/claude-code-config

# 2. Deploy
./install.sh

# 3. Multi-account profiles
bash ~/.claude/setup-profiles.sh

# 4. Source profile functions from zsh + add a sync alias
echo 'source ~/.claude/claude-profiles.sh' >> ~/.zshrc
echo "alias claude-sync='$PWD/claude-sync.sh'" >> ~/.zshrc
source ~/.zshrc

# 5. Log in per profile
HOME=~/.claude-profiles/personal claude login
HOME=~/.claude-profiles/work     claude login

# 6. Health check
./doctor.sh --repo "$PWD"
```

### Windows + WSL

Run **inside the WSL distro** (Ubuntu/bash), and **clone into the Linux
filesystem** (`~/...`), NOT `/mnt/c/...` — `/mnt/c` is slow and invites
Windows-side git to touch line endings.

```bash
# 1. Clone (bash, inside WSL, on the ext4 home)
git clone https://github.com/MaceGrim/claude-code-config.git ~/github/claude-code-config
cd ~/github/claude-code-config

# 2. Deploy
./install.sh

# 3. Multi-account profiles
bash ~/.claude/setup-profiles.sh

# 4. Source profile functions from bash + add a sync alias
echo 'source ~/.claude/claude-profiles.sh' >> ~/.bashrc
echo "alias claude-sync='$PWD/claude-sync.sh'" >> ~/.bashrc
source ~/.bashrc

# 5. Log in per profile
HOME=~/.claude-profiles/personal claude login
HOME=~/.claude-profiles/work     claude login

# 6. Health check
./doctor.sh --repo "$PWD"
```

Prereqs on a fresh WSL distro (install if `doctor.sh` flags them):
`sudo apt update && sudo apt install -y git tmux python3`, Node via `nvm`,
`npm i -g @anthropic-ai/claude-code @openai/codex`. `gemini` is optional.

## Routine updates (both machines — same command)

```sh
claude-sync          # pull + reinstall + doctor, in one step
claude-sync --check  # pull + doctor only (no reinstall) — quick drift check
```

If `doctor` reports `install is behind/ahead of repo`, you ran `git pull`
without reinstalling — just run `claude-sync` and it reconciles.

## Plugins (manual on both, but tracked)

Plugins aren't copied by `install.sh`; install them once per machine inside
Claude Code. The canonical list is `plugins.txt`, and `doctor.sh` reports which
are present so you can spot a machine that's missing one.

```
/plugins marketplace add anthropics/claude-plugins-official
/plugins marketplace add jarrodwatts/claude-hud
/plugins marketplace add k-dense-ai/claude-scientific-writer
/plugins install frontend-design github pr-review-toolkit pyright-lsp playwright code-simplifier claude-hud
```

## Parallel-worktree spawn workflow (the `/spawn` use case)

The **portable, required** primitive is the same on both machines:

```sh
claude --worktree <name> --tmux
```

For the **multi-pane, several-worktrees-at-once** version (what felt good in
testing), use the bundled portable script — same command on Mac and WSL, no
AppleScript:

```sh
~/.claude/skills/spawn/scripts/spawn-tmux.sh core-rules ui-and-flow ai-opponent
# --install-deps  apt/brew-installs tmux if missing
# --base <ref>    base branch for the new worktrees (auto: dev/main/HEAD)
# --prompt <text> initial prompt broadcast to every pane's claude
# --no-attach     create panes without attaching (scripting/tests)
```

It creates one worktree + branch per slug, tiles one Claude pane per worktree,
and attaches in your current terminal (the portable "open").

That creates the worktree + a tmux session. The only thing that differs is the
*optional* "pop open a fresh terminal window for me" convenience — and you
should treat it as optional sugar, never as load-bearing. The reliable fallback
on both machines is just `tmux attach -t <session>`.

### Mac

- `claude --worktree foo --tmux` (uses iTerm2 native panes when available).
- Optional auto-open-a-window trick is macOS-only AppleScript:
  `osascript -e 'tell application "Terminal" to do script "tmux attach -t <session>"'`.
  Do **not** put this in shared tooling — it has no WSL equivalent. See
  `skills/spawn/LEARNINGS.md`.

### Windows + WSL

- `claude --worktree foo --tmux` works the same (classic tmux panes).
- There is **no `osascript`**. If you want a fresh Windows Terminal window
  attached, call it via interop (Windows Terminal must be installed):
  ```bash
  cmd.exe /c wt.exe wsl.exe -- tmux attach -t <session>
  ```
  (`wt` alone isn't on PATH inside WSL; go through `cmd.exe /c wt.exe`.)
- Otherwise just `tmux attach -t <session>` in your current WSL terminal — this
  is the recommended default; don't build the workflow around GUI automation.

## Known parity gaps (accepted)

- **Plugins & external CLI versions** are manually installed → can drift.
  `doctor.sh` + `plugins.txt`/`tool-versions.txt` make drift *visible*, not
  *prevented*. Run `claude-sync --check` on both machines if something feels off.
- **Terminal auto-open** differs by OS (AppleScript vs `wt.exe`); the shared
  contract is only `--tmux` + `tmux attach`.
- **Profile login state** is intentionally per-machine.
