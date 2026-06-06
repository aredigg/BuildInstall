# build and install

build() {
    local name="${1}"
    local kind="${2}"
    local config="${3}"
    local alt_options="${4}"
    local directory="${5}"
    local base="${name%(_bootstrap|_stage_1|_stage_2|_stage_3)}"
    local src="$BUILD_SOURCES_DIRECTORY/${base}/${directory}"
    local bld="$BUILD_BUILDS_DIRECTORY/${name}"

    if [[ -d "$bld" ]]; then sudo rm -rf "$bld"; fi

    if [[ -f "$INSTALL_MANIFESTS/${name}.pre-manifest" ]]; then
        rm "$INSTALL_MANIFESTS/${name}.pre-manifest"
    elif [[ -f "${INSTALL_MANIFESTS}/${name}.current" && -f "${INSTALL_MANIFESTS}/${name}.old" ]]; then
        if [[ "$(<${INSTALL_MANIFESTS}/${name}.current)" == "$(<${INSTALL_MANIFESTS}/${name}.old)" ]]; then
            return
        fi
    fi

    if [[ "$name" == "cpython" ]]; then    
        {   find "$INSTALL_PREFIX" -type f 2>/dev/null
            find "/Library/Frameworks/Python.framework" -type f 2>/dev/null
            find "/Applications/Python"* -type f 2>/dev/null
        } | sort -u > "${INSTALL_MANIFESTS}/${name}.pre-manifest"
    elif [[ "$name" == "$base" ]]; then
        find "$INSTALL_PREFIX" -type f | sort > "${INSTALL_MANIFESTS}/${name}.pre-manifest"
    fi

    case "$kind" in
        configure) build_configure "$name" "$src" "$bld" "$config" ;;
    esac
    
    if [[ $INSTALL_COMMAND == "install" ]]; then
        if [[ $name == "cpython" ]]; then
            {   find "$INSTALL_PREFIX" -type f 2>/dev/null
                find "/Library/Frameworks/Python.framework" -type f 2>/dev/null
                find "/Applications/Python"* -type f 2>/dev/null
            } | sort -u > "$INSTALL_MANIFESTS/$name.post-manifest"
        elif [[ "$name" == "$base" ]]; then
            find "$INSTALL_PREFIX" -type f | sort > "$INSTALL_MANIFESTS/$name.post-manifest"
        fi
        comm -13 "$INSTALL_MANIFESTS/$name.pre-manifest" "$INSTALL_MANIFESTS/$name.post-manifest" >> "$INSTALL_MANIFESTS/$name.manifest"
        rm -f "$INSTALL_MANIFESTS/$name.pre-manifest" "$INSTALL_MANIFESTS/$name.post-manifest"
        if [[ $INSTALL_ARCHIVE == ON ]]; then
            create_archive $name "$INSTALL_MANIFESTS/$name.manifest"
        fi
    fi

    if [[ $INSTALL_COMMAND == "remove" ]]; then
        rm "$INSTALL_MANIFESTS/${name}.pre-manifest"
    fi 
 
    if [[ -f "${INSTALL_MANIFESTS}/${name}.current" ]]; then
        mv "${INSTALL_MANIFESTS}/${name}.current" "${INSTALL_MANIFESTS}/${name}.old"
    fi
}

