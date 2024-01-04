#!/usr/bin/env bash
set -ex

rm -rf root/*
./scripts/build_using_docker.sh

cd root
find opt/ -type d -name __pycache__ | xargs rm -rf
find opt/ -name *.pyc -exec rm {} \;
rm opt/miniconda/miniconda3/pkgs/cache/*
cd ..
