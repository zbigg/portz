#
# runtime
#   sourced script that ensure that portz runtime
#   is ok
#

if [ -z "${portz_libdir}" ] ; then
    echo "runtime.mk: portz_libdir not set or incorrect, panic" 2>&1
    exit 1
fi

#
# find bashfoo
#
if [ -f ${portz_libdir}/bashfoo/bashfoo.sh ] ; then
    export bashfoo_libdir="${portz_libdir}/bashfoo"
    source  ${portz_libdir}/bashfoo/bashfoo.sh
elif [ ! type bashfoo >/dev/null 2>/dev/null ] ; then
    eval `bashfoo --eval-out`
else
    echo "bashfoo not found or incorrect, panic" 2>&1
    exit 1
fi

bashfoo_require path
bashfoo_require log
bashfoo_require run

#
# find rest of portz
#
if [ -f "${portz_libdir}/scripts/runtime.sh" ] ; then
    portz_scripts=${portz_libdir}/scripts
    portz_tools=${portz_libdir}/tools
else
    echo "runtime.mk, cannot find rest of portz in \$portz_libdir ($portz_libdir), panic" 2>&1
    exit 1
fi

#
# find repo
#
if [ -z "${portz_repo}" ] ; then
    if [ -f "${portz_libdir}/../../bin/portz" ] ; then
        portz_root="$(abspath ${portz_libdir}/../..)"
        portz_repo="${portz_root}/var/lib/portz"
    else
        portz_repo="${portz_libdir}/repo"
    fi
fi

if [ -z "${portz_archive}" ] ; then
    if [ -f "${portz_libdir}/../../bin/portz" ] ; then
        portz_root="$(abspath ${portz_libdir}/../..)"
        portz_archive="${portz_root}/var/cache/portz/archive"
    else
        portz_archive="${portz_libdir}/archive"
    fi
fi

log_debug "portz_scripts=$portz_scripts"
log_debug "portz_repo=$portz_repo"
log_debug "portz_archive=$portz_archive"

