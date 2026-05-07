#!/usr/bin/env bash
# Static server lifecycle helpers. Used by Phase 3 mockup server (port range
# 9000-9499) and Phase 6.5 doc-site server (port range 9500-9999). Both rely
# on verifier.sh for port allocation and probe.sh for probe-before-announce.
#
# Requires: scripts/lib/vm.sh sourced first (LARV_VM_HOST).

# static_server_compose_command <port> <doc_root>
# Returns the command that starts a PHP built-in static server bound to all
# interfaces. The caller backgrounds it or runs it inside a tmux session.
static_server_compose_command() {
    local port="$1"
    local doc_root="$2"
    [ -n "$port" ] || { echo "ERROR: port required" >&2; return 1; }
    [ -n "$doc_root" ] || { echo "ERROR: doc_root required" >&2; return 1; }
    echo "php -S 0.0.0.0:$port -t $doc_root"
}

static_server_check_remote_deps() {
    local ssh_target="$1"
    [ -n "$ssh_target" ] || { echo "ERROR: ssh_target required" >&2; return 1; }
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$ssh_target" \
        "command -v php >/dev/null && command -v tmux >/dev/null && command -v curl >/dev/null && command -v rsync >/dev/null"
}

# static_server_url <port>
# Returns the externally visible URL for a running static server.
static_server_url() {
    local port="$1"
    [ -n "$port" ] || { echo "ERROR: port required" >&2; return 1; }
    echo "http://${LARV_VM_HOST}:$port"
}

# static_server_start <ssh_target> <port> <doc_root> <session_name>
# Starts the server in a tmux session on the VM. Caller MUST run
# probe-before-announce via probe.sh before announcing the URL.
static_server_start() {
    local ssh_target="$1" port="$2" doc_root="$3" session="$4"
    local cmd
    [ -n "$ssh_target" ] || { echo "ERROR: ssh_target required" >&2; return 1; }
    [ -n "$session" ] || { echo "ERROR: session required" >&2; return 1; }
    cmd="$(static_server_compose_command "$port" "$doc_root")" || return 1
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$ssh_target" \
        "test -d '$doc_root' && tmux kill-session -t '$session' 2>/dev/null || true; tmux new-session -d -s '$session' '$cmd'; tmux has-session -t '$session'"
}

# static_server_stop <ssh_target> <session_name>
static_server_stop() {
    local ssh_target="$1" session="$2"
    [ -n "$ssh_target" ] || { echo "ERROR: ssh_target required" >&2; return 1; }
    [ -n "$session" ] || { echo "ERROR: session required" >&2; return 1; }
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$ssh_target" \
        "tmux kill-session -t '$session' 2>/dev/null || true"
}

# static_server_open_firewall <ssh_target> <port>
# Opens the port in ufw on the VM.
static_server_open_firewall() {
    local ssh_target="$1" port="$2"
    [ -n "$ssh_target" ] || { echo "ERROR: ssh_target required" >&2; return 1; }
    [ -n "$port" ] || { echo "ERROR: port required" >&2; return 1; }
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$ssh_target" \
        "if command -v ufw >/dev/null; then sudo ufw allow $port/tcp >/dev/null; fi"
}
