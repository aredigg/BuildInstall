# build and install

build() {
    local name="${1}"
    local kind="${2}"
    local config="${3}"
    local alt_options="${4}"
    local directory="${5}"
    local manifesting="${6}"
    local base="${name%(_bootstrap|_stage_1|_stage_2|_stage_3)}"
    local src="$BUILD_SOURCES_DIRECTORY/${base}/${directory}"
    local bld="$BUILD_BUILDS_DIRECTORY/${name}"

    # Remove build directory
    if [[ -d "$bld" ]]; then sudo rm -rf "$bld"; fi

    # Skip if same is built/installed already
    if [[ -f "$INSTALL_MANIFESTS/${name}.pre-manifest" ]]; then
        rm "$INSTALL_MANIFESTS/${name}.pre-manifest"
    elif [[ -f "${INSTALL_MANIFESTS}/${name}.current" && -f "${INSTALL_MANIFESTS}/${name}.old" ]]; then
        if [[ "$(<${INSTALL_MANIFESTS}/${name}.current)" == "$(<${INSTALL_MANIFESTS}/${name}.old)" ]]; then
            return
        fi
    fi

    # Create pre manifest
    {
        find "$INSTALL_PREFIX" -type f 2>/dev/null
        for dirs in ${(s:,:)manifesting}; do
            find $~dirs -type f 2>/dev/null
        done
    } | sort -u > "${INSTALL_MANIFESTS}/${name}.pre-manifest"

    # Call build/install routines
    case "$kind" in
        configure) build_configure "$name" "$src" "$bld" "$config" ;;
    esac
    
    # Post manifest and complete manifest
    if [[ $INSTALL_COMMAND == "install" ]]; then
        {
            find "$INSTALL_PREFIX" -type f 2>/dev/null
            for dirs in ${(s:,:)manifesting}; do
                find $~dirs -type f 2>/dev/null
            done
        } | sort -u > "${INSTALL_MANIFESTS}/${name}.post-manifest"
        comm -13 "$INSTALL_MANIFESTS/$name.pre-manifest" "$INSTALL_MANIFESTS/$name.post-manifest" >> "$INSTALL_MANIFESTS/$name.manifest"
        rm -f "$INSTALL_MANIFESTS/$name.pre-manifest" "$INSTALL_MANIFESTS/$name.post-manifest"
        if [[ $INSTALL_ARCHIVE == ON ]]; then
            create_archive $name "$INSTALL_MANIFESTS/$name.manifest"
        fi
    fi

    # Cleanup
    if [[ $INSTALL_COMMAND == "remove" ]]; then
        rm "$INSTALL_MANIFESTS/${name}.pre-manifest"
    fi 
 
    if [[ -f "${INSTALL_MANIFESTS}/${name}.current" ]]; then
        mv "${INSTALL_MANIFESTS}/${name}.current" "${INSTALL_MANIFESTS}/${name}.old"
    fi
}

build_configure() {
    local name="${1}"
    local source_directory="${2}"
    local build_directory="${3}"
    local configure_options"${4}"
}
