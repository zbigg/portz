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
else
	archive_file=$(portz_step $(pwd) fetch ${baseurl})

	inform archive_file="$archive_file"
	portz_step ${TMP}/portz/${package}/src unarchive ${archive_file}
fi
