#!/usr/bin/env bash
# Live-scan runtime resource verifier. No central registry. Per spec §14.
#
# Requires: scripts/lib/vm.sh sourced first.

verifier_ssh_target() {
    echo "${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}"
}

verifier_run() {
    if [ "${LARV_RUNTIME_MODE:-local}" = "local" ]; then
        bash -lc "$1"
    else
        ssh -o BatchMode=yes -o ConnectTimeout=5 "$(verifier_ssh_target)" "$1"
    fi
}

# port_reservation_base
# Shared local reservation directory used to close the allocation/start race
# between parallel larv runs on the same VM.
port_reservation_base() {
    echo "${LARV_PORT_RESERVATION_DIR:-/tmp/larv-port-reservations}"
}

port_reservation_lock_file() {
    local base
    base="$(port_reservation_base)"
    mkdir -p "$base"
    echo "$base/.lock"
}

port_reservation_role_dir() {
    local role="$1" base
    base="$(port_reservation_base)"
    mkdir -p "$base/$role"
    echo "$base/$role"
}

port_reservation_ttl_seconds() {
    echo "${LARV_PORT_RESERVATION_TTL_SECONDS:-21600}"
}

port_reservation_is_stale() {
    local file="$1" ttl now created_at
    [ -f "$file" ] || return 0
    ttl="$(port_reservation_ttl_seconds)"
    created_at="$(awk -F= '$1 == "created_at" {print $2}' "$file" 2>/dev/null | head -1)"
    case "$created_at" in
        ''|*[!0-9]*) return 0 ;;
    esac
    now="$(date +%s)"
    [ $((now - created_at)) -gt "$ttl" ]
}

port_reservation_owner() {
    awk -F= '$1 == "owner" {print $2}' "$1" 2>/dev/null | head -1
}

port_reserved_any_unlocked() {
    local role="$1" port="$2" dir file
    dir="$(port_reservation_role_dir "$role")"
    file="$dir/$port"
    if [ ! -f "$file" ]; then
        return 1
    fi
    if port_reservation_is_stale "$file"; then
        rm -f "$file"
        return 1
    fi
    return 0
}

port_reserved_by_other_unlocked() {
    local role="$1" port="$2" owner="${3:-}" dir file reserved_owner
    dir="$(port_reservation_role_dir "$role")"
    file="$dir/$port"
    port_reserved_any_unlocked "$role" "$port" || return 1
    reserved_owner="$(port_reservation_owner "$file")"
    [ -z "$owner" ] || [ "$reserved_owner" != "$owner" ]
}

reserve_port_unlocked() {
    local role="$1" port="$2" owner="$3" dir file
    dir="$(port_reservation_role_dir "$role")"
    file="$dir/$port"
    {
        printf "owner=%s\n" "$owner"
        printf "created_at=%s\n" "$(date +%s)"
        printf "pid=%s\n" "$$"
    } > "$file"
}

# release_port_reservation <role> <port> [owner]
# Removes a reservation after the server has successfully bound and probes pass.
release_port_reservation() {
    local role="$1" port="$2" owner="${3:-}" dir file reserved_owner lock_file
    dir="$(port_reservation_role_dir "$role")"
    file="$dir/$port"
    lock_file="$(port_reservation_lock_file)"
    exec 9>"$lock_file"
    flock 9
    if [ -f "$file" ]; then
        reserved_owner="$(port_reservation_owner "$file")"
        if [ -z "$owner" ] || [ "$reserved_owner" = "$owner" ]; then
            rm -f "$file"
        fi
    fi
}

# allocate_port <role> [owner]
# Roles: mockup (9000-9499), docsite (9500-9999), app (8000-8999).
# Strategy: live-scan via ss -tlnp, then reserve the selected port under a
# VM-local flock so parallel larv runs cannot select the same free port before
# their servers bind.
allocate_port() {
    local role="$1"
    local owner="${2:-larv-$$}"
    local lo hi lock_file
    case "$role" in
        mockup)  lo=9000; hi=9499 ;;
        docsite) lo=9500; hi=9999 ;;
        app)     lo=8000; hi=8999 ;;
        *) echo "ERROR: unknown port role: $role" >&2; return 1 ;;
    esac

    lock_file="$(port_reservation_lock_file)"
    exec 9>"$lock_file"
    flock 9

    local listening
    listening="$(verifier_run "ss -tlnp 2>/dev/null" 2>/dev/null \
        | awk '{print $4}' | awk -F: '{print $NF}' | sort -un)"

    local port
    for ((port=lo; port<=hi; port++)); do
        if ! grep -qx "$port" <<<"$listening" && ! port_reserved_any_unlocked "$role" "$port"; then
            reserve_port_unlocked "$role" "$port" "$owner"
            echo "$port"
            return 0
        fi
    done
    echo "ERROR: port range $lo-$hi exhausted (role=$role)" >&2
    return 1
}

# allocate_db <slug>
# Returns "larv_<slug-with-dashes-as-underscores>". Verifies it does not exist
# on the VM's MySQL instance (or returns non-zero if it does).
allocate_db() {
    local slug="$1"
    local db_name
    db_name="larv_$(echo "$slug" | tr '-' '_')"
    local existing
    existing="$(verifier_run "mysql -N -B -e 'SHOW DATABASES' 2>/dev/null" 2>/dev/null || true)"
    if grep -qx "$db_name" <<<"$existing"; then
        echo "ERROR: database $db_name already exists on VM" >&2
        return 1
    fi
    echo "$db_name"
}

# allocate_project_root <slug>
# Returns /srv/larv/<slug>. Verifies it does not already exist on the VM.
allocate_project_root() {
    local slug="$1"
    local existing
    existing="$(verifier_run "ls /srv/larv/ 2>/dev/null" 2>/dev/null || true)"
    if grep -qx "$slug" <<<"$existing"; then
        echo "ERROR: project root /srv/larv/$slug is taken" >&2
        return 1
    fi
    echo "${LARV_VM_PROJECT_ROOT}/$slug"
}

# verify_allocation <port> <role> [owner]
# Re-scan to confirm a previously allocated port is still free and either not
# reserved or reserved by this owner. Returns 0 if usable, non-zero if taken.
verify_allocation() {
    local port="$1"
    local role="${2:-}"
    local owner="${3:-}"
    local lock_file
    lock_file="$(port_reservation_lock_file)"
    exec 9>"$lock_file"
    flock 9
    local listening
    listening="$(verifier_run "ss -tlnp 2>/dev/null" 2>/dev/null \
        | awk '{print $4}' | awk -F: '{print $NF}' | sort -un)"
    if grep -qx "$port" <<<"$listening"; then
        return 1
    fi
    if [ -n "$role" ] && port_reserved_by_other_unlocked "$role" "$port" "$owner"; then
        return 1
    fi
    return 0
}
