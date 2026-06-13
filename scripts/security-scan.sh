#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: security-scan.sh <project-dir> <report-path>" >&2
    exit 64
}

relpath() {
    local path="$1"
    local base="$2"
    path="${path#$base/}"
    printf "%s" "$path"
}

append_rule_matches() {
    local dir="$1"
    local report="$2"
    local rule_id="$3"
    local severity="$4"
    local pattern="$5"
    local count=0
    local matches

    matches="$(rg -n -I --hidden \
        --glob '!.git/objects/**' \
        --glob '!.git/logs/**' \
        --glob '!vendor/**' \
        --glob '!node_modules/**' \
        --glob '!.larv/**' \
        --glob '!.superpowers/**' \
        --glob '!.playwright-mcp/**' \
        --glob '!storage/framework/**' \
        --glob '!bootstrap/cache/**' \
        --glob '!docs/larv/security/**' \
        --glob '!scripts/security-scan.sh' \
        --glob '!**/scripts/security-scan.sh' \
        --glob '!tests/pre-flight.bats' \
        --glob '!**/tests/pre-flight.bats' \
        --glob '!codex-skills/security/SKILL.md' \
        --glob '!**/codex-skills/security/SKILL.md' \
        --glob '!skills/larv-security/SKILL.md' \
        --glob '!**/skills/larv-security/SKILL.md' \
        -e "$pattern" "$dir" 2>/dev/null || true)"

    if [ -n "$matches" ]; then
        while IFS= read -r line; do
            [ -n "$line" ] || continue
            count=$((count + 1))
            printf -- "- [%s] \`%s\` %s\n" "$severity" "$rule_id" "$(relpath "$line" "$dir")" >>"$report"
        done <<<"$matches"
    fi
    echo "$count"
}

append_git_hook_findings() {
    local dir="$1"
    local report="$2"
    local count=0

    if [ -f "$dir/.git/config" ] && rg -q 'hooksPath\s*=' "$dir/.git/config"; then
        printf -- "- [high] \`git-hooks-path\` .git/config contains core.hooksPath\n" >>"$report"
        count=$((count + 1))
    fi

    if [ -d "$dir/.git/hooks" ]; then
        while IFS= read -r hook; do
            [ -n "$hook" ] || continue
            printf -- "- [medium] \`active-git-hook\` %s\n" "$(relpath "$hook" "$dir")" >>"$report"
            count=$((count + 1))
        done < <(find "$dir/.git/hooks" -maxdepth 1 -type f ! -name '*.sample' -print 2>/dev/null | sort)
    fi

    echo "$count"
}

append_package_script_findings() {
    local dir="$1"
    local report="$2"
    local count=0
    local matches

    {
        echo
        echo "## Package install script review"
    } >>"$report"

    if [ -f "$dir/package.json" ]; then
        matches="$(rg -n -I '"(preinstall|install|postinstall|prepare)"[[:space:]]*:' "$dir/package.json" 2>/dev/null || true)"
        if [ -n "$matches" ]; then
            while IFS= read -r line; do
                [ -n "$line" ] || continue
                printf -- "- [review] \`npm-lifecycle-script\` %s\n" "$(relpath "$line" "$dir")" >>"$report"
            done <<<"$matches"
        else
            echo "- npm lifecycle scripts: none found" >>"$report"
        fi
        matches="$(rg -n -I '"(preinstall|install|postinstall|prepare)"[[:space:]]*:[^,]*(curl|wget|base64|powershell|nc[[:space:]]|bash|sh[[:space:]]|node[[:space:]]+-e|chmod[[:space:]]+\+x)' "$dir/package.json" 2>/dev/null || true)"
        if [ -n "$matches" ]; then
            while IFS= read -r line; do
                [ -n "$line" ] || continue
                printf -- "- [high] \`suspicious-npm-lifecycle-script\` %s\n" "$(relpath "$line" "$dir")" >>"$report"
                count=$((count + 1))
            done <<<"$matches"
        fi
    else
        echo "- npm lifecycle scripts: skipped, no package.json" >>"$report"
    fi

    if [ -f "$dir/composer.json" ]; then
        matches="$(rg -n -I '"(pre-install-cmd|post-install-cmd|pre-update-cmd|post-update-cmd|post-autoload-dump|scripts)"[[:space:]]*:' "$dir/composer.json" 2>/dev/null || true)"
        if [ -n "$matches" ]; then
            while IFS= read -r line; do
                [ -n "$line" ] || continue
                printf -- "- [review] \`composer-script-hook\` %s\n" "$(relpath "$line" "$dir")" >>"$report"
            done <<<"$matches"
        else
            echo "- Composer scripts: none found" >>"$report"
        fi
        matches="$(rg -n -I '"(pre-install-cmd|post-install-cmd|pre-update-cmd|post-update-cmd|post-autoload-dump)"[[:space:]]*:[^,]*(curl|wget|base64|powershell|nc[[:space:]]|bash|sh[[:space:]]|chmod[[:space:]]+\+x)' "$dir/composer.json" 2>/dev/null || true)"
        if [ -n "$matches" ]; then
            while IFS= read -r line; do
                [ -n "$line" ] || continue
                printf -- "- [high] \`suspicious-composer-script-hook\` %s\n" "$(relpath "$line" "$dir")" >>"$report"
                count=$((count + 1))
            done <<<"$matches"
        fi
    else
        echo "- Composer scripts: skipped, no composer.json" >>"$report"
    fi

    echo "$count"
}

append_dependency_audits() {
    local dir="$1"
    local report="$2"
    local failures=0

    {
        echo
        echo "## Dependency audit"
    } >>"$report"

    if [ -f "$dir/composer.json" ] && [ -f "$dir/composer.lock" ]; then
        if command -v composer >/dev/null 2>&1; then
            if (cd "$dir" && composer audit --locked --no-interaction) >>"$report" 2>&1; then
                echo "- Composer audit: passed" >>"$report"
            else
                echo "- Composer audit: failed" >>"$report"
                failures=$((failures + 1))
            fi
        else
            echo "- Composer audit: skipped, composer not installed" >>"$report"
        fi
    else
        echo "- Composer audit: skipped, no composer lockfile" >>"$report"
    fi

    if [ -f "$dir/package.json" ] && [ -f "$dir/package-lock.json" ]; then
        if command -v npm >/dev/null 2>&1; then
            if (cd "$dir" && npm audit --audit-level=high --omit=dev) >>"$report" 2>&1; then
                echo "- npm audit: passed" >>"$report"
            else
                echo "- npm audit: failed at high-or-critical threshold" >>"$report"
                failures=$((failures + 1))
            fi
        else
            echo "- npm audit: skipped, npm not installed" >>"$report"
        fi
    else
        echo "- npm audit: skipped, no npm lockfile" >>"$report"
    fi

    if [ -f "$dir/pnpm-lock.yaml" ]; then
        if command -v pnpm >/dev/null 2>&1; then
            if (cd "$dir" && pnpm audit --audit-level high) >>"$report" 2>&1; then
                echo "- pnpm audit: passed" >>"$report"
            else
                echo "- pnpm audit: failed at high-or-critical threshold" >>"$report"
                failures=$((failures + 1))
            fi
        else
            echo "- pnpm audit: skipped, pnpm not installed" >>"$report"
        fi
    else
        echo "- pnpm audit: skipped, no pnpm lockfile" >>"$report"
    fi

    if [ -f "$dir/yarn.lock" ]; then
        if command -v yarn >/dev/null 2>&1; then
            if (cd "$dir" && yarn npm audit --severity high) >>"$report" 2>&1; then
                echo "- Yarn audit: passed" >>"$report"
            else
                echo "- Yarn audit: failed at high-or-critical threshold" >>"$report"
                failures=$((failures + 1))
            fi
        else
            echo "- Yarn audit: skipped, yarn not installed" >>"$report"
        fi
    else
        echo "- Yarn audit: skipped, no yarn lockfile" >>"$report"
    fi

    echo "$failures"
}

main() {
    [ "$#" -eq 2 ] || usage
    local dir="$1"
    local report="$2"

    [ -d "$dir" ] || { echo "ERROR: project dir not found: $dir" >&2; exit 64; }
    command -v rg >/dev/null 2>&1 || { echo "ERROR: security scan requires rg" >&2; exit 69; }

    mkdir -p "$(dirname "$report")"
    cat >"$report" <<EOF
# Security baseline

Project directory: $dir
Generated at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Static malware indicators
EOF

    local findings=0
    findings=$((findings + $(append_rule_matches "$dir" "$report" "curl-pipe-shell" "high" '(curl|wget)[^|&;]*(\|)[^#]*(sh|bash)')))
    findings=$((findings + $(append_rule_matches "$dir" "$report" "base64-pipe-shell" "high" 'base64[[:space:]]+(-d|--decode)[^|&;]*(\|)[^#]*(sh|bash)')))
    findings=$((findings + $(append_rule_matches "$dir" "$report" "php-eval-base64" "high" 'eval[[:space:]]*\([[:space:]]*base64_decode[[:space:]]*\(')))
    findings=$((findings + $(append_rule_matches "$dir" "$report" "php-request-exec" "high" '(system|shell_exec|passthru|exec)[[:space:]]*\([[:space:]]*\$_(GET|POST|REQUEST|COOKIE)')))
    findings=$((findings + $(append_rule_matches "$dir" "$report" "php-assert-request" "high" 'assert[[:space:]]*\([[:space:]]*\$_(GET|POST|REQUEST|COOKIE)')))
    findings=$((findings + $(append_rule_matches "$dir" "$report" "node-request-exec" "high" '(exec|execSync|spawn|spawnSync)[[:space:]]*\([^)]*req\.(query|body|params)')))
    findings=$((findings + $(append_rule_matches "$dir" "$report" "powershell-encoded-command" "high" 'powershell([^[:alnum:]]|\.exe).*(-EncodedCommand|-enc[[:space:]])')))
    findings=$((findings + $(append_rule_matches "$dir" "$report" "reverse-shell-dev-tcp" "high" '/dev/tcp/[0-9A-Za-z_.-]+/[0-9]+')))
    findings=$((findings + $(append_rule_matches "$dir" "$report" "netcat-exec-shell" "high" 'nc[[:space:]][^#]*(\s-e\s|\s-c\s)[^#]*(sh|bash|cmd\.exe)')))
    findings=$((findings + $(append_rule_matches "$dir" "$report" "cron-or-systemd-persistence" "medium" '(@reboot|crontab[[:space:]].*-[el]|systemctl[[:space:]]+enable|/etc/systemd/system)')))
    findings=$((findings + $(append_rule_matches "$dir" "$report" "hardcoded-private-key" "high" '-----BEGIN (RSA |DSA |EC |OPENSSH |PGP )?PRIVATE KEY-----')))
    findings=$((findings + $(append_rule_matches "$dir" "$report" "hardcoded-cloud-secret" "high" '(AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|xox[baprs]-[0-9A-Za-z-]{10,})')))
    findings=$((findings + $(append_git_hook_findings "$dir" "$report")))
    findings=$((findings + $(append_package_script_findings "$dir" "$report")))

    local audit_failures
    audit_failures="$(append_dependency_audits "$dir" "$report")"

    {
        echo
        echo "## Result"
        echo "- Static findings: $findings"
        echo "- Dependency audit failures: $audit_failures"
    } >>"$report"

    if [ "$findings" -gt 0 ] || [ "$audit_failures" -gt 0 ]; then
        if [ "${LARV_SECURITY_ALLOW_FAIL:-0}" = "1" ]; then
            echo "- Status: bypassed" >>"$report"
            echo "security check bypassed with LARV_SECURITY_ALLOW_FAIL=1; see $report" >&2
            exit 0
        fi
        echo "- Status: failed" >>"$report"
        echo "security check failed; see $report" >&2
        exit 1
    fi

    echo "- Status: passed" >>"$report"
    echo "security check passed; report: $report"
}

main "$@"
