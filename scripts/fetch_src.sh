#!/bin/bash

# fetch and unarchive
src_dir="${TMP}/portz/${package_name}/src"
rm -rf ${src_dir}
mkdir -p ${src_dir}

if [ -n "${svn_path}" ] ; then
	dir="$package-trunk"
	if [ -n "${revision}" ] ; then
		svn_options="-r ${revision}"
		dir="${package_name}-r${revision}"
	fi
	(
		cd ${src_dir}
		portz_invoke svn co ${svn_options} ${svn_path} ${dir}
	)
elif [ -n "${mtn_url}" ] ; then
	if [ -z "${revision}" ] ; then
		echo "$package: mtn package is missing revision property"
		exit 1
	fi

	dir="${package_name}-r${revision}"
	db="${portz_archive}/${package_name}.mtn"
	if [ ! -f "$db" ] ; then
		portz_invoke mtn -d $db db init 
	fi
	portz_invoke mtn -d "$db" $mtn_options pull "$mtn_url"
	(
		cd "${src_dir}"
		portz_invoke mtn -d "${db}" checkout -r$revision ${dir}
	)
elif [ -n "${git_url}" ] ; then
    if [ -z "$git_tag" -a -z "$git_branch" -a -z "$git_ref" ] ; then
        if [ -n "$version" ] ; then
            git_tag="$version"
        fi
    fi
    repo="${portz_archive}/${package_name}.git"
    refspec=""
    dir="${src_dir}/${package_name}"
    
    if [ -n "$git_tag" ] ; then
        #refspec="refs/tags/$git_tag:refs/tags/$git_tag"
        git_ref="$git_tag"
    fi                  
    if [ ! -d "${repo}" ] ; then
        mkdir -p "${repo}"
        git init "${repo}"
        ( cd "$repo" ; git remote add origin "$git_url")
    fi
    # ensure repo is up-to-date
    (
        cd "${repo}"
        git remote set-url origin "$git_url"
        git fetch origin
        
    )
    # and checkout
    git clone --reference="$repo" "$git_url" "$dir"
    ( 
        cd "$dir"
        git checkout "$git_ref"
    )
else
	archive_file=$(portz_step $(pwd) fetch ${package_baseurl})

	inform archive_file="$archive_file"
	portz_step ${TMP}/portz/${package_name}/src unarchive ${archive_file}
fi
