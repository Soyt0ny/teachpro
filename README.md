# teachpro — portable multi-agent installer

Installs the `teachpro` teaching personality (based on `amosblomqvist/learn`: probe → plan → teach) on any machine, for all agents, with one command.

## Install

```bash
git clone <your-repo-url> teachpro
cd teachpro
./install.sh
```

Preview without changes:

```bash
./install.sh --dry-run
```

Install only some agents:

```bash
./install.sh --only pi,opencode,claude
```

## What it installs

- Skills `teachpro`, `teach`, `visualize` → every detected agent skills dir:
  `~/.agents/skills`, `~/.config/opencode/skills`, `~/.claude/skills`,
  `~/.codex/skills`, `~/.copilot/skills` (only if `~/.copilot` exists),
  `~/.gemini/skills`, `~/.pi/skills`
- Pi-only extras (skipped when `~/.pi` is absent):
  `agents/` (researcher, mermaid-maker, svg-maker),
  `extensions/` (quiz, md-log, ask-user-question, visual-tools),
  `config/teachpro.json` (never overwrites an existing config)

## Strategy: copy, like gentle-ai

Verified on the source machine: gentle-ai skills are separate copies per agent dir (distinct inodes), not symlinks. Copy keeps installs portable across machines, survives repo deletion, and avoids symlink issues. The repo is the source of truth — re-run `./install.sh` after `git pull` to update.

## Uninstall

```bash
./uninstall.sh
```

Removes only the three skill copies per agent dir. Pi agents/extensions/config are left untouched.
