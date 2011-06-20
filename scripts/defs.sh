if [ -z "${portz_root}" ] ; then
    echo "$0: portz_root not set, report it as a portz bug" 1>&2
    exit 3
fi

if [ -d "${portz_root}/repo" ] ; then
    portz_local=1
    portz_repo=${portz_root}/repo
    portz_scripts=${portz_root}/scripts
    portz_archive=${portz_root}/archive 
    portz_tools=${portz_root}/tools
else
    portz_repo=${portz_root}/share/portz/repo
    portz_scripts=${portz_root}/share/portz/scripts
    portz_tools=${portz_root}/share/portz/tools
    portz_archive=${portz_root}/var/cache/portz/archive 
fi

. ${portz_scripts}/functions.sh

if [ -z "$OSTYPE" ] ; then
    OSTYPE=`uname`
fi 

#
# all defaults
#
CC=${CC-gcc}
CXX=${CXX-g++}

export CC CFLAGS
export CXX CXXFLAGS

def_dist_name="$(uname -s | tr A-Z a-z)-$(uname -m)"
def_prefix=/usr

TAR=tar
PATCH=patch
MAKE=make
PYTHON=python

#
# custom platforms
#

case "$OSTYPE" in
    *solaris*)
        TAR=gtar
        PATCH=gpatch
	MAKE=gmake
        ;;
    *FreeBSD*)
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
esac

#
# 
#

stereotype="${stereotype-auto}"

#
# prefix and exec_prefix 
# 
prefix=${prefix-$def_prefix}

if test "x$PORTZ_SEPARATE_EXEC" = "x1"
then
    def_exec_prefix=${prefix}/platforms/$(uname -m)
else
    def_exec_prefix=${prefix}
fi

exec_prefix=${exec_prefix-$def_exec_prefix}

export prefix exec_prefix

if [ -z "${dist_name}" ]; then
    dist_name="${def_dist_name}"
fi

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
else
    cpus=1
fi

portz_make_parallel()
{
    ${MAKE} -j$cpus "$@"
}

MAKE_PARALLEL="${MAKE} -j$cpus"
#
# read package config
#

[ -z "${TMP}" ] && TMP=/tmp

if [ -n "$package" ] ; then
    manifest_file=${exec_prefix}/lib/portz/${package}.MANIFEST
    staging_dir=${TMP}/portz/${package}/staging
    DESTDIR=${staging_dir}
    # read package configuration from repo
    
    if [ -d "${portz_repo}/${package}" ] ; then
        package_def_file="${portz_repo}/${package}/info.txt"
        package_folder="${portz_repo}/${package}"
    elif [ -f "${portz_repo}/${package}.portz" ] ; then
        package_def_file="${portz_repo}/${package}.portz"
    elif [ -f "${portz_repo}/${package}" ] ; then
        package_def_file="${portz_repo}/${package}"
    else
        #inform "unknown package (not found in ${portz_repo}"
        unknown_package=1
    fi
    if [ -z "${unknown_package}" ] ; then
        . ${package_def_file}
    fi
fi

#
# portz_step
#

portz_do_invoke_step()
{
    folder=$1
    script=$2
    shift ; shift
    
    if [ ! -d ${folder} ] ; then
        portz_invoke_always mkdir -p ${folder}
        mkdir -p ${folder}
        
    fi
    (
        if [ "$(pwd)" != "$folder" ] ; then
            cd ${folder}
        fi
        portz_root=${portz_root} package="$package" $script "$@"
        exit $?
    )
    return $?
}

function_exists()
{
	declare -F $1 2> /dev/null
	return $?
}

portz_step()
{
    folder=$1
    action=$2
    
    shift
    shift    
    portz_step_path="${package_folder} ${portz_scripts}/${stereotype} ${portz_scripts}/common"

    step_function_name="${action}_step"
    if function_exists ${step_function_name} ; then
        (cd $folder ; eval $step_function_name "$@" )
        return $?
    fi
    
    for SP in ${portz_step_path} ; do
        local script="$SP/$action"
        if [ -f "${script}" ] ; then
            portz_do_invoke_step $folder $script "$@"
            return $?
        fi
    done
    fail "step $action not found (path is ${portz_step_path})"
}

portz_optional_step()
{
    folder=$1
    action=$2
    
    shift
    shift

    step_function_name="${action}_step"
    if declare -F ${step_function_name} ; then
        (cd $folder ; eval $step_function_name "$@" )
        return $?
    fi
    
    portz_step_path="${package_folder} ${portz_scripts}/${stereotype} ${portz_scripts}/common"

    for SP in ${portz_step_path} ; do
        local script="$SP/$action"
        if [ -f "${script}" ] ; then
            portz_do_invoke_step $folder $script "$@"
            return "$?"
        fi
    done
    inform "${action} step skipped"
}

maybe_detect_stereotype()
{
	if [ "$stereotype" = "auto" ] ; then
        	inform "detecting stereotype"
        	if [ -f "${src_dir}/configure" ] ; then
                	inform "stereotype=gnu"
                	export stereotype=gnu
        	else
                	inform "unknown stereotype, assuming make works"
        	fi
	fi
}

