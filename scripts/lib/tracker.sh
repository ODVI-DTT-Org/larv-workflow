#!/usr/bin/env bash
# Implementation tracker per spec §16.

# Resolve the plugin root from this script's location.
__tracker_plugin_root() {
    local here
    here="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
    cd "$here/../.." && pwd
}

tracker_path_yaml() { echo "$1/docs/larv/implementation-tracker.yaml"; }
tracker_path_md()   { echo "$1/docs/larv/implementation-tracker.md"; }

tracker_init() {
    local dir="$1"
    local p plugin_root
    p="$(tracker_path_yaml "$dir")"
    if [ -e "$p" ]; then
        echo "ERROR: tracker already exists at $p" >&2
        return 1
    fi
    plugin_root="$(__tracker_plugin_root)"
    mkdir -p "$(dirname "$p")"
    cp "$plugin_root/templates/tracker.yaml.tmpl" "$p"
}

# tracker_append <dir> <title> <description> <type> <tool> <model> \
#   <slices_csv> <files_csv> <status>
tracker_append() {
    local dir="$1" title="$2" description="$3" type="$4"
    local tool="$5" model="$6" slices_csv="$7" files_csv="$8" status="$9"

    case "$type" in
        feature|bug|hotfix|refactor|migration) ;;
        *) echo "ERROR: invalid type: $type" >&2; return 1 ;;
    esac
    case "$status" in
        planned|in-progress|completed|reverted) ;;
        *) echo "ERROR: invalid status: $status" >&2; return 1 ;;
    esac

    local p next_id now slices_yaml files_yaml
    p="$(tracker_path_yaml "$dir")"
    [ -f "$p" ] || { echo "ERROR: no tracker at $p — call tracker_init first" >&2; return 1; }

    local count
    count="$(yq '.entries | length' "$p")"
    next_id="$(printf "ENT-%04d" $((count + 1)))"
    now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    # Build YAML arrays from CSV input
    slices_yaml="$(echo "$slices_csv" | awk -F, '{for(i=1;i<=NF;i++) printf "\"%s\"%s", $i, (i<NF?",":"")}')"
    files_yaml="$(echo "$files_csv" | awk -F, '{for(i=1;i<=NF;i++) printf "\"%s\"%s", $i, (i<NF?",":"")}')"

    yq -i ".entries += [{
        \"id\": \"$next_id\",
        \"title\": \"$title\",
        \"description\": \"$description\",
        \"type\": \"$type\",
        \"created_by\": { \"tool\": \"$tool\", \"model\": \"$model\" },
        \"created_at\": \"$now\",
        \"slices_touched\": [$slices_yaml],
        \"files_changed\": [$files_yaml],
        \"status\": \"$status\",
        \"related_adr\": [],
        \"related_handsoff\": \"\",
        \"learnings_appended\": false
    }]" "$p"
}

tracker_render() {
    local dir="$1"
    local yaml_p md_p
    yaml_p="$(tracker_path_yaml "$dir")"
    md_p="$(tracker_path_md "$dir")"
    [ -f "$yaml_p" ] || { echo "ERROR: no tracker at $yaml_p" >&2; return 1; }

    {
        echo "# Implementation Tracker"
        echo
        echo "Auto-generated from \`implementation-tracker.yaml\`. Do not edit by hand."
        echo
        echo "| ID | Type | Title | By | Status | When |"
        echo "|---|---|---|---|---|---|"
        yq -r '.entries[]
            | [.id, .type, .title, (.created_by.tool + " (" + .created_by.model + ")"), .status, .created_at]
            | @tsv' "$yaml_p" \
        | awk -F'\t' '{ printf "| %s | %s | %s | %s | %s | %s |\n", $1,$2,$3,$4,$5,$6 }'
    } > "$md_p"
}
