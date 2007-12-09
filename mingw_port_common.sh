#
# mingw_port_common
#

mingwport_repo=$mingwport_root/repo
mingwport_archive=$mingwport_root/archive

mingwport_is_installed()
{
    package=$1
    shift
    echo "$PNAME: checking if $package is installed"
    return 1 # FAKE/TODO always false
}


mingwport_check_deps()
{
    package=$1
    shift
    echo "$PNAME: chcking $package dependencies"
    return 0 # FAKE/TODO: always ok
}


mingwport_install()
{
    package=$1
    shift
    echo "$PNAME: installing $package"    
    $mingwport_root/mingw_port_runport.sh $mingwport_root $package install
}

#
# archive management
#
#  (archive = source)

mingw_need_source()
{
    url=$1
    shift
    filename=`basename $url`
    archived_filename="$mingwport_archive/$filename"
    if [ ! -f $archived_filename ] ; then
        [ -d $mingwport_archive ] || mkdir -p $mingwport_archive
        #trap "rm -rf $archived_filename; exit 1"
        mingwport_wget -O $archived_filename $url
        #trap
    fi
    echo $archived_filename
    return 0
}

mingwport_unzip()
{
    if which unzip > /dev/null; then
        unzip $*
    else
        inform "using bundled unzip"
        $mingwport_root/tools/unzip/unzip $*
    fi
}
mingwport_wget()
{
    if which wget > /dev/null; then
        wget $*
    else
        inform "using bundled wget"
        $mingwport_root/tools/wget/wget $*
    fi
}
mingwport_unarchive()
{
    name=$1
    case $name in
        *.tar)     tar xf  $name ;;
        *.tar.gz)  tar zxf $name ;; 
        *.tgz)     tar zxf $name ;; 
        *.tar.bz2) tar jxf $name ;;
        *.tbz)     tar jxf $name ;;
        *.zip)     mingwport_unzip $name ;;
        *) fail "unknown archive type: $name (supported tar (gz,bz2) and zip"        
    esac
}

#
# common actions
#
install()
{
    ./configure --prefix=$prefix $configure_options
    make 
    make install
}

goto_srcdir()
{
    if [ $(ls -1 | wc -l) == "1" ] ; then 
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