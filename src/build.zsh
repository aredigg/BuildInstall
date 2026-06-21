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
    # Debug print
    debug_print "(build) Name $name; kind $kind; config $config; alt_options $alt_options; directory $directory; manifesting $manifesting"
    debug_print "        src $src; bld $bld"

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
        if modified "$INSTALL_MANIFESTS/${name}.manifest"; then
            # We skip also when less than 12 hours since last build
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
        makeonly) build_makeonly "$name" "$src" "$bld" "$config" "$alt_options" ;;
        meson) build_meson "$name" "$src" "$bld" "$config" ;;
        pip) build_pip "$name" "$src" "$config" "$alt_options" ;;
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
    # Debug print
    debug_print "(uninstall_manifested) Name $name"
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
        "-Wno-author"
        "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
        '-DCMAKE_INSTALL_RPATH=@loader_path/../lib'
        "-DCMAKE_BUILD_TYPE=Release"
        "-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX"
        "-DBUILD_SHARED_LIBS=TRUE"
    )
    if [[ $name != "ninja" ]]; then
        cmake_options+=("-GNinja")
    fi
    cmake_options+=( "${(@es:;:)4}" )
    # Debug print
    debug_print "(build_cmake) Name $name; cmake_options $cmake_options"
    debug_print "              source_directory $source_directory; build_directory $build_directory"

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
    meson_options+=( "${(@es:;:)4}" )
    # Debug print
    debug_print "(build_meson) Name $name; meson_options $meson_options"
    debug_print "              source_directory $source_directory; build_directory $build_directory"
    local -x LDFLAGS="-Wl,-rpath,@loader_path/../lib"

    if [[ $INSTALL_COMMAND == "install" ]]; then
        status_print $name I "Configuring"
        if [[ -n $build_directory ]]; then
            mkdir -p "$build_directory"
        fi
        pushd "$source_directory" > /dev/null
        meson $meson_options "$build_directory"
        status_print $name I "Building"
        meson compile -C "$build_directory"
        uninstall_manifested "$name"
        status_print $name I "Installing"
        sudo meson install -C "$build_directory"
        popd > /dev/null
        status_print $name D "Install completed"
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        uninstall_manifested "$name"
    fi
}

build_pip() {
    local name="${1}"
    local source_directory="${2}"
    local pip_settings config_settings
    if [[ -n "$3" ]]; then
        pip_settings=( "${(@es:;:)3}" )
        local setting
        for setting in "${pip_settings[@]}"; do
            [[ -n "$setting" ]] && config_settings+=( "--config-settings=$setting" )
        done
    fi
    local name="${name%(_bootstrap|_stage_1|_stage_2|_stage_3)}"

    local build_option="${4}"
    # Debug print
    debug_print "(build_pip) Name $name; config_settings $config_settings; build_option $build_option"
    debug_print "            source_directory $source_directory"
    local -x LDFLAGS="-Wl,-rpath,@loader_path/../lib"
    if [[ $INSTALL_COMMAND == "install" ]]; then
        if [[ $name == "pip" ]]; then
            curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py
            sudo python3 get-pip.py --force-reinstall
            rm get-pip.py
        fi
        if [[ -d "$source_directory" ]]; then
            sudo -H pip3 install --root-user-action ignore "${config_settings[@]}" --no-deps --no-build-isolation "$source_directory"
        elif [[ $build_option == "binary" ]]; then
            sudo -H pip3 install --root-user-action ignore --no-deps --only-binary :all: --upgrade "$name"
        else
            sudo -H pip3 install --root-user-action ignore "${config_settings[@]}" --no-deps --no-build-isolation --no-binary :all: --upgrade "$name"
        fi
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        # sudo -H pip3 uninstall -y "$name"
        uninstall_manifested "$name"
    fi
}

build_configure() {
    local name="${1}"
    local source_directory="${2}"
    local build_directory="${3}"
    local -a configure_options
    configure_options+="--prefix=$INSTALL_PREFIX"
    configure_options+=( "${(@es:;:)4}" )
    # We use alt_options if we need a custom autoconf script or similar to create configure
    local configure_custom="${5}"
    # Debug print
    debug_print "(build_configure) Name $name; configure_options $configure_options; configure_custom $configure_custom"
    debug_print "                  source_directory $source_directory; build_directory $build_directory"
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
            pushd "$source_directory" > /dev/null
            if ! "${source_directory}/bootstrap" $configure_options; then
                 "${source_directory}/bootstrap" --force
            fi
            popd > /dev/null
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
        build_make "$name" "$source_directory"
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        uninstall_manifested "$name"
    fi
}

build_makeonly() {
    local name="${1}"
    local source_directory="${2}"
    local build_directory="${3}"
    local -a make_options
    make_options+=( "${(@es:;:)4}" )
    # We use alt_options for an optional prescript
    local custom_maker="${5}"
    # Debug print
    debug_print "(build_makeonly) Name $name; make_options $make_options; custom_maker $custom_maker"
    debug_print "                 source_directory $source_directory; build_directory $build_directory"
    local -x LDFLAGS="-Wl,-rpath,@loader_path/../lib"
    if [[ -n "$custom_maker" ]]; then
        $custom_maker
    fi
    build_make "$name" "$source_directory" "$make_options"
}

build_make() {
    local name="${1}"
    local source_directory="${2}"
    local make_options="${3}"
    # Debug print
    debug_print "(build_make) Name $name; make_options $make_options"
    debug_print "             source_directory $source_directory"
    if [[ $INSTALL_COMMAND == "install" ]]; then
        status_print $name I "Patching"
        if [[ -f "${source_directory}/makefile" ]]; then
            mv "${source_directory}/makefile" "${source_directory}/Makefile"
        fi
        if [[ -f "${source_directory}/Makefile" ]]; then
            sed -i '' "s|/usr/local|${INSTALL_PREFIX}${custom_prefix}|g" "$source_directory/Makefile"
        fi
        if [[ ! -f "Makefile" ]]; then
            cd "$source_directory"
        fi
        status_print $name I "Making"
        # Now attempt to make, if it fails try not concurrent
        $BUILD_MAKE_TOOL -j$CONCURRENT_JOBS $make_options || $BUILD_MAKE_TOOL
        # Remove old install
        uninstall_manifested "$name"
        # Install the built utility
        status_print $name I "Installing"
        sudo $BUILD_MAKE_TOOL install $make_options || sudo $BUILD_MAKE_TOOL install
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
    install_options+=( "${(@es:;:)4}" )
    # We use alt_options for a script to install if available, otherwise name of directory under install prefix
    local install_script="${5}"
    # TODO maybe split this?
    local custom_directory="$install_script"
    # Debug print
    debug_print "(no_build) Name $name; install_options $install_options; install_script $install_script; "
    debug_print "           source_directory $source_directory; build_directory $build_directory; custom_directory $custom_directory"
    uninstall_manifested "$name"
    if [[ $INSTALL_COMMAND == "install" ]]; then
        status_print $name I "Installing"
        if [[ -n "$install_script" || -n "$custom_directory" ]]; then
            if [[ -x "${source_directory}/${install_script}" ]]; then
                # TODO some safety questions and checks
                sudo "${source_directory}/${install_script}" "$install_options"
            else
                if [[ ! -d "$INSTALL_PREFIX/${custom_directory}" ]]; then
                    mkdir -p "$INSTALL_PREFIX/${custom_directory}"
                fi
                sudo cp -rPf $source_directory/* "$INSTALL_PREFIX/${custom_directory}/"
            fi
        else
            count_files=( "$source_directory"/*(.N) )
            if (( ${#count_files} == 1 )); then
                if [[ ! -x "$count_files[1]" ]]; then
                    chmod +x "$count_files[1]"
                fi
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
