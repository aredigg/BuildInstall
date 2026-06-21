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
    export BI_RPATH_NODIST="-Wl,-rpath,${INSTALL_PREFIX}/lib"
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
    source_directory="${2}"
    case "$name" in
        openssl)
            # There is also /System/Library/OpenSSL
            if [[ ! -f "$INSTALL_PREFIX/ssl/certs/cert.pem" ]]; then
                /usr/bin/security export -k /System/Library/Keychains/SystemRootCertificates.keychain -t certs -p  > "$source_directory/keychain_root_certs.pem"
                sudo mkdir -p "$INSTALL_PREFIX/ssl/certs"
                sudo cp "$source_directory/keychain_root_certs.pem" "$INSTALL_PREFIX/ssl/certs/cert.pem"
            fi
            ;;
        curl)
            sed -i '' "s|\[unreleased\]|$(date '+%Y-%m-%d') \(Unsupported\)|g" "$source_directory/include/curl/curlver.h" ;;
        helix)
            export HELIX_DEFAULT_RUNTIME="$INSTALL_PREFIX/libexec/helix/runtime" ;;
        fontconfig)
            local ASSETS_V2_FONTS=(/System/Library/AssetsV2/com_apple_MobileAsset_Font*(N))
            local ASSETS_FONTS=(/System/Library/Assets/com_apple_MobileAsset_Font*(N))
            local FONTS=(
                /System/Library/Fonts
                /Library/Fonts
                "$HOME/Library/Fonts"
                ${ASSETS_V2_FONTS[@]}
                ${ASSETS_FONTS[@]}
            )
            export FONTCONFIG_FONTS_DIRS="${(j:,:)FONTS}"
            ;;
        gettext)
            export am_cv_func_iconv_works=yes
            ;;
        pkgconf)
            local f="$source_directory/libpkgconf/fragment.c"
            if [[ -f "$f" ]] && ! grep -q 'xlocale.h' "$f"; then
                # Darwin: make nl_langinfo_l visible under -std=c99
                sed -i '' '1i\
#if defined(__APPLE__)\
#include <xlocale.h>\
#endif
' "$f"
            fi
            ;;
   esac
}

# Patches applied after build/install
post_patch() {
    name="${1}"
    case "$name" in
        libtool)
            export LIBTOOLIZE="gnulibtoolize"
            sudo ln -sf $INSTALL_PREFIX/bin/gnulibtoolize $INSTALL_PREFIX/bin/libtoolize
            ;;
        pkgconf)
            install_builtin_pkgconf
            sudo ln -sf $INSTALL_PREFIX/bin/pkgconf $INSTALL_PREFIX/bin/pkg-config
            sudo ln -sf $INSTALL_PREFIX/share/man/man1/pkgconf $INSTALL_PREFIX/share/man/man1/pkg-config.1
            ;;
        libomp)
            pkgconf_omp ;;
        cpython)
            export PATH="/Library/Frameworks/Python.framework/Versions/Current/bin:$PATH"
            export SSL_CERT_DIR="$INSTALL_PREFIX/ssl/certs"
            export PKG_CONFIG_PATH="/Library/Frameworks/Python.framework/Versions/Current/lib/pkgconfig:$PKG_CONFIG_PATH"
            export PYTHON_EXEC="$INSTALL_PREFIX/bin/python3"
            ;;
        ohmyposh)
            sudo mv "$INSTALL_PREFIX/bin/posh-darwin-arm64" "$INSTALL_PREFIX/bin/oh-my-posh"
            ;;
        helix)
            rm -rf "$source_directory/runtime/grammars/sources/"
            sudo cp -rPf $source_directory/runtime $INSTALL_PREFIX/libexec/helix/
            ;;
        vhdl_ls)
            sudo mkdir -p $INSTALL_PREFIX/lib/rust_hdl/
            sudo cp -rPf $source_directory/vhdl_libraries $INSTALL_PREFIX/lib/rust_hdl/vhdl_libraries
            ;;
    esac
}
