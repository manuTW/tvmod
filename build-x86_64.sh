#!/bin/bash

MODEL="TS-X71 TS-X53II"
#QTS source
SRC_REPO=/mnt/sourcetgz

#
# build media driver against given QTS version,
#
usage() {
	echo "Usage: $0 -q QTS"
	echo "    QTS: the QTS tar in ${SRC_REPO}, NasX86.tgz, NasX86.4.2.1.tgz, or NasX86.4.2.x.tgz"
	exit
}

#
# Update global variables
# Output : FILENAME
# 
#
parse_param() {
	#parse option
        while getopts "q:" opt; do
                case $opt in
                q) QTS=$OPTARG;;
                *) usage;;
                esac
        done
        OPTIND=1

	test -z "${QTS}" -o ! -f "${SRC_REPO}/${QTS}" && echo "Missing QTS file ..." && usage
	local filename=`basename ${QTS}`
	SRC_DIR=${HOME}/${filename%.*}

	#untar in home dir		
	test -d ${SRC_DIR} #&& rm -rf ${SRC_DIR}
	cd && echo Extracting ${SRC_REPO}/${QTS} ...
	tar xf ${SRC_REPO}/${QTS}
}

#SRC_DIR
do_build() {
	for model in ${MODEL}; do
		if [ -d ${SRC_DIR}/Model/${model} ]; then
			echo to build ${SRC_DIR}/Model/${model}
			pushd ${SRC_DIR}/Model/${model} >/dev/null
			popd >/dev/null
		fi
	done
}


parse_param $@
do_build
