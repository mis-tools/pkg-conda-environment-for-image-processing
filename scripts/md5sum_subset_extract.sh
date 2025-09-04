#!/usr/bin/env bash
set -e

md5sums_file=$1
md5sum_subset_file=$2

# .pyc files are currently not reprodicible, so they are
# excluded from the md5sum validation process
# see: https://github.com/python/cpython/issues/73894 and
# https://github.com/conda/conda-package-handling/issues/1
cat ${md5sums_file} | grep -v ".pyc$" | grep -v "conda-meta/history$" > ${md5sum_subset_file}
