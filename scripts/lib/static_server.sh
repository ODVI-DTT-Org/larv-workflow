#!/usr/bin/env bash
# Static server lifecycle helpers. Used by Phase 3 mockup server (port range
# 9000-9499) and Phase 6.5 doc-site server (port range 9500-9999). Both rely
# on verifier.sh for port allocation and probe.sh for probe-before-announce.
#
# Requires: scripts/lib/vm.sh sourced first (LARV_RUNTIME_MODE, LARV_VM_HOST).

# static_server_compose_command <port> <doc_root>
# Returns the command that starts a PHP built-in static server bound to all
# interfaces. The caller runs it through the configured process manager.
static_server_compose_command() {
    local port="$1"
    local doc_root="$2"
    [ -n "$port" ] || { echo "ERROR: port required" >&2; return 1; }
    [ -n "$doc_root" ] || { echo "ERROR: doc_root required" >&2; return 1; }
    printf "php -S 0.0.0.0:%s -t %q\n" "$port" "$doc_root"
}

static_server_check_remote_deps() {
    local ssh_target="$1"
    if [ "${LARV_RUNTIME_MODE:-local}" = "local" ]; then
        command -v php >/dev/null && command -v curl >/dev/null && command -v ss >/dev/null && command -v setsid >/dev/null
        return
    fi
    [ -n "$ssh_target" ] || { echo "ERROR: ssh_target required" >&2; return 1; }
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$ssh_target" \
        "command -v php >/dev/null && command -v curl >/dev/null && command -v ss >/dev/null && command -v setsid >/dev/null && command -v rsync >/dev/null"
}

# static_server_url <port>
# Returns the externally visible URL for a running static server.
static_server_url() {
    local port="$1"
    [ -n "$port" ] || { echo "ERROR: port required" >&2; return 1; }
    echo "http://${LARV_VM_HOST}:$port"
}

static_server_wait_for_port() {
    local port="$1" attempt listening
    for attempt in $(seq 1 10); do
        listening="$(ss -tlnp 2>/dev/null | awk '{print $4}' | awk -F: '{print $NF}' | sort -un || true)"
        if grep -qx "$port" <<<"$listening"; then
            return 0
        fi
        sleep 0.2
    done
    return 1
}

static_server_process_base() {
    echo "${LARV_SANDBOX_PROCESS_DIR:-/tmp/larv-sandbox-processes}"
}

static_server_pid_file() {
    local session="$1" base
    base="$(static_server_process_base)"
    mkdir -p "$base"
    echo "$base/$session.pid"
}

static_server_log_file() {
    local session="$1" base
    base="$(static_server_process_base)"
    mkdir -p "$base"
    echo "$base/$session.log"
}

static_server_stop_process_local() {
    local session="$1" pid_file pid
    pid_file="$(static_server_pid_file "$session")"
    [ -f "$pid_file" ] || return 0
    pid="$(cat "$pid_file" 2>/dev/null || true)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        kill "-$pid" 2>/dev/null || kill "$pid" 2>/dev/null || true
        for _ in $(seq 1 20); do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.1
        done
        kill -9 "-$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$pid_file"
}

static_server_start_process_local() {
    local port="$1" doc_root="$2" session="$3" cmd pid_file log_file
    test -d "$doc_root" || return 1
    cmd="$(static_server_compose_command "$port" "$doc_root")" || return 1
    pid_file="$(static_server_pid_file "$session")"
    log_file="$(static_server_log_file "$session")"
    static_server_stop_process_local "$session"
    setsid bash -lc "exec $cmd" >"$log_file" 2>&1 < /dev/null &
    echo "$!" > "$pid_file"
    static_server_wait_for_port "$port"
}

# static_server_start <ssh_target> <port> <doc_root> <session_name>
# Starts the server on the runtime host. Default process manager is PID-file
# based background process so muxplex does not show sandbox tmux sessions.
# Set LARV_STATIC_SERVER_PROCESS_MANAGER=tmux for legacy behavior.
# Caller MUST run probe-before-announce via probe.sh before announcing the URL.
static_server_start() {
    local ssh_target="$1" port="$2" doc_root="$3" session="$4"
    local cmd
    [ -n "$session" ] || { echo "ERROR: session required" >&2; return 1; }
    cmd="$(static_server_compose_command "$port" "$doc_root")" || return 1
    if [ "${LARV_RUNTIME_MODE:-local}" = "local" ]; then
        if [ "${LARV_STATIC_SERVER_PROCESS_MANAGER:-process}" = "tmux" ]; then
            test -d "$doc_root" || return 1
            tmux kill-session -t "$session" 2>/dev/null || true
            tmux new-session -d -s "$session" "$cmd"
            tmux has-session -t "$session"
            static_server_wait_for_port "$port"
            return
        fi
        static_server_start_process_local "$port" "$doc_root" "$session"
        return
    fi
    [ -n "$ssh_target" ] || { echo "ERROR: ssh_target required" >&2; return 1; }
    if [ "${LARV_STATIC_SERVER_PROCESS_MANAGER:-process}" = "tmux" ]; then
        ssh -o BatchMode=yes -o ConnectTimeout=5 "$ssh_target" \
            "test -d '$doc_root' || exit 1; tmux kill-session -t '$session' 2>/dev/null || true; tmux new-session -d -s '$session' '$cmd'; tmux has-session -t '$session' && for attempt in \$(seq 1 10); do ss -tlnp 2>/dev/null | awk '{print \$4}' | awk -F: '{print \$NF}' | sort -un | grep -qx '$port' && exit 0; sleep 0.2; done; exit 1"
        return
    fi
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$ssh_target" \
        "set -e; test -d '$doc_root'; base='\${LARV_SANDBOX_PROCESS_DIR:-/tmp/larv-sandbox-processes}'; mkdir -p \"\$base\"; pid_file=\"\$base/$session.pid\"; log_file=\"\$base/$session.log\"; if [ -f \"\$pid_file\" ]; then pid=\$(cat \"\$pid_file\" 2>/dev/null || true); [ -n \"\$pid\" ] && kill -TERM -\"\$pid\" 2>/dev/null || true; rm -f \"\$pid_file\"; fi; setsid bash -lc 'exec $cmd' >\"\$log_file\" 2>&1 < /dev/null & echo \$! > \"\$pid_file\"; for attempt in \$(seq 1 10); do ss -tlnp 2>/dev/null | awk '{print \$4}' | awk -F: '{print \$NF}' | sort -un | grep -qx '$port' && exit 0; sleep 0.2; done; exit 1"
}

# static_server_stop <ssh_target> <session_name>
static_server_stop() {
    local ssh_target="$1" session="$2"
    [ -n "$session" ] || { echo "ERROR: session required" >&2; return 1; }
    if [ "${LARV_RUNTIME_MODE:-local}" = "local" ]; then
        static_server_stop_process_local "$session"
        if command -v tmux >/dev/null; then
            tmux kill-session -t "$session" 2>/dev/null || true
        fi
        return
    fi
    [ -n "$ssh_target" ] || { echo "ERROR: ssh_target required" >&2; return 1; }
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$ssh_target" \
        "base='\${LARV_SANDBOX_PROCESS_DIR:-/tmp/larv-sandbox-processes}'; pid_file=\"\$base/$session.pid\"; if [ -f \"\$pid_file\" ]; then pid=\$(cat \"\$pid_file\" 2>/dev/null || true); [ -n \"\$pid\" ] && kill -TERM -\"\$pid\" 2>/dev/null || true; rm -f \"\$pid_file\"; fi; if command -v tmux >/dev/null; then tmux kill-session -t '$session' 2>/dev/null || true; fi"
}

# static_server_open_firewall <ssh_target> <port>
# Opens the port in ufw on the runtime host.
static_server_open_firewall() {
    local ssh_target="$1" port="$2"
    [ -n "$port" ] || { echo "ERROR: port required" >&2; return 1; }
    if [ "${LARV_RUNTIME_MODE:-local}" = "local" ]; then
        if command -v ufw >/dev/null; then
            sudo ufw allow "$port/tcp" >/dev/null
            sudo ufw status | grep -q "$port/tcp"
        fi
        return
    fi
    [ -n "$ssh_target" ] || { echo "ERROR: ssh_target required" >&2; return 1; }
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$ssh_target" \
        "if command -v ufw >/dev/null; then sudo ufw allow $port/tcp >/dev/null; fi"
}
