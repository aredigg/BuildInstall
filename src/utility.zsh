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

status_print() {
    local name="${1}"
    local pstatus="${2}"
    local message="${3}"
    local elapsed=$(elapsed_time)
    local output
    case "$pstatus" in
        D) output="DONE" ;;
        I) output="INFO" ;;
        A) output="ATTN" ;;
        W) output="WARN" ;;
        F) output="FAIL" ;;
        *) output="DEBUG" ;;
    esac
    print -f "%s %s [%-25.25s] %-30.30s\r" "$output" "$elapsed" "$name" "$message" > /dev/tty
}

debug_print() {
    output="${1}"
    status_code="${2}"
    if [[ $DEBUG == ON ]]; then
        TZ=UTC strftime -s timefmt '%Y-%m-%d %H:%M:%S' "$BI_STARTTIME"
        if [[ -n $status_code ]]; then
            if [[ $status_code -gt 0 ]]; then
                print "DEBUG [$timefmt]: ERROR ${status_code} ${output}" > /dev/tty
            fi
        else
            print "DEBUG [$timefmt]: ${output}" > /dev/tty
        fi
    fi
}
