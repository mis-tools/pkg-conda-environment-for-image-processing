#!/usr/bin/env bash
set -e

deb_root=$1

echo "Compute md5 checksum."
cwd=$(pwd)
mkdir -p ${deb_root}/DEBIAN
cd ${deb_root}
find . -type f ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -print0 | tr '\0' '\n' | sort | xargs -d '\n' md5sum > DEBIAN/md5sums
cd ${cwd}
