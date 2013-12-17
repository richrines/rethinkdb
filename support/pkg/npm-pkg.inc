#!/usr/bin/env bash

# Fetch and build an npm package

# Expects npm_package_name to be set

npm_conf=$(niceabspath "$conf_dir/npm.conf")

real_npm=$(which npm)

npm () {
    "$real_npm" --userconfig "$npm_conf" --no-cache "$@"
}

package_json=$(cat <<EOF
{ "name": "packed-$npm_package",
  "version": "$version",
  "dependencies": { "$npm_package": "$version" },
  "bundleDependencies": [ "$npm_package" ] }
EOF
)

pkg_fetch () {
    local tmp_dir
    tmp_dir=$(mktemp -d "$src_dir.fetch-XXXXXXXX")
    cp "$pkg_dir/$npm_package.shrinkwrap" "$tmp_dir/npm-shrinkwrap.json"
    echo "$package_json" > "$tmp_dir/package.json"
    in_dir "$tmp_dir" npm install
    in_dir "$tmp_dir" npm pack
    in_dir "$tmp_dir" rm -rf npm-shrinkwrap.json package.json node_modules
    test -e "$src_dir" && rm -rf "$src_dir"
    mv "$tmp_dir" "$src_dir"
}

pkg_shrinkwrap () {
    local tmp_dir
    tmp_dir=$(mktemp -d "$src_dir.fetch-XXXXXXXX")
    echo "$package_json" > "$tmp_dir/package.json"
    in_dir "$tmp_dir" npm install
    in_dir "$tmp_dir" npm shrinkwrap
    cp "$tmp_dir/npm-shrinkwrap.json" "$pkg_dir/$npm_package.shrinkwrap"
    rm -rf "$tmp_dir"
}

pkg_install () {
    rm -rf "$install_dir" || : 2>/dev/null
    mkdir -p "$install_dir/node_modules"
    local tgz
    tgz=$(niceabspath "$src_dir/packed-$npm_package-$version.tgz")
    in_dir "$install_dir" npm --no-registry install "$tgz"

    local bin_dir="$install_dir/node_modules/packed-$npm_package/node_modules/.bin/"
    mkdir "$install_dir/bin"
    for bin in "$bin_dir"*; do
        local name
        name=$(basename "$bin")
        local script="$install_dir/bin/$name"
        echo '#!/bin/sh' > "$script"
        echo "exec $(niceabspath "$bin")"' "$@"' >> "$script"
        chmod +x "$script"
    done
}
