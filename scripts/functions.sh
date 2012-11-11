fail()
{
    if [ -n "$name" ]; then
        echo "$PNAME($name), error: $*" 1>&2
    else
        echo "$PNAME, error: $*" 1>&2
    fi
    exit 1
}

inform()
{
    if [ -n "$name" ]; then
        echo "$PNAME($name): $*" 1>&2
    else
        echo "$PNAME: $*" 1>&2
    fi
}

portz_invoke()
{
    inform "[!] $@"
    "$@"
    if [ "$?" != "0" ] ; then
        "[!] failed with error code $?"
        exit $?
    fi
}

portz_invoke_always()
{
    inform "[!] $@"
    eval "$@"
}

portz_assert_know_package()
{
    if [ -n "$unknown_package" ] ; then
        fail "unknown package (descriptor not found in ${portz_repo})"
    fi
}
