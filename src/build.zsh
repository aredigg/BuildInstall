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
    # Debug print
    debug_print "(build) Name $name; Base $base; kind $kind; config $config; alt_options $alt_options; directory $directory; manifesting $manifesting"
    debug_print "        src $src; bld $bld"

    if [[ $INSTALL_COMMAND == "remove" ]]; then
        uninstall_manifested "$name"
        return
    fi

    # Checking for patches
    status_print $name I "Patching"
    [[ -d $src ]] && pushd "$src" > /dev/null
    pre_patch "$name" "$src"
    [[ -d $src ]] && popd > /dev/null

    # Remove build directory
    status_print $name I "Cleaning"
    if [[ -d "$bld" ]]; then sudo rm -rf "$bld"; fi

    # Skip if same is built/installed already
    status_print $name I "Checking"
    if [[ -f "$INSTALL_MANIFESTS/${name}.pre-manifest" ]]; then
        rm "$INSTALL_MANIFESTS/${name}.pre-manifest"
    elif [[ -f "$INSTALL_MANIFESTS/${name}.manifest" && -f "${INSTALL_MANIFESTS}/${name}.current" && -f "${INSTALL_MANIFESTS}/${name}.old" ]]; then
        if [[ "$(<${INSTALL_MANIFESTS}/${name}.current)" == "$(<${INSTALL_MANIFESTS}/${name}.old)" ]]; then
            status_print $name I "Skip build"
            return
        fi
    fi

    # Call build/install routines
    case "$kind" in
        cargo) build_cargo "$name" "$src" "$bld" "$manifesting" ;;
        configure) build_configure "$name" "$src" "$bld" "$config" "$alt_options" "$manifesting" ;;
        configure_in_source) build_configure "$name" "$src" "" "$config" "$alt_options" "$manifesting" ;;
        cmake) build_cmake "$name" "$src" "$bld" "$config" "$manifesting" ;;
        makeonly) build_makeonly "$name" "$src" "$bld" "$config" "$alt_options" "$manifesting" ;;
        meson) build_meson "$name" "$src" "$bld" "$config" "$manifesting" ;;
        muon) build_muon "$name" "$src" "$bld" "$config" "$manifesting" ;;
        npm) build_deno "$name" "$src" "$config" "$manifesting" ;;
        prebuilt) no_build "$name" "$src" "$config" "$alt_options" "$manifesting" ;;
        uv) build_uv "$name" "$src" "$config" "$alt_options" "$manifesting" ;;
        zig) build_zig "$name" "$src" "$bld" "$config" "$manifesting" ;;
        custom) ;;
        *) exit 11 ;;
    esac

    # Checking for patches
    status_print $name I "Patching"
    post_patch "$name" "$src" "$bld"

    # Post manifest and complete manifest
    if [[ $INSTALL_COMMAND == "install" ]]; then
        complete_postmanifest "$name" "$manifesting"
    fi

    if [[ -f "${INSTALL_MANIFESTS}/${name}.current" ]]; then
        mv "${INSTALL_MANIFESTS}/${name}.current" "${INSTALL_MANIFESTS}/${name}.old"
    fi
}

create_premanifest() {
    local name="${1}"
    local manifesting="${2}"
    local dirs
    debug_print "(create_premanifest) Name $name Manifesting $manifesting"
    status_print $name I "Manifesting PRE"
    {
        find "$INSTALL_PREFIX" -type f 2>/dev/null || true
        for dirs in ${(s:;:)manifesting}; do
            find $~dirs -type f 2>/dev/null || true
        done
    } | sort -u > "${INSTALL_MANIFESTS}/${name}.pre-manifest"
}

complete_postmanifest() {
    local name="${1}"
    local manifesting="${2}"
    local dirs
    debug_print "(complete_postmanifest) Name $name Manifesting $manifesting"
    status_print $name I "Manifesting POST"
    {
        find "$INSTALL_PREFIX" -type f 2>/dev/null || true
        for dirs in ${(s:;:)manifesting}; do
            find $~dirs -type f 2>/dev/null || true
        done
    } | sort -u > "${INSTALL_MANIFESTS}/${name}.post-manifest"
    status_print $name I "Manifesting"
    comm -13 "$INSTALL_MANIFESTS/$name.pre-manifest" "$INSTALL_MANIFESTS/$name.post-manifest" >> "$INSTALL_MANIFESTS/$name.manifest"
    rm -f "$INSTALL_MANIFESTS/$name.pre-manifest" "$INSTALL_MANIFESTS/$name.post-manifest"
    if [[ $INSTALL_ARCHIVE == ON ]]; then
        create_archive $name "$INSTALL_MANIFESTS/$name.manifest"
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
        status_print $name I "Removing files"
        for file in "${files[@]}"; do
            if [[ -f "$file" || -L "$file" ]]; then
                sudo rm -f "$file"
            fi
        done
        # attempt to remove directories if empty
        status_print $name I "Cleaning directories"
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
    local -a cmake_options=(
        "-Wno-author"
        "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
        $BI_RPATH_CMAKE
        "-DCMAKE_BUILD_TYPE=Release"
        "-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX"
        "-DBUILD_SHARED_LIBS=TRUE"
    )
    if [[ $name != "ninja" ]]; then
        cmake_options+=("-GNinja")
    fi
    cmake_options+=( "${(@es:;:)4}" )
    local manifesting="${5}"
    # Debug print
    debug_print "(build_cmake) Name $name; cmake_options $cmake_options"
    debug_print "              source_directory $source_directory; build_directory $build_directory"

    if [[ $INSTALL_COMMAND == "install" ]]; then
        status_print $name I "Configuring"
        if [[ -n $build_directory ]]; then
            mkdir -p "$build_directory"
            cd "$build_directory"
        fi
        $INSTALL_PREFIX/bin/cmake "${cmake_options[@]}" "$source_directory"
        status_print $name I "Building"
        $INSTALL_PREFIX/bin/cmake --build "$build_directory" --parallel $CONCURRENT_JOBS
        uninstall_manifested "$name"
        create_premanifest "$name" "$manifesting"
        status_print $name I "Installing"
        sudo $INSTALL_PREFIX/bin/cmake --install "$build_directory"
        status_print $name D "Install completed"
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        uninstall_manifested "$name"
    fi
}

build_meson() {
    local name="${1}"
    local source_directory="${2}"
    local build_directory="${3}"
    local -a meson_options=(
        "setup"
        "--buildtype" "release"
        "-Ddefault_library=shared"
        "--prefix=$INSTALL_PREFIX"
        "-Dc_link_args=$BI_RPATH_REL $LDFLAGS"
        "-Dcpp_link_args=$BI_RPATH_REL $LDFLAGS"
    )
    meson_options+=( "${(@es:;:)4}" )
    local manifesting="${5}"
    # Debug print
    debug_print "(build_meson) Name $name; meson_options $meson_options"
    debug_print "              source_directory $source_directory; build_directory $build_directory"

    if [[ $INSTALL_COMMAND == "install" ]]; then
        status_print $name I "Configuring"
        if [[ -n $build_directory ]]; then
            mkdir -p "$build_directory"
        fi
        pushd "$source_directory" > /dev/null
        meson "${meson_options[@]}" "$build_directory"
        status_print $name I "Building"
        meson compile -C "$build_directory"
        uninstall_manifested "$name"
        create_premanifest "$name" "$manifesting"
        status_print $name I "Installing"
        sudo meson install -C "$build_directory"
        popd > /dev/null
        status_print $name D "Install completed"
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        uninstall_manifested "$name"
    fi
}

build_muon() {
    local name="${1}"
    local source_directory="${2}"
    local build_directory="${3}"
    local -a meson_options=(
        "setup"
        "-Dbuildtype=release"
        "-Ddefault_library=shared"
        "-Dprefix=$INSTALL_PREFIX"
        "-Dc_link_args=$BI_RPATH_REL $LDFLAGS"
        "-Dcpp_link_args=$BI_RPATH_REL $LDFLAGS"
    )
    meson_options+=( "${(@es:;:)4}" )
    local manifesting="${5}"
    # Debug print
    debug_print "(build_muon) Name $name; meson_options $meson_options"
    debug_print "             source_directory $source_directory; build_directory $build_directory"

    if [[ $INSTALL_COMMAND == "install" ]]; then
        status_print $name I "Configuring"
        if [[ -n $build_directory ]]; then
            mkdir -p "$build_directory"
        fi
        pushd "$source_directory" > /dev/null
        muon "${meson_options[@]}" "$build_directory"
        status_print $name I "Building"
        muon -C "$build_directory" samu
        uninstall_manifested "$name"
        create_premanifest "$name" "$manifesting"
        status_print $name I "Installing"
        sudo muon -C "$build_directory" install
        popd > /dev/null
        status_print $name D "Install completed"
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        uninstall_manifested "$name"
    fi
}

build_uv() {
    local name="${1}"
    local source_directory="${2}"
    local -a pip_settings config_settings
    if [[ -n "$3" ]]; then
        pip_settings=( "${(@es:;:)3}" )
        local setting
        for setting in "${pip_settings[@]}"; do
            [[ -n "$setting" ]] && config_settings+=( "--config-settings=$setting" )
        done
    fi
    local base="${name%(_bootstrap|_stage_1|_stage_2|_stage_3)}"
    local build_option="${4}"
    local manifesting="${5}"
    # Debug print
    debug_print "(build_uv) Name $name; config_settings $config_settings; build_option $build_option"
    debug_print "           source_directory $source_directory"
    local -x LDFLAGS="$BI_RPATH_REL $LDFLAGS"

    # The manifest is very likely empty on macOS
    uninstall_manifested "$name"
    if [[ $INSTALL_COMMAND == "install" ]]; then
        create_premanifest "$name" "$manifesting"
        status_print $name I "Installing"
        if [[ -d "$source_directory" ]]; then
            sudo -H uv pip install \
                --python "$PYTHON_EXEC" \
                "${config_settings[@]}" \
                --system --no-deps --no-build-isolation \
                "$source_directory"
        elif [[ $build_option == "binary" ]]; then
            sudo -H uv pip install \
                --python "$PYTHON_EXEC" \
                --system --no-deps --only-binary :all: --upgrade \
                "$base"
        else
            sudo -H uv pip install \
                --python "$PYTHON_EXEC" \
                "${config_settings[@]}" \
                --system --no-deps --no-build-isolation --no-binary :all: --upgrade \
                "$base"
        fi
        status_print $name D "Install completed"
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        # This is hopefully enough on macOS, otherwise we have to add manifest paths
        sudo -H uv pip uninstall \
            --python "$PYTHON_EXEC" \
            --system \
            "$base"
    fi
}

build_cargo() {
    local name="${1}"
    local source_directory="${2}"
    local build_directory="${3}"
    local manifesting="${4}"
    if [[ $INSTALL_COMMAND == "install" ]]; then
        status_print $name I "Building"
        if [[ -n $build_directory ]]; then
            mkdir -p "$build_directory"
            cd "$build_directory"
        fi
        cargo build --release --manifest-path "$source_directory/Cargo.toml"
        uninstall_manifested "$name"
        create_premanifest "$name" "$manifesting"
        status_print $name I "Installing"
        sudo cargo install --force --locked --path "$source_directory" --root $INSTALL_PREFIX
        status_print $name D "Install completed"
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        uninstall_manifested "$name"
    fi
}

build_deno() {
    local name="${1}"
    local source_directory="${2}"
    local target="${3}"
    local manifesting="${4}"
    uninstall_manifested "$name"
    if [[ $INSTALL_COMMAND == "install" ]]; then
        create_premanifest "$name" "$manifesting"
        status_print $name I "Installing"
        sudo deno install -f --global --allow-all --name $name --root "$INSTALL_PREFIX" npm:$target
        status_print $name D "Install completed"
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        sudo deno uninstall --global --root "$INSTALL_PREFIX" $name
    fi
}

build_zig() {
    local name="${1}"
    local source_directory="${2}"
    local build_directory="${3}"
    local -a zig_options
    zig_options+=( "${(@es:;:)4}" )
    local manifesting="${5}"
    if [[ $INSTALL_COMMAND == "install" ]]; then
        status_print $name I "Building"
        mkdir -p "$build_directory"
        cd "$build_directory"
        zig build -Doptimize=ReleaseFast --build-file "$source_directory/build.zig" --cache-dir "$build_directory/zig-cache"
        uninstall_manifested "$name"
        create_premanifest "$name" "$manifesting"
        status_print $name I "Installing"
        sudo zig build -Doptimize=ReleaseFast --build-file "$source_directory/build.zig" --cache-dir "$build_directory/zig-cache" install -p "$INSTALL_PREFIX"
        status_print $name D "Install completed"
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
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
    local manifesting="${6}"
    # Debug print
    debug_print "(build_configure) Name $name; configure_options $configure_options; configure_custom $configure_custom"
    debug_print "                  source_directory $source_directory; build_directory $build_directory"
    local -x LDFLAGS="$BI_RPATH_REL $LDFLAGS"

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
            "${source_directory}/configure" "${configure_options[@]}"
        elif [[ -f "${source_directory}/Configure" ]]; then
            "${source_directory}/Configure" "${configure_options[@]}"
        elif [[ -f "${source_directory}/bootstrap" ]]; then
            pushd "$source_directory" > /dev/null
            if ! "${source_directory}/bootstrap" "${configure_options[@]}"; then
                 "${source_directory}/bootstrap" --force
            fi
            popd > /dev/null
            if [[ -f "${source_directory}/configure" ]]; then
                "${source_directory}/configure" "${configure_options[@]}"
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
                "${source_directory}/configure" "${configure_options[@]}"
            fi
        fi
        # We should now make
        build_make "$name" "$source_directory" "" "$manifesting"
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
    local manifesting="${6}"
    # Debug print
    debug_print "(build_makeonly) Name $name; make_options $make_options; custom_maker $custom_maker"
    debug_print "                 source_directory $source_directory; build_directory $build_directory"
    local -x LDFLAGS="$BI_RPATH_REL $LDFLAGS"
    if [[ -n "$custom_maker" ]]; then
        $custom_maker
    fi
    build_make "$name" "$source_directory" "${make_options[@]}" "$manifesting"
}

make_target_exists() {
    local makefile
    for makefile in Makefile GNUmakefile; do
        [ -f "$makefile" ] || continue
        if grep -qE "^${1}:" "$makefile"; then
            return 0
        fi
    done
    return 1
}

build_make() {
    local name="${1}"
    local source_directory="${2}"
    local -a make_options
    make_options+=( "${(@es:;:)3}" )
    local manifesting="${4}"
    # Debug print
    debug_print "(build_make) Name $name; make_options $make_options"
    debug_print "             source_directory $source_directory"
    if [[ $INSTALL_COMMAND == "install" ]]; then
        status_print $name I "Patching"
        if [[ -f "${source_directory}/makefile" ]]; then
            mv "${source_directory}/makefile" "${source_directory}/Makefile"
        fi
        if [[ -f "${source_directory}/Makefile" ]]; then
            "${PATCH_SED_TOOL[@]}" "s|/usr/local|${INSTALL_PREFIX}${custom_prefix}|g" "$source_directory/Makefile"
        fi
        if [[ ! -f "Makefile" && ! -f "GNUmakefile" ]]; then
            cd "$source_directory"
        fi
        status_print $name I "Making"
        # Now attempt to make, if it fails try not concurrent
        $BUILD_MAKE_TOOL -j$CONCURRENT_JOBS "${make_options[@]}" || $BUILD_MAKE_TOOL
        # Remove old install
        uninstall_manifested "$name"
        create_premanifest "$name" "$manifesting"
        # Install the built utility
        if make_target_exists "install"; then
            status_print $name I "Installing"
            sudo $BUILD_MAKE_TOOL install "${make_options[@]}" || sudo $BUILD_MAKE_TOOL install
            status_print $name D "Install completed"
        fi
    elif [[ $INSTALL_COMMAND == "remove" ]]; then
        uninstall_manifested "$name"
    fi
}

no_build() {
    local name="${1}"
    local source_directory="${2}"
    local install_options
    install_options+=( "${(@es:;:)3}" )
    # We use alt_options for a script to install if available, otherwise name of directory under install prefix
    local install_script="${4}"
    # TODO maybe split this?
    local custom_directory="$install_script"
    local manifesting="${5}"
    # Debug print
    debug_print "(no_build) Name $name; install_options $install_options; install_script $install_script; "
    debug_print "           source_directory $source_directory; custom_directory $custom_directory"
    uninstall_manifested "$name"
    if [[ $INSTALL_COMMAND == "install" ]]; then
        create_premanifest "$name" "$manifesting"
        status_print $name I "Installing"
        if [[ -n "$install_script" || -n "$custom_directory" ]]; then
            if [[ ! -d "${source_directory}/${install_script}" && -x "${source_directory}/${install_script}" ]]; then
                # TODO some safety questions and checks
                sudo "${source_directory}/${install_script}" "${install_options[@]}"
            else
                if [[ ! -d "$INSTALL_PREFIX/${custom_directory}" ]]; then
                    sudo mkdir -p "$INSTALL_PREFIX/${custom_directory}"
                fi
                sudo cp -rPf "$source_directory"/* "$INSTALL_PREFIX/${custom_directory}/"
            fi
        else
            local count_files=( "$source_directory"/*(.N) )
            if (( ${#count_files} == 1 )); then
                if [[ ! -x "$count_files[1]" ]]; then
                    chmod +x "$count_files[1]"
                fi
                sudo cp -Pf "$count_files[1]" "$INSTALL_PREFIX/bin/"
            else
                local directories=(bin etc include lib libexec man sbin share)
                local directory
                local copied=0
                for directory in "${directories[@]}"; do
                    if [[ ! -d "$source_directory/$directory" ]]; then
                        sudo cp -rPf "$source_directory/$directory" "$INSTALL_PREFIX/"
                        copied=1
                    fi
                done
                if (( copied == 0 )); then
                    sudo mkdir -p "$INSTALL_PREFIX/share/$name"
                    sudo cp -rPf "$source_directory"/* "$INSTALL_PREFIX/share/$name/"
                fi
            fi
        fi
        status_print $name D "Install completed"
    fi
}
