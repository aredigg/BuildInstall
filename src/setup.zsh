# Setup routines

usage() {
    printf "\
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
    -a, --archive   Create tar.xz archives of the built install
    -n, --nocolor   Plain output
$1"
    if [[ -n $1 ]]; then
        exit 1
    else
        exit 0
    fi
}

parse() {
    local valid_commands=("install" "download" "print" "remove" "help" "version")
    declare -A opts
    opts[-p]="$BI_SYSTEM_PREFIX"
    zparseopts -A opts -D -E -F -K \
        h -help=h \
        v -verbose=v \
        d -debug=d \
        p: -prefix:=p \
        a -archive=a \
        u: -utility:=u \
        n -nocolor=n \
        2>/dev/null || usage "ERROR: Invalid option entered or missing argument\n"
    print "command = <$1>"
    print "options = <${(k)opts}>"
    print "remaining = <$@>"
    INSTALL_PREFIX="${opts[-p]#=}"
    if [[ -v opts[-h] || $1 = "help" ]]; then
        usage
    fi
    if [[ $# -eq 1 ]]; then
        INSTALL_COMMAND="$1"
    else
        usage "ERROR: Invalid or missing command\n"
    fi
    if [[ $INSTALL_COMMAND = "version" ]]; then
        print "$BI_VERSION"
        exit 0
    fi
    if [[ -v opts[-d] ]]; then
        DEBUG=ON
    else
        DEBUG=OFF
    fi
    if [[ -v opts[-v] ]]; then
        VERBOSE=ON
    else
        VERBOSE=OFF
    fi
    if [[ -v opts[-n] ]]; then
        PLAIN_OUTPUT=ON
    else
        PLAIN_OUTPUT=OFF
    fi
    if [[ -v opts[-u] ]]; then
        INSTALL_UTILITY="${opts[-u]#=}"
    fi
}

setup() {
}
