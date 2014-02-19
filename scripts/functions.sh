

bashfoo_require run
bashfoo_require log
bashfoo_require path
bashfoo_require assert


fail()
{
    log_error "$@"
    exit 1
}

inform()
{
    log_info "$@"
}

realpath()
(
    if [ -d "$1" ] ; then
        cd $1
        pwd
    else
        f="$(basename $1)"
        d="$(dirname $1)"
        cd $d
        echo "$(pwd)/$f"
    fi
)

portz_invoke()
{
    inform "executing: $@"
    #if quiet_if_success "$@" ; then
    if "$@" ; then
        return 0
    else
        r="$?"
        log_error "'$@' failed with error code $r" 1>&2
        return $r
    fi
}

portz_unzip()
{
    if which unzip > /dev/null; then
        portz_invoke_always unzip $*
    else
        inform "using bundled unzip"
        portz_invoke_always $portz_tools/unzip/unzip $*
    fi
} 


portz_unarchive() {
    local archive_file="$1"

    local TAR_COMMON_OPTIONS="-m --no-same-owner --no-same-permissions"
    case ${archive_file} in
        *.tar)     portz_invoke_always ${TAR} x ${TAR_COMMON_OPTIONS} -f ${archive_file} ;;
        *.tar.gz)  portz_invoke_always ${TAR} zx ${TAR_COMMON_OPTIONS} -f ${archive_file} ;;
        *.tgz)     portz_invoke_always ${TAR} zx ${TAR_COMMON_OPTIONS} -f ${archive_file} ;; 
        *.tar.bz2) portz_invoke_always ${TAR} jx ${TAR_COMMON_OPTIONS} -f ${archive_file} ;;
        *.tbz)     portz_invoke_always ${TAR} jx ${TAR_COMMON_OPTIONS} -f ${archive_file} ;;
        *.txz|*.tar.xz)     
                   portz_invoke_always xz --decompress --stdout ${archive_file} | portz_invoke ${TAR} x ${TAR_COMMON_OPTIONS} -f - 
                   ;;
        *.zip)     portz_unzip ${archive_file} ;;
        *.tar.lzma) portz_invoke_always ${TAR} x --lzma -f ${archive_file} ;;
        # TODO, add lzma
        *) fail "unknown archive type: ${archive_file} (supported tar (gz,bz2,xz) and zip"
    esac
}

portz_invoke_always()
{
    portz_invoke "$@"
}

portz_assert_know_package()
{
    local package="${package-$package_param}"
    if [ -n "$unknown_package" ] ; then
        fail "unknown package '$package' (descriptor not found in ${portz_repo})"
    fi
}

check_command()
{
    local path="$(which $1 2>/dev/null || true)"
    if [ -n "$path" ]; then
        log_info "found command $1 -> $path"
        return 0
    else
        return 1
    fi
}

portz_check_installed()
{
    local dep_pkginfo="$prefix/lib/portz/$1.PKGINFO"
    if [ -f "$dep_pkginfo" ] ; then
        return 0
    fi
    (
        load_package "$1"
        if function_exists check_presence_step ; then
            check_presence_step
        else
            exit 1
        fi
    )
    r=$?
    if [ "$r" = 0 ] ; then
        return $r
    fi
    return $r
}

portz_show_pkginfo()
{
    local dep_pkginfo="$prefix/lib/portz/$1.PKGINFO"
    cat $dep_pkginfo | bashfoo.prefix "    "
}

function_exists()
{
	declare -F $1 2>/dev/null 1> /dev/null
	return $?
}

portz_step()
{
    local optional=0
    if [ "$1" = --optional ] ; then
        optional=1
        shift
    fi
    local folder="$1"
    local action="$2"

    shift
    shift
    portz_step_path="${package_folder} ${portz_scripts}/${stereotype} ${portz_scripts}/common"

    step_function_name="${action}_step"
    actionu="$(echo $action | tr a-z A-Z)"
    if function_exists ${step_function_name} ; then
    	inform "$actionu (in $folder) (port custom)"
        (
            set -e
            mkdir -p $folder
            cd $folder
            $step_function_name "$@"
        )
        return $?
    fi

    for SP in ${portz_step_path} ; do
        local script="$SP/$action"
        if [ -f "${script}" ] ; then
    	    inform "$actionu (in $folder)"
    	    (
    	        set -e
    	        mkdir -p $folder
    	        cd $folder 
    	        source $script "$@"
            )
            return $?
        fi
    done
    if [ "$optional" = 1 ] ; then
        inform "${action} step skipped"
    else
        fail "step '${action}' not found (path is ${portz_step_path})"
    fi
}

portz_optional_step()
{
    portz_step --optional "$@"
}


# jedit: :tabSize=8:indentSize=4:noTabs=true:mode=shellscript:

