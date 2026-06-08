# Custom patches to ensure correct operations on macOS

# System setup
platform_setup() {
    MACOS_SDK_PATH="$(xcrun --show-sdk-path)"
    export MACOSX_DEPLOYMENT_TARGET="$(xcrun --show-sdk-platform-version)"
    local cpus="$(getconf _NPROCESSORS_ONLN)"
    CONCURRENT_JOBS=$(( $cpus + $cpus >> 1))
    debug_print "MacOS SDK <$MACOS_SDK_PATH> <$MACOSX_DEPLOYMENT_TARGET> Job target <$CONCURRENT_JOBS>"
}

# Patches applied after download, before build/install
pre_patch() {
    name="${1}"
}

# Patches applied after build/install
post_patch() {
    name="${1}"
    case "$name" in
        libtool)
            export LIBTOOLIZE="gnulibtoolize" ;;
    esac
}
