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

    if [[ $INSTALL_COMMAND == "remove" ]]; then
        uninstall_manifested "$name"
        return
    fi

    debug_print "Preparing to build <$name> ($base)"

    # Checking for patches
    pre_patch "$name" "$src"

    # Remove build directory
    if [[ -d "$bld" ]]; then sudo rm -rf "$bld"; fi
    debug_print "Cleaned build directory <$bld>"

    # Skip if same is built/installed already
    if [[ -f "$INSTALL_MANIFESTS/${name}.pre-manifest" ]]; then
        rm "$INSTALL_MANIFESTS/${name}.pre-manifest"
    elif [[ -f "$INSTALL_MANIFESTS/${name}.manifest" && -f "${INSTALL_MANIFESTS}/${name}.current" && -f "${INSTALL_MANIFESTS}/${name}.old" ]]; then
        if [[ "$(<${INSTALL_MANIFESTS}/${name}.current)" == "$(<${INSTALL_MANIFESTS}/${name}.old)" ]]; then
            debug_print "Already built and installed"
            return
        fi
    fi

    # Create pre manifest
    debug_print "Creating pre manifest"
    {
        find "$INSTALL_PREFIX" -type f 2>/dev/null
        for dirs in ${(s:,:)manifesting}; do
            find $~dirs -type f 2>/dev/null
        done
    } | sort -u > "${INSTALL_MANIFESTS}/${name}.pre-manifest"
    debug_print "Completed pre manifest"

    # Call build/install routines
    case "$kind" in
        configure) build_configure "$name" "$src" "$bld" "$config" "$alt_options" ;;
    esac

    # Checking for patches
    post_patch "$name"
    
    # Post manifest and complete manifest
    if [[ $INSTALL_COMMAND == "install" ]]; then
        debug_print "Creating post manifest"
        {
            find "$INSTALL_PREFIX" -type f 2>/dev/null
            for dirs in ${(s:,:)manifesting}; do
                find $~dirs -type f 2>/dev/null
            done
        } | sort -u > "${INSTALL_MANIFESTS}/${name}.post-manifest"
        comm -13 "$INSTALL_MANIFESTS/$name.pre-manifest" "$INSTALL_MANIFESTS/$name.post-manifest" >> "$INSTALL_MANIFESTS/$name.manifest"
        rm -f "$INSTALL_MANIFESTS/$name.pre-manifest" "$INSTALL_MANIFESTS/$name.post-manifest"
        debug_print "Completed post manifest"
        if [[ $INSTALL_ARCHIVE == ON ]]; then
            create_archive $name "$INSTALL_MANIFESTS/$name.manifest"
        fi
    fi

    if [[ -f "${INSTALL_MANIFESTS}/${name}.current" ]]; then
        mv "${INSTALL_MANIFESTS}/${name}.current" "${INSTALL_MANIFESTS}/${name}.old"
    fi
    debug_print "Completed build and install <$name>"
}

uninstall_manifested() {
    local name="${1}"
    if [ -f "$INSTALL_MANIFESTS/${name}.manifest" ]; then
        debug_print "Preparing to uninstall files <$name>"
        # load all filenames from the manifest file
        local files=( "${(@f)$(< "$INSTALL_MANIFESTS/${name}.manifest")}" )
        if (( ${#files} == 0 )); then
            debug_print "Manifest file <$INSTALL_MANIFESTS/${name}.manifest> is empty!"
            rm -f "$INSTALL_MANIFESTS/${name}.manifest"
            # empty
            return
        fi
        # extract the directory names from the filenames and sort
        local -U directories=( "${files:h}" )
        directories=( "${(O)directories[@]}" )
        # remove the files
        debug_print "Removing files"
        for file in "${files[@]}"; do
            if [[ -f "$file" || -L "$file" ]]; then
                rm -f "$file"
            fi
        done
        debug_print "Removing empty directories"
        # attempt to remove directories if empty
        for directory in "${directories[@]}"; do
            if [[ -d "$directory" ]]; then
                rmdir "$directory" 2>/dev/null || true
            fi
        done
        # finally remove the manifest file
        rm -f "$INSTALL_MANIFESTS/${name}.manifest"
        debug_print "Completed uninstall <$name>"
    fi
}

build_configure() {
    local name="${1}"
    local source_directory="${2}"
    local build_directory="${3}"
    local configure_options
    configure_options+="--prefix=$INSTALL_PREFIX"
    configure_options+=( "${(@s:,:)4}" )
    # We use alt_options if we need a custom autoconf script or similar to create configure
    local configure_custom="${5}"
    debug_print "Building using configure <$name>"

    if [[ $INSTALL_COMMAND == "install" ]]; then
        # If we are installing, find how to configure
        if [[ -n $configure_custom ]]; then
            pushd "$source_directory" > /dev/null
            if [[ -f "$configure_custom" ]]; then
                debug_print "Configuring using <$configure_custom>"
                "./$configure_custom"
            fi
            popd > /dev/null
        fi
        if [[ -f "${source_directory}/configure" ]]; then
            "${source_directory}/configure" $configure_options
        elif [[ -f "${source_directory}/Configure" ]]; then
            "${source_directory}/Configure" $configure_options
        elif [[ -f "${source_directory}/bootstrap" ]]; then
            if ! "${source_directory}/bootstrap" $configure_options; then
                 "${source_directory}/bootstrap" --force
            fi
            if [[ -f "${source_directory}/configure" ]]; then
                "${source_directory}/configure" $configure_options
            fi
        else
            pushd "$source_directory" > /dev/null
            debug_print "No configure script found, atempt to autoconf"
            if [[ -f "configure.ac" ]]; then
                autoreconf --force --install
            else
                debug_print "Missing configurer, $PWD"
            fi
            popd > /dev/null
            if [[ -f "${source_directory}/configure" ]]; then
                "${source_directory}/configure" $configure_options
            fi
        fi
        debug_print "Configured <$name>"
        # We should now make
        build_make "$name"
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        uninstall_manifested "$name"
    fi
}

build_make() {
    local name="${1}"
    debug_print "Making <$name>"
    if [[ $INSTALL_COMMAND == "install" ]]; then
        # Now attempt to make, if it fails try not concurrent
        debug_print "Making"
        $BUILD_MAKE_TOOL -j$CONCURRENT_JOBS || $BUILD_MAKE_TOOL
        # Remove old install
        uninstall_manifested "$name"
        # Install the built utility
        debug_print "Installing"
        sudo $BUILD_MAKE_TOOL install
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        uninstall_manifested "$name"
    fi
    debug_print "Completed make <$name>"
}
