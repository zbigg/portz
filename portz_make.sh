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

for x in "$@" ; do 
    echo "$0: $x"
    eval $x
done

portz_prompt()
{
    local x=$(eval echo \$$1)
    if [ -n "$x" ];  then
        printf "%35s: %s\n" "$2" "$x"
    else
        printf "%35s: " "$2" 
        read $1
    fi
}

portz_prompt name "Name of package (unix-like name)"
portz_prompt website "WebSite"
portz_prompt version "Version"
portz_prompt baseurl "URL" 

portz_file=${portz_root}/repo/$name.portz

if [ -f $portz_file ] ; then
    echo "$0: $name portz already exists in repo" 1>&2
    exit 1
fi

(
    echo "version=$version"
    echo baseurl="$(echo $baseurl | sed -e s,$version,\${version},)"
    echo web="$website"
) | tee repo/$name.portz

