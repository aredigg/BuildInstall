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

    local -x LDFLAGS="-Wl,-rpath,@loader_path/../lib"

    if [[ $INSTALL_COMMAND == "remove" ]]; then
        uninstall_manifested "$name"
        return
    fi

    # Checking for patches
    pre_patch "$name" "$src"

    # Remove build directory
    status_print $name I "Cleaning"
    if [[ -d "$bld" ]]; then sudo rm -rf "$bld"; fi

    # Skip if same is built/installed already
    status_print $name I "Pre manifest"
    if [[ -f "$INSTALL_MANIFESTS/${name}.pre-manifest" ]]; then
        rm "$INSTALL_MANIFESTS/${name}.pre-manifest"
    elif [[ -f "$INSTALL_MANIFESTS/${name}.manifest" && -f "${INSTALL_MANIFESTS}/${name}.current" && -f "${INSTALL_MANIFESTS}/${name}.old" ]]; then
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
        configure) build_configure "$name" "$src" "$bld" "$config" "$alt_options" ;;
    esac

    # Checking for patches
    post_patch "$name"
    
    # Post manifest and complete manifest
    if [[ $INSTALL_COMMAND == "install" ]]; then
        status_print $name I "Manifesting"
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

    if [[ -f "${INSTALL_MANIFESTS}/${name}.current" ]]; then
        mv "${INSTALL_MANIFESTS}/${name}.current" "${INSTALL_MANIFESTS}/${name}.old"
    fi
}

uninstall_manifested() {
    local name="${1}"
    if [ -f "$INSTALL_MANIFESTS/${name}.manifest" ]; then
        status_print $name I "Uninstalling"
        # load all filenames from the manifest file
        local files=( "${(@f)$(< "$INSTALL_MANIFESTS/${name}.manifest")}" )
        if (( ${#files} == 0 )); then
            rm -f "$INSTALL_MANIFESTS/${name}.manifest"
            # empty
            return
        fi
        # extract the directory names from the filenames and sort
        local -U directories=( "${files:h}" )
        directories=( "${(O)directories[@]}" )
        # remove the files
        for file in "${files[@]}"; do
            if [[ -f "$file" || -L "$file" ]]; then
                sudo rm -f "$file"
            fi
        done
        # attempt to remove directories if empty
        for directory in "${directories[@]}"; do
            if [[ -d "$directory" ]]; then
                sudo rmdir "$directory" 2>/dev/null || true
            fi
        done
        # finally remove the manifest file
        rm -f "$INSTALL_MANIFESTS/${name}.manifest"
        status_print $name D "Uninstall complete"
    fi
}

build_configure() {
    local name="${1}"
    local source_directory="${2}"
    local build_directory="${3}"
    local configure_options
    configure_options+="--prefix=$INSTALL_PREFIX"
    configure_options+=( "${(@s:;:)4}" )
    # We use alt_options if we need a custom autoconf script or similar to create configure
    local configure_custom="${5}"

    if [[ $INSTALL_COMMAND == "install" ]]; then
        status_print $name I "Configuring"
        if [[ -n $build_directory ]]; then
            mkdir -p "$build_directory"
            cd "$build_directory"
        else
            build_directory="$source_directory"
            cd "$source_directory"
        fi
        # If we are installing, find how to configure
        if [[ -n $configure_custom ]]; then
            pushd "$source_directory" > /dev/null
            if [[ -f "$configure_custom" ]]; then
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
            if [[ -f "configure.ac" ]]; then
                status_print $name I "Autoconf"
                autoreconf --force --install
            else
                print "Missing configurer, $PWD"
            fi
            popd > /dev/null
            if [[ -f "${source_directory}/configure" ]]; then       
                status_print $name I "Configuring"
                "${source_directory}/configure" $configure_options
            fi
        fi
        # We should now make
        build_make "$name"
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        uninstall_manifested "$name"
    fi
}

build_make() {
    local name="${1}"
    if [[ $INSTALL_COMMAND == "install" ]]; then
        status_print $name I "Making"
        # Now attempt to make, if it fails try not concurrent
        $BUILD_MAKE_TOOL -j$CONCURRENT_JOBS || $BUILD_MAKE_TOOL        
        # Remove old install
        uninstall_manifested "$name"
        # Install the built utility
        status_print $name I "Installing"
        sudo $BUILD_MAKE_TOOL install
        status_print $name D "Install completed"
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        uninstall_manifested "$name"
    fi
}
