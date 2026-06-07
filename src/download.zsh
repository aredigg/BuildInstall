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
    case "$cmd" in
        https) download_https "$name" "$url" "$sig" "$strip" ;;
    esac
}

download_https() {
    local name="${1}"
    local url="${2}"
    local sig="${3}"
    local strip="${4}"
    local filename="${url:t}"
    debug_print "Downloading <$name> using https"

    if [[ $INSTALL_COMMAND == "remove" ]]; then
        if [[ -f "${BUILD_SOURCES_DIRECTORY}/${filename}" ]]; then rm "${BUILD_SOURCES_DIRECTORY}/${filename}"; fi
        if [[ -f "${BUILD_SOURCES_DIRECTORY}/${name}" ]]; then rm "${SOURCES_DIRECTORY}/${name}"; fi
        if [[ -d "${BUILD_SOURCES_DIRECTORY}/${name}" ]]; then rm -rf "${BUILD_SOURCES_DIRECTORY}/${name}"; fi
        if [[ -f "${INSTALL_MANIFESTS}/${filename}.etag" ]]; then rm "${INSTALL_MANIFESTS}/${filename}.etag"; fi
        debug_print "Removed downloaded artifacts"
        return
    fi

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

