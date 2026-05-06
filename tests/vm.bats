#!/usr/bin/env bats

load helpers

@test "vm.sh exports LARV_VM_HOST as 31.220.79.31" {
    run bash -c 'source scripts/lib/vm.sh && echo "$LARV_VM_HOST"'
    [ "$status" -eq 0 ]
    [ "$output" = "31.220.79.31" ]
}

@test "vm.sh sets LARV_VM_HOST_SSH_USER to a non-empty string" {
    run bash -c 'source scripts/lib/vm.sh && echo "$LARV_VM_HOST_SSH_USER"'
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "vm.sh allows override via environment" {
    run bash -c 'export LARV_VM_HOST=10.0.0.1; source scripts/lib/vm.sh && echo "$LARV_VM_HOST"'
    [ "$status" -eq 0 ]
    [ "$output" = "10.0.0.1" ]
}
