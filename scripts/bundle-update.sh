#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MASTERPLAN_COMMANDS_SOURCE="${MASTERPLAN_COMMANDS_SOURCE:-}"
MASTERPLAN_SKILLS_SOURCE="${MASTERPLAN_SKILLS_SOURCE:-}"
SUPERPOWERS_LARAVEL_SOURCE="${SUPERPOWERS_LARAVEL_SOURCE:-}"
DOMAIN_DRIVEN_DESIGN_SOURCE="${DOMAIN_DRIVEN_DESIGN_SOURCE:-}"

usage() {
    cat <<EOF
Usage: bundle-update.sh <name|--all|--verify>

Names:
  masterplan
  superpowers-laravel
  domain-driven-design

Environment overrides:
  MASTERPLAN_COMMANDS_SOURCE
  MASTERPLAN_SKILLS_SOURCE
  SUPERPOWERS_LARAVEL_SOURCE
  DOMAIN_DRIVEN_DESIGN_SOURCE
EOF
    exit 0
}

require_source() {
    local name="$1"
    local value="$2"

    if [ -z "$value" ]; then
        echo "ERROR: $name must be set to a local source path." >&2
        echo "This maintainer script intentionally has no machine-specific defaults." >&2
        exit 1
    fi
}

require_path() {
    local path="$1"
    [ -e "$path" ] || { echo "ERROR: missing source path: $path" >&2; exit 1; }
}

reset_dir() {
    local dir="$1"
    rm -rf "$dir"
    mkdir -p "$dir"
}

copy_masterplan() {
    require_source MASTERPLAN_COMMANDS_SOURCE "$MASTERPLAN_COMMANDS_SOURCE"
    require_source MASTERPLAN_SKILLS_SOURCE "$MASTERPLAN_SKILLS_SOURCE"
    require_path "$MASTERPLAN_COMMANDS_SOURCE"
    require_path "$MASTERPLAN_SKILLS_SOURCE"
    reset_dir "$PLUGIN_ROOT/bundle/masterplan"
    mkdir -p "$PLUGIN_ROOT/bundle/masterplan/commands" "$PLUGIN_ROOT/bundle/masterplan/skills"
    cp -a "$MASTERPLAN_COMMANDS_SOURCE"/masterplan-*.md "$PLUGIN_ROOT/bundle/masterplan/commands/"
    cp -a "$MASTERPLAN_SKILLS_SOURCE"/masterplan-* "$PLUGIN_ROOT/bundle/masterplan/skills/"
}

copy_superpowers_laravel() {
    require_source SUPERPOWERS_LARAVEL_SOURCE "$SUPERPOWERS_LARAVEL_SOURCE"
    require_path "$SUPERPOWERS_LARAVEL_SOURCE"
    rm -rf "$PLUGIN_ROOT/bundle/superpowers-laravel"
    cp -a "$SUPERPOWERS_LARAVEL_SOURCE" "$PLUGIN_ROOT/bundle/superpowers-laravel"
}

copy_domain_driven_design() {
    require_source DOMAIN_DRIVEN_DESIGN_SOURCE "$DOMAIN_DRIVEN_DESIGN_SOURCE"
    require_path "$DOMAIN_DRIVEN_DESIGN_SOURCE"
    reset_dir "$PLUGIN_ROOT/bundle/domain-driven-design"
    mkdir -p "$PLUGIN_ROOT/bundle/domain-driven-design/skills"
    cp -a "$DOMAIN_DRIVEN_DESIGN_SOURCE" "$PLUGIN_ROOT/bundle/domain-driven-design/skills/domain-driven-design"
}

verify_bundle() {
    local missing=0
    local checks=(
        "$PLUGIN_ROOT/bundle/VERSIONS.yaml"
        "$PLUGIN_ROOT/bundle/masterplan/commands"
        "$PLUGIN_ROOT/bundle/masterplan/skills"
        "$PLUGIN_ROOT/bundle/superpowers-laravel/.claude-plugin/plugin.json"
        "$PLUGIN_ROOT/bundle/superpowers-laravel/commands"
        "$PLUGIN_ROOT/bundle/superpowers-laravel/skills"
        "$PLUGIN_ROOT/bundle/domain-driven-design/skills/domain-driven-design/SKILL.md"
        "$PLUGIN_ROOT/bundle/impeccable/SKILL.md"
        "$PLUGIN_ROOT/bundle/impeccable/scripts/impeccable"
    )

    local p
    for p in "${checks[@]}"; do
        if [ ! -e "$p" ]; then
            echo "ERROR: missing vendored content: $p" >&2
            missing=1
        fi
    done

    if find "$PLUGIN_ROOT/bundle" -name PLACEHOLDER.md -print -quit | grep -q .; then
        echo "ERROR: placeholder files remain in bundle/" >&2
        missing=1
    fi

    [ "$missing" -eq 0 ] || exit 1
    echo "Bundle verified: all vendored sources are present."
}

copy_one() {
    case "$1" in
        masterplan) copy_masterplan ;;
        superpowers-laravel) copy_superpowers_laravel ;;
        domain-driven-design) copy_domain_driven_design ;;
        *) echo "ERROR: unknown bundle name '$1'" >&2; usage ;;
    esac
}

main() {
    [ "$#" -ge 1 ] || usage
    case "$1" in
        --verify)
            verify_bundle
            ;;
        --all)
            copy_masterplan
            copy_superpowers_laravel
            copy_domain_driven_design
            verify_bundle
            ;;
        *)
            copy_one "$1"
            verify_bundle
            ;;
    esac
}

main "$@"
