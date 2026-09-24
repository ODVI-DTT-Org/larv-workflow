#!/bin/sh
# larv shared Higgsfield CLI wrapper. Keeps credentials and config beside the
# pinned binary. Never run `auth token` in recorded sessions: it prints the access token.
set -eu
larv_hf_dir=$(CDPATH= cd -- "$(dirname -- "$(readlink -f -- "$0")")" && pwd)
umask 077
export HIGGSFIELD_CREDENTIALS_PATH="$larv_hf_dir/credentials.json"
export HIGGSFIELD_CONFIG_PATH="$larv_hf_dir/config.json"
export HIGGSFIELD_DISABLE_TELEMETRY=1
export HIGGSFIELD_NO_UPDATE_CHECK=1
exec "$larv_hf_dir/bin/higgsfield" "$@"
