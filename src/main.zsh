# Main routine

main() {
    local line
    local name kind config_options alt_options directory
    local download_command download_url download_branch download_sig
    local extract_strip manifesting

    while IFS= read -r line; do
        [[ $line == '#'* || -z $line ]] && continue
        IFS=',' read -r \
            name \
            kind \
            config_options \
            alt_options \
            directory \
            download_command \
            download_url \
            download_branch \
            download_sig \
            extract_strip \
            manifesting \
            <<< "$line"
        print "<$name> <$kind> <$config_options> <$alt_options> <$directory> <$download_command> <$download_url> <$download_branch> <$download_sig> <$extract_strip> <$manifesting>"
        status_print $name I "Preparing"
        download "$name" "$download_command" "$download_url" "$download_branch" "$download_sig" "$extract_strip"
        build "$name" "$kind" "$config_options" "$alt_options" "$directory" "$manifesting"
    done < "$INSTALL_UTILITIES_FILE"
}
