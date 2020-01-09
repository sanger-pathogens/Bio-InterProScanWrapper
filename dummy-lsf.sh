#!/usr/bin/env bash

mkdir -p $1 && cd $1
# Perl LSF module checks for version. Use dummy.
echo ">&2 echo 'LSF 9.1.3.0'" > lsid-dummy
chmod -R +x lsid-dummy
