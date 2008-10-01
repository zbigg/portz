#
# This file is part of 'portz'
#
# Copyright (C) Zbigniew Zagorski <z.zagorski@gmail.com> and others, 
# licensed to the public under the terms of the GNU GPL (>= 2)
# see the file COPYING for details
#
# I.e., do what you like, but keep copyright and there's NO WARRANTY. 
# 

set -e
PNAME=`basename $0`
portz_root=$1
. $portz_root/portz_common.sh

package=$2
action=$3

package_file=$portz_repo/${package}.portz

if [ ! -f $package_file ] ; then
    fail "descriptor not found (extected $package_file), check package name or update repository"
fi

. $package_file

if [ "$action" = "install" ] ; then
    inform "installing version $version"
    inform "source url: $baseurl"
    archive=`portz_need_source $baseurl`
    inform "local archive file: $archive"
    tmpsrcdir=/tmp/portz_build/$package
    rm -rf $tmpsrcdir
    mkdir -p $tmpsrcdir
    (
        cd $tmpsrcdir
        portz_unarchive $archive
        goto_srcdir
        srcdir=`pwd`
        inform "building $package in $srcdir"
        ( set -x ; install ; )
    )
    inform "removing temporary files"
    rm -rf $tmpsrcdir
else 
    fail "action '$action' not supported"
fi
