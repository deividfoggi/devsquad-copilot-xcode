#!/bin/bash
# Locate the absolute path of sdd-init.sh across known install locations.
#
# Prints the absolute path to stdout if found and exits 0.
# Prints nothing and exits 1 if no copy of sdd-init.sh can be located.
#
# Resolution order:
#   1. Sibling of this helper (works for any install path, including future
#      ones we have not enumerated below).
#   2. Workspace path (.github/plugins/devsquad/hooks/sdd-init.sh) for users
#      developing this plugin or vendoring it into their repo.
#   3. ${COPILOT_PLUGIN_ROOT}/hooks/sdd-init.sh if the runtime exports it.
#   4. ${CLAUDE_PLUGIN_ROOT}/hooks/sdd-init.sh if the runtime exports it.
#   5. ~/.vscode/agent-plugins/github.com/microsoft/devsquad-copilot/...
#   6. ~/.copilot/agent-plugins/github.com/microsoft/devsquad-copilot/...
#   7. ~/.copilot/installed-plugins/devsquad-copilot/devsquad/hooks/sdd-init.sh
#
# This helper is invoked by the devsquad.init agent. The agent finds any
# copy of this helper at one of the same locations and runs it once per
# session to resolve sdd-init.sh, then reuses the resolved path.

set -eu

self_dir="$(cd "$(dirname "$0")" && pwd)"

candidates=(
  "$self_dir/sdd-init.sh"
  ".github/plugins/devsquad/hooks/sdd-init.sh"
  "${COPILOT_PLUGIN_ROOT:-}/hooks/sdd-init.sh"
  "${CLAUDE_PLUGIN_ROOT:-}/hooks/sdd-init.sh"
  "${HOME:-}/.vscode/agent-plugins/github.com/microsoft/devsquad-copilot/.github/plugins/devsquad/hooks/sdd-init.sh"
  "${HOME:-}/.copilot/agent-plugins/github.com/microsoft/devsquad-copilot/.github/plugins/devsquad/hooks/sdd-init.sh"
  "${HOME:-}/.copilot/installed-plugins/devsquad-copilot/devsquad/hooks/sdd-init.sh"
)

for p in "${candidates[@]}"; do
  case "$p" in
    /hooks/sdd-init.sh) continue ;;
  esac
  [ -n "$p" ] && [ -f "$p" ] || continue
  printf '%s\n' "$(cd "$(dirname "$p")" && pwd)/$(basename "$p")"
  exit 0
done

exit 1
