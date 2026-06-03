#!/usr/bin/env zsh
#
# zsh install script for building and installing various utilities
#
# ©️ 2025-2026 Are Digranes
#
#  MIT license
#

zmodload zsh/datetime

BI_VERSION="2.00"
BI_SCRIPT="${ZSH_SCRIPT}"
BI_STARTTIME="${EPOCHSECONDS}"
BI_DIRECTORY="${0:A:h}"

source "$BI_DIRECTORY/src/setup"

printf "$BI_SCRIPT $BI_VERSION $BI_STARTTIME\n"
