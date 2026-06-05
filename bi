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

source "$BI_DIRECTORY/src/setup.zsh"
source "$BI_DIRECTORY/src/utility.zsh"

parse "$@"
setup


print "$INSTALL_COMMAND $INSTALL_PREFIX $CONCURRENT_JOBS"
if [[ -n "$INSTALL_UTILITY" ]]; then
    print "$INSTALL_UTILITY"
fi
