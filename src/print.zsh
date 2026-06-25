print_package_header() {
    print_line "Name" "Installed" "Files" "Kind" "Download" "URL" "Branch"
    print -ru3 -- "---------------------------------------------------------------------"
}

print_package_status() {
    local name=${1}
    local kind=${2}
    local download=${3}
    local url=${4}
    local branch=${5}
    local installed="NO"
    local files=0
    local manifest="$INSTALL_MANIFESTS/${name}.manifest"
    status_print $name I "Checking"
    if [[ -f "$INSTALL_MANIFESTS/${name}.pre-manifest" ]]; then
        installed="Incomplete"
    elif [[ -f "$manifest" ]]; then
        TZ=UTC strftime -s installed '%Y-%m-%d %H:%M' "$(zstat +mtime -- "$manifest")"
        local -a lines
        while IFS= read -r line; do
            [[ -z $line ]] && continue
            lines+=( "$line" )
        done < "$manifest"
        files=${#lines}
    fi
    status_print $name I "Outputting"
    print_line "$name" "$installed" "$files" "$kind" "$download" "$url" "$branch"
}

print_line() {
    print -ru3 -f "%-25.25s %-18.18s %5.5s %-9.9s %-8.8s\n" "$1" "$2" "$3" "$4" "$5"
}
