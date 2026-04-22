# MAC_MIGRATION.md — macOS Setup Guide

**If you are a Claude Code instance reading this to set up Mason's MacBook, follow these steps in order.** This file exists because `CLAUDE.md` and some scripts in this repo were authored on a WSL machine and contain Linux-specific paths. Those files are intentionally left WSL-flavored so the WSL machine keeps working — this guide covers the Mac-specific adaptations.

---

## Assumptions about this machine

- macOS (any recent version)
- Default shell is **zsh** (anything from Catalina onward). If Mason is on bash, substitute `~/.bashrc` for `~/.zshrc` throughout.
- Username may differ from `mgrim` — do **not** hardcode paths; always use `$HOME` or `~`.
- Homebrew is installed (or Mason is willing to install it). If not: https://brew.sh

---

## Step 0 — Prerequisites

Check each of these before starting. If missing, install and proceed.

```bash
command -v git       || brew install git
command -v node      || brew install node          # or nvm
command -v python3   || brew install python
command -v claude    || npm install -g @anthropic-ai/claude-code
```

Ask Mason before installing anything you're unsure about.

---

## Step 1 — Clone this repo

Suggested location: `~/Github/claude-code-config` (mirrors the WSL layout). Confirm with Mason before choosing a different path.

```bash
mkdir -p ~/Github
git clone <repo-url> ~/Github/claude-code-config
cd ~/Github/claude-code-config
```

---

## Step 2 — Run the installer

```bash
bash install.sh
```

This copies `CLAUDE.md`, commands, skills, agents, hooks, settings templates, and the multi-profile scripts (`setup-profiles.sh`, `claude-profiles.sh`) into `~/.claude/`.

---

## Step 3 — Fix the WSL-specific paths in CLAUDE.md

`~/.claude/CLAUDE.md` references `/mnt/o/obsidian_vault/` — a WSL mount that does not exist on macOS. Ask Mason where the Obsidian vault lives on this Mac (common locations: `~/Documents/obsidian_vault`, iCloud Drive, Dropbox, an external drive).

**Recommended fix — symlink, then edit paths:**

```bash
# Replace <real-vault-path> with Mason's actual vault location
ln -s "<real-vault-path>" ~/obsidian_vault
```

Then edit `~/.claude/CLAUDE.md` and replace every `/mnt/o/obsidian_vault` with `~/obsidian_vault`. There are three occurrences in the "Wiki Knowledge Base" and "Obsidian Vault" sections.

Also remove the WSL explanatory clause: the line that reads "`(WSL path for O:\obsidian_vault)`" should be changed to note the Mac location instead, or just deleted.

**Do not commit these edits back to the repo** — the WSL machine still uses `/mnt/o/...`. If Mason wants the repo's CLAUDE.md to be truly portable later, that's a separate refactor.

---

## Step 4 — Set up multi-account profiles

This creates `~/.claude-profiles/{work,personal}/` with symlinks back to canonical `~/.claude/`.

```bash
bash ~/.claude/setup-profiles.sh
```

The script is defensive — missing dotfiles (e.g. `.nvm` if Mason uses Homebrew-node instead) are skipped silently.

---

## Step 5 — Install the profile aliases into zsh

```bash
echo 'source ~/.claude/claude-profiles.sh' >> ~/.zshrc
source ~/.zshrc
```

Verify the functions are loaded:

```bash
type claude-personal-dsp
# Expected: "claude-personal-dsp is a shell function..."
```

---

## Step 6 — Log in to each profile

Each profile has its own Claude Code credentials and session state.

```bash
HOME=~/.claude-profiles/work claude login
HOME=~/.claude-profiles/personal claude login
```

---

## Step 7 — Install Claude Code plugins

Launch Claude Code under a profile (e.g. `claude-personal`) and run:

```
/plugins marketplace add anthropics/claude-plugins-official
/plugins marketplace add jarrodwatts/claude-hud
/plugins marketplace add k-dense-ai/claude-scientific-writer

/plugins install frontend-design
/plugins install github
/plugins install pr-review-toolkit
/plugins install pyright-lsp
/plugins install playwright
/plugins install code-simplifier
/plugins install claude-hud
```

See `README.md` for the full list and optional plugins.

---

## Step 8 — External CLI tools

```bash
# Multi-model debate (/adversarial-spec, /council)
npm install -g @openai/codex && codex login
npm install -g @google/gemini-cli && gemini auth login

# gemini-image skill
pip3 install google-genai pillow
# Then add to ~/.zshrc:
#   export GEMINI_API_KEY='...'
```

For ntfy push notifications, edit `~/.claude/settings.json` and replace `YOUR-TOPIC-HERE` with Mason's ntfy topic (ask him — he has one already set up on the WSL machine, same topic should work).

---

## Step 9 — Verify

Each of these should succeed:

```bash
claude-personal --version           # launches Claude Code under personal profile
claude-personal-dsp                 # launches with --dangerously-skip-permissions
```

Inside Claude Code:

- `/ralph status` — skills loaded
- `/plugins list` — plugins installed
- Status line at bottom shows claude-hud output

---

## Step 10 — Things you'll need to ask Mason

Don't guess. Ask:

1. **Obsidian vault location on this Mac** (needed for Step 3)
2. **ntfy topic name** (needed for Step 8) — or skip ntfy entirely
3. **Whether to set up both `work` and `personal` profiles**, or just one
4. **Where he wants this repo cloned** if `~/Github/claude-code-config` isn't right
5. **GEMINI_API_KEY** — if he wants the `gemini-image` skill on this Mac

---

## Known portability gaps (for future cleanup)

These aren't blockers, but flag them to Mason if relevant:

- `CLAUDE.md` hardcodes `/mnt/o/obsidian_vault` — could be refactored to use `~/obsidian_vault` symlink on all machines
- `setup-profiles.sh` `HOME_DOTFILES` list includes `miniconda3`, `mcp_agent_mail`, `.nvm` which may not exist on Mac — the script skips missing ones, so no error, but the list could be trimmed
- Hook scripts in `hooks/` — spot-check for `/mnt/`, `wsl`, or `bash`-specific syntax before relying on them. Most are Python and should be portable.
