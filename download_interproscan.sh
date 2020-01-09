#!/usr/bin/env bash

usage() {
  local script_name=$(basename $0)
  cat <<EOT
${script_name}: download interproscan and repackage it with external links for data and property file
Usage: ${script_name} -v <interproscan version> -o <output directory>
       interproscan version	mandatory: the version of interproscan to download
       output directory		mandatory: the directory where the package will be stored
EOT
}

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
  >&2 echo Please specify the output dir.
  usage
  exit 1
fi

name="interproscan-${version}"
url=ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/5/${version}/${name}-64-bit.tar.gz

echo "Downloading ${name}-64-bit.tar.gz" \
 && mkdir -p "${output}" \
 && cd "${output}" \
 && wget -q ${url} \
 && echo "Unarchiving and deleting ${name}-64-bit.tar.gz" \
 && tar xzf ${name}-64-bit.tar.gz \
 && rm ${name}-64-bit.tar.gz \
 && echo "Replacing data and interproscan.properties by external links" \
 && cd ${name} \
 && rm -rf data interproscan.properties \
 && ln -s /interproscan/data data \
 && ln -s /interproscan/config/interproscan.properties interproscan.properties \
 && cd .. \
 && echo "Rebuilding archive ${name}-64-bit.tar.gz" \
 && tar cf ${name}-64-bit.tar ${name} \
 && gzip -9 ${name}-64-bit.tar \
 && rm -rf ${name}

