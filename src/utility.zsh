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
        *) debug_print "$message" ;;
    esac
    [[ -w /dev/tty ]] && print -f "%s %s [%-25.25s] %-30.30s\r" "$output" "$elapsed" "$name" "$message" > /dev/tty
}

debug_print() {
    local output="${1}"
    local status_code="${2}"
    local timefmt
    if [[ $DEBUG == ON ]]; then
        TZ=UTC strftime -s timefmt '%Y-%m-%d %H:%M:%S' "$EPOCHSECONDS"
        if [[ -n $status_code ]]; then
            if [[ $status_code -gt 0 ]]; then
                print -u2 "DEBUG [$timefmt]: ERROR ${status_code} ${output}"
            fi
        else
            print -u2 "DEBUG [$timefmt]: ${output}"
        fi
    fi
}

modified() {
    if [[ -e "$1" ]]; then
        local mtime=$(zstat +mtime -- "$1")
        local threshold=$(( $EPOCHSECONDS - 43200 ))
        if (( mtime > threshold )); then
            debug_print "(modified) $mtime > $threshold = true, File $1"
            return 0
        fi
        debug_print "(modified) $mtime > $threshold = false, File $1"
    fi
    return 1
}
