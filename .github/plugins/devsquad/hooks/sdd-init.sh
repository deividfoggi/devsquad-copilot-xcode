#!/bin/bash
# Deterministic init operations for SDD Framework files.
# Replaces LLM-driven template reading with direct file comparison and copy.
#
# Distributed files carry a one-line provenance header so consumers can
# detect which plugin version wrote each file. Templates that consumers
# copy per artifact (feature spec, migration spec, envisioning, ADR) are
# tracked via the lock file only, with no inline header, to avoid leaking
# provenance into authored documents.
#
# Usage:
#   sdd-init.sh verify              → JSON status report for all managed files
#   sdd-init.sh diff <target-path>  → unified diff between existing and template
#   sdd-init.sh create <target-path> → copy template to target (mkdir -p as needed)
#   sdd-init.sh create-missing      → create all missing files
#   sdd-init.sh update-all [--dry-run] → create missing + overwrite outdated
#
# Lock file: .github/devsquad/manifest.lock (JSON). One entry per managed
# target with plugin_version, template_sha, and written_at.
#
# Exit codes: 0 = success, 1 = usage error, 2 = file not in manifest

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
PLUGIN_NAME="${DEVSQUAD_PLUGIN_NAME:-devsquad}"
LOCKFILE=".github/${PLUGIN_NAME}/manifest.lock"
LOCK_SCHEMA_VERSION=1

# ── File manifest ──────────────────────────────────────────────────────────────
# Template files mirror target paths inside hooks/templates/.
# Format: target_path|group|copy_source
#   copy_source=1 marks files that consumers copy per artifact (feature spec,
#   migration spec, envisioning doc, ADR). Those files do NOT receive a
#   provenance header so the comment does not leak into authored documents;
#   provenance for them is recorded only in the lock file.
MANIFEST=(
  ".github/copilot-instructions.md|config|0"
  ".github/instructions/adrs.instructions.md|config|0"
  ".github/instructions/envisioning.instructions.md|config|0"
  ".github/instructions/specs.instructions.md|config|0"
  ".github/instructions/tasks.instructions.md|config|0"
  ".github/instructions/migration-specs.instructions.md|config|0"
  ".github/instructions/migration-tasks.instructions.md|config|0"
  ".github/instructions/documentation-style.instructions.md|config|0"
  ".github/docs/coding-guidelines.md|config|0"
  ".markdownlint.yaml|config|0"
  "docs/features/TEMPLATE.md|docs|1"
  "docs/migrations/TEMPLATE.md|docs|1"
  "docs/envisioning/TEMPLATE.md|docs|1"
  "docs/architecture/decisions/ADR-TEMPLATE.md|docs|1"
)

# ── Helpers ────────────────────────────────────────────────────────────────────

get_manifest_field() {
  # Args: target field_index (1=target, 2=group, 3=copy_source)
  local target="$1"
  local idx="$2"
  for entry in "${MANIFEST[@]}"; do
    local t="${entry%%|*}"
    if [[ "$t" == "$target" ]]; then
      echo "$entry" | awk -F'|' -v i="$idx" '{print $i}'
      return 0
    fi
  done
  return 1
}

get_template_file() {
  get_manifest_field "$1" 1
}

get_group() {
  get_manifest_field "$1" 2
}

is_copy_source() {
  local flag
  flag=$(get_manifest_field "$1" 3) || return 1
  [[ "$flag" == "1" ]]
}

# Reads .version from .github/plugin/plugin.json. Falls back to "unknown".
get_plugin_version() {
  local manifest=".github/plugin/plugin.json"
  if [[ -f "$manifest" ]] && command -v jq > /dev/null 2>&1; then
    jq -r '.version // "unknown"' "$manifest" 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

# Computes the first 12 hex chars of sha256 of stdin. Portable across macOS and Linux.
sha256_short() {
  if command -v sha256sum > /dev/null 2>&1; then
    sha256sum | awk '{print substr($1,1,12)}'
  elif command -v shasum > /dev/null 2>&1; then
    shasum -a 256 | awk '{print substr($1,1,12)}'
  else
    echo "unknown"
  fi
}

# Returns 0 if the path uses HTML comments (markdown), 1 if hash comments (yaml).
is_markdown_target() {
  local target="$1"
  case "$target" in
    *.md) return 0 ;;
    *.yaml|*.yml) return 1 ;;
    *) return 0 ;;
  esac
}

# Detects a provenance header on the first line of stdin.
# Matches:
#   <!-- devsquad-template: <path> v<ver> sha=<hex> -->
#   # devsquad-template: <path> v<ver> sha=<hex>
header_regex() {
  echo '^(<!-- )?devsquad-template: .* sha=[0-9a-f]+( -->)?$|^# devsquad-template: .* sha=[0-9a-f]+$|^<!-- devsquad-template: .* sha=[0-9a-f]+ -->$'
}

# Strips the provenance header (if present on line 1) from the file at $1 to stdout.
strip_header() {
  local file="$1"
  awk -v re="$(header_regex)" 'NR==1 && $0 ~ re { next } { print }' "$file"
}

# Builds the provenance header string for a target. Args: target version sha.
build_header() {
  local target="$1"
  local version="$2"
  local sha="$3"
  if is_markdown_target "$target"; then
    echo "<!-- devsquad-template: ${target} v${version} sha=${sha} -->"
  else
    echo "# devsquad-template: ${target} v${version} sha=${sha}"
  fi
}

# Computes the canonical sha256 prefix of the template body (header excluded
# in case the template file itself ever ends up with one).
compute_template_sha() {
  local template_path="$1"
  if [[ ! -f "$template_path" ]]; then
    echo "unknown"
    return
  fi
  strip_header "$template_path" | sha256_short
}

file_status() {
  local target="$1"
  local template_name
  template_name=$(get_template_file "$target") || return 2
  local template_path="$TEMPLATES_DIR/$template_name"

  if [[ ! -f "$template_path" ]]; then
    echo "error:template-missing"
    return 1
  fi

  if [[ ! -f "$target" ]]; then
    echo "missing"
    return 0
  fi

  # Compare bodies with the provenance header stripped from both sides so
  # consumer files predating the header rollout still match a fresh template.
  local target_body template_body
  target_body=$(strip_header "$target")
  template_body=$(strip_header "$template_path")

  if [[ "$target_body" == "$template_body" ]]; then
    echo "up-to-date"
  else
    local added removed
    added=$(diff <(echo "$template_body") <(echo "$target_body") 2>/dev/null | grep -c '^>' || true)
    removed=$(diff <(echo "$template_body") <(echo "$target_body") 2>/dev/null | grep -c '^<' || true)
    echo "outdated:+${added}-${removed}"
  fi
  return 0
}

# ── Lock file ──────────────────────────────────────────────────────────────────

ensure_lock() {
  if ! command -v jq > /dev/null 2>&1; then
    return 1
  fi
  if [[ ! -f "$LOCKFILE" ]]; then
    mkdir -p "$(dirname "$LOCKFILE")"
    jq -n --argjson sv "$LOCK_SCHEMA_VERSION" '{schema_version: $sv, last_updated: null, files: {}}' > "$LOCKFILE"
  fi
  return 0
}

# Records a managed file in the lock. Args: target plugin_version template_sha.
lock_record() {
  local target="$1"
  local plugin_version="$2"
  local template_sha="$3"

  ensure_lock || return 0

  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local tmp
  tmp=$(mktemp)
  jq \
    --arg target "$target" \
    --arg pv "$plugin_version" \
    --arg sha "$template_sha" \
    --arg now "$now" \
    '.last_updated = $now
     | .files[$target] = {plugin_version: $pv, template_sha: $sha, written_at: $now}' \
    "$LOCKFILE" > "$tmp" && mv "$tmp" "$LOCKFILE"
}

# Returns the recorded plugin_version for a target, or empty string if missing.
lock_recorded_version() {
  local target="$1"
  if [[ ! -f "$LOCKFILE" ]] || ! command -v jq > /dev/null 2>&1; then
    echo ""
    return
  fi
  jq -r --arg t "$target" '.files[$t].plugin_version // ""' "$LOCKFILE" 2>/dev/null || echo ""
}

# ── Commands ───────────────────────────────────────────────────────────────────

cmd_verify() {
  local first_config=1
  local first_docs=1

  echo "{"

  # Config group
  echo '  "config": ['
  for entry in "${MANIFEST[@]}"; do
    local target="${entry%%|*}"
    local group
    group=$(get_group "$target")
    [[ "$group" != "config" ]] && continue

    local status recorded
    status=$(file_status "$target")
    recorded=$(lock_recorded_version "$target")

    [[ $first_config -eq 0 ]] && echo ","
    first_config=0

    local status_val="${status%%:*}"
    local summary="${status#*:}"
    [[ "$status_val" == "$summary" ]] && summary=""

    printf '    {"file": "%s", "status": "%s"' "$target" "$status_val"
    [[ -n "$summary" ]] && printf ', "summary": "%s"' "$summary"
    [[ -n "$recorded" ]] && printf ', "recorded_version": "%s"' "$recorded"
    printf '}'
  done
  echo ""
  echo "  ],"

  # Docs group
  echo '  "docs": ['
  for entry in "${MANIFEST[@]}"; do
    local target="${entry%%|*}"
    local group
    group=$(get_group "$target")
    [[ "$group" != "docs" ]] && continue

    local status recorded
    status=$(file_status "$target")
    recorded=$(lock_recorded_version "$target")

    [[ $first_docs -eq 0 ]] && echo ","
    first_docs=0

    local status_val="${status%%:*}"
    local summary="${status#*:}"
    [[ "$status_val" == "$summary" ]] && summary=""

    printf '    {"file": "%s", "status": "%s"' "$target" "$status_val"
    [[ -n "$summary" ]] && printf ', "summary": "%s"' "$summary"
    [[ -n "$recorded" ]] && printf ', "recorded_version": "%s"' "$recorded"
    printf '}'
  done
  echo ""
  echo "  ]"

  echo "}"
}

cmd_diff() {
  local target="$1"
  local template_name
  template_name=$(get_template_file "$target") || { echo "Error: '$target' not in manifest" >&2; exit 2; }
  local template_path="$TEMPLATES_DIR/$template_name"

  if [[ ! -f "$target" ]]; then
    echo "File does not exist: $target"
    echo "Template content would be created from: $template_name"
    return 0
  fi

  # Strip provenance headers from both sides so a header-only delta does not show up.
  diff --unified <(strip_header "$target") <(strip_header "$template_path") || true
}

# Writes the template to target. For non-copy-source files, prepends a one-line
# provenance header. Records the file in the manifest lock either way.
cmd_create() {
  local target="$1"
  local template_name
  template_name=$(get_template_file "$target") || { echo "Error: '$target' not in manifest" >&2; exit 2; }
  local template_path="$TEMPLATES_DIR/$template_name"

  local dir
  dir=$(dirname "$target")
  [[ -n "$dir" && "$dir" != "." ]] && mkdir -p "$dir"

  local plugin_version template_sha
  plugin_version=$(get_plugin_version)
  template_sha=$(compute_template_sha "$template_path")

  if is_copy_source "$target"; then
    # Copy-source templates: no inline header, lock-only provenance.
    cp "$template_path" "$target"
  else
    local header
    header=$(build_header "$target" "$plugin_version" "$template_sha")
    {
      echo "$header"
      strip_header "$template_path"
    } > "$target"
  fi

  lock_record "$target" "$plugin_version" "$template_sha"
  echo "Created: $target"
}

cmd_create_missing() {
  local count=0
  for entry in "${MANIFEST[@]}"; do
    local target="${entry%%|*}"
    if [[ ! -f "$target" ]]; then
      cmd_create "$target"
      count=$((count + 1))
    fi
  done
  echo "---"
  echo "Created $count missing file(s)"
}

# Apply path used by cmd_update_all. Always writes a timestamped backup before
# overwriting an existing file, so repeated applies within one plugin version
# do not collide.
apply_update() {
  local target="$1"
  local plugin_version="$2"

  if [[ -f "$target" ]]; then
    local ts
    ts=$(date -u +%s)
    local backup="${target}.pre-${plugin_version}-${ts}.bak"
    cp "$target" "$backup"
  fi

  cmd_create "$target"
}

cmd_update_all() {
  local dry_run=0
  if [[ "${1:-}" == "--dry-run" ]]; then
    dry_run=1
  fi

  local created=0
  local updated=0
  local skipped=0
  local plugin_version
  plugin_version=$(get_plugin_version)

  for entry in "${MANIFEST[@]}"; do
    local target="${entry%%|*}"
    local status
    status=$(file_status "$target")
    local status_val="${status%%:*}"

    case "$status_val" in
      missing)
        if [[ $dry_run -eq 1 ]]; then
          echo "Would create: $target"
        else
          cmd_create "$target"
        fi
        created=$((created + 1))
        ;;
      outdated)
        if [[ $dry_run -eq 1 ]]; then
          echo "Would update: $target ($status)"
        else
          apply_update "$target" "$plugin_version"
        fi
        updated=$((updated + 1))
        ;;
      *)
        skipped=$((skipped + 1))
        ;;
    esac
  done

  echo "---"
  if [[ $dry_run -eq 1 ]]; then
    echo "Dry-run: would create $created, update $updated, skip $skipped"
  else
    echo "Created: $created | Updated: $updated | Skipped (up to date): $skipped"
  fi
}

# ── Main ───────────────────────────────────────────────────────────────────────

usage() {
  echo "Usage: sdd-init.sh <command> [args]"
  echo ""
  echo "Commands:"
  echo "  verify                       JSON status report for all managed files"
  echo "  diff <target-path>           Unified diff between existing file and template"
  echo "  create <target-path>         Copy template to target path"
  echo "  create-missing               Create all missing files"
  echo "  update-all [--dry-run]       Create missing + overwrite outdated"
  echo ""
  echo "Notes:"
  echo "  - Distributed files receive a one-line provenance header."
  echo "  - Files consumers copy per artifact (TEMPLATE.md, ADR-TEMPLATE.md) are"
  echo "    tracked via .github/devsquad/manifest.lock without an inline header."
  echo "  - update-all is destructive by default; use --dry-run to preview."
  echo "  - Each apply writes a timestamped backup: <target>.pre-<version>-<unix>.bak."
  exit 1
}

[[ $# -lt 1 ]] && usage

case "$1" in
  verify)
    cmd_verify
    ;;
  diff)
    [[ $# -lt 2 ]] && { echo "Error: diff requires a target path" >&2; exit 1; }
    cmd_diff "$2"
    ;;
  create)
    [[ $# -lt 2 ]] && { echo "Error: create requires a target path" >&2; exit 1; }
    cmd_create "$2"
    ;;
  create-missing)
    cmd_create_missing
    ;;
  update-all)
    cmd_update_all "${2:-}"
    ;;
  *)
    echo "Error: unknown command '$1'" >&2
    usage
    ;;
esac
