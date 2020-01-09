#!/usr/bin/env bash

cd /tmp \
  && echo "Downloading LSF-0.9.tar.gz" \
  && wget https://cpan.metacpan.org/authors/id/M/MS/MSOUTHERN/LSF-0.9.tar.gz \
  && echo "Extracting  LSF-0.9.tar.gz" \
  && tar xzf LSF-0.9.tar.gz \
  && rm LSF-0.9.tar.gz \
  && echo "Disabling lsid checks" \
  && cd LSF-0.9 \
  && sed -i 's/lsid/lsid-dummy/g' Makefile.PL \
  && sed -i 's/lsid/lsid-dummy/g' LSF.pm \
  && echo "Installing dependencies and package" \
  && cpanm --notest --installdeps . \
  && perl Makefile.PL \
  && make install \
  && cd .. \
  && rm -rf LSF-0.9

