#!/bin/bash

set -x
set -e

start_dir=$(pwd)

# Install perl dependencies
cpanm Dist::Zilla
dzil authordeps --missing | cpanm
cpanm GO::Parser Bio::Roary

set +x
set +e