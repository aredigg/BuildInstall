# Custom patches to ensure correct operations on macOS

# System setup
platform_setup() {
    MACOS_SDK_PATH="$(xcrun --show-sdk-path)"
    export MACOSX_DEPLOYMENT_TARGET="$(xcrun --show-sdk-platform-version)"
    export JAVA_HOME=$(java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home' | awk '{print $3}')
    local cpus="$(getconf _NPROCESSORS_ONLN)"
    CONCURRENT_JOBS=$(( $cpus + $cpus >> 1))
    # metal toolchain
    if ! xcrun --find metal >/dev/null 2>&1; then
        xcodebuild -downloadComponent MetalToolchain
        sudo xcodebuild -downloadComponent MetalToolchain
    fi
}

# Custom pkg-config files for the builtins
install_builtin_pkgconf() {
    pkgconf_zlib
    pkgconf_xml2
    pkgconf_ffi
    pkgconf_ncurses
    pkgconf_ncursesw
    pkgconf_iconv
}

pkgconf_zlib() {
    if [[ $INSTALL_COMMAND == "install" ]]; then
        if [[ ! -f "$INSTALL_PREFIX/lib/pkgconfig/zlib.pc" && -f "$MACOS_SDK_PATH/usr/lib/libz.tbd" ]]; then  
            local version=$(
                awk -F': *' '
                    $1 == "current-version" {
                        gsub(/'\''|"/, "", $2)
                        print $2
                        exit
                    }
                ' "$MACOS_SDK_PATH/usr/lib/libz.tbd"
            )

            sudo tee "$INSTALL_PREFIX/lib/pkgconfig/zlib.pc" > /dev/null << EOF
prefix=$MACOS_SDK_PATH/usr
exec_prefix=\${prefix}
bindir=$MACOS_SDK_PATH/usr/bin
libdir=$MACOS_SDK_PATH/usr/lib
includedir=$MACOS_SDK_PATH/usr/include

Name: zlib
Description: Compression library
Version: $version
Libs: -L\${libdir} -lz
Cflags: -I\${includedir}
EOF
        fi
    fi
}

pkgconf_xml2() {
    if [[ $INSTALL_COMMAND == "install" ]]; then
        if [[ ! -f "$INSTALL_PREFIX/lib/pkgconfig/libxml-2.0.pc" && -f "$MACOS_SDK_PATH/usr/lib/libxml2.tbd" ]]; then  
            local version=$(
                awk -F': *' '
                    $1 == "current-version" {
                        gsub(/'\''|"/, "", $2)
                        print $2
                        exit
                    }
                ' "$MACOS_SDK_PATH/usr/lib/libxml2.tbd"
            )

            sudo tee "$INSTALL_PREFIX/lib/pkgconfig/libxml-2.0.pc" > /dev/null << EOF
prefix=$MACOS_SDK_PATH/usr
exec_prefix=$MACOS_SDK_PATH/usr
bindir=$MACOS_SDK_PATH/usr/bin
libdir=$MACOS_SDK_PATH/usr/lib
includedir=$MACOS_SDK_PATH/usr/include

Name: libXML
Description: XML toolkit version 2
Version: $version
Libs: -L\${libdir} -lxml2
Libs.private: -lz -lpthread -licucore -lm
Cflags: -I\${includedir}
EOF
        fi
    fi
}

pkgconf_ffi() {
    if [[ $INSTALL_COMMAND == "install" ]]; then
        if [[ ! -f "$INSTALL_PREFIX/lib/pkgconfig/libffi.pc" && -f "$MACOS_SDK_PATH/usr/lib/libffi.tbd" ]]; then  
            local version=$(
                awk -F': *' '
                    $1 == "current-version" {
                        gsub(/'\''|"/, "", $2)
                        print $2
                        exit
                    }
                ' "$MACOS_SDK_PATH/usr/lib/libffi.tbd"
            )

            sudo tee "$INSTALL_PREFIX/lib/pkgconfig/libffi.pc" > /dev/null << EOF
prefix=$MACOS_SDK_PATH/usr
exec_prefix=$MACOS_SDK_PATH/usr
bindir=$MACOS_SDK_PATH/usr/bin
libdir=$MACOS_SDK_PATH/usr/lib
includedir=$SDK_PATH/usr/include/ffi

Name: libffi
Description: Library supporting Foreign Function Interfaces
Version: $version
Libs: -L\${libdir} -lffi
Cflags: -I\${includedir}
EOF
        fi
    fi
}

pkgconf_ncurses() {
    if [[ $INSTALL_COMMAND == "install" ]]; then
        if [[ ! -f "$INSTALL_PREFIX/lib/pkgconfig/ncurses.pc" && -f "$MACOS_SDK_PATH/usr/lib/libncurses.tbd" ]]; then  
            local version=$(
                awk -F': *' '
                    $1 == "current-version" {
                        gsub(/'\''|"/, "", $2)
                        print $2
                        exit
                    }
                ' "$MACOS_SDK_PATH/usr/lib/libncurses.tbd"
            )

            sudo tee "$INSTALL_PREFIX/lib/pkgconfig/ncurses.pc" > /dev/null << EOF
prefix=$MACOS_SDK_PATH/usr
exec_prefix=$MACOS_SDK_PATH/usr
bindir=$MACOS_SDK_PATH/usr/bin
libdir=$MACOS_SDK_PATH/usr/lib
includedir=$SDK_PATH/usr/include

Name: ncurses
Description: Free software emulation of curses
Version: $version
Libs: -L\${libdir} -lncurses
Cflags: -I\${includedir}
EOF
        fi
    fi
}

pkgconf_ncursesw() {
    if [[ $INSTALL_COMMAND == "install" ]]; then
        if [[ ! -f "$INSTALL_PREFIX/lib/pkgconfig/ncursesw.pc" && -f "$MACOS_SDK_PATH/usr/lib/libncurses.tbd" ]]; then  
            local version=$(
                awk -F': *' '
                    $1 == "current-version" {
                        gsub(/'\''|"/, "", $2)
                        print $2
                        exit
                    }
                ' "$MACOS_SDK_PATH/usr/lib/libncurses.tbd"
            )

            sudo tee "$INSTALL_PREFIX/lib/pkgconfig/ncursesw.pc" > /dev/null << EOF
prefix=$MACOS_SDK_PATH/usr
exec_prefix=$MACOS_SDK_PATH/usr
bindir=$MACOS_SDK_PATH/usr/bin
libdir=$MACOS_SDK_PATH/usr/lib
includedir=$SDK_PATH/usr/include

Name: ncursesw
Description: Free software emulation of curses
Version: $version
Libs: -L\${libdir} -lncurses
Cflags: -I\${includedir}
EOF
        fi
    fi
}

pkgconf_iconv() {
    if [[ $INSTALL_COMMAND == "install" ]]; then
        if [[ ! -f "$INSTALL_PREFIX/lib/pkgconfig/iconv.pc" && -f "$MACOS_SDK_PATH/usr/lib/libiconv.tbd" ]]; then  
            local version=$(
                awk -F': *' '
                    $1 == "current-version" {
                        gsub(/'\''|"/, "", $2)
                        print $2
                        exit
                    }
                ' "$MACOS_SDK_PATH/usr/lib/libiconv.tbd"
            )

            sudo tee "$INSTALL_PREFIX/lib/pkgconfig/iconv.pc" > /dev/null << EOF
prefix=$MACOS_SDK_PATH/usr
exec_prefix=$MACOS_SDK_PATH/usr
bindir=$MACOS_SDK_PATH/usr/bin
libdir=$MACOS_SDK_PATH/usr/lib
includedir=$SDK_PATH/usr/include

Name: iconv
Description: Character set conversion library
Version: $version
Libs: -L\${libdir} -liconv
Cflags: -I\${includedir}
EOF
        fi
    fi
}

pkgconf_omp() {
    if [[ $INSTALL_COMMAND == "install" ]]; then
        if [[ ! -f "$INSTALL_PREFIX/lib/pkgconfig/libomp.pc" ]]; then  
            sudo tee "$INSTALL_PREFIX/lib/pkgconfig/libomp.pc" > /dev/null << EOF            
prefix=$INSTALL_PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libomp
Description: OpenMP Library for Apple Clang
Version: 1.0
Libs: -L\${libdir} -lomp
Cflags: -I\${includedir} -Xpreprocessor -fopenmp
EOF
        fi
    fi
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
        pkgconf)
            install_builtin_pkgconf
            sudo ln -sf $INSTALL_PREFIX/bin/pkgconf $INSTALL_PREFIX/bin/pkg-config
            sudo ln -sf $INSTALL_PREFIX/share/man/man1/pkgconf $INSTALL_PREFIX/share/man/man1/pkg-config.1
            ;;
        libomp)
            pkgconf_omp ;;
    esac
}
