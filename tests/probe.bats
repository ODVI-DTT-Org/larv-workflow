#!/usr/bin/env bats

load helpers

setup() {
    PORT=$(awk 'BEGIN{srand(); print 30000 + int(rand()*10000)}')
    # spawn a simple HTTP server in background
    python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
    SERVER_PID=$!
    sleep 0.5
}

teardown() {
    if [ -n "${SERVER_PID:-}" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
}

@test "probe_url succeeds against a live HTTP server" {
    run bash -c "source scripts/lib/probe.sh && probe_url 'http://127.0.0.1:$PORT/' static"
    [ "$status" -eq 0 ]
}

@test "probe_url fails against a closed port" {
    local closed_port=1
    run bash -c "source scripts/lib/probe.sh && probe_url 'http://127.0.0.1:$closed_port/' static"
    [ "$status" -ne 0 ]
}

@test "probe_with_retries returns 0 quickly when service is up" {
    run bash -c "source scripts/lib/probe.sh && probe_with_retries 'http://127.0.0.1:$PORT/' static"
    [ "$status" -eq 0 ]
    # Ensure it didn't burn through every retry slot
    [[ ! "$output" =~ retry\ 5/5 ]]
}

@test "probe_with_retries fails after exhausting retries on dead service" {
    run bash -c "source scripts/lib/probe.sh && PROBE_STATIC_RETRIES=2 PROBE_STATIC_DELAY=1 probe_with_retries 'http://127.0.0.1:1/' static"
    [ "$status" -ne 0 ]
    echo "$output" | grep -q "exhausted"
}

@test "probe_with_retries rejects unknown service profile" {
    run bash -c "source scripts/lib/probe.sh && probe_with_retries 'http://127.0.0.1/' bogus"
    [ "$status" -ne 0 ]
    echo "$output" | grep -qi "unknown.*profile"
}
