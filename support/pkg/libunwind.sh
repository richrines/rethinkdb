
version=1.1

pkg_fetch () {
    local tmp_dir
    tmp_dir=$(mktemp -d "$src_dir.fetch-XXXXXXXX")

    local archive=libunwind-$version.tar.gz
    geturl http://gnu.mirrors.pair.com/savannah/savannah//libunwind/$archive > "$tmp_dir/$archive"
    in_dir "$tmp_dir" tar -xzf $archive

    test -e "$src_dir" && rm -rf "$src_dir"
    mv "$tmp_dir/libunwind-$version" "$src_dir"
    rm -rf "$tmp_dir"
}

pkg_install () {
    mkdir -p "$install_dir/build"
    cp -a "$src_dir/." "$install_dir/build"

    in_dir "$install_dir/build" ./configure --prefix="$(niceabspath "$install_dir")"
    in_dir "$install_dir/build" make install
}
