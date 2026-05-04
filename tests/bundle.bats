#!/usr/bin/env bats

load helpers

BUNDLES=(masterplan superpowers-laravel domain-driven-design huashu-design)

@test "bundle/VERSIONS.yaml exists and is valid YAML" {
    [ -f bundle/VERSIONS.yaml ]
    run yq '.' bundle/VERSIONS.yaml
    [ "$status" -eq 0 ]
}

@test "bundle/VERSIONS.yaml lists all 4 dependencies" {
    for b in "${BUNDLES[@]}"; do
        run yq -r ".[\"$b\"]" bundle/VERSIONS.yaml
        [ "$status" -eq 0 ]
        [ "$output" != "null" ]
    done
}

@test "all 4 bundle directories exist" {
    for b in "${BUNDLES[@]}"; do
        [ -d "bundle/$b" ] || { echo "missing bundle/$b"; return 1; }
    done
}

@test "bundle directories contain real vendored content, not placeholders" {
    for b in "${BUNDLES[@]}"; do
        [ ! -f "bundle/$b/PLACEHOLDER.md" ] || { echo "placeholder remains in bundle/$b"; return 1; }
    done
}

@test "masterplan bundle vendors commands and skills" {
    [ -d bundle/masterplan/commands ]
    [ -d bundle/masterplan/skills ]
    run find bundle/masterplan/skills -name SKILL.md -type f
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    run find bundle/masterplan/commands -name 'masterplan-*.md' -type f
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "superpowers-laravel bundle vendors plugin manifest commands and skills" {
    [ -f bundle/superpowers-laravel/.claude-plugin/plugin.json ]
    [ -d bundle/superpowers-laravel/commands ]
    [ -d bundle/superpowers-laravel/skills ]
    run find bundle/superpowers-laravel/skills -name SKILL.md -type f
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "domain-driven-design bundle vendors its skill" {
    [ -f bundle/domain-driven-design/skills/domain-driven-design/SKILL.md ]
}

@test "huashu-design bundle vendors its skill and references" {
    [ -f bundle/huashu-design/SKILL.md ]
    [ -d bundle/huashu-design/references ]
}

@test "bundle-update.sh exists and is executable" {
    [ -x scripts/bundle-update.sh ]
}

@test "bundle-update.sh prints help with no args" {
    run bash scripts/bundle-update.sh
    echo "$output" | grep -qiE "usage|help"
}

@test "bundle-update.sh --verify validates current vendored content" {
    run bash scripts/bundle-update.sh --verify
    [ "$status" -eq 0 ]
    echo "$output" | grep -qi "verified"
}
