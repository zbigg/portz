#
# portz_runport.sh
#

set -e -x
PNAME=`basename $0`
portz_root=`pwd`
. $portz_root/portz_common.sh

url=$1

inform "installing from source url: $url"
archive=`portz_need_source $url`
echo "got archive: $archive"
tmpsrcdir=/tmp/portz_build/$package
rm -rf $tmpsrcdir
mkdir -p $tmpsrcdir
pushd $tmpsrcdir
portz_unarchive $archive
goto_srcdir
srcdir=`pwd`

echo "building $package in $srcdir"
if ( set -x ; install ; ) ; then
    popd
    rm -rf $tmpsrcdir
else
    fail "build/install failed, check build ad $srcdir"
fi
