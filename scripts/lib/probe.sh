#!/usr/bin/env bash
# Probe-before-announce. Per-spec §3.3: no URL is announced until the service
# behind it returns HTTP 200 (or documented non-error) from inside the VM and
# from the runner's perspective.

# Service profiles: per-service retry counts and inter-attempt delay (seconds).
# Override via environment for tests.
: "${PROBE_STATIC_RETRIES:=5}"
: "${PROBE_STATIC_DELAY:=1}"
: "${PROBE_LARAVEL_RETRIES:=6}"
: "${PROBE_LARAVEL_DELAY:=10}"
: "${PROBE_NGINX_RETRIES:=5}"
: "${PROBE_NGINX_DELAY:=2}"

probe_profile_retries() {
    case "$1" in
        static)  echo "$PROBE_STATIC_RETRIES" ;;
        laravel) echo "$PROBE_LARAVEL_RETRIES" ;;
        nginx)   echo "$PROBE_NGINX_RETRIES" ;;
        *) return 1 ;;
    esac
}

probe_profile_delay() {
    case "$1" in
        static)  echo "$PROBE_STATIC_DELAY" ;;
        laravel) echo "$PROBE_LARAVEL_DELAY" ;;
        nginx)   echo "$PROBE_NGINX_DELAY" ;;
        *) return 1 ;;
    esac
}

# probe_url <url> <profile>
# Single attempt. Returns 0 on HTTP 2xx/3xx, non-zero otherwise.
probe_url() {
    local url="$1"
    local profile="$2"
    if ! probe_profile_retries "$profile" >/dev/null; then
        echo "ERROR: unknown probe profile: $profile" >&2
        return 2
    fi
    curl -fsS --max-time 5 -o /dev/null "$url"
}

# probe_with_retries <url> <profile>
# Retries per-profile. Prints status to stderr; returns 0 on first success,
# non-zero after retries are exhausted.
probe_with_retries() {
    local url="$1"
    local profile="$2"
    local retries delay attempt
    retries="$(probe_profile_retries "$profile")" || {
        echo "ERROR: unknown probe profile: $profile" >&2
        return 2
    }
    delay="$(probe_profile_delay "$profile")"
    for ((attempt=1; attempt<=retries; attempt++)); do
        if probe_url "$url" "$profile"; then
            echo "probe ok ($url, profile=$profile, attempt=$attempt/$retries)" >&2
            return 0
        fi
        if [ "$attempt" -lt "$retries" ]; then
            sleep "$delay"
        fi
    done
    echo "probe exhausted: $url (profile=$profile, retries=$retries)" >&2
    return 1
}

# probe_url_inside <ssh-target> <port> <profile>
# Probe via SSH from inside the VM. Used to confirm the service is bound on
# 127.0.0.1 from the VM's perspective before exposing it externally.
probe_url_inside() {
    local ssh_target="$1"
    local port="$2"
    local profile="$3"
    local retries delay attempt
    retries="$(probe_profile_retries "$profile")" || return 2
    delay="$(probe_profile_delay "$profile")"
    for ((attempt=1; attempt<=retries; attempt++)); do
        if ssh -o BatchMode=yes -o ConnectTimeout=5 "$ssh_target" \
            "curl -fsS --max-time 5 -o /dev/null http://127.0.0.1:$port/" \
            >/dev/null 2>&1; then
            return 0
        fi
        [ "$attempt" -lt "$retries" ] && sleep "$delay"
    done
    return 1
}
