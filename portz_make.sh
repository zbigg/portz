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

portz_prompt()
{
    printf "%40s: " "$2" 
    read $1
}
portz_prompt name "Name of package (unix-like name)"
portz_prompt website "WebSite"
portz_prompt baseurl "URL" 

echo $name
echo $website
echo $baseurl
