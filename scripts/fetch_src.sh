#!/bin/bash

# fetch and unarchive
. ${portz_root}/scripts/defs.sh

src_dir="${TMP}/portz/${package}/src"
rm -rf ${src_dir}
mkdir -p ${src_dir}

if [ -n "${svn_path}" ] ; then
	dir="$package-trunk"
	if [ -n "${revision}" ] ; then
		svn_options="-r ${revision}"
		dir="${package}-r${revision}"
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

	dir="${package}-r${revision}"
	db="${portz_root}/archive/${package}.mtn"
	if [ ! -f "$db" ] ; then
		portz_invoke mtn -d $db db init 
	fi
	portz_invoke mtn -d "$db" $mtn_options pull -k ""  "$mtn_url"
	(
		cd "${src_dir}"
		portz_invoke mtn -d "${db}" checkout -r$revision ${dir}
	)
elif [ -n "${git_url}" ] ; then
	# version as a tag
	if [ -z "$git_tag" -a -z "$git_branch" ] ; then
	    if [ -n "$version" ] ; then
	        git_tag="$version"
        fi
    fi
    set -x
	if [ -n "$git_tag" ] ; then
	    dir=$name-$git_tag
	    refspec="refs/tags/$git_tag:refs/tags/$git_tag"
	    if [ ! -d "${src_dir}/$dir" ] ; then
	        git init "${src_dir}/$dir"
        fi
	    (
	        cd "${src_dir}/$dir"
	        git fetch --depth=1 $git_url $refspec
	        git checkout $git_tag
	    )
    else
        exit 1
    fi    
	
else
	archive_file=$(portz_step $(pwd) fetch ${baseurl})

	inform archive_file="$archive_file"
	portz_step ${TMP}/portz/${package}/src unarchive ${archive_file}
fi
