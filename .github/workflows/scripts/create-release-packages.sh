#!/usr/bin/env bash
set -euo pipefail

# create-release-packages.sh (workflow-local)
# Build Spec Kit template release archives for each supported AI assistant and script type.
# Usage: .github/workflows/scripts/create-release-packages.sh <version>
#   Version argument should include leading 'v'.
#   Optionally set AGENTS and/or SCRIPTS env vars to limit what gets built.
#     AGENTS  : space or comma separated subset of: claude gemini copilot qwen opencode (default: all)
#     SCRIPTS : space or comma separated subset of: sh ps (default: both)
#   Examples:
#     AGENTS=claude SCRIPTS=sh $0 v0.2.0
#     AGENTS="copilot,gemini" $0 v0.2.0
#     SCRIPTS=ps $0 v0.2.0

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <version-with-v-prefix>" >&2
  exit 1
fi
NEW_VERSION="$1"
if [[ ! $NEW_VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must look like v0.0.0" >&2
  exit 1
fi

echo "Building release packages for $NEW_VERSION"

rm -rf sdd-package-base* sdd-*-package-* spec-kit-template-*-"${NEW_VERSION}".zip || true

rewrite_paths() {
  sed -E \
    -e 's@(/?)memory/@.specify/memory/@g' \
    -e 's@(/?)scripts/@.specify/scripts/@g' \
    -e 's@(/?)templates/@.specify/templates/@g'
}

generate_commands() {
  local agent=$1 ext=$2 arg_format=$3 output_dir=$4 script_variant=$5
  mkdir -p "$output_dir"
  local base_dir="templates/commands"
  local override_dir="templates/commands/$agent"
  declare -A seen

  process_template() {
    local template_path=$1 base_name=$2
    local file_content description script_command body name
    name=${base_name%.md}

    file_content=$(tr -d '\r' < "$template_path")
    description=$(printf '%s\n' "$file_content" | awk '/^description:/ {sub(/^description:[[:space:]]*/, ""); print; exit}')
    script_command=$(printf '%s\n' "$file_content" | awk -v sv="$script_variant" '/^[[:space:]]*'"$script_variant"':[[:space:]]*/ {sub(/^[[:space:]]*'"$script_variant"':[[:space:]]*/, ""); print; exit}')

    if [[ -z $script_command ]]; then
      echo "Warning: no script command found for $script_variant in $template_path" >&2
      script_command="(Missing script command for $script_variant)"
    fi

    body=$(printf '%s\n' "$file_content" | sed "s|{SCRIPT}|${script_command}|g")
    body=$(printf '%s\n' "$body" | awk '
      /^---$/ { print; if (++dash_count == 1) in_frontmatter=1; else in_frontmatter=0; next }
      in_frontmatter && /^scripts:$/ { skip_scripts=1; next }
      in_frontmatter && /^[a-zA-Z].*:/ && skip_scripts { skip_scripts=0 }
      in_frontmatter && skip_scripts && /^[[:space:]]/ { next }
      { print }
    ')

    body=$(printf '%s\n' "$body" | sed "s/{ARGS}/$arg_format/g" | sed "s/__AGENT__/$agent/g" | rewrite_paths)

    case $ext in
      toml)
        { echo "description = \"$description\""; echo; echo "prompt = \"\"\""; echo "$body"; echo "\"\"\""; } > "$output_dir/${name}.$ext" ;;
      md)
        echo "$body" > "$output_dir/${name}.$ext" ;;
      prompt.md)
        echo "$body" > "$output_dir/${name}.$ext" ;;
    esac
  }

  for template in "$base_dir"/*.md; do
    [[ -f "$template" ]] || continue
    local base=$(basename "$template")
    local source="$template"
    if [[ -f "$override_dir/$base" ]]; then
      source="$override_dir/$base"
      seen["$base"]=1
    fi
    process_template "$source" "$base"
  done

  if [[ -d "$override_dir" ]]; then
    for template in "$override_dir"/*.md; do
      [[ -f "$template" ]] || continue
      local base=$(basename "$template")
      if [[ -n ${seen[$base]:-} ]]; then
        continue
      fi
      process_template "$template" "$base"
    done
  fi
}

build_variant() {
  local agent=$1 script=$2
  local base_dir="sdd-${agent}-package-${script}"
  echo "Building $agent ($script) package..."
  mkdir -p "$base_dir"
  
  # Copy base structure but filter scripts by variant
  SPEC_DIR="$base_dir/.specify"
  mkdir -p "$SPEC_DIR"
  
  [[ -d memory ]] && { cp -r memory "$SPEC_DIR/"; echo "Copied memory -> .specify"; }
  # Include root-level AGENTS.md if present
  [[ -f AGENTS.md ]] && { cp AGENTS.md "$base_dir/AGENTS.md"; echo "Copied AGENTS.md -> package root"; }
  
  # Only copy the relevant script variant directory
  if [[ -d scripts ]]; then
    mkdir -p "$SPEC_DIR/scripts"
    case $script in
      sh)
        [[ -d scripts/bash ]] && { cp -r scripts/bash "$SPEC_DIR/scripts/"; echo "Copied scripts/bash -> .specify/scripts"; }
        # Copy any script files that aren't in variant-specific directories
        find scripts -maxdepth 1 -type f -exec cp {} "$SPEC_DIR/scripts/" \; 2>/dev/null || true
        ;;
      ps)
        [[ -d scripts/powershell ]] && { cp -r scripts/powershell "$SPEC_DIR/scripts/"; echo "Copied scripts/powershell -> .specify/scripts"; }
        # Copy any script files that aren't in variant-specific directories
        find scripts -maxdepth 1 -type f -exec cp {} "$SPEC_DIR/scripts/" \; 2>/dev/null || true
        ;;
    esac
  fi
  
  [[ -d templates ]] && { mkdir -p "$SPEC_DIR/templates"; find templates -type f -not -path "templates/commands/*" -exec cp --parents {} "$SPEC_DIR"/ \; ; echo "Copied templates -> .specify/templates"; }
  # Inject variant into plan-template.md within .specify/templates if present
  local plan_tpl="$base_dir/.specify/templates/plan-template.md"
  if [[ -f "$plan_tpl" ]]; then
    plan_norm=$(tr -d '\r' < "$plan_tpl")
    # Extract script command from YAML frontmatter
    script_command=$(printf '%s\n' "$plan_norm" | awk -v sv="$script" '/^[[:space:]]*'"$script"':[[:space:]]*/ {sub(/^[[:space:]]*'"$script"':[[:space:]]*/, ""); print; exit}')
    if [[ -n $script_command ]]; then
      # Always prefix with .specify/ for plan usage
      script_command=".specify/$script_command"
      # Replace {SCRIPT} placeholder with the script command and __AGENT__ with agent name
      substituted=$(sed "s|{SCRIPT}|${script_command}|g" "$plan_tpl" | tr -d '\r' | sed "s|__AGENT__|${agent}|g")
      # Strip YAML frontmatter from plan template output (keep body only)
      stripped=$(printf '%s\n' "$substituted" | awk 'BEGIN{fm=0;dash=0} /^---$/ {dash++; if(dash==1){fm=1; next} else if(dash==2){fm=0; next}} {if(!fm) print}')
      printf '%s\n' "$stripped" > "$plan_tpl"
    else
      echo "Warning: no plan-template script command found for $script in YAML frontmatter" >&2
    fi
  fi
  # NOTE: We substitute {ARGS} internally. Outward tokens differ intentionally:
  #   * Markdown/prompt (claude, copilot, cursor, opencode): $ARGUMENTS
  #   * TOML (gemini, qwen): {{args}}
  # This keeps formats readable without extra abstraction.

  case $agent in
    claude)
      mkdir -p "$base_dir/.claude/commands"
      generate_commands claude md "\$ARGUMENTS" "$base_dir/.claude/commands" "$script" ;;
    gemini)
      mkdir -p "$base_dir/.gemini/commands"
      generate_commands gemini toml "{{args}}" "$base_dir/.gemini/commands" "$script"
      [[ -f agent_templates/gemini/GEMINI.md ]] && cp agent_templates/gemini/GEMINI.md "$base_dir/GEMINI.md" ;;
    copilot)
      mkdir -p "$base_dir/.github/prompts"
      generate_commands copilot prompt.md "\$ARGUMENTS" "$base_dir/.github/prompts" "$script" ;;
    cursor)
      mkdir -p "$base_dir/.cursor/commands"
      generate_commands cursor md "\$ARGUMENTS" "$base_dir/.cursor/commands" "$script" ;;
    qwen)
      mkdir -p "$base_dir/.qwen/commands"
      generate_commands qwen toml "{{args}}" "$base_dir/.qwen/commands" "$script"
      [[ -f agent_templates/qwen/QWEN.md ]] && cp agent_templates/qwen/QWEN.md "$base_dir/QWEN.md" ;;
    opencode)
      mkdir -p "$base_dir/.opencode/command"
      generate_commands opencode md "\$ARGUMENTS" "$base_dir/.opencode/command" "$script" ;;
    codex)
      mkdir -p "$base_dir/.codex/prompts"
      generate_commands codex md "\$ARGUMENTS" "$base_dir/.codex/prompts" "$script"
      [[ -f agent_templates/codex/CODEX.md ]] && cp agent_templates/codex/CODEX.md "$base_dir/CODEX.md"
      # Include Mode Orchestrator files in .vscode
      if [[ -d templates/codex-mode ]]; then
        mkdir -p "$base_dir/.vscode"
        cp templates/codex-mode/codex-mode-policy.schema.json "$base_dir/.vscode/" || true
        cp templates/codex-mode/codex-mode-policy.json "$base_dir/.vscode/" || true
        cp templates/codex-mode/codex-controller-preamble.txt "$base_dir/.vscode/" || true
        cp templates/codex-mode/settings.json "$base_dir/.vscode/" || true
        echo "Copied Codex Mode Orchestrator files into .vscode"
      fi
      ;;
  esac
  ( cd "$base_dir" && zip -r "../spec-kit-template-${agent}-${script}-${NEW_VERSION}.zip" . )
  echo "Created spec-kit-template-${agent}-${script}-${NEW_VERSION}.zip"
}

# Determine agent list
ALL_AGENTS=(claude gemini copilot cursor qwen opencode codex)
ALL_SCRIPTS=(sh ps)


norm_list() {
  # convert comma+space separated -> space separated unique while preserving order of first occurrence
  tr ',\n' '  ' | awk '{for(i=1;i<=NF;i++){if(!seen[$i]++){printf((out?" ":"") $i)}}}END{printf("\n")}'
}

validate_subset() {
  local type=$1; shift; local -n allowed=$1; shift; local items=("$@")
  local ok=1
  for it in "${items[@]}"; do
    local found=0
    for a in "${allowed[@]}"; do [[ $it == "$a" ]] && { found=1; break; }; done
    if [[ $found -eq 0 ]]; then
      echo "Error: unknown $type '$it' (allowed: ${allowed[*]})" >&2
      ok=0
    fi
  done
  return $ok
}

if [[ -n ${AGENTS:-} ]]; then
  mapfile -t AGENT_LIST < <(printf '%s' "$AGENTS" | norm_list)
  validate_subset agent ALL_AGENTS "${AGENT_LIST[@]}" || exit 1
else
  AGENT_LIST=("${ALL_AGENTS[@]}")
fi

if [[ -n ${SCRIPTS:-} ]]; then
  mapfile -t SCRIPT_LIST < <(printf '%s' "$SCRIPTS" | norm_list)
  validate_subset script ALL_SCRIPTS "${SCRIPT_LIST[@]}" || exit 1
else
  SCRIPT_LIST=("${ALL_SCRIPTS[@]}")
fi

echo "Agents: ${AGENT_LIST[*]}"
echo "Scripts: ${SCRIPT_LIST[*]}"

for agent in "${AGENT_LIST[@]}"; do
  for script in "${SCRIPT_LIST[@]}"; do
    build_variant "$agent" "$script"
  done
done

echo "Archives:"
ls -1 spec-kit-template-*-"${NEW_VERSION}".zip
