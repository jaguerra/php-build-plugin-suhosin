#!/usr/bin/env bash


TIME="$(date "+%Y%m%d%H%M%S")"


FAILED=
PREFIX=$1

usage() {
    echo "Usage: ./run-tests.sh <prefix>"
}

if ! which "bats" > /dev/null; then
    echo "You need http://github.com/sstephenson/bats installed." >&2
    exit 1
fi


if [ $# -eq 0 ]; then
    usage
    exit 1
fi

echo "Testing on $PREFIX"
echo

while true; do echo "..."; sleep 60; done & #https://github.com/CHH/php-build/issues/134

echo -n "Building ..."

# Bootstrap some php-build environment
export PREFIX
exec 3<&2
exec 4<&2

if ./share/php-build/after-install.d/suhosin.sh &> /dev/null; then
    echo "OK"

    export TEST_PREFIX="$PREFIX"

    echo "Running Tests..."
    bats "tests/"
else
    echo "FAIL"
    FAILED=1
fi

kill %1 #https://github.com/CHH/php-build/issues/134

if [ -z "$FAILED" ]; then
    rm -f "$PREFIX/etc/conf.d/suhosin.ini"
else
    echo "Build fail."
    exit 1
fi
