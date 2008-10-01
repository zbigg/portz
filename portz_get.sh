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
portz_root=$PWD

. ${portz_root}/portz_common.sh

package=$1

package_file=$portz_repo/${package}.portz
[ -f $package_file ] || fail "descriptor not found (extected $package_file), check package name or update repository"

. $package_file 

inform "fertching source from source url: $baseurl"
archive=`portz_need_source $baseurl`
echo "got archive: $archive"
tmpsrcdir=$PWD/src/$package
mkdir -p $tmpsrcdir
(
    cd $tmpsrcdir
    portz_unarchive $archive 
)
