#!/bin/bash
#
# Copyright (c) 2022, Jesús Lapastora <cyber.gsuscode@gmail.com>
#
# SPDX-License-Identifier: BSD-2-Clause

stat_format_flags="-c %Y"
if [[ $OSTYPE == 'darwin'* ]]; then
  stat_format_flags="-f %m"
fi

echo "Checking & building Jakttest if necessary"
set -e
ninja -C jakttest
set +e

if [ ! -x build/main ]; then
    echo "Selfhost binary does not exist; compiling it"
    set -e
    cargo run selfhost/main.jakt
    set +e
else
# check for selfhost/ mtime and build/main mtime
{
    binary_mtime=$(stat "$stat_format_flags" build/main)
    latest_selfhost_mtime=$(stat "$stat_format_flags" selfhost/*.jakt | sort | tail -n1)
    if [ "$binary_mtime" -lt "$latest_selfhost_mtime" ]; then
        echo "re-compiling selfhost to match source"
        set -e
        cargo run selfhost/main.jakt
        set +e
    fi
}
fi

# default JOBS to number of prossing units dictated by kernel
if [[ $OSTYPE == 'darwin'* ]]; then
    [ -z "$JOBS" ] && JOBS=$(sysctl -n hw.ncpu)
else
    [ -z "$JOBS" ] && JOBS=$(nproc)
fi

tempdir=$(mktemp -d)

trap "rm -rf $tempdir" EXIT

./jakttest/build/jakttest --jobs "$JOBS" "$tempdir"
