#!/usr/bin/env bash

fmt_minutes() {
    local minutes="$1"
    local hours=$((minutes / 60))
    local rest=$((minutes % 60))
    if [ "$hours" -gt 0 ]; then
        printf "%dh %02dm" "$hours" "$rest"
    else
        printf "%dm" "$rest"
    fi
}

fmt_money() {
    printf "\$%.2f" "$1"
}

fmt_pct() {
    local consumed="$1"
    local estimated="$2"
    if awk -v e="$estimated" 'BEGIN { exit !(e > 0) }'; then
        awk -v c="$consumed" -v e="$estimated" 'BEGIN { printf "%.0f%%", (c / e) * 100 }'
    else
        echo "n/a"
    fi
}
