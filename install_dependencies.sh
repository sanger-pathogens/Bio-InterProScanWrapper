#!/bin/bash

set -x
set -e

start_dir=$(pwd)

# Bio-ASN1-EntrezGene perl package (to break circular dependency)
mkdir entrezgene && cd entrezgene
ENTREZ_GENE_TAG=1.73
ENTREZ_GENE_NAME="Bio-ASN1-EntrezGene-${ENTREZ_GENE_TAG}"
ENTREZ_GENE_URL="http://www.cpan.org/authors/id/C/CJ/CJFIELDS/${ENTREZ_GENE_NAME}.tar.gz"
wget -O - -o /dev/null "${ENTREZ_GENE_URL}" | tar xzf - \
    && cd "${ENTREZ_GENE_NAME}" \
    && perl Makefile.PL \
    && make install \
    && cd "${start_dir}" \
    && rm -rf entrezgene


# Install LSF perl module
mkdir build
cd build
build_dir=$(pwd)

#Create dummy bin with executables for LSF
$(dirname $0)/dummy-lsf.sh "${build_dir}/bin"

export PATH=${build_dir}/bin:$PATH
export PATH=$start_dir/bin:$PATH
export GO_OBO=$start_dir/t/data/gene_ontology_subset.obo
export PERL5LIB=${start_dir}/lib:${start_dir}/t/lib:${PERL5LIB}

wget https://cpan.metacpan.org/authors/id/M/MS/MSOUTHERN/LSF-0.9.tar.gz
cpanm -fn LSF-0.9.tar.gz

cd $start_dir
# Install perl dependencies
cpanm --notest Dist::Zilla
dzil authordeps --missing | cpanm --notest
dzil listdeps --missing | cpanm --notest

set +x
set +e
