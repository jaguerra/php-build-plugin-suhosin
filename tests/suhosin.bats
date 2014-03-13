#!/usr/bin/env bats

@test "Installs suhosin.so" {
    local ext_dir=$("$TEST_PREFIX/bin/php" -r "echo ini_get('extension_dir');")

    [ -f "$ext_dir/suhosin.so" ]
}

@test "Enables Suhosin" {
    "$TEST_PREFIX/bin/php" -i | grep "suhosin"
}

