
version=2.5.0

src_url=http://protobuf.googlecode.com/files/protobuf-$version.tar.bz2

pkg_install-include () {
    protobuf_install_target=install-data pkg_install
}

pkg_install () {
    pkg_copy_src_to_build

    local ENV=
    if [[ "$OS" = "Darwin" ]]; then
        ENV="env CXX=clang++ CXXFLAGS='-std=c++11 -stdlib=libc++' LDFLAGS=-lc++"
    fi

    in_dir "$build_dir" $ENV ./configure --prefix="$(niceabspath "$install_dir")"
    in_dir "$build_dir" $ENV make ${protobuf_install_target:-install}

    # TODO: is there a platform that needs the library path to be adjusted like this?
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
