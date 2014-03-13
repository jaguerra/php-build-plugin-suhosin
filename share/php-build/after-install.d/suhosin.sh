#!/bin/bash

set -e

if [ -n "$PHP_BUILD_DEBUG" ]; then
    set -x
fi

TMP="$(dirname $(mktemp --dry-run 2>/dev/null || echo "/var/tmp/tmp_dir"))/php-build"

if [ ! -d "$TMP" ]; then
    mkdir -p "$TMP"
fi

if [ ! -d "$TMP/packages" ]; then
    mkdir "$TMP/packages"
fi

if [ ! -d "$TMP/source" ]; then
    mkdir "$TMP/source"
fi

function install_suhosin {
    local version=$1
    local package_url="http://download.suhosin.org/suhosin-$version.tgz"

    if [ -z "$version" ]; then
        echo "install_suhosin: No Version given." >&3
        return 1
    fi

    echo "Suhosin - Downloading $package_url"

    # We cache the tarballs for Suhosin versions in `packages/`.
    if [ ! -f "$TMP/packages/suhosin-$version.tgz" ]; then
        wget -qP "$TMP/packages" "$package_url"
    fi

    # Each tarball gets extracted to `source/Suhosin-$version`.
    if [ -d "$TMP/source/suhosin-$version" ]; then
        rm -rf "$TMP/source/suhosin-$version"
    fi

    tar -xzf "$TMP/packages/suhosin-$version.tgz" -C "$TMP/source"

    _build_suhosin "$TMP/source/suhosin-$version"
}

function _build_suhosin {
    local source_dir="$1"
    local cwd=$(pwd)

    echo "Suhosin - Compiling in $source_dir"

    cd "$source_dir"

    {
        $PREFIX/bin/phpize > /dev/null
        ./configure --with-php-config=$PREFIX/bin/php-config > /dev/null

        make > /dev/null
        make install > /dev/null
    } >&4 2>&1

    local suhosin_ini="$PREFIX/etc/conf.d/suhosin.ini"

    if [ ! -f "$suhosin_ini" ]; then
        echo "Suhosin Installing Suhosin configuration in $suhosin_ini"

        echo "extension=\"suhosin.so\"" > $suhosin_ini

    fi

    echo "Suhosin - Cleaning up."
    make clean > /dev/null

    cd "$cwd" > /dev/null
}

if "$PREFIX/bin/php" -v | grep "PHP 5.2"; then
		install_suhosin "0.9.28"
else
		install_suhosin "0.9.35"
fi
