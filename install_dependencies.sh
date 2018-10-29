#!/bin/bash

set -x
set -e

start_dir=$(pwd)

# Install perl dependencies
cpanm Dist::Zilla
dzil authordeps --missing | cpanm
dzil listdeps --missing | cpanm

set +x
set +e