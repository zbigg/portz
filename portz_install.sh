#!/bin/sh
#
# This file is part of 'portz'
#
# Copyright (C) Zbigniew Zagorski <z.zagorski@gmail.com> and others, 
# licensed to the public under the terms of the GNU GPL (>= 2)
# see the file COPYING for details
#
# I.e., do what you like, but keep copyright and there's NO WARRANTY. 
# 

PNAME=`basename $0`
set -e
portz_root=`dirname $0`
portz_root=$PWD

. ${portz_root}/portz_common.sh

#set -x

if [ "$1" = "--update" ] ; then
    echo "$PNAME: updating repository"
    exit 0
elif [ "$1" = "--install" ] ; then
    shift
else
    echo "$PNAME: bad usage"
fi

packages=$*

while [ -n "$packages" ] ; do
    for package in $packages ; do
        echo "$PNAME: trying $package ..."
        if portz_is_installed $package ; then
            echo "$PNAME: $package already installed"
        elif portz_check_deps $package ; then
            portz_install $package        
        else
            failed_deps="$failed_deps $package"
        fi
    done
    packages="$failed_deps"
done
