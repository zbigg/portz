

bashfoo_require run
bashfoo_require log
bashfoo_require path
bashfoo_require assert

#
# TBD, it shall be autoconf like-test 
# executed before in configure
# or before first run of config ?
#
case "$OSTYPE" in
    *freebsd*|*FreeBSD*|*darwin*|*msys*)
        SHA1SUM="shasum -a 1"
	;;
    *)
        SHA1SUM="sha1sum"
    	;;
esac

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

portz_sha1sum()
{
    $SHA1SUM "$@"| awk '{print $1}'
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

portz_list_files_from_manifest()
{
    local manifest_file="$1"
    local prefix="$2"
    if [ -z "$prefix" ] ; then
        prefix="$(realpath $(dirname ${manifest_file})/../..)"
    fi
    # there are two formats of MANIFEST
    # relative to ${prefix}
    #   bin/goo
    #   lib/libfoo.so
    #   ...
    # absolute, starting with ./
    #   ./opt/foo/bin/goo
    #   ./opt/foo/lib/libfoo.so

    awk -v r=$prefix '
        # absolute format
        /^.\//  {printf("%s\n", substr($1,2)); next; }
        # relative format
        //      {printf("%s/%s\n",r,$1); next; }
        ' "${manifest_file}"
}
function_exists()
{
	declare -F $1 2>/dev/null 1> /dev/null
	return $?
}

invoke_step_maybe_quiet()
{
    if [ -n "$quiet_steps" ] ; then
        quiet_if_success "$@"
    else
        "$@"
    fi
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

    local step_function_name="${action}_step"
    local add_function_name="${action}_add"
    local step_result=
    actionu="$(echo $action | tr a-z A-Z)"
    if function_exists ${step_function_name} ; then
    	inform "$actionu (in $folder) (port custom)"
        (
            set -e
            mkdir -p $folder
            cd $folder
            invoke_step_maybe_quiet $step_function_name "$@"
        )
        step_result=$?
    fi
    if [ -z "$step_result" ] ; then
        for SP in ${portz_step_path} ; do
            local script="$SP/$action"
            if [ -f "${script}" ] ; then
                inform "$actionu (in $folder)"
                (
                    set -e
                    mkdir -p $folder
                    cd $folder
                    invoke_step_maybe_quiet source $script "$@"
                )
                step_result=$?
                break
            fi
        done
    fi
    if function_exists ${add_function_name} ; then
        inform "$add_function_name (in $folder) (port additional step)"
        (
            set -e
            mkdir -p $folder
            cd $folder
            invoke_step_maybe_quiet $add_function_name "$@"
        )
        r=$?
        if [ "$r" != 0 ] ; then
            step_result=$r
        fi
    fi
    if [ -n "$step_result" ]; then
        return "$step_result"
    fi
    if [ "$optional" = 1 ] ; then
        inform "${action} step skipped"
    else
        fail "step '${action}' not found (path is ${portz_step_path})"
    fi
}

portz_step_capture()
{
    local old_quiet_steps="$quiet_steps"
    unset quiet_steps
    portz_step "$@"
    quiet_steps="$old_quiet_steps"
}
portz_optional_step()
{
    portz_step --optional "$@"
}

izip()
{
    local a1=($1)
    local a2=($2)
    local a3=($3)
    local i=0
    for v in ${a1[@]} ; do
        echo "$v ${a2[$i]} ${a3[$i]}"
        i="$((i+1))"
    done
}

portz_download()
{
    if which wget > /dev/null; then
        portz_invoke_always wget --no-check-certificate -O $1 $2
    elif which curl > /dev/null ; then
        portz_invoke_always curl --location --output $1 $2
    else
        inform "using bundled wget"
        portz_invoke_always ${portz_tools}/wget/wget -O $1 $*
    fi
}

portz_fetch_url_with_cache()
{
    local url=$1
    shift
    local filename=`basename $url`
    if ! [[ ${filename} =~ ^${package_name} ]] ; then
        filename="${package_name}-${filename}"
    fi

    local archived_filename="${portz_archive}/$filename"

    if [ ! -f $archived_filename ] ; then
        # THIS is soooo weak, TBD
        # fix this
        #  - download to REAL tmp
        #  - move only on success
        [ -d $portz_archive ] || mkdir -p $portz_archive
        #trap "rm -rf $archived_filename; exit 1"
        rm -rf $archived_filename.tmp
        log_info "downloading $url"
        portz_download ${archived_filename}.tmp $url
        mv $archived_filename.tmp $archived_filename
        #trap
    else
        log_info "$filename already in cache"
    fi
    echo "$archived_filename"
}

# jedit: :tabSize=8:indentSize=4:noTabs=true:mode=shellscript:

