
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
    protobuf_install_target=install-data install
}

install () {
    mkdir -p "$install_dir/build"
    cp -a "$src_dir/." "$install_dir/build"

    local ENV
    if [[ "$COMPILER $OS" = "CLANG Darwin" ]]; then
        ENV="env CXX=clang++ CXXFLAGS='-std=c++11 -stdlib=libc++' LDFLAGS=-lc++"
    else
        ENV=
    fi

    in_dir "$install_dir/build" $ENV ./configure --prefix="$(niceabspath "$install_dir")"
    in_dir "$install_dir/build" $ENV make ${protobuf_install_target:-install}
    # local protoc="$install_dir/bin/protoc"
    # if test -e "$protoc"; then
    #     mv "$protoc" "$protoc-orig"
    #     echo '#!/bin/sh' > "$protoc"
    #     echo "export LD_LIBRARY_PATH='$install_dir/lib':\$LD_LIBRARY_PATH" >> "$protoc"
    #     echo "export PATH='$install_dir/bin':\$PATH" >> "$protoc"
    #     echo 'exec protoc-orig "$@"' >> "$protoc"
    #     chmod +x "$protoc"
    # fi
}
