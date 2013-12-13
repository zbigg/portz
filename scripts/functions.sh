


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
    quiet_if_success "$@"
    #"$@"
    r=$?
    if [ "$r" != "0" ] ; then
        log_error "'$@' failed with error code $r" 1>&2
        exit $?
    fi
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

portz_check_installed()
{
    dep_pkginfo="$prefix/lib/portz/$1.PKGINFO"
    if [ -f "$dep_pkginfo" ] ; then
        inform "$1 is installed:"
        cat $dep_pkginfo
        return 0
    fi
    return 1
}

# jedit: :tabSize=8:indentSize=4:noTabs=true:mode=shellscript:

