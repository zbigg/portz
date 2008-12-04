#
# This file is part of 'portz'
#
# Copyright (C) Zbigniew Zagorski <z.zagorski@gmail.com> and others, 
# licensed to the public under the terms of the GNU GPL (>= 2)
# see the file COPYING for details
#
# I.e., do what you like, but keep copyright and there's NO WARRANTY. 
# 
portz_repo=$portz_root/repo
portz_archive=$portz_root/archive


if [ "$OSTYPE" = "msys" ] ; then
    def_prefix=/mingw
else
    def_prefix=/usr
fi

if [ ! -w $def_prefix ] ; then
    def_prefix=$HOME
fi

if test "x$PORTZ_SEPARATE_EXEC" = "x1"
then
    def_exec_prefix=$def_prefix/platforms/$(uname -m)
else
    def_exec_prefix=$def_prefix
fi

prefix=${prefix-$def_prefix}
exec_prefix=${exec_prefix-$def_exec_prefix}

export prefix export exec_prefix

CC=${CC-gcc}
CXX=${CXX-g++}

export CC CFLAGS
export CXX CXXFLAGS

case "$OSTYPE" in
    *solaris*)
        TAR=gtar
        PATCH=gpatch
        ;;
    *)
        TAR=tar
        PATCH=patch
        ;;
esac

get_cpus_count()
{
    if [ -f /proc/cpuinfo ] ; then
        cpus=$(cat /proc/cpuinfo | egrep "^processor" | wc -l)
    elif [ -n "$NUMBER_OF_PROCESSORS" ] ; then
        cpus=$NUMBER_OF_PROCESSORS
    else
        cpus=1
    fi
        
    inform cpu count: $cpus
}
export prefix
export TAR
export PATCH

portz_is_installed()
{
    package=$1
    shift
    inform "checking if $package is installed"
    return 1 # FAKE/TODO always false
}


portz_check_deps()
{
    package=$1
    shift
    inform "checking $package dependencies"
    return 0 # FAKE/TODO: always ok
}


portz_install()
{
    package=$1
    shift
    inform "installing"    
    $portz_root/portz_runport.sh $portz_root $package install
}

#
# archive management
#
#  (archive = source)

portz_need_source()
{
    url=$1
    shift
    filename=`basename $url`
    archived_filename="$portz_archive/$filename"
    if [ ! -f $archived_filename ] ; then
        [ -d $portz_archive ] || mkdir -p $portz_archive
        #trap "rm -rf $archived_filename; exit 1"
        rm -rf $archived_filename.tmp
        portz_wget -O $archived_filename.tmp $url
        mv $archived_filename.tmp $archived_filename
        #trap
    fi
    echo $archived_filename
    return 0
}

portz_unzip()
{
    if which unzip > /dev/null; then
        unzip $*
    else
        inform "using bundled unzip"
        $portz_root/tools/unzip/unzip $*
    fi
}
portz_wget()
{
    if which wget > /dev/null; then
        wget $*
    else
        inform "using bundled wget"
        $portz_root/tools/wget/wget $*
    fi
}

portz_unarchive()
{
    name=$1
    case $name in
        *.tar)     tar xf  $name ;;
        *.tar.gz)  tar zxf $name ;; 
        *.tgz)     tar zxf $name ;; 
        *.tar.bz2) tar jxf $name ;;
        *.tbz)     tar jxf $name ;;
        *.zip)     portz_unzip $name ;;
        *) fail "unknown archive type: $name (supported tar (gz,bz2) and zip"        
    esac
}

#
# common actions
#
install()
{
    ./configure --prefix=$prefix --exec_prefix=$exec_prefix $configure_options
    make -j$cpus
    make install
}

goto_srcdir()
{
    if [ `ls -1 | wc -l` = "1" ] ; then 
        cd `ls -1`
    else
        fail "unable to find source directory in unpacked archive, override goto_srcdir() in package def"
    fi
}
#
# common sh lib
#

fail()
{
    set +x
    if [ -n "$package" ]; then
        echo "$PNAME error: $package: $*" 1>&2
    else
        echo "$PNAME error: $*" 1>&2
    fi
    exit 1
}

inform()
{
    if [ -n "$package" ]; then
        echo "$PNAME $package: $*" 1>&2
    else
        echo "$PNAME $*" 1>&2
    fi
}

get_cpus_count

