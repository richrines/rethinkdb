
version=2.1

pkg_fetch () {
    pkg fetched libunwind || pkg fetch libunwind

    local tmp_dir
    tmp_dir=$(mktemp -d "$src_dir.fetch-XXXXXXXX")

    local archive=gperftools-$version.tar.gz
    geturl http://gperftools.googlecode.com/files/$archive > "$tmp_dir/$archive"
    in_dir "$tmp_dir" tar -xzf $archive

    test -e "$src_dir" && rm -rf "$src_dir"
    mv "$tmp_dir/gperftools-$version" "$src_dir"
    rm -rf "$tmp_dir"
}

pkg_install-include () {
    mkdir -p "$install_dir/include"
}

pkg_install () {
    pkg install libunwind
    eval "$(pkg environment libunwind)"

    mkdir -p "$install_dir/build"
    cp -a "$src_dir/." "$install_dir/build"

    in_dir "$install_dir/build" ./configure --prefix="$(niceabspath "$install_dir")" LDFLAGS="$LDFLAGS -lunwind"
    in_dir "$install_dir/build" make install
}
