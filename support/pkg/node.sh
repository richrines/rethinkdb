
version=0.10.15

fetch () {
    local tmp_dir
    tmp_dir=$(mktemp -d "$src_dir.fetch-XXXXXXXX")

    local archive=node-v$version.tar.gz
    geturl http://nodejs.org/dist/v$version/$archive > "$tmp_dir/$archive"
    in_dir "$tmp_dir" tar -zxf $archive

    test -e "$src_dir" && rm -rf "$src_dir"
    mv "$tmp_dir/node-v$version" "$src_dir"
    rm -rf "$tmp_dir"
}

install () {
    mkdir -p "$install_dir/build"
    cp -a "$src_dir/." "$install_dir/build"

    in_dir "$install_dir/build" ./configure --prefix="$(niceabspath "$install_dir")"
    in_dir "$install_dir/build" make
    in_dir "$install_dir/build" make install
}
