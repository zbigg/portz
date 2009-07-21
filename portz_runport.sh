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
manifest_dir=${prefix}/lib/portz/
manifest_file=${prefix}/lib/portz/${package}.MANIFEST

if [ ! -f $package_file ] ; then
    fail "descriptor not found (extected $package_file), check package name or update repository"
fi

. $package_file

tmpsrcdir=/tmp/portz_build/src/$package
tmpsitedir=/tmp/portz_build/site/$package
    
install_in_tmpsitedir() {
    inform "building version $version"
    inform "source url: $baseurl"
    local archive=`portz_need_source $baseurl`
    inform "local archive file: $archive"
    
    rm -rf $tmpsrcdir $tmpsitedir
    mkdir -p $tmpsrcdir
    (
        cd $tmpsrcdir
        portz_unarchive $archive
        goto_srcdir
        srcdir=`pwd`
        inform "building $package in $srcdir"
        ( 
            export DESTDIR=${tmpsitedir}
            set -x
            install 
	)
    )
}

create_manifest()
{
    mkdir -p ${tmpsitedir}${manifest_dir}
    (
        cd ${tmpsitedir}; 
        find . -type f | sed -e 'sX^\./XX' > ${tmpsitedir}${manifest_file}
    )
}

clean_tmpdirs()
{
    inform "removing temporary files"
    rm -rf $tmpsrcdir $tmpsitedir
}

if [ "$action" = "install" ] ; then
    inform "BUILDING"
    install_in_tmpsitedir
    
    inform "updating manifest"
    create_manifest
        
    inform "INSTALLATION"
    (
	inform "installing $(cat ${tmpsitedir}${manifest_file} | wc -l ) files"
	
        # this hack is something like
        #   cp -r --dont-create-folders-that-already exist
        # and is implemented using 
        # tar which unpacks in root and doesn't modify atime and modify time
	(cd ${tmpsitedir} ; tar cv . ; ) | ( cd / ; tar x -m --atime-preserve ; ) 
    )
    
elif [ "$action" = "dist" ] ; then
    inform "BUILDING"
    install_in_tmpsitedir
    
    inform "updating manifest"
    create_manifest
    
    inform "DIST"
    here=$(pwd)
    filename=${package}-${version}${dist_suffix}.tar.gz
    inform "creating distribution archive: ${filename} ($(cat ${tmpsitedir}${manifest_file} | wc -l ) files)"
    
    ( cd ${tmpsitedir} ; tar chozf ${here}/${filename} * ; )
else
    fail "action '$action' not supported"
fi

# jedit: :tabSize=8:indentSize=4:noTabs=true:mode=shellscript:

