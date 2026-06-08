# Download routines

download() {
    local name="${1}"
    local cmd="${2}"
    local url="${3}"
    local dbr="${4:=main}"
    local sig="${5}"
    local strip="${6:=YES}"
    local name="${name%(_bootstrap|_stage_1|_stage_2|_stage_3)}"
    debug_print "Entering download <$name>"
    # TODO possibility for url to contain several alternatives
    case "$cmd" in
        https) download_https "$name" "$url" "$sig" "$strip" ;;
        git) download_git "$name" "$url" "$dbr" "$sig"
    esac
}

download_git() {
    local name="${1}"
    local url="${2}"
    local branch="${3}"
    local hash="${4}"

    if [[ $INSTALL_COMMAND == "remove" ]]; then
        rm -rf "${BUILD_SOURCES_DIRECTORY}/${name}"
        debug_print "Removed downloaded artifacts"
        return
    fi

    debug_print "Downloading <$name> using git"

    if [[ ! -d "${BUILD_SOURCES_DIRECTORY}/${name}" ]]; then
        debug_print "Cloning into <$url> <$branch> <$hash>"
        git clone  --no-checkout "$url" "${BUILD_SOURCES_DIRECTORY}/${name}"
        git -C "${BUILD_SOURCES_DIRECTORY}/${name}" config --add remote.origin.fetch '^refs/heads/users/*'
        git -C "${BUILD_SOURCES_DIRECTORY}/${name}" config --add remote.origin.fetch '^refs/heads/revert-*'
        git -C "${BUILD_SOURCES_DIRECTORY}/${name}" checkout $branch
        git -C "${BUILD_SOURCES_DIRECTORY}/${name}" submodule update --init --recursive
        git -C "${BUILD_SOURCES_DIRECTORY}/${name}" checkout $hash
    else
        if git -C "${BUILD_SOURCES_DIRECTORY}/${name}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            debug_print "Git tree exists, updating if necessary"
            git -C "${BUILD_SOURCES_DIRECTORY}/${name}" reset --hard HEAD
            git -C "${BUILD_SOURCES_DIRECTORY}/${name}" clean -x -f -f -d
            git -C "${BUILD_SOURCES_DIRECTORY}/${name}" checkout -f $branch
            git -C "${BUILD_SOURCES_DIRECTORY}/${name}" pull
            git -C "${BUILD_SOURCES_DIRECTORY}/${name}" checkout -f $hash
        else
            debug_print "No git tree, cleaning up"
            rm -rf "${BUILD_SOURCES_DIRECTORY}/${name}"
            download_git "$1" "$2" "$3" "$4"
        fi
    fi

    debug_print "Git download completed"
}

download_https() {
    local name="${1}"
    local url="${2}"
    local sig="${3}"
    local strip="${4}"
    local filename="${url:t}"

    if [[ $INSTALL_COMMAND == "remove" ]]; then
        if [[ -f "${BUILD_SOURCES_DIRECTORY}/${filename}" ]]; then rm "${BUILD_SOURCES_DIRECTORY}/${filename}"; fi
        if [[ -f "${BUILD_SOURCES_DIRECTORY}/${name}" ]]; then rm "${SOURCES_DIRECTORY}/${name}"; fi
        if [[ -d "${BUILD_SOURCES_DIRECTORY}/${name}" ]]; then rm -rf "${BUILD_SOURCES_DIRECTORY}/${name}"; fi
        if [[ -f "${INSTALL_MANIFESTS}/${filename}.etag" ]]; then rm "${INSTALL_MANIFESTS}/${filename}.etag"; fi
        if [[ -f "${INSTALL_MANIFESTS}/${filename}.old" ]]; then rm "${INSTALL_MANIFESTS}/${filename}.old"; fi
        if [[ -f "${INSTALL_MANIFESTS}/${filename}.current" ]]; then rm "${INSTALL_MANIFESTS}/${filename}.current"; fi
        debug_print "Removed downloaded artifacts"
        return
    fi

    debug_print "Downloading <$name> using https"

    debug_print "Starting download of <$filename>"
    curl -sL \
        --etag-compare "${INSTALL_MANIFESTS}/${filename}.etag" \
        --etag-save "${INSTALL_MANIFESTS}/${filename}.etag" \
        -o "${BUILD_SOURCES_DIRECTORY}/${filename}" \
        "${url}"
    debug_print "Completed download of file"

    sha512 -q "${BUILD_SOURCES_DIRECTORY}/${filename}" > "${INSTALL_MANIFESTS}/${name}.current"

    # TODO check signatures

    extract "$name" "$filename" "$strip"
    debug_print "Download completed"
}

# Extract routines

extract() {
    local name="${1}"
    local filename="${2}"
    local strip="${3}"
    local mime_types=(
        "application/x-gzip"            # .gz
        "application/gzip"              # .gz
        "application/zip"               # .zip
        "application/x-bzip2"           # .bz2
        "application/x-xz"              # .xz
        "application/x-compress"        # .Z
        "application/x-tar"             # .tar
        "application/x-rar"             # .rar
        "application/x-7z-compressed"   # .7z
        "application/x-lzip"            # .lz
    )
    debug_print "Extracting <$name> from downloaded archive <$filename>"
    if [[ " ${mime_types[@]} " =~ " $(file --brief --mime-type "${BUILD_SOURCES_DIRECTORY}/${filename}") " ]]; then
        if [[ -d "${BUILD_SOURCES_DIRECTORY}/${name}" ]]; then
            rm -rf "${BUILD_SOURCES_DIRECTORY}/${name}"
        fi
        mkdir -p "${BUILD_SOURCES_DIRECTORY}/${name}"
        if [[ "$strip" == "YES" ]]; then
            tar xf "${BUILD_SOURCES_DIRECTORY}/${filename}" -C "${BUILD_SOURCES_DIRECTORY}/${name}" --strip-components=1
        else
            tar xf "${BUILD_SOURCES_DIRECTORY}/${filename}" -C "${BUILD_SOURCES_DIRECTORY}/${name}"
        fi
    else
        debug_print "Unknown mime-type for <$filename>: $(file --brief --mime-type "${BUILD_SOURCES_DIRECTORY}/${filename}")"
    fi
    debug_print "Completed extraction"
}

