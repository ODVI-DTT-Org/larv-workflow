#!/usr/bin/env bash
# VM connection constants for larv. Single point of change for future
# generalization (multi-VM support is out of scope for MVP).

: "${LARV_VM_HOST:=31.220.79.31}"
: "${LARV_VM_HOST_SSH_USER:=larv}"
: "${LARV_VM_PROJECT_ROOT:=/srv/larv}"

export LARV_VM_HOST LARV_VM_HOST_SSH_USER LARV_VM_PROJECT_ROOT
