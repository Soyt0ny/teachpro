#!/usr/bin/env bash
# teachpro multi-agent installer (copy strategy, like gentle-ai).
# Usage: ./install.sh [--dry-run] [--only pi,opencode,claude,codex,copilot,gemini,agents]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0
ONLY=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --only=*) ONLY="${arg#--only=}" ;;
    -h|--help)
      echo "Usage: ./install.sh [--dry-run] [--only pi,opencode,claude,codex,copilot,gemini,agents]"
      exit 0
      ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

wanted() {
  local name="$1"
  [[ -z "$ONLY" ]] && return 0
  [[ ",$ONLY," == *",$name,"* ]]
}

install_skill() {
  local src="$1" dest_parent="$2" label="$3"
  if [[ ! -d "$src" ]]; then echo "SKIP $label: missing source $src"; return 0; fi
  local skill_name
  skill_name="$(basename "$src")"
  local dest="$dest_parent/$skill_name"
  if [[ $DRY_RUN -eq 1 ]]; then echo "WOULD COPY $src -> $dest"; return 0; fi
  mkdir -p "$dest"
  cp -r "$src"/. "$dest"/
  echo "INSTALLED $label: $dest"
}

install_dir_contents() {
  local src="$1" dest="$2" label="$3"
  if [[ ! -d "$src" ]]; then echo "SKIP $label: missing source $src"; return 0; fi
  if [[ $DRY_RUN -eq 1 ]]; then echo "WOULD COPY $src/* -> $dest/"; return 0; fi
  mkdir -p "$dest"
  cp -r "$src"/. "$dest"/
  echo "INSTALLED $label: $dest"
}

SKILL_SRC_DIRS=("$REPO_DIR/skills/teachpro" "$REPO_DIR/skills/teach" "$REPO_DIR/skills/visualize")

# 1. Generic + per-agent skills dirs (copy strategy).
declare -A SKILL_TARGETS=(
  [agents]="$HOME/.agents/skills"
  [opencode]="$HOME/.config/opencode/skills"
  [claude]="$HOME/.claude/skills"
  [codex]="$HOME/.codex/skills"
  [copilot]="$HOME/.copilot/skills"
  [gemini]="$HOME/.gemini/skills"
  [pi]="$HOME/.pi/skills"
)

for agent in agents opencode claude codex copilot gemini pi; do
  if ! wanted "$agent"; then continue; fi
  dest_parent="${SKILL_TARGETS[$agent]}"
  # Only create copilot skills dir if copilot itself is present (avoid junk dirs).
  if [[ "$agent" == "copilot" && ! -d "$HOME/.copilot" ]]; then
    echo "SKIP copilot: $HOME/.copilot not present"
    continue
  fi
  for skill_src in "${SKILL_SRC_DIRS[@]}"; do
    install_skill "$skill_src" "$dest_parent" "$agent/skills"
  done
done

# 2. Pi-only extras (agents, extensions, config) — other runtimes ignore these.
# NOTE: only top-level *.md files are pi agents; subdirs (claude/, opencode/)
# hold per-platform adaptations installed in their own sections below.
if wanted pi && [[ -d "$HOME/.pi" ]]; then
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "WOULD COPY $REPO_DIR/agents/*.md -> $HOME/.pi/agents/"
  else
    mkdir -p "$HOME/.pi/agents"
    cp "$REPO_DIR"/agents/*.md "$HOME/.pi/agents"/
    echo "INSTALLED pi/agents: $HOME/.pi/agents/{researcher,mermaid-maker,svg-maker}.md"
  fi
  install_dir_contents "$REPO_DIR/extensions" "$HOME/.pi/extensions" "pi/extensions"
  if [[ -f "$REPO_DIR/config/teachpro.json" ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "WOULD COPY $REPO_DIR/config/teachpro.json -> $HOME/.pi/teachpro/config.json (no overwrite if exists)"
    else
      mkdir -p "$HOME/.pi/teachpro"
      if [[ ! -f "$HOME/.pi/teachpro/config.json" ]]; then
        cp "$REPO_DIR/config/teachpro.json" "$HOME/.pi/teachpro/config.json"
        echo "INSTALLED pi/config: $HOME/.pi/teachpro/config.json"
      else
        echo "KEEP pi/config: $HOME/.pi/teachpro/config.json already exists (not overwritten)"
      fi
    fi
  fi
else
  echo "SKIP pi extras: $HOME/.pi not present or not wanted"
fi

# 3. Claude subagents (file-based, ~/.claude/agents).
# Only researcher is portable: mermaid-maker/svg-maker depend on pi-only
# visual-tools (write_mermaid/render_mermaid/write_svg/...) and cannot run elsewhere.
if wanted claude && [[ -d "$HOME/.claude" ]]; then
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "WOULD COPY $REPO_DIR/agents/claude/*.md -> $HOME/.claude/agents/"
  else
    mkdir -p "$HOME/.claude/agents"
    cp "$REPO_DIR"/agents/claude/*.md "$HOME/.claude/agents"/
    echo "INSTALLED claude/agents: $HOME/.claude/agents/researcher.md"
  fi
else
  echo "SKIP claude/agents: $HOME/.claude not present or not wanted"
fi

# 4. OpenCode subagent (teachpro-researcher entry in opencode.json).
# Idempotent: creates the key only if missing, updates it only if it carries
# our marker; never touches user-owned keys.
if wanted opencode && [[ -f "$HOME/.config/opencode/opencode.json" ]]; then
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "WOULD MERGE agent teachpro-researcher into $HOME/.config/opencode/opencode.json"
  else
    REPO_DIR="$REPO_DIR" python3 - <<'EOF'
import json, os
repo = os.environ["REPO_DIR"]
cfg_path = os.path.expanduser("~/.config/opencode/opencode.json")
with open(os.path.join(repo, "agents/opencode/teachpro-researcher.prompt.md")) as f:
    prompt = f.read()
with open(cfg_path) as f:
    cfg = json.load(f)
agents = cfg.setdefault("agent", {})
existing = agents.get("teachpro-researcher", {})
if existing and existing.get("__managed_by") != "teachpro/install":
    print("KEEP opencode/agent: teachpro-researcher exists without our marker (not overwritten)")
else:
    action = "UPDATED" if existing else "INSTALLED"
    agents["teachpro-researcher"] = {
        "__managed_by": "teachpro/install",
        "description": "TeachPro web researcher — verifies facts via web search before teaching.",
        "mode": "subagent",
        "prompt": prompt,
    }
    with open(cfg_path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
    print(f"{action} opencode/agent: teachpro-researcher in {cfg_path}")
EOF
  fi
else
  echo "SKIP opencode/agent: opencode.json not present or not wanted"
fi

# 5. Codex / Copilot / Gemini subagents: no file-based subagent mechanism was
# found on this machine (checked ~/.codex, ~/.copilot, ~/.github, ~/.gemini),
# so these platforms get skills-only. Revisit if they add agent dirs.

echo "Done. Skills use copy strategy: re-run ./install.sh after git pull to update."
