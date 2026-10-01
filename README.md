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
  `agents/*.md` (researcher, mermaid-maker, svg-maker),
  `extensions/` (quiz, md-log, ask-user-question, visual-tools),
  `config/teachpro.json` (never overwrites an existing config)
- Subagents where each platform allows it:
  - Claude: `agents/claude/researcher.md` → `~/.claude/agents/researcher.md`
  - OpenCode: `teachpro-researcher` entry merged into `opencode.json`
    (idempotent; never touches user-owned keys)
  - Codex / Copilot / Gemini: skills-only (no file-based subagent
    mechanism found, so nothing to register)

## Why only researcher travels

`mermaid-maker` and `svg-maker` depend on pi-only tools
(`write_mermaid`, `render_mermaid`, `write_svg`, … from the bundled
`visual-tools` extension). They cannot run on other platforms without
reimplementing those tools, so they stay pi-only by design. `researcher`
only needs web search + fetch, which every platform has.

## Strategy: copy, like gentle-ai

Verified on the source machine: gentle-ai skills are separate copies per agent dir (distinct inodes), not symlinks. Copy keeps installs portable across machines, survives repo deletion, and avoids symlink issues. The repo is the source of truth — re-run `./install.sh` after `git pull` to update.

## Uninstall

```bash
./uninstall.sh
```

Removes only the three skill copies per agent dir. Pi agents/extensions/config are left untouched.
