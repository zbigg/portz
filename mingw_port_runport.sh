#
# mingw_port_runport.sh
#

set -e
PNAME=`basename $0`
mingwport_root=$1
. $mingwport_root/mingw_port_common.sh

package=$2
action=$3

package_file=$mingwport_repo/${package}.mingw
[ -f $package_file ] || fail "descriptor not found (extected $package_file), check package name or update repository"

. $package_file

if [ "$action" == "install" ] ; then
    inform "installing version $version"
    inform "source url: $baseurl"
    archive=`mingw_need_source $baseurl`
    echo "got archive: $archive"
    tmpsrcdir=`mktemp`
    rm -rf $tmpsrcdir
    mkdir -p $tmpsrcdir
    pushd $tmpsrcdir
    mingwport_unarchive $archive
    goto_srcdir
    srcdir=`pwd`
    export prefix=/mingw
    echo "building $package in $srcdir"
    ( set -x ; install ; )
    popd
    rm -rf $tmpsrcdir
else 
    fail "action $action unknown"
fi