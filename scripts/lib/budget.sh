#!/usr/bin/env bash

budget_cap_threshold() {
    local policy="$1"
    case "$policy" in
        pause_at_100pct) echo "1.00" ;;
        pause_at_120pct) echo "1.20" ;;
        pause_at_150pct) echo "1.50" ;;
        never_pause) echo "999" ;;
        *) echo "1.20" ;;
    esac
}

budget_cap_exceeded() {
    local consumed="$1"
    local estimated="$2"
    local policy="$3"
    local threshold
    threshold="$(budget_cap_threshold "$policy")"
    awk -v c="$consumed" -v e="$estimated" -v t="$threshold" 'BEGIN { exit !(c > e * t) }'
}
