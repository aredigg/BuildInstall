# Main routine

main() {
    local line
    local -a lines
    local comment name version kind config_options alt_options directory
    local download_command download_url download_branch download_sig
    local extract_strip manifesting overflow

    status_print "SCRIPT" I "Preparing"
    while IFS= read -r line; do
        [[ $line == '#'* || -z $line ]] && continue
        lines+=( "$line" )
    done < "$INSTALL_UTILITIES_FILE"

    if [[ $INSTALL_COMMAND == "install" || $INSTALL_COMMAND = "download" ]]; then
        for (( i = 1; i <= ${#lines}; i++ )); do
            line="${lines[i]}"
            IFS=',' read -r \
            comment version name kind config_options alt_options directory \
            download_command download_url download_branch download_sig \
            extract_strip manifesting overflow <<< "$line"
            if [[ -n $overflow ]]; then
                print -u2 "ERROR in csv <$name> <$overflow>"
            fi
            exec >"${BUILD_LOGS_DIRECTORY}/$name-install-out.log" 2>"${BUILD_LOGS_DIRECTORY}/$name-install-err.log"
            if [[ ! -n $INSTALL_UTILITY || $INSTALL_UTILITY == "$name" ]]; then
                print "<$name> <$kind> <$config_options> <$alt_options> <$directory> <$download_command> <$download_url> <$download_branch> <$download_sig> <$extract_strip> <$manifesting>"
                print -u2 "<$name> <$kind> <$config_options> <$alt_options> <$directory> <$download_command> <$download_url> <$download_branch> <$download_sig> <$extract_strip> <$manifesting>"
                if ! modified "$INSTALL_MANIFESTS/${name}.manifest"; then
                    status_print $name I "Preparing"
                    download "$name" "$download_command" "$download_url" "$download_branch" "$download_sig" "$extract_strip"
                    if [[ ! $INSTALL_COMMAND = "download" ]]; then
                        build "$name" "$kind" "$config_options" "$alt_options" "$directory" "$manifesting"
                    fi
                else
                    # We skip also when less than 12 hours since last build
                    status_print $name I "Skip build 12 hrs"
                fi
            fi
            platform_env $name
            exec >"$BUILD_LOG_OUT" 2>"$BUILD_LOG_ERR"
        done
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        for (( i = ${#lines}; i >= 1; i-- )); do
            line="${lines[i]}"
            IFS=',' read -r \
            comment version name kind config_options alt_options directory \
            download_command download_url download_branch download_sig \
            extract_strip manifesting overflow <<< "$line"
            if [[ -n $overflow ]]; then
                print -u2 "ERROR in csv <$name> <$overflow>"
            fi
            exec >"${BUILD_LOGS_DIRECTORY}/$name-remove-out.log" 2>"${BUILD_LOGS_DIRECTORY}/$name-remove-err.log"
            if [[ ! -n $INSTALL_UTILITY || $INSTALL_UTILITY == "$name" ]]; then
                print "<$name> <$kind> <$config_options> <$alt_options> <$directory> <$download_command> <$download_url> <$download_branch> <$download_sig> <$extract_strip> <$manifesting>"
                status_print $name I "Preparing"
                download "$name" "$download_command" "$download_url" "$download_branch" "$download_sig" "$extract_strip"
                build "$name" "$kind" "$config_options" "$alt_options" "$directory" "$manifesting"
            fi
            exec >"$BUILD_LOG_OUT" 2>"$BUILD_LOG_ERR"
        done
    elif [[ $INSTALL_COMMAND == "print" ]]; then
        print_package_header
        for (( i = 1; i <= ${#lines}; i++ )); do
            line="${lines[i]}"
            IFS=',' read -r \
            comment version name kind config_options alt_options directory \
            download_command download_url download_branch download_sig \
            extract_strip manifesting overflow <<< "$line"
            if [[ -n $overflow ]]; then
                print -u2 "ERROR in csv <$name> <$overflow>"
            fi
            if [[ ! -n $INSTALL_UTILITY || $INSTALL_UTILITY == "$name" ]]; then
                print "<$name> <$kind> <$config_options> <$alt_options> <$directory> <$download_command> <$download_url> <$download_branch> <$download_sig> <$extract_strip> <$manifesting>"
                status_print $name I "Preparing"
                print_package_status $name $kind $download_command $download_url $download_branch
            fi
        done
    fi
}
