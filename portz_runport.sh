#
# portz_runport.sh
#

set -e
PNAME=`basename $0`
portz_root=$1
. $portz_root/portz_common.sh

package=$2
action=$3

package_file=$portz_repo/${package}.portz
[ -f $package_file ] || fail "descriptor not found (extected $package_file), check package name or update repository"

. $package_file

if [ "$action" == "install" ] ; then
    inform "installing version $version"
    inform "source url: $baseurl"
    archive=`portz_need_source $baseurl`
    echo "got archive: $archive"
    tmpsrcdir=/tmp/portz_build/$package
    rm -rf $tmpsrcdir
    mkdir -p $tmpsrcdir
    pushd $tmpsrcdir
    portz_unarchive $archive
    goto_srcdir
    srcdir=`pwd`
    export prefix=/usr/local
    echo "building $package in $srcdir"
    ( set -x ; install ; )
    popd
    rm -rf $tmpsrcdir
else 
    fail "action $action unknown"
fi
