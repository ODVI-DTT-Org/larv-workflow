#!/usr/bin/env bash
# Runtime constants for larv. Default mode is local because Claude Code is
# expected to run inside the sandbox VM.

: "${LARV_RUNTIME_MODE:=local}"
: "${LARV_VM_HOST:=sandbox.example.com}"
: "${LARV_VM_HOST_SSH_USER:=larv-user}"
: "${LARV_VM_PROJECT_ROOT:=/srv/larv}"

export LARV_RUNTIME_MODE LARV_VM_HOST LARV_VM_HOST_SSH_USER LARV_VM_PROJECT_ROOT
