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

TRAPDEBUG() {
    BI_DEBUG_COMMAND=$ZSH_DEBUG_CMD
    BI_DEBUG_LOCATION=${funcfiletrace[1]:-${(%):-%N:%i}}
#    if [[ $DEBUG == ON ]]; then
#        TZ=UTC strftime -s timefmt '%Y-%m-%d %H:%M:%S' "$EPOCHSECONDS"        
#        print -rf " == DEBUG [$timefmt] == \n  %s\n--\n%s\n--\n" "$BI_DEBUG_LOCATION" "$BI_DEBUG_COMMAND" > /dev/tty
#    fi
}

TRAPERR() {
    print "ERROR: Status   $1" > /dev/tty
    print "       Location $BI_DEBUG_LOCATION" > /dev/tty
    print "       Command  $BI_DEBUG_COMMAND" > /dev/tty
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
