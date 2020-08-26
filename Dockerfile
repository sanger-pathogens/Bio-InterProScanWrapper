FROM  ubuntu:20.04

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

# Install probelm packages manually (circular dependency + LSF dependencies)
COPY ./dummy-lsf.sh /tmp
RUN /tmp/dummy-lsf.sh /opt/dummy-lsf
ENV PATH=/opt/dummy-lsf:$PATH
COPY ./install_perl_lsf.sh /tmp
RUN /tmp/install_perl_lsf.sh
COPY ./install_entrez.sh /tmp
RUN /tmp/install_entrez.sh

ARG BUILD_DIR=/tmp/BUILD_DIR
ENV PATH=$PATH:${BUILD_DIR}/bin
ARG PERL5LIB=${BUILD_DIR}/lib:${BUILD_DIR}/t/lib:${PERL5LIB}
ARG GO_OBO=${BUILD_DIR}/t/data/gene_ontology_subset.obo
COPY . ${BUILD_DIR}
RUN cd ${BUILD_DIR} \
    && cpanm --notest Dist::Zilla \
    && dzil authordeps --missing | grep -v LSF | cpanm --notest \
    && dzil listdeps --missing | grep -v LSF | cpanm --notest \
    && dzil install \
    && rm -rf /root/.cpanm \
    && cd /tmp \
    && rm -rf ${BUILD_DIR}

# Interproscan
ARG INTERPROSCAN_TAG=5.46-81.0
ARG INTERPROSCAN_NAME=interproscan-${INTERPROSCAN_TAG}
ARG INTERPROSCAN_URL=ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/5/${INTERPROSCAN_TAG}/${INTERPROSCAN_NAME}-64-bit.tar.gz
RUN cd /usr/local \
    && echo "Downloading ${INTERPROSCAN_URL}" \
    && wget ${INTERPROSCAN_URL} --progress=dot:giga \
    && echo "Unarchiving and deleting ${INTERPROSCAN_NAME}-64-bit.tar.gz" \
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

