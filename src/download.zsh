# Download routines

download() {
    local name="${1}"
    local cmd="${2}"
    local url="${3}"
    local dbr="${4:=main}"
    local sig="${5}"
    local strip="${6:=YES}"
    local name="${name%(_bootstrap|_stage_1|_stage_2|_stage_3)}"
    # Debug print
    debug_print "(download) Name $name; cmd $cmd; url $url; dbr $dbr; sig $sig; strip $strip"
    # TODO possibility for url to contain several alternatives
    status_print $name I "Download"
    case "$cmd" in
        https) download_https "$name" "$url" "$sig" "$strip" ;;
        git) download_git "$name" "$url" "$dbr" "$sig" ;;
        *) exit 9 ;;
    esac
}

download_git() {
    local name="${1}"
    local url="${2}"
    local branch="${3}"
    local hash="${4}"
    # Debug print
    debug_print "(download_git) Name $name; url $url; branch $branch; hash $hash"

    if [[ $INSTALL_COMMAND == "remove" ]]; then
        status_print $name I "Removing"
        rm -rf "${BUILD_SOURCES_DIRECTORY}/${name}"
        if [[ -f "${INSTALL_MANIFESTS}/${name}.old" ]]; then rm "${INSTALL_MANIFESTS}/${name}.old"; fi
        if [[ -f "${INSTALL_MANIFESTS}/${name}.current" ]]; then rm "${INSTALL_MANIFESTS}/${name}.current"; fi
        return
    fi

    if [[ ! -d "${BUILD_SOURCES_DIRECTORY}/${name}" ]]; then
        status_print $name I "Cloning"
        git clone --no-checkout "$url" "${BUILD_SOURCES_DIRECTORY}/${name}"
        git -C "${BUILD_SOURCES_DIRECTORY}/${name}" config --add remote.origin.fetch '^refs/heads/users/*'
        git -C "${BUILD_SOURCES_DIRECTORY}/${name}" config --add remote.origin.fetch '^refs/heads/revert-*'
        git -C "${BUILD_SOURCES_DIRECTORY}/${name}" checkout $branch
        git -C "${BUILD_SOURCES_DIRECTORY}/${name}" submodule update --init --recursive
        git -C "${BUILD_SOURCES_DIRECTORY}/${name}" checkout $hash
        status_print $name D "Cloning complete"
    else
        if git -C "${BUILD_SOURCES_DIRECTORY}/${name}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            status_print $name I "Updating"
            git -C "${BUILD_SOURCES_DIRECTORY}/${name}" reset --hard HEAD
            sudo git -C "${BUILD_SOURCES_DIRECTORY}/${name}" clean -x -f -f -d
            git -C "${BUILD_SOURCES_DIRECTORY}/${name}" checkout -f $branch
            git -C "${BUILD_SOURCES_DIRECTORY}/${name}" pull
            git -C "${BUILD_SOURCES_DIRECTORY}/${name}" checkout -f $hash
            status_print $name D "Update complete"
        else
            status_print $name I "Cleaning"
            rm -rf "${BUILD_SOURCES_DIRECTORY}/${name}"
            download_git "$1" "$2" "$3" "$4"
        fi
    fi

    git -C "${BUILD_SOURCES_DIRECTORY}/${name}" describe --always --match=HEAD --abbrev=0 > "${INSTALL_MANIFESTS}/${name}.current"
}

download_https() {
    local name="${1}"
    local url="${2}"
    local sig="${3}"
    local strip="${4}"
    local filename="${url:t}"
    # Debug print
    debug_print "(download_https) Name $name; url $url; sig $sig; strip $strip; filename $filename"

    if [[ $INSTALL_COMMAND == "remove" ]]; then
        status_print $name I "Removing"
        if [[ -f "${BUILD_SOURCES_DIRECTORY}/${filename}" ]]; then rm "${BUILD_SOURCES_DIRECTORY}/${filename}"; fi
        if [[ -f "${BUILD_SOURCES_DIRECTORY}/${name}" ]]; then rm "${BUILD_SOURCES_DIRECTORY}/${name}"; fi
        if [[ -d "${BUILD_SOURCES_DIRECTORY}/${name}" ]]; then rm -rf "${BUILD_SOURCES_DIRECTORY}/${name}"; fi
        if [[ -f "${INSTALL_MANIFESTS}/${filename}.etag" ]]; then rm "${INSTALL_MANIFESTS}/${filename}.etag"; fi
        if [[ -f "${INSTALL_MANIFESTS}/${name}.old" ]]; then rm "${INSTALL_MANIFESTS}/${name}.old"; fi
        if [[ -f "${INSTALL_MANIFESTS}/${name}.current" ]]; then rm "${INSTALL_MANIFESTS}/${name}.current"; fi
        return
    fi

    status_print $name I "Downloading"
    local -i attempt curl_code
    for attempt in 1 2 3; do
        curl -sL \
            --etag-compare "${INSTALL_MANIFESTS}/${filename}.etag" \
            --etag-save "${INSTALL_MANIFESTS}/${filename}.etag" \
            -o "${BUILD_SOURCES_DIRECTORY}/${filename}" \
            "${url}" && break
        curl_code=$?
        if (( attempt == 3 )); then
            return $curl_code
        fi
        status_print $name W "Retrying $attempt ($curl_code)"
        sleep 2
    done

    sha512 -q "${BUILD_SOURCES_DIRECTORY}/${filename}" > "${INSTALL_MANIFESTS}/${name}.current"

    # TODO check signatures

    status_print $name D "Download complete"
    extract "$name" "$filename" "$strip"
}

# Extract routines

extract() {
    local name="${1}"
    local filename="${2}"
    local strip="${3}"
    # Debug print
    debug_print "(extract) Name $name; filename $filename; strip $strip"

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
    status_print $name I "Extracting"
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
    elif [[ " $(file --brief --mime-type "${BUILD_SOURCES_DIRECTORY}/${filename}") " == " application/x-mach-binary " ]]; then
        print -u2 "${filename} is a binary executable"
        if [[ -d "${BUILD_SOURCES_DIRECTORY}/${name}" ]]; then
            rm -rf "${BUILD_SOURCES_DIRECTORY}/${name}"
        fi
        mkdir -p "${BUILD_SOURCES_DIRECTORY}/${name}"
        cp -Pf "${BUILD_SOURCES_DIRECTORY}/${filename}" "${BUILD_SOURCES_DIRECTORY}/${name}/"
    else
        print -u2 "Unknown mime-type for <$filename>: $(file --brief --mime-type "${BUILD_SOURCES_DIRECTORY}/${filename}")"
        exit 4
    fi
    status_print $name D "Extracting complete"
}
