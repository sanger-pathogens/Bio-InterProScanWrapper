#!/bin/bash

set -x
set -e

start_dir=$(pwd)

IPROSCAN_VERSION="5.31-70.0"

IPROSCAN_DOWNLOAD_URL="ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/5/${IPROSCAN_VERSION}/interproscan-${IPROSCAN_VERSION}-64-bit.tar.gz"

# Make an install location
if [ ! -d 'build' ]; then
  mkdir build
fi
cd build
build_dir=$(pwd)

# DOWNLOAD ALL THE THINGS
download () {
  url=$1
  download_location=$2

  if [ -e $download_location ]; then
    echo "Skipping download of $url, $download_location already exists"
  else
    echo "Downloading $url to $download_location"
    wget $url -O $download_location
  fi
}

download $IPROSCAN_DOWNLOAD_URL "interproscan-${IPROSCAN_VERSION}-64-bit.tar.gz"

## smalt
cd $build_dir
iproscan_dir=$(pwd)/"interproscan-${IPROSCAN_VERSION}"
if [ ! -d $iproscan_dir ]; then
  tar -pxvzf interproscan-${IPROSCAN_VERSION}-64-bit.tar.gz
fi

# Setup environment variables
update_path () {
  new_dir=$1
  if [[ ! "$PATH" =~ (^|:)"${new_dir}"(:|$) ]]; then
    export PATH=${new_dir}:${PATH}
  fi
}

update_path ${iproscan_dir}

cd $start_dir

# Install perl dependencies
cpanm Dist::Zilla
dzil authordeps --missing | cpanm
cpanm GO::Parser Bio::Roary

set +x
set +e