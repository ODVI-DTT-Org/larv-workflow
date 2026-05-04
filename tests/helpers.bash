# Common test helpers
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
cd "$PROJECT_ROOT"

setup_tmp_project() {
    local tmp
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/docs/larv"
    echo "$tmp"
}

teardown_tmp_project() {
    [ -n "$1" ] && [ -d "$1" ] && rm -rf "$1"
}
