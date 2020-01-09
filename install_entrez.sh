#!/usr/bin/env bash

ENTREZ_GENE_TAG=1.73
ENTREZ_GENE_NAME="Bio-ASN1-EntrezGene-${ENTREZ_GENE_TAG}"
ENTREZ_GENE_URL="http://www.cpan.org/authors/id/C/CJ/CJFIELDS/${ENTREZ_GENE_NAME}.tar.gz"

cd /tmp \
  && wget -O - -o /dev/null "${ENTREZ_GENE_URL}" | tar xzf - \
  && cd "${ENTREZ_GENE_NAME}" \
  && perl Makefile.PL \
  && make install \
  && cd "${start_dir}" \
  && rm -rf entrezgene
