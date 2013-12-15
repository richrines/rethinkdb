
version=2.5.0

fetch () {
    local tmp_dir
    tmp_dir=$(mktemp -d "$src_dir.fetch-XXXXXXXX")

    local archive=protobuf-$version.tar.bz2
    geturl http://protobuf.googlecode.com/files/$archive > "$tmp_dir/$archive"
    in_dir "$tmp_dir" tar -xjf $archive

    test -e "$src_dir" && rm -rf "$src_dir"
    mv "$tmp_dir/protobuf-$version" "$src_dir"
    rm -rf "$tmp_dir"
}

install-include () {
    mkdir -p "$install_dir"
    test -e "$install_dir/include" && rm -rf "$install_dir/include"
    cp -ra "$src_dir/include" "$install_dir"
}

install () {
    # TODO
    mkdir -p "$install_dir/lib"
    test -e "$install_dir/build" && rm -rf "$install_dir/build"
    cp -ra "$src_dir" "$install_dir/build"
    make -C "$install_dir/build" native CXXFLAGS=-Wno-array-bounds
    find "$install_dir/build" -iname "*.o" | grep -v '\/preparser_lib\/' | xargs ar cqs "$install_dir/lib/libv8.a"
}
