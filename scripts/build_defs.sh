#
# build_defs.mk (current: defs.mk)
#   functions use by steps !
#     remove package_XXX detection and move to 'package_defs.mk' 

if [ -z "$OSTYPE" ] ; then
    OSTYPE=`uname`
fi 

#
# all defaults
#
CC=${CC-gcc}
CXX=${CXX-g++}
PYTHON="${PYTHON-python}"

export CC CFLAGS
export CXX CXXFLAGS
export PYTHON

def_dist_name="$(uname -s | tr A-Z a-z)-$(uname -m)"
def_prefix=/usr

TAR=tar
PATCH=patch
MAKE=make

#
# custom platforms
#

case "$OSTYPE" in
    *solaris*)
        TAR=gtar
        PATCH=gpatch
	MAKE=gmake
        ;;
    *freebsd*|*FreeBSD*)
        MAKE=gmake
        C_INCLUDE_PATH=$C_INCLUDE_PATH:/usr/local/include
        CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:/usr/local/include
        LIBRARY_PATH=$LIBRARY_PATH:/usr/local/lib
        LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib	
        export C_INCLUDE_PATH CPLUS_INCLUDE_PATH
	;;
    *msys*|MINGW*)
        def_prefix=/mingw
        def_dist_name="mingw-$(uname -m)"
        ;;
    *darwin*)
        is_macosx=1
    	;;
esac

#
# 
#

stereotype="${stereotype-auto}"

#
# archiecture
#

config_guess()
{
    sh ${portz_scripts}/config.guess
}

convert_path_to_msys()
{
    # converts now
    #   D:/fofo   -> /d/foo
    #   C:/blbala -> /c/blabla
    sed -e 's#\([A-Za-z]\):/#/\1/#g'
}

convert_path_to_cygwin()
{
    # converts now
    #   D:/fofo   -> /d/foo
    #   C:/blbala -> /c/blabla
    sed -e 's#\([A-Za-z]\):/#/cygdrive/\1/#g'
}

addpath() {
        local name=$1 ; shift
        eval "current=\"\$$name\""
        if [ -z "$current" ] ; then
                D=""
        else
                D=":"
        fi
        for path in $* ; do
                if   [ "$OSTYPE" == msys ] ; then
                    path="$(echo $path | convert_path_to_msys)"
                elif [ "$OSTYPE" == cygwin ] ; then
                    path="$(echo $path | convert_path_to_cygwin)"
                fi
                if [ -d $path ] ; then
                        current="${path}${D}${current}"
                        D=":"
                fi
        done
        eval "$name=\"$current\""
        export $name

        unset name first current D
}


current_arch=$(config_guess)

#
# site
#
if [ -n "$site" ] ; then
	inform "using site settings from $site"
	prefix="$site"
	exec_prefix="${prefix}"

	# other defaults
        addpath LIBRARY_PATH       $site/lib
        addpath PKG_CONFIG_PATH    $site/lib/pkgconfig
	
	# noarch paths
        addpath C_INCLUDE_PATH     $base/include
        addpath CPLUS_INCLUDE_PATH $base/include
        addpath MANPATH            $base/share/man
        addpath PYTHONPATH         $base/lib/python{2.3,2.4,2.5,2.6,2.7,3.0}/site-packages

	PORTZ_SEPARATE_EXEC=0
	if [ -f "$site/.portz.conf" ] ; then
	    inform "using site settings file $site/.portz.conf"
            . "$site/.portz.conf"
	fi

        if [ -z "$arch" -o "$current_arch" = "$arch" ] ; then
            addpath PATH $site/bin

            if   [ "$OSTYPE" != msys -a "$OSTYPE" != cygwin ] ; then
                addpath LD_LIBRARY_PATH $site/lib
            fi
        fi
fi

target_arch=${arch-$current_arch}

if [ "$current_arch" != "$target_arch" ] ; then
        PORTZ_SEPARATE_EXEC=${PORTZ_SEPARATE_EXEC-1}
fi

#
# prefix and exec_prefix 
# 
prefix=${prefix-$def_prefix}

if [ "${portz_deploy_mode}" = stow ] ; then
    if [ -n "${package_name}" -a -n "${package_version}" ] ; then
        prefix="${prefix}/${package_name}-${package_version}"
    else
        inform "warning: portz_deploy_mode=stow, but package_name&version unknown"
    fi
fi

if [ -n "${portz_prefix_suffix}" ] ; then
    prefix="${prefix}${portz_prefix_suffix}"
fi

if test "x$PORTZ_SEPARATE_EXEC" = "x1"
then
    def_exec_prefix=${prefix}/platforms/${target_arch}
else
    def_exec_prefix=${prefix}
fi

exec_prefix=${exec_prefix-$def_exec_prefix}

export prefix exec_prefix

inform "prefix      = $prefix"
inform "exec_prefix = $exec_prefix"

libdir=${libdir-$exec_prefix/lib}
includedir=${includedir-$prefix/include}

if [ -z "${dist_name}" ]; then
    dist_name="${def_dist_name}"
fi

#
# now when arch & directories are known,
# prepare default C/C++ compile and linking flags
#
#

C_INCLUDE_PATH="${prefix}/include:$C_INCLUDE_PATH"
CPLUS_INCLUDE_PATH="${prefix}/include:$CPLUS_INCLUDE_PATH"
LD_LIBRARY_PATH="${exec_prefix}/lib:$LD_LIBRARY_PATH"
LIBRARY_PATH="${exec_prefix}/lib:$LIBRARY_PATH"
PKG_CONFIG_PATH="${exec_prefix}/lib/pkgconfig:${prefix}/lib/pkgconfig:$PKG_CONFIG_PATH"

export C_INCLUDE_PATH CPLUS_INCLUDE_PATH LD_LIBRARY_PATH PKG_CONFIG_PATH

if [ "$current_arch" != "$target_arch" ] ; then
        cross_configure_options="--host=$target_arch"
        case $target_arch in
            *i*86-*linux*)
                CROSS_CFLAGS="-m32"
                CROSS_CXXFLAGS="-m32"
                CROSS_LDFLAGS="-m32"
                ;;
            x86_64*linux*)
                CROSS_CFLAGS="-m64"
                CROSS_CXXFLAGS="-m64"
                CROSS_LDFLAGS="-m64"
                ;;
            default)
                # no universal special handling
                true
                ;;
        esac
        
        CROSS_CC=${target_arch}-cc
        CROSS_CXX=${target_arch}-c++
        
        if which $CROSS_CC > /dev/null; then
            CC=$CROSS_CC
            export CC
        fi
        if which $CROSS_CXX > /dev/null ; then
            CXX=$CROSS_CXX
            export CXX
        fi 
fi

STD_CFLAGS="${CFLAGS--g -O2}"
STD_CXXFLAGS="${CXXFLAGS--g -O2}"
STD_LDFLAGS="${LDFLAGS--g}"

CFLAGS="$STD_CFLAGS $CROSS_CFLAGS"
CXXFLAGS="$STD_CXXFLAGS $CROSS_CXXFLAGS"
LDFLAGS="$STD_LDFLAGS $CROSS_LDFLAGS"

export CFLAGS CXXFLAGS LDFLAGS

#
# dist platform suffix
#
dist_suffix="-${dist_name}"

#
# detect cpu count
#   TODO: move to  separate script
#
if [ -f /proc/cpuinfo ] ; then
    cpus=$(cat /proc/cpuinfo | egrep "^processor" | wc -l)
elif [ -n "$NUMBER_OF_PROCESSORS" ] ; then
    cpus=$NUMBER_OF_PROCESSORS
elif [ -n "$is_macosx" ] ; then
    if [ -x "/usr/sbin/sysctl" ] ; then
        cpus="$(/usr/sbin/sysctl -n hw.ncpu)"
    else
        cpus=1
    fi
else
    cpus=1
fi
log_info "detected cpu/core count: $cpus"

portz_make_parallel()
{
    ${MAKE} -j$cpus "$@"
}

MAKE_PARALLEL="${MAKE} -j$cpus"

if [ -z "${TMP}" ] ; then
    TMP="${TEMP-/tmp}"
fi

