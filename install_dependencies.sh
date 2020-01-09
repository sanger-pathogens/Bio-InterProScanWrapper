#!/bin/bash

set -x
set -e

start_dir=$(pwd)

# Bio-ASN1-EntrezGene perl package (to break circular dependency)
${start_dir}/install_entrez.sh

# Install LSF perl module
lsf_dir=${start_dir}/lsf
${start_dir}/dummy-lsf.sh "${lsf_dir}"
export PATH=${lsf_dir}:$PATH
${start_dir}/install_perl_lsf.sh



# Install perl dependencies
export PATH=$start_dir/bin:$PATH
export GO_OBO=$start_dir/t/data/gene_ontology_subset.obo
export PERL5LIB=${start_dir}/lib:${start_dir}/t/lib:${PERL5LIB}
cpanm --notest Dist::Zilla
dzil authordeps --missing | cpanm --notest
dzil listdeps --missing | cpanm --notest

set +x
set +e
