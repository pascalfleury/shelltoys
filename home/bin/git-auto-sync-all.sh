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

function find_exec() {
    local path="$1"
    [[ -z "${path}" ]] && LOG FATAL "find_exec needs a non-empty path"
    local exec="$(which "${path}")"
    [[ -z "${exec}" ]] && LOG FATAL "Could not find binary '${path}'"
    echo ${exec}
}

function has_gcert() {
    local remote="${1:-origin}"
    find_exec git >/dev/null
    case "$(git remote get-url ${remote})" in
        sso://*)
            find_exec gcertstatus >/dev/null
            gcertstatus --quiet
            return $?
            ;;
        *) return ${SUCCESS}
           ;;
    esac
}

GIT_AUTO_SYNC="$(find_exec git-auto-sync)"

for repos in $(${GIT_AUTO_SYNC} daemon list); do
    echo "Syncing repository ${repos} ..." >&2
    (
        cd "${repos}"
        is_tty && LOG INFO "in TTY" || LOG INFO "not a TTY"
        has_gcert && LOG INFO "has vali gcert" || LOG WARN "has no gcert creds"
        set -x
        if ! is_tty && ! has_gcert; then
            gcert || LOG FATAL "Could not run gcert!"
        fi
        ${GIT_AUTO_SYNC} sync
    )
done
