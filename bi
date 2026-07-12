#!/usr/bin/env zsh
#
# zsh install script for building and installing various utilities
#
# ©️ 2025-2026 Are Digranes
#
#  MIT license
#

zmodload zsh/datetime
zmodload zsh/zutil
zmodload zsh/stat

BI_VERSION="2.00"
BI_SCRIPT="${ZSH_SCRIPT}"
BI_SCRIPT_PID="$$"
BI_STARTTIME="${EPOCHSECONDS}"
BI_DIRECTORY="${0:A:h}"
BI_SYSTEM_PREFIX="/usr/local"
BI_SYSTEM_TMP="/tmp"
BI_SYSTEM_FILE="utilities.csv"
BI_SKIP_TIME="302400"
# 43200  - 12 hrs
# 86400  - 24 hrs
# 604800 - 7 days

typeset -g BI_DEBUG_COMMAND
typeset -g BI_DEBUG_LOCATION
typeset -g BI_TRAPERR
typeset -g BI_SUDO_PID

exec 3>&1 4>&2

TRAPDEBUG() {
    BI_DEBUG_COMMAND=$ZSH_DEBUG_CMD
    BI_DEBUG_LOCATION=${funcfiletrace[1]:-${(%):-%N:%i}}
}

TRAPERR() {
    BI_TRAPERR=$?
    error_handler $BI_TRAPERR
    exit $BI_TRAPERR
}

TRAPEXIT() {
    local -i exit_code=$?
    if [[ -n "$BI_SUDO_PID" ]]; then
        kill "$BI_SUDO_PID" 2>/dev/null || true
    fi
    if [[ ! -n $BI_TRAPERR ]]; then
        if (( exit_code != 0 )); then
            error_handler $exit_code
        fi
        return $exit_code
    fi
    return $BI_TRAPERR
}

error_handler() {
    print -- "\n" >&4
    print -- "--------------------------------------------------------------------------------" >&4
    print -- "ERROR: Status   $1" >&4
    print -- "       Location $BI_DEBUG_LOCATION" >&4
    print -- "       Command  $BI_DEBUG_COMMAND" >&4
    print -- "--------------------------------------------------------------------------------" >&4
    return $1
}

source "$BI_DIRECTORY/src/setup.zsh"
source "$BI_DIRECTORY/src/utility.zsh"
source "$BI_DIRECTORY/src/main.zsh"
source "$BI_DIRECTORY/src/download.zsh"
source "$BI_DIRECTORY/src/build.zsh"
source "$BI_DIRECTORY/src/print.zsh"

parse "$@"
setup
main
