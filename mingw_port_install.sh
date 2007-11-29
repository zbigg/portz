#!/bin/sh

PNAME=`basename $0`
set -e
mingwport_root=`dirname $0`
mingwport_root=$PWD

. ${mingwport_root}/mingw_port_common.sh

#set -x

if [ "$1" == "--update" ] ; then
    echo "$PNAME: updating repository"
    exit 0
elif [ "$1" == "--install" ] ; then
    shift
else
    echo "$PNAME: bad usage"
fi

packages=$*

while [ -n "$packages" ] ; do
    for package in $packages ; do
        echo "$PNAME: trying $package ..."
        if mingwport_is_installed $package ; then
            echo "$PNAME: $package already installed"
        elif mingwport_check_deps $package ; then
            mingwport_install $package        
        else
            failed_deps="$failed_deps $package"
        fi
    done
    packages="$failed_deps"
done