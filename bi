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
BI_STARTTIME="${EPOCHSECONDS}"
BI_DIRECTORY="${0:A:h}"
BI_SYSTEM_PREFIX="/usr/local"

source "$BI_DIRECTORY/src/setup.zsh"
source "$BI_DIRECTORY/src/utility.zsh"

print "$BI_SCRIPT $BI_VERSION $BI_STARTTIME"
parse "$@"
print "$INSTALL_COMMAND $INSTALL_PREFIX"
if [[ -n "$INSTALL_UTILITY" ]]; then
    print "$INSTALL_UTILITY"
fi
