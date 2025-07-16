#!/bin/bash

readonly SUCCESS=0
readonly FAILURE=1

function LOG() {
  local level="$1"
  shift 1
  case "${level}" in
    WARN*)  echo "[${level}] $*" >&2 ;;
    INFO)   echo "[${level}] $*" >&2 ;;
    FATAL)  echo "[${level}] $*" >&2 ; kill $$ ;;
    *)      echo "[DEBUG-${level}] $*" >&2 ;;
  esac
}

function is_tty() {
  [ -t 1 ] && return ${SUCCESS}
  return ${FAILURE}
}

# Finds the binary in the $PATH
function find_exec() {
  local path="$1"
  [[ -z "${path}" ]] && LOG FATAL "find_exec needs a non-empty path"
  local exec="$(which "${path}")"
  [[ -z "${exec}" ]] && LOG FATAL "Could not find binary '${path}'"
  echo ${exec}
}

# Find the binary in $PATH that is actually part of the system.
function find_system_exec() {
  local path="$1"
  [[ -z "${path}" ]] && LOG FATAL "find_exec needs a non-empty path"
  local exec="$( which -a "${path}" | egrep -e '^/(bin|usr/bin|usr/local/bin)/' | head -n 1)"
  [[ -z "${exec}" ]] && LOG FATAL "Could not find binary '${path}'"
  echo "${exec}"
}

function ensure_gcert() {
  local repos_url="$1"
  case "${repos_url}" in
    sso://*)
      find_system_exec gcertstatus >/dev/null
      $(find_system_exec gcertstatus) --check_remaining=5h --quiet && return ${SUCCESS}
      is_tty || LOG FATAL "Not an interactive mode!"
      $(find_system_exec gcert) || LOG FATAL "Could not renew certificate!"
      ;;
  esac
  return ${SUCCESS}
}

GIT_AUTO_SYNC="$(find_exec git-auto-sync)"
for repos in $(${GIT_AUTO_SYNC} daemon list); do
  (
    cd "${repos}"
    remote_url="$(git remote get-url origin)"
    LOG INFO "Syncing repository 「${remote_url%%:*}」 ${repos} ..."
    ensure_gcert "${remote_url}"
    ${GIT_AUTO_SYNC} sync
  )
done
