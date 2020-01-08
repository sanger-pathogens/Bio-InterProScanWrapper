#!/usr/bin/env bash

usage() {
  local script_name=$(basename $0)
  cat <<EOT
${script_name}: download interproscan's data and copy it in a versioned output directory
Usage: ${script_name} -v <interproscan version> -o <output directory>
       interproscan version	mandatory: the version of interproscan to download
       output directory		mandatory: the directory where the data will be stored
				the output directory can also be specified via the environment variable INTERPROSCAN_DATA_DIR
EOT

}

if [[ ! -z "${INTERPROSCAN_DATA_DIR}" ]]
then
  output="${INTERPROSCAN_DATA_DIR}"
fi

while getopts "h?v:o:" opt; do
    case "$opt" in
    h|\?)
        usage 
        exit 0
        ;;
    v)  version=$OPTARG
        ;;
    o)  output=$OPTARG
        ;;
    esac
done

if [[ -z "${version}" ]]
then
  >&2 echo Please specify the interproscan version
  usage
  exit 1
fi

if [[ -z "${output}" ]]
then
  >&2 echo Please specify the output dir or set the variable INTERPROSCAN_DATA_DIR
  usage
  exit 1
fi

name="interproscan-${version}"
url=ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/5/${version}/${name}-64-bit.tar.gz
target="${output}/${name}"

mkdir -p "${target}" \
 && cd "${target}" \
 && echo "Downloading interproscan, this will take some time..." \
 && wget -O - -q ${url} | tar xzf - \
 && mv "${target}/${name}/data" . \
 && rm -rf "${target}/${name}" \
 && echo Done \
 && exit 0

>&2 echo An error occured
exit 1
