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

portz_invoke()
{
    inform "[!] $@"
    eval "$@"
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