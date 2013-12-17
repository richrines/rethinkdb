
version=2.1

src_url=http://gperftools.googlecode.com/files/gperftools-$version.tar.gz

pkg_install () {
    pkg install libunwind
    eval "$(pkg environment libunwind)"

    pkg_copy_src_to_build

    pkg_configure LDFLAGS="$LDFLAGS -lunwind"
    pkg_make install
}
