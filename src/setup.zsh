# Setup routines

usage() {
    print -u 2 -f "\
Usage: $BI_SCRIPT command [options]
BuildInstall is an install script for building and installing various utilities
Commands
    install    Install all tools and utilities
    download   Download and extract only
    print      Print a list of installed tools and utilities
    remove     Remove all tools and utilities
    version    Display the current version of this script
Options
    -h, --help      Show this help and exit
    -d, --debug     Turn on debug output
    -p, --prefix    Custom install prefix (Default $BI_SYSTEM_PREFIX)
    -u, --utility   Install, remove or print only the selected utility
    -t, --temp      Temporary directory for downloads and build artifacts (Default $BI_SYSTEM_TMP)
    -m, --manifest  Directory where manifest files are stored (Default $BI_SYSTEM_TMP/bi/manifests)
    -a, --archive   Create tar.xz archives of the built install
    -f, --from      Alternative csv file containg list of utilities  
    -n, --nocolor   Plain output
$1"
    if [[ -n $1 ]]; then
        exit 1
    fi
    exit 0
}

parse() {
    local valid_commands=("install" "download" "print" "remove" "help" "version")
    declare -A opts
    opts[-p]="$BI_SYSTEM_PREFIX"
    opts[-t]="$BI_SYSTEM_TMP"
    opts[-m]="$BI_SYSTEM_TMP/bi/manifests"
    opts[-f]=""
    zparseopts -A opts -D -E -F -K \
        h -help=h \
        v -verbose=v \
        d -debug=d \
        p: -prefix:=p \
        a -archive=a \
        u: -utility:=u \
        t: -temp:=t \
        m: -manifest:=m \
        f: -from:=f \
        n -nocolor=n \
        2>/dev/null || usage "ERROR: Invalid option entered or missing argument\n"
    # print "command = <$1>"
    # print "options = <${(k)opts}>"
    # print "remaining = <$@>"

    # Set the install prefix
    INSTALL_PREFIX="${opts[-p]#=}"

    # Display usage
    if [[ -v opts[-h] || $1 = "help" ]]; then
        usage
    fi

    # Check that we have a install command
    if [[ $# -eq 1 ]]; then
        INSTALL_COMMAND="$1"
    else
        usage "ERROR: Invalid or missing command\n"
    fi

    # Display version
    if [[ $INSTALL_COMMAND = "version" ]]; then
        print "$BI_VERSION"
        exit 0
    fi

    # Turn on debug if requested
    if [[ -v opts[-d] ]]; then
        DEBUG=ON
    else
        DEBUG=OFF
    fi

    # Store archives of install
    if [[ -v opts[-a] ]]; then
        INSTALL_ARCHIVE=ON
    else
        INSTALL_ARCHIVE=OFF
    fi

    # Different temp directory
    INSTALL_TEMP="${opts[-t]#=}"

    # Different manifest directory
    INSTALL_MANIFESTS="${opts[-m]#=}"

    # Different utilities file
    INSTALL_UTILITIES_FILE="${opts[-f]#=}"

    # Turn on verbose mode
    if [[ -v opts[-v] ]]; then
        VERBOSE=ON
    else
        VERBOSE=OFF
    fi

    # If requested to not output "fancy" colors
    if [[ -v opts[-n] ]]; then
        PLAIN_OUTPUT=ON
    else
        PLAIN_OUTPUT=OFF
    fi

    # If single utility is requested
    if [[ -v opts[-u] ]]; then
        INSTALL_UTILITY="${opts[-u]#=}"
    fi
}

setup() {
    # Assert that we have an install command
    if [[ ! -n INSTALL_COMMAND ]]; then
        print -u2 "ERROR: Missing install command"
        exit 2
    fi

    # Custom settings for specific systems
    INSTALL_SYSTEM=$(uname)
    if [[ -f "$BI_DIRECTORY/src/$INSTALL_SYSTEM/patch.zsh" ]]; then
        source "$BI_DIRECTORY/src/$INSTALL_SYSTEM/patch.zsh"
        platform_setup
    else
        print -u 2 "ERROR: Not on a supported system"
        exit 2
    fi
    # Check that the csv file exists
    if [[ ! -n "$INSTALL_UTILITIES_FILE" ]]; then
        INSTALL_UTILITIES_FILE="$BI_DIRECTORY/src/$INSTALL_SYSTEM/$BI_SYSTEM_FILE"
    fi
    if [[ ! -f "$INSTALL_UTILITIES_FILE" ]]; then
        print -u2 "ERROR: Missing $INSTALL_UTILITIES_FILE"
        exit 2
    fi

    # Setup directories
    BUILD_SOURCES_DIRECTORY="${INSTALL_TEMP}/bi/sources"
    BUILD_BUILDS_DIRECTORY="${INSTALL_TEMP}/bi/builds"
    BUILD_LOGS_DIRECTORY="${INSTALL_TEMP}/bi/logs"
    INSTALL_ARCHIVES="${INSTALL_TEMP}/bi/archives"
    mkdir -p \
        "$BUILD_SOURCES_DIRECTORY" \
        "$BUILD_BUILDS_DIRECTORY" \
        "$BUILD_LOGS_DIRECTORY" \
        "$INSTALL_ARCHIVES" \
        "$INSTALL_MANIFESTS"
    BUILD_LOG_OUT="${BUILD_LOGS_DIRECTORY}/out.log"
    BUILD_LOG_ERR="${BUILD_LOGS_DIRECTORY}/err.log"
    # Check if we have gnumake
    BUILD_MAKE_TOOL="make"
    if command -v gnumake >/dev/null 2>&1; then
        BUILD_MAKE_TOOL="gnumake"
    fi
    # Redirect standard out and error
    exec >"$BUILD_LOG_OUT" 2>"$BUILD_LOG_ERR"
    # We need sudo access to install
    sudo -K
    sudo -vp "Please enter password to allow system install: "
    # Keep sudo alive
    { while kill -O "$BI_SCRIPT_PID" 2>/dev/null; do sudo -nv || exit; sleep 60 || exit; done 2>/dev/null & }
    BI_SUDO_PID=$!
    # Print script starttime into the logs
    TZ=UTC strftime -s timefmt '%Y-%m-%d %H:%M:%S' "$BI_STARTTIME"
    print -ru1 $timefmt
    print -ru2 $timefmt
}

