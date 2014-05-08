#
# package_defs.sh
#

find_package_path_in_repo()
{
    local name="$1"
    #assert_variable_present portz_repo
    
    if [ -f "${portz_repo}/${name}/info.txt" ] ; then
        echo "${portz_repo}/${name}"
    elif [ -f "${portz_repo}/${name}.portz" ] ; then
        echo "${portz_repo}/${name}.portz"
    else
        return 1
    fi
}

maybe_detect_stereotype()
{
    if [ -z "$stereotype" -o "$stereotype" = "auto" ] ; then
        inform "detecting stereotype"
        if [ -f "${src_dir}/configure" -o -f "${src_dir}/configure.ac" -o -f "${src_dir}/configure.in" ] ; then
            inform "stereotype=gnu"
            export stereotype=gnu
        elif [ -f "${src_dir}/setup.py" ]; then
            inform "stereotype=python"
            export stereotype=python
        else
            inform "unknown stereotype, assuming make works"
        fi
    fi
}

package_setup_variables()
{
    if [ -z "$name" ] ; then
        package_def_file_basename="$(basename "$package_def_file")"
        if [ "$package_def_file_basename" = "info.txt" ] ; then
            name="$(basename $(dirname "$package_def_file"))"
        else
            name="$(basename "$package_def_file" | sed -e 's/\.portz//')"
        fi
        log_info "warning: $package_def_file_basename doesn't define name, name ('$name') inferred from package path"
    fi

    package_name="$name"
    package_version="$version"
    package_baseurl="$baseurl"
    
    message="loaded $package_name"
    [ -n "$package_version" ] && message="$message version=$package_version"
    log_info "$message"
    #maybe_detect_stereotype
    
    #TBD, support REPLACEMENT VARIABLES
    #so, one can override version or download url"

}
package_from_portz_file()
{
    package_def_file="$1"
    if [ ! -f "$package_def_file" ] ; then
        fail "package info file '$package_def_file' doesn't exit"
    fi

    package_folder="$(abspath $(dirname $1))"
    unset name
    unset version
    unset baseurl
    unset stereotype
    unset depends
    
    source "$package_def_file"

    package_setup_variables
}

package_from_info_dir()
{
    package_folder="$1"
    if [ ! -d "$package_folder" ] ; then
        fail "package folder '$package_folder' doesn't exit"
    fi
    package_def_file="$package_folder/info.txt"
    if [ ! -f "$package_def_file" ] ; then
        fail "package info file '$package_def_file' doesn't exit"
    fi

    source "$package_def_file"
    package_setup_variables
}

package_from_path()
{
    if [ -f "$1/info.txt" ] ; then
        log_info "loading package from $1/info.txt"
        package_from_info_dir "$1"
    else
        log_info "loading portz file $1"
        package_from_portz_file "$1"
    fi
}


load_package()
{
    local name="$1"
    if [ -f "$name" ] ; then
        log_info "loading portz file $name"
        package_from_portz_file "$name"
        package_path="$name"
    elif path="$(find_package_path_in_repo $name)" ; then
        package_from_path "$path"
        package_path="$path"
    else
        log_info "package $name is not file and cannot be found in repo '$portz_repo'"
        return 1
    fi
}

setup_package_build_defs()
{
    manifest_file=${exec_prefix}/lib/portz/${package_name}.MANIFEST
    pkginfo_file=${exec_prefix}/lib/portz/${package_name}.PKGINFO
    staging_dir=${TMP}/portz/${package_name}/staging
    DESTDIR="${staging_dir}"
}

# jedit: :tabSize=8:indentSize=4:noTabs=true:mode=shellscript:

