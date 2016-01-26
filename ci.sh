#!/usr//bin/env bash

#
# build/ci.sh
#
#   script that does various CI (Continous Integration) tasks for portz
#

# by default, it 
#  - boostraps environment
#  - configures
#  - builds
#  - makes fake installation
#  - tests
#  - makes distcheck
#
###

header()
{
    echo "===================="
    echo "| $@"
    echo "--------------------"
}

set -e

git submodule update --init

header "autoreconf"
autoreconf -i

header "configure"
./configure

source makefoo_configured_defs.mk

header "make"
${MAKEFOO_MAKE}

header "make install"
${MAKEFOO_MAKE} install DESTDIR=`pwd`/.tmp-installation
rm -rf .tmp-installation

header "make distcheck"
${MAKEFOO_MAKE} distcheck

