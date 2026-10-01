#!/usr/bin/env bash
# teachpro multi-agent uninstaller. Removes only the teachpro/teach/visualize copies it installs.
set -euo pipefail

SKILLS=(teachpro teach)
SKILLS+=(visualize)
PARENTS=(
  "$HOME/.agents/skills"
  "$HOME/.config/opencode/skills"
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.copilot/skills"
  "$HOME/.gemini/skills"
  "$HOME/.pi/skills"
)

for parent in "${PARENTS[@]}"; do
  for s in "${SKILLS[@]}"; do
    target="$parent/$s"
    if [[ -d "$target" ]]; then
      rm -rf "$target"
      echo "REMOVED $target"
    fi
  done
done

echo "Done. Pi agents/extensions/config left untouched by design."
