#!/bin/bash

# fetch and unarchive

. ${portz_scripts}/fetch_src.sh

# find dirs

src_dir=$(portz_step ${TMP}/portz/${package_name}/src find_src_dir)
inform src_dir="$src_dir"

bld_dir=$(portz_step ${src_dir} find_bld_dir)
inform bld_dir="$bld_dir"

export src_dir bld_dir

maybe_detect_stereotype
setup_package_build_defs

# preparation

portz_optional_step ${src_dir} patch
portz_optional_step ${bld_dir} configure
portz_optional_step ${bld_dir} patch_after_conf

# build
portz_step ${bld_dir} build

# and staging install
rm -rf ${staging_dir}
portz_step ${bld_dir} install_staging

# update manifest

portz_step "${staging_dir}" make_pkginfo
portz_step "${staging_dir}" make_manifest

# jedit: :tabSize=8:indentSize=4:noTabs=true:mode=shellscript:

