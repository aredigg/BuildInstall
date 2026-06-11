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
    local dirs

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
        cmake) build_cmake "$name" "$src" "$bld" "$config" ;;
        meson) build_meson "$name" "$src" "$bld" "$config" ;;
        prebuilt) no_build "$name" "$src" "$config" "$alt_options" ;;
        custom) ;;
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
    local file directory
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

build_cmake() {
    local name="${1}"
    local source_directory="${2}"
    local build_directory="${3}"
    local cmake_options=(
        "-Wno-dev"    
        "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"    
        '-DCMAKE_INSTALL_RPATH=@loader_path/../lib'    
        "-DCMAKE_BUILD_TYPE=Release"    
        "-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX"    
        "-DBUILD_SHARED_LIBS=TRUE"    
    )
    if [[ $name != "ninja" ]]; then    
        cmake_options+=("-GNinja")    
    fi
    cmake_options+=( "${(@s:;:)4}" )

    if [[ $INSTALL_COMMAND == "install" ]]; then
        status_print $name I "Configuring"
        if [[ -n $build_directory ]]; then
            mkdir -p "$build_directory"
            cd "$build_directory"
        fi
        $INSTALL_PREFIX/bin/cmake $cmake_options "$source_directory"
        status_print $name I "Building"
        $INSTALL_PREFIX/bin/cmake --build . --parallel=$CONCURRENT_JOBS
        uninstall_manifested "$name"
        status_print $name I "Installing"
        sudo $INSTALL_PREFIX/bin/cmake --install .
        status_print $name D "Install completed"
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        uninstall_manifested "$name"
    fi
}

build_meson() {
    local name="${1}"
    local source_directory="${2}"
    local build_directory="${3}"
    local meson_options=(
        "setup"
        "--buildtype" "release"
        "-Ddefault_library=shared"
        "--prefix=$INSTALL_PREFIX"    
    )
    meson_options+=( "${(@s:;:)4}" )
    local -x LDFLAGS="-Wl,-rpath,@loader_path/../lib"

    if [[ $INSTALL_COMMAND == "install" ]]; then
        status_print $name I "Configuring"
        if [[ -n $build_directory ]]; then
            mkdir -p "$build_directory"
            cd "$build_directory"
        fi
        meson $meson_options "$build_directory"
        status_print $name I "Building"
        meson compile -C "$build_directory"
        uninstall_manifested "$name"
        status_print $name I "Installing"
        sudo meson install -C "$build_directory"
        status_print $name D "Install completed"
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        uninstall_manifested "$name"
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
    local -x LDFLAGS="-Wl,-rpath,@loader_path/../lib"

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

no_build() {
    local name="${1}"
    local source_directory="${2}"
    local build_directory="${3}"
    local install_options
    install_options+=( "${(@s:;:)4}" )
    # We use alt_options for a script to install if available, otherwise name of directory under install prefix
    local install_script="${5}"
    local custom_directory="$install_script"
    uninstall_manifested "$name"
    if [[ $INSTALL_COMMAND == "install" ]]; then
        status_print $name I "Installing"
        if [[ -n "$install_script" ]]; then
            if [[ -x "${source_directory}/${install_script}" ]]; then
                sudo "${source_directory}/${install_script}" "$install_options"
            else
                if [[ -d "${source_directory}/${custom_directory}" ]]; then
                    mkdir -p "$INSTALL_PREFIX/${custom_directory}"
                    sudo cp -rPf $source_directory/* "$INSTALL_PREFIX/${custom_directory}/"
                fi
            fi
        else
            count_files=( "$source_directory"/*(.N) )
            if (( ${#count_files} == 1 )); then
                sudo cp -Pf "$count_files[1]" "$INSTALL_PREFIX/bin/"
            else
                local directories=(bin etc include lib libexec man sbin share)
                local directory
                for directory in "${directories[@]}"; do
                    if [[ ! -d "$source_directory/$directory" ]]; then
                        # TODO 
                        status_print $name W "Unsupported"
                        return
                    fi
                done
                for directory in "${directories[@]}"; do
                    if [[ -d "$source_directory/$directory" ]]; then
                        sudo cp -rPf "$source_directory/$directory" "$INSTALL_PREFIX/"
                    fi
                done
            fi
        fi
        status_print $name D "Install completed"
    fi
}
