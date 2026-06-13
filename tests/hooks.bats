#!/usr/bin/env bats

load helpers

@test "Claude hooks manifest registers larv guardrails" {
    [ -f hooks/hooks.json ]
    grep -q "PreToolUse" hooks/hooks.json
    grep -q "PostToolUse" hooks/hooks.json
    grep -q "SessionStart" hooks/hooks.json
    grep -q "guard-pre-tool.sh" hooks/hooks.json
    grep -q "guard-post-tool.sh" hooks/hooks.json
}

@test "pre tool hook blocks app edits before sandbox bootstrap" {
    TMP="$(setup_tmp_project)"
    mkdir -p "$TMP/docs/Handsoff" "$TMP/app/Models"
    echo "# Handsoff" > "$TMP/docs/Handsoff.md"
    run bash -c "cd '$TMP' && printf '%s\n' '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"app/Models/Loan.php\"}}' | '$PROJECT_ROOT/hooks/guard-pre-tool.sh'"
    [ "$status" -ne 0 ]
    echo "$output" | grep -q "bootstrap-sandbox.md"
    teardown_tmp_project "$TMP"
}

@test "pre tool hook allows docs edits and app edits after bootstrap" {
    TMP="$(setup_tmp_project)"
    mkdir -p "$TMP/docs/Handsoff" "$TMP/docs/larv/07-runtime" "$TMP/app/Models"
    echo "# Handsoff" > "$TMP/docs/Handsoff.md"
    echo "http://sandbox.example.com:8001/" > "$TMP/docs/larv/07-runtime/sandbox-url.txt"
    run bash -c "cd '$TMP' && printf '%s\n' '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"app/Models/Loan.php\"}}' | '$PROJECT_ROOT/hooks/guard-pre-tool.sh'"
    [ "$status" -eq 0 ]
    run bash -c "cd '$TMP' && printf '%s\n' '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"docs/larv/notes.md\"}}' | '$PROJECT_ROOT/hooks/guard-pre-tool.sh'"
    [ "$status" -eq 0 ]
    teardown_tmp_project "$TMP"
}

@test "pre tool hook blocks likely secret file edits" {
    TMP="$(setup_tmp_project)"
    run bash -c "cd '$TMP' && printf '%s\n' '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\".env\"}}' | '$PROJECT_ROOT/hooks/guard-pre-tool.sh'"
    [ "$status" -ne 0 ]
    echo "$output" | grep -qi "secret"
    teardown_tmp_project "$TMP"
}

@test "post tool hook reminds about tracker after app edits" {
    TMP="$(setup_tmp_project)"
    mkdir -p "$TMP/docs/Handsoff" "$TMP/docs/larv/07-runtime" "$TMP/app/Models"
    echo "# Handsoff" > "$TMP/docs/Handsoff.md"
    echo "http://sandbox.example.com:8001/" > "$TMP/docs/larv/07-runtime/sandbox-url.txt"
    run bash -c "cd '$TMP' && printf '%s\n' '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"app/Models/Loan.php\"}}' | '$PROJECT_ROOT/hooks/guard-post-tool.sh'"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "implementation-tracker.yaml"
    teardown_tmp_project "$TMP"
}
