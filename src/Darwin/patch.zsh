# Custom patches to ensure correct operations on macOS

# System setup
platform_setup() {
    export PATH="$INSTALL_PREFIX/bin:$PATH"
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
    export BI_RPATH_NODIST="-Wl,-rpath,$INSTALL_PREFIX/lib"
    export BI_RPATH_REL="-Wl,-rpath,@loader_path/../lib"
    export BI_RPATH_CMAKE='-DCMAKE_INSTALL_RPATH=@loader_path/../lib'

    export PYTHON_EXEC="$(command -v python3)"
    export OPENSSL_DIR="$(openssl version -d | sed 's/.*"\(.*\)"/\1/')"
    export SSL_CERT_DIR="$OPENSSL_DIR"
}

platform_setup_debug() {
    debug_print "Initial Platform Setup"
    debug_print "  Path $PATH"
    debug_print "  SDK Path $MACOS_SDK_PATH"
    debug_print "  Reported Deployment Target $MACOSX_DEPLOYMENT_TARGET"
    debug_print "  Java Home $JAVA_HOME"
    debug_print "  Jobs $CONCURRENT_JOBS"
    debug_print "  Python $PYTHON_EXEC"
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
includedir=$MACOS_SDK_PATH/usr/include/ffi

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
includedir=$MACOS_SDK_PATH/usr/include

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
includedir=$MACOS_SDK_PATH/usr/include

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
includedir=$MACOS_SDK_PATH/usr/include

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

# Still some larger patches

patch_ffmpeg() {
    git apply - <<'PATCH'

diff --git a/libavfilter/af_asr.c b/libavfilter/af_asr.c
index 8e8eeb19a7..bba793cfb5 100644
--- a/libavfilter/af_asr.c
+++ b/libavfilter/af_asr.c
@@ -41,7 +41,7 @@ typedef struct ASRContext {
     char *logfn;

     ps_decoder_t *ps;
-    cmd_ln_t *config;
+    ps_config_t *config;

     int utt_started;
 } ASRContext;
@@ -100,16 +100,16 @@ static av_cold int asr_init(AVFilterContext *ctx)
     ASRContext *s = ctx->priv;
     const float frate = s->rate;
     char *rate = av_asprintf("%f", frate);
-    const char *argv[] = { "-logfn",    s->logfn,
-                           "-hmm",      s->hmm,
-                           "-lm",       s->lm,
-                           "-lmctl",    s->lmctl,
-                           "-lmname",   s->lmname,
-                           "-dict",     s->dict,
-                           "-samprate", rate,
-                           NULL };
-
-    s->config = cmd_ln_parse_r(NULL, ps_args(), 14, (char **)argv, 0);
+
+    s->config = ps_config_init(NULL);
+    ps_config_set_str(s->config, "logfn", s->logfn);
+    ps_config_set_str(s->config, "hmm", s->hmm);
+    ps_config_set_str(s->config, "lm", s->lm);
+    ps_config_set_str(s->config, "lmctl", s->lmctl);
+    ps_config_set_str(s->config, "lmname", s->lmname);
+    ps_config_set_str(s->config, "dict", s->dict);
+    ps_config_set_str(s->config, "samprate", rate);
+
     av_free(rate);
     if (!s->config)
         return AVERROR(ENOMEM);
@@ -160,7 +160,7 @@ static av_cold void asr_uninit(AVFilterContext *ctx)

     ps_free(s->ps);
     s->ps = NULL;
-    cmd_ln_free_r(s->config);
+    ps_config_free(s->config);
     s->config = NULL;
 }

PATCH
}

# TODO combine these functions with the manifest

strip_build_rpath() {
    local file="$1"
    local build_directory="$2"
    debug_print "(strip_build_rpath) File $file"
    debug_print "                    build_directory $build_directory"
    file --brief --mime-type "$file" 2>/dev/null | grep -q application/x-mach-binary || return 0
    if otool -l "$file" 2>/dev/null | grep -q "path ${build_directory} "; then
        sudo install_name_tool -delete_rpath "$build_directory" "$file" 2>/dev/null || true
    fi
}

add_rpath_prefix() {
    local file="$1"
    debug_print "(add_rpath_prefix) File $file"
    file --brief --mime-type "$file" 2>/dev/null | grep -q application/x-mach-binary || return 0
    for entry in $(otool -L "$file" | awk 'NR>1{print $1}'); do
        if [[ $entry != /* && $entry != @* ]]; then
            sudo install_name_tool -change "$entry" "@rpath/$entry" "$file"
        fi
    done
}

add_rpath() {
    local file="$1"
    debug_print "(add_rpath) File $file"
    file --brief --mime-type "$file" 2>/dev/null | grep -q application/x-mach-binary || return 0
    if ! otool -l "$file" 2>/dev/null | grep -q 'path @loader_path/../lib '; then
        sudo install_name_tool -add_rpath @loader_path/../lib "$file" 2>/dev/null || true
    fi
}

platform_cargo() {
    mkdir -p "$HOME/.cargo"
    cat > "$HOME/.cargo/config.toml" <<'EOF'
[target.aarch64-apple-darwin]
rustflags = [
    "-C", "rpath=true",
    "-C", "link-arg=-Wl,-rpath,@loader_path/../lib",
]
EOF
}

# Patches applied after download, before build/install
pre_patch() {
    name="${1}"
    source_directory="${2}"
    build_directory="${3}"
    case "$name" in
        curl)
            "${PATCH_SED_TOOL[@]}" "s|\[unreleased\]|$(date '+%Y-%m-%d') \(Unsupported\)|g" "$source_directory/include/curl/curlver.h" ;;
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
                "${PATCH_SED_TOOL[@]}" '1i\
#if defined(__APPLE__)\
#include <xlocale.h>\
#endif
' "$f"
            fi
            ;;
        lame)
            "${PATCH_SED_TOOL[@]}" "/lame_init_old/d" "$source_directory/include/libmp3lame.sym"
            curl -fsSL https://tmkk.undo.jp/lame/lame/lame-3.100-neon-20230418.diff | patch -ruN -d "$source_directory" -p0
            ;;
        flite)
            "${PATCH_SED_TOOL[@]}" "s|/proc/cpuinfo|/dev/null|g" "$source_directory/configure"
            "${PATCH_SED_TOOL[@]}" "s|/proc/cpuinfo|/dev/null|g" "$source_directory/configure.in"
            ;;
        rubberband)
            "${PATCH_SED_TOOL[@]}" '/#define RUBBERBAND_MATHMISC_H/a\
#include <cstddef>
' "$source_directory/src/common/mathmisc.h"
            ;;
        shine)
            "${PATCH_SED_TOOL[@]}" "s|-export-symbols libshine.sym|-export-symbols $source_directory/libshine.sym|g" "$source_directory/Makefile.am"
            ;;
        xavs2)
            export CFLAGS=-Wno-incompatible-pointer-types
            ;;
        molten-vk)
            # TODO this is quite extensive script, we may integrate it
            status_print $name I "Fetching"
            ./fetchDependencies --macos
            ;;
        flex)
            curl -fsSL https://raw.githubusercontent.com/Homebrew/formula-patches/03cf8088210822aa2c1ab544ed58ea04c897d9c4/libtool/configure-big_sur.diff | patch -ruN -d "$source_directory" -p1
            ;;
        snort)
            "${PATCH_SED_TOOL[@]}" "s| -pagezero_size 10000 -image_base 100000000\"|\"|g" "$source_directory/cmake/FindLuaJIT.cmake"
            "${PATCH_SED_TOOL[@]}" \
              -e 's/X509_NAME\* cert_subject = nullptr;/const X509_NAME* cert_subject = nullptr;/' \
              -e 's/X509_NAME\* cert_issuer = nullptr;/const X509_NAME* cert_issuer = nullptr;/' \
              -e 's/X509_NAME_ENTRY\* e = X509_NAME_get_entry/const X509_NAME_ENTRY* e = X509_NAME_get_entry/g' \
              -e 's/ASN1_STRING\* asn1_str = X509_NAME_ENTRY_get_data/const ASN1_STRING* asn1_str = X509_NAME_ENTRY_get_data/g' \
              "$source_directory/src/protocols/ssl.cc"
            ;;
        nmap)
            "${PATCH_SED_TOOL[@]}" 's|\$(PYTHON) -m build |&--wheel |g' "$source_directory/Makefile.in"
            ;;
        john)
            export CFLAGS="-g -O2 -Xpreprocessor -fopenmp -I$INSTALL_PREFIX/include $CFLAGS"
            export LDFLAGS="-lomp -L$INSTALL_PREFIX/lib $LDFLAGS"
            export CPPFLAGS="-I$INSTALL_PREFIX/include $CPPFLAGS"
            ;;
        libcdio-paranoia)
            "${PATCH_SED_TOOL[@]}" 's/^[[:space:]]*extern int getopt();[[:space:]]*$/extern int getopt(int ___argc, char *const *___argv, const char *__shortopts) __THROW;/' "$source_directory/src/getopt.h"
            ;;
        ffmpeg)
            patch_ffmpeg
            ;;
        postgres)
            export DYLD_LIBRARY_PATH="$INSTALL_PREFIX/lib"
            ;;
        deno_cargo)
            export RUSTFLAGS="-C link-arg=-fuse-ld=$INSTALL_PREFIX/llvm/bin/ld64.lld $RUSTFLAGS"
            ;;
        openmp)
            export CC=/usr/bin/clang
            export CXX=/usr/bin/clang++
            ;;
        tablecruncher)
            export LDFLAGS="-framework ScreenCaptureKit $LDFLAGS"
            "${PATCH_SED_TOOL[@]}" "s|BUILDDIR=\"./build/dist\"|BUILDDIR=\"$build_directory/dist\"|g" "$source_directory/scripts/create-bundle.sh"
            ;;
        rtmpdump)
            export XCFLAGS=-I$INSTALL_PREFIX/include
            ;;
    esac
}

# Patches applied after build/install
post_patch() {
    name="${1}"
    source_directory="${2}"
    build_directory="${3}"
    case "$name" in
        libtool)
            sudo ln -sf $INSTALL_PREFIX/bin/gnulibtoolize $INSTALL_PREFIX/bin/libtoolize
            ;;
        pkgconf)
            install_builtin_pkgconf
            # muon don't seem to add and strip rpaths
            strip_build_rpath $INSTALL_PREFIX/bin/pkgconf $build_directory
            strip_build_rpath $INSTALL_PREFIX/lib/libpkgconf.dylib $build_directory
            add_rpath_prefix $INSTALL_PREFIX/bin/pkgconf
            add_rpath_prefix $INSTALL_PREFIX/lib/libpkgconf.dylib
            sudo ln -sf $INSTALL_PREFIX/bin/pkgconf $INSTALL_PREFIX/bin/pkg-config
            sudo ln -sf $INSTALL_PREFIX/share/man/man1/pkgconf $INSTALL_PREFIX/share/man/man1/pkg-config.1
            ;;
        libomp)
            pkgconf_omp ;;
        ohmyposh_bin)
            sudo mv "$INSTALL_PREFIX/bin/posh-darwin-arm64" "$INSTALL_PREFIX/bin/oh-my-posh"
            ;;
        helix)
            sudo rm -rf "$source_directory/../runtime/grammars/sources/"
            sudo mkdir -p $INSTALL_PREFIX/libexec/helix/runtime
            sudo cp -rPf $source_directory/../runtime $INSTALL_PREFIX/libexec/helix/
            ;;
        vhdl_ls)
            sudo mkdir -p $INSTALL_PREFIX/lib/rust_hdl/
            sudo cp -rPf $source_directory/../vhdl_libraries $INSTALL_PREFIX/lib/rust_hdl/vhdl_libraries
            ;;
        glib)
            add_rpath $INSTALL_PREFIX/lib/libglib-2.0.dylib
            ;;
        wget)
            print -r -- "ca_certificate = $SSL_CERT_DIR/cert.pem" | sudo tee "$INSTALL_PREFIX/etc/wgetrc" >/dev/null
            ;;
        xavs2)
            unset CFLAGS 2>/dev/null || true
            ;;
        zsh-autosuggestions)
            sudo mkdir -p "$INSTALL_PREFIX/share/zsh-autosuggestions"
            sudo cp -f "$source_directory/zsh-autosuggestions.zsh" "$INSTALL_PREFIX/share/zsh-autosuggestions/"
            ;;
        gnutls)
            if [[ -f "$INSTALL_PREFIX/bin/certtool" ]]; then
                sudo mv "$INSTALL_PREFIX/bin/certtool" "$INSTALL_PREFIX/bin/gnu-certtool"
            fi
            if [[ -f "$INSTALL_PREFIX/share/man/man1/certtool.1" ]]; then
                sudo mv "$INSTALL_PREFIX/share/man/man1/certtool.1" "$INSTALL_PREFIX/share/man/man1/gnu-certtool.1"
            fi
            ;;
        snort)
            sudo chmod o+r /dev/bpf*
            ;;
        john)
            sudo mv $source_directory/../run/john $INSTALL_PREFIX/bin
            sudo mkdir -p $INSTALL_PREFIX/share/john
            sudo cp -a $source_directory/../run/* $INSTALL_PREFIX/share/john
            sudo mv $INSTALL_PREFIX/share/john/*.{pl,py,rb} $INSTALL_PREFIX/share/john/{relbench,benchmark-unify,mailer,makechr} $INSTALL_PREFIX/bin
            unset CPPFLAGS 2>/dev/null || true
            unset LDFLAGS 2>/dev/null || true
            unset CFLAGS 2>/dev/null || true
            ;;
        ffmpeg)
            sudo "${PATCH_SED_TOOL[@]}" 's/-Wl,-framework -Wl,/-framework /g' $INSTALL_PREFIX/lib/pkgconfig/libav*.pc $INSTALL_PREFIX/lib/pkgconfig/libsw*.pc || true
            sudo "${PATCH_SED_TOOL[@]}" 's/-Wl,-framework,/-framework /g' $INSTALL_PREFIX/lib/pkgconfig/libav*.pc $INSTALL_PREFIX/lib/pkgconfig/libsw*.pc || true
            ;;
        postgres)
            unset DYLD_LIBRARY_PATH 2>/dev/null || true
            ;;
        deno_cargo)
            unset RUSTFLAGS 2>/dev/null || true
            ;;
        openmp)
            if [[ -x "$INSTALL_PREFIX/llvm/bin/clang" ]]; then
                export CC="$INSTALL_PREFIX/llvm/bin/clang"
                export CXX="$INSTALL_PREFIX/llvm/bin/clang++"
            else
                unset CC CXX 2>/dev/null || true
            fi
            ;;
        llvm)
            # the stupid prebuilt llvm-config has homebrew paths compiled in (--system-libs).
            # In future probably we should build the entire project ourselves
            sudo mv "$INSTALL_PREFIX/llvm/bin/llvm-config" \
                    "$INSTALL_PREFIX/llvm/bin/llvm-config.binary"
            sudo tee "$INSTALL_PREFIX/llvm/bin/llvm-config" >/dev/null <<EOF
#!/bin/sh
exec "$INSTALL_PREFIX/llvm/bin/llvm-config.binary" "\$@" | sed \\
    -e 's|/opt/homebrew/lib/libzstd.a|$INSTALL_PREFIX/lib/libzstd.dylib|g' \\
    -e 's|/opt/homebrew/lib/libzstd.dylib|$INSTALL_PREFIX/lib/libzstd.dylib|g' \\
    -e 's|/opt/homebrew/lib/|$INSTALL_PREFIX/lib/|g'
EOF
            sudo chmod +x "$INSTALL_PREFIX/llvm/bin/llvm-config"
            ;;
        tablecruncher)
            sudo rm -rf /Applications/Tablecruncher.app
            sudo mv $build_directory/dist/Tablecruncher.app /Applications/
            ;;
        rtmpdump)
            unset XCFLAGS || true
            ;;
        bgutil)
            mkdir -p $HOME/.yt-dlp/plugins/bgutil-pot-provider
            cp -rPf $source_directory/plugin/* $HOME/.yt-dlp/plugins/bgutil-pot-provider
            ;;
        jdtls)
            # based on AUR script
            sudo mkdir -p "$INSTALL_PREFIX/share/java/jdtls"
            sudo cp -R "${source_directory}/"config_* "${source_directory}/features" "${source_directory}/plugins" "${source_directory}/bin" "$INSTALL_PREFIX/share/java/jdtls"
            sudo mkdir -p "$INSTALL_PREFIX/bin"
            sudo ln -fs "$INSTALL_PREFIX/share/java/jdtls/bin/jdtls" "$INSTALL_PREFIX/bin/jdtls"
            ;;
    esac
}

platform_env() {
    name="${1}"
    case "$name" in
        libtool)
            export LIBTOOLIZE="gnulibtoolize"
            ;;
        cpython)
            export PATH="/Library/Frameworks/Python.framework/Versions/Current/bin:$PATH"
            export PKG_CONFIG_PATH="/Library/Frameworks/Python.framework/Versions/Current/lib/pkgconfig:$PKG_CONFIG_PATH"
            export PYTHON_EXEC="$INSTALL_PREFIX/bin/python3"
            ;;
        wget)
            export WGETRC="$INSTALL_PREFIX/etc/wgetrc"
            ;;
        llvm)
            # Use upstream clang as the driver, but Apple's SDK + libc++.
            export CC="$INSTALL_PREFIX/llvm/bin/clang"
            export CXX="$INSTALL_PREFIX/llvm/bin/clang++"
            ;;
        golang)
            export PATH="$INSTALL_PREFIX/go/bin:$PATH"
            ;;
    esac
    export CFLAGS="-isysroot $MACOS_SDK_PATH"
    export CXXFLAGS="-isysroot $MACOS_SDK_PATH"
    export CPPFLAGS="-isysroot $MACOS_SDK_PATH"
    export LDFLAGS="-isysroot $MACOS_SDK_PATH"
}
