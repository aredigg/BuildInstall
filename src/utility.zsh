# Utility functions

elapsed_time() {
    local elapsed=$(( $EPOCHSECONDS - $BI_STARTTIME ))
    local d=$(( elapsed / 86400 ))
    local h=$(( (elapsed % 86400) / 3600 ))
    local m=$(( (elapsed % 3600) / 60 ))
    local s=$(( elapsed % 60 ))
    printf "%02d:%02d:%02d:%02d" $d $h $m $s
}

sudo_validate() {
    if ! sudo -Nnv 2>/dev/null; then
        sudo -K
        sudo -p ">>> "
    fi
}


