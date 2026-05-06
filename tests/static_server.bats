#!/usr/bin/env bats

load helpers

setup() {
    PORT=$(awk 'BEGIN{srand(); print 30000 + int(rand()*10000)}')
}

@test "static_server_compose_command produces a php -S command for a path" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/static_server.sh && static_server_compose_command 8001 /srv/larv/x/mockups"
    [ "$status" -eq 0 ]
    [[ "$output" == *"php -S 0.0.0.0:8001"* ]]
    [[ "$output" == *"-t /srv/larv/x/mockups"* ]]
}

@test "static_server_url returns http url with VM host and port" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/vm.sh && source $PROJECT_ROOT/scripts/lib/static_server.sh && static_server_url 8001"
    [ "$status" -eq 0 ]
    [ "$output" = "http://31.220.79.31:8001" ]
}

@test "static_server_compose_command rejects empty arguments" {
    run bash -c "source $PROJECT_ROOT/scripts/lib/static_server.sh && static_server_compose_command '' /tmp/x"
    [ "$status" -ne 0 ]
    run bash -c "source $PROJECT_ROOT/scripts/lib/static_server.sh && static_server_compose_command 8001 ''"
    [ "$status" -ne 0 ]
}
