# Common test helpers
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
cd "$PROJECT_ROOT"

# Never let a test run the live design-tools probe (real Higgsfield account /
# Impeccable engine). Tests that exercise it set this to 0 locally with stubs.
export LARV_PREFLIGHT_SKIP_DESIGN_CHECK=1

setup_tmp_project() {
    local tmp
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/docs/larv"
    echo "$tmp"
}

teardown_tmp_project() {
    [ -n "$1" ] && [ -d "$1" ] && rm -rf "$1"
}
