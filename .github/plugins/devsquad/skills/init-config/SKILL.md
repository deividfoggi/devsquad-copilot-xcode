---
name: init-config
description: "Verify and create SDD Framework configuration files (.github/copilot-instructions.md, instructions, coding-guidelines, markdownlint). Use when initializing a project or checking if configuration files are up to date. Do not use for documentation templates (use init-docs) or community files (use init-scaffold)."
---

# Init Config

Manage 10 SDD Framework configuration and instruction files.

## Managed Files

| File | Purpose |
|------|---------|
| `.github/copilot-instructions.md` | Pragmatic senior engineer guidelines |
| `.github/instructions/adrs.instructions.md` | ADR creation and management guidelines |
| `.github/instructions/envisioning.instructions.md` | Envisioning document guidelines |
| `.github/instructions/specs.instructions.md` | Feature spec guidelines |
| `.github/instructions/tasks.instructions.md` | Task list guidelines |
| `.github/instructions/migration-specs.instructions.md` | Migration spec guidelines |
| `.github/instructions/migration-tasks.instructions.md` | Migration task guidelines |
| `.github/instructions/documentation-style.instructions.md` | Markdown formatting rules |
| `.github/docs/coding-guidelines.md` | Fundamental values, mandatory rules, code style |
| `.markdownlint.yaml` | Markdown linting configuration |

## Important Constraints

> NEVER create, copy, or recreate files under `.github/plugins/`. The plugin folder is managed externally. If `sdd-init.sh` cannot be located via the discovery snippet below, inform the user to install/update the plugin.

## Locating sdd-init.sh

The plugin can be installed in several locations (workspace, runtime env vars, `~/.vscode/agent-plugins/...`, `~/.copilot/agent-plugins/...`). Use the `locate-sdd-init.sh` helper to resolve the absolute path of `sdd-init.sh` once, then reuse it in every subsequent command. The discovery snippet:

```bash
for h in \
  .github/plugins/devsquad/hooks/locate-sdd-init.sh \
  "${COPILOT_PLUGIN_ROOT:-}/hooks/locate-sdd-init.sh" \
  "${CLAUDE_PLUGIN_ROOT:-}/hooks/locate-sdd-init.sh" \
  "$HOME/.vscode/agent-plugins/github.com/microsoft/devsquad-copilot/.github/plugins/devsquad/hooks/locate-sdd-init.sh" \
  "$HOME/.copilot/agent-plugins/github.com/microsoft/devsquad-copilot/.github/plugins/devsquad/hooks/locate-sdd-init.sh" \
  "$HOME/.copilot/installed-plugins/devsquad-copilot/devsquad/hooks/locate-sdd-init.sh"; do
  if [ -n "$h" ] && [ -f "$h" ]; then
    SDD_INIT="$("$h" 2>/dev/null || true)"
    [ -n "$SDD_INIT" ] && [ -f "$SDD_INIT" ] && { echo "FOUND: $SDD_INIT"; exit 0; }
  fi
done
echo "MISSING"
exit 1
```

Capture the absolute path printed after `FOUND:` and substitute it for `<SDD_INIT>` in every command below. Bash variables do not persist across tool calls, so use the literal path string.

## Verification Mode

```bash
<SDD_INIT> verify
```

Parse the JSON output. Each entry in `config` has `file`, `status` (`up-to-date`, `outdated`, `missing`), and optionally `summary`.

## Creation Mode

To create or update specific files:

```bash
<SDD_INIT> create <target-path>
```

For bulk operations:

```bash
# Create only missing files
<SDD_INIT> create-missing

# Create missing + overwrite outdated
<SDD_INIT> update-all
```

To show a diff for an outdated file:

```bash
<SDD_INIT> diff <target-path>
```
