#!/usr/bin/env bash
# Live-scan VM resource verifier. No central registry. Per spec §14.
#
# Requires: scripts/lib/vm.sh sourced first (LARV_VM_HOST, LARV_VM_HOST_SSH_USER).

verifier_ssh_target() {
    echo "${LARV_VM_HOST_SSH_USER}@${LARV_VM_HOST}"
}

# allocate_port <role>
# Roles: mockup (9000-9499), docsite (9500-9999), app (8000-8999).
# Strategy: live-scan via ss -tlnp; pick first free port in range.
# Caller is responsible for binding immediately to close the TOCTOU window.
allocate_port() {
    local role="$1"
    local lo hi
    case "$role" in
        mockup)  lo=9000; hi=9499 ;;
        docsite) lo=9500; hi=9999 ;;
        app)     lo=8000; hi=8999 ;;
        *) echo "ERROR: unknown port role: $role" >&2; return 1 ;;
    esac

    local listening
    listening="$(ssh -o BatchMode=yes -o ConnectTimeout=5 \
        "$(verifier_ssh_target)" "ss -tlnp 2>/dev/null" 2>/dev/null \
        | awk '{print $4}' | awk -F: '{print $NF}' | sort -un)"

    local port
    for ((port=lo; port<=hi; port++)); do
        if ! grep -qx "$port" <<<"$listening"; then
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
    existing="$(ssh -o BatchMode=yes -o ConnectTimeout=5 \
        "$(verifier_ssh_target)" \
        "mysql -N -B -e 'SHOW DATABASES' 2>/dev/null" 2>/dev/null || true)"
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
    existing="$(ssh -o BatchMode=yes -o ConnectTimeout=5 \
        "$(verifier_ssh_target)" "ls /srv/larv/ 2>/dev/null" 2>/dev/null || true)"
    if grep -qx "$slug" <<<"$existing"; then
        echo "ERROR: project root /srv/larv/$slug is taken" >&2
        return 1
    fi
    echo "${LARV_VM_PROJECT_ROOT}/$slug"
}

# verify_allocation <port> <role>
# Re-scan to confirm a previously allocated port is still free (catches TOCTOU
# races). Returns 0 if free, non-zero if taken.
verify_allocation() {
    local port="$1"
    local listening
    listening="$(ssh -o BatchMode=yes -o ConnectTimeout=5 \
        "$(verifier_ssh_target)" "ss -tlnp 2>/dev/null" 2>/dev/null \
        | awk '{print $4}' | awk -F: '{print $NF}' | sort -un)"
    ! grep -qx "$port" <<<"$listening"
}
