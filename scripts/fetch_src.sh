#!/bin/bash

# fetch and unarchive
. ${portz_root}/scripts/defs.sh

archive_file=$(portz_step $(pwd) fetch ${baseurl})

inform archive_file="$archive_file"
rm -rf ${TMP}/portz/${package}/src
portz_step ${TMP}/portz/${package}/src unarchive ${archive_file}
