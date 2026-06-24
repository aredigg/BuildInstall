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

typeset -g BI_DEBUG_COMMAND
typeset -g BI_DEBUG_LOCATION
typeset -g BI_TRAPERR

TRAPDEBUG() {
    BI_DEBUG_COMMAND=$ZSH_DEBUG_CMD
    BI_DEBUG_LOCATION=${funcfiletrace[1]:-${(%):-%N:%i}}
}

TRAPERR() {
    BI_TRAPERR=$?
    error_handler $BI_TRAPERR
    return $BI_TRAPERR
}

TRAPEXIT() {
    local -i exit_code=$?
    if [[ ! -n $BI_TRAPERR ]]; then
        if (( exit_code != 0 )); then
            error_handler $exit_code
        fi
        return $exit_code
    fi
    return $BI_TRAPERR
}

error_handler() {
    if [[ -w /dev/tty ]]; then
        print -- "\n" > /dev/tty
        print -- "--------------------------------------------------------------------------------" > /dev/tty
        print -- "ERROR: Status   $1" > /dev/tty
        print -- "       Location $BI_DEBUG_LOCATION" > /dev/tty
        print -- "       Command  $BI_DEBUG_COMMAND" > /dev/tty
        print -- "--------------------------------------------------------------------------------" > /dev/tty
    fi
    return $1
}

source "$BI_DIRECTORY/src/setup.zsh"
source "$BI_DIRECTORY/src/utility.zsh"
source "$BI_DIRECTORY/src/main.zsh"
source "$BI_DIRECTORY/src/download.zsh"
source "$BI_DIRECTORY/src/build.zsh"

parse "$@"
setup
main

# print "$INSTALL_COMMAND $INSTALL_PREFIX $CONCURRENT_JOBS"
# if [[ -n "$INSTALL_UTILITY" ]]; then
#     print "$INSTALL_UTILITY"
# fi
