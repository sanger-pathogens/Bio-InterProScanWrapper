FROM  ubuntu:14.04

ARG   DEBIAN_FRONTEND=noninteractive

LABEL maintainer=path-help@sanger.ac.uk

# Apt packages and locales
RUN   apt-get update -y -qq \
      && apt-get install -y -qq software-properties-common \
      && add-apt-repository ppa:openjdk-r/ppa \
      && apt-get update -y -qq \
      && apt-get install -y -qq \
        locales \
        bedtools \
        cd-hit \
        mcl \
        parallel \
        cpanminus \
        prank \
        mafft \
        fasttree \
        wget \
        openjdk-11-jre \
        build-essential \
        libssl-dev \
        libexpat1-dev \
        python3 \
        python3-pip \
        libdw1 \
        libdw-dev \
      && locale-gen en_GB.UTF-8 \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*
ENV   LANG     en_GB.UTF-8
ENV   LANGUAGE en_GB:en
ENV   LC_ALL   en_GB.UTF-8

# LSF perl package (cpanm cannot find it)
COPY ./dummy-lsf.sh /tmp
RUN /tmp/dummy-lsf.sh /tmp/binny
ARG REAL_PATH=$PATH
ENV PATH=/tmp/binny:$PATH
RUN cd /tmp \
    && wget https://cpan.metacpan.org/authors/id/M/MS/MSOUTHERN/LSF-0.9.tar.gz \
    && cpanm --notest -fn LSF-0.9.tar.gz

# Bio-ASN1-EntrezGene perl package (to break circular dependency)
ARG ENTREZ_GENE_TAG=1.73
ARG ENTREZ_GENE_NAME="Bio-ASN1-EntrezGene-${ENTREZ_GENE_TAG}"
ARG ENTREZ_GENE_URL="http://www.cpan.org/authors/id/C/CJ/CJFIELDS/${ENTREZ_GENE_NAME}.tar.gz"
RUN cd /tmp \
    && wget -O - -o /dev/null "${ENTREZ_GENE_URL}" | tar xzf - \
    && cd "${ENTREZ_GENE_NAME}" \
    && perl Makefile.PL \
    && make install \
    && cd /tmp \
    && rm -rf "${ENTREZ_GENE_NAME}"*


ARG BUILD_DIR=/tmp/BUILD_DIR
ENV PATH=$PATH:${BUILD_DIR}/bin
ARG PERL5LIB=${BUILD_DIR}/lib:${BUILD_DIR}/t/lib:${PERL5LIB}
ARG GO_OBO=${BUILD_DIR}/t/data/gene_ontology_subset.obo
COPY . ${BUILD_DIR}
RUN cd ${BUILD_DIR} \
    && cpanm --notest Dist::Zilla \
    && dzil authordeps --missing | cpanm --notest \
    && dzil listdeps --missing | cpanm --notest \
    && dzil install \
    && rm -rf /root/.cpanm \
    && cd /tmp \
    && rm -rf ${BUILD_DIR}

ENV PATH=$REAL_PATH

# Interproscan
ARG INTERPROSCAN_TAG=5.39-77.0
ARG INTERPROSCAN_NAME=interproscan-${INTERPROSCAN_TAG}
ARG INTERPROSCAN_URL=ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/5/${INTERPROSCAN_TAG}/${INTERPROSCAN_NAME}-64-bit.tar.gz
RUN cd /usr/local \
    && echo "Downloading ${INTERPROSCAN_URL}" \
    && wget ${INTERPROSCAN_URL} \
    && echo "Unarchiving and deleting ${name}-64-bit.tar.gz" \
    && tar xzf ${INTERPROSCAN_NAME}-64-bit.tar.gz \
    && rm ${INTERPROSCAN_NAME}-64-bit.tar.gz \
    && echo "Replacing data and interproscan.properties by external links" \
    && cd ${INTERPROSCAN_NAME} \
    && rm -rf data interproscan.properties \
    && ln -s /interproscan/data data \
    && ln -s /interproscan/config/interproscan.properties interproscan.properties \
    && cd .. \
    && mv ${INTERPROSCAN_NAME} interproscan
ENV PATH=$PATH:/usr/local/interproscan

