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

# jedit: :tabSize=8:indentSize=4:noTabs=true:mode=shellscript:

