
version=3.19.18.4

fetch () {
    local tmp_dir
    tmp_dir=$(mktemp -d "$src_dir.fetch-XXXXXXXX")

    git_clone_tag git://github.com/v8/v8 $version "$tmp_dir"

    make -C "$tmp_dir" dependencies

    test -e "$src_dir" && rm -rf "$src_dir"

    mv -f "$tmp_dir" "$src_dir"
}

install-include () {
    mkdir -p "$install_dir"
    test -e "$install_dir/include" && rm -rf "$install_dir/include"
    cp -ra "$src_dir/include" "$install_dir"
}

install () {
    mkdir -p "$install_dir/lib"
    test -e "$install_dir/build" && rm -rf "$install_dir/build"
    cp -ra "$src_dir" "$install_dir/build"
    make -C "$install_dir/build" native CXXFLAGS=-Wno-array-bounds
    find "$install_dir/build" -iname "*.o" | grep -v '\/preparser_lib\/' | xargs ar cqs "$install_dir/lib/libv8.a"
}
