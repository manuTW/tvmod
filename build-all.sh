#!/bin/bash

SHELL_DIR=`dirname $0`
[ ${SHELL_DIR} = "." ] && SHELL_DIR=`pwd`
#models to build
MODEL_x86_64="TS-X71 TS-X53II"
#MODEL_x86_64="TS-X71"
MODEL_arm="TS-X31P"

#QTS source
SRC_REPO=/mnt/sourcetgz

#
# build media driver against given QTS version,
#
usage() {
	echo "Usage: $0 -q QTS -a ARCH"
	echo "    QTS: the QTS tar in ${SRC_REPO}, NasX86.tgz, NasX86.4.2.1.tgz, or NasX86.4.2.x.tgz"
	echo "   ARCH: arm or x86_64"
	exit
}


#
# 1. Set global variables according argument. 
# 2. Unter QTS compress file to $HOME
# In  : SSRC_REPO
# Out : $SRC_DIR - root of QTS
#       $ARCH - architecture, arm or x86_64
#       $TEST - null means not testing
#
parse_param() {
	local qts
	#parse option
	while getopts "q:a:t" opt; do
		case $opt in
		q) qts=$OPTARG;;
		a)
			case ${OPTARG} in
			arm)
				ARCH=${OPTARG}
				export PATH=/opt/cross-project/arm/linaro/bin:$PATH
				;;
			x86_64) ARCH=${OPTARG};;
			*) usage;;
			esac
			;;
		t) TEST=1;;
		*) usage;;
		esac
	done
        OPTIND=1

	test -z "${qts}" -o ! -f "${SRC_REPO}/${qts}" && echo "Missing QTS file ..." && usage
	local filename=`basename ${qts}`
	local subdir=${filename%.*}
	SRC_DIR=${HOME}/${subdir}

	#untar in home dir
	#take care if root QTS present
	test -d ${SRC_DIR} && {
		if [ -n "${TEST}" ]; then
			#ask if in testing
			echo -n "Whether to delete existing ${SRC_DIR} ? (N/y) "
			read ans
			case $ans in
			Y|y) rm -rf ${SRC_DIR};;
			esac
		fi
	}

	#create if not present
	test ! -d ${SRC_DIR} && mkdir -p ${SRC_DIR}
	test ! -d ${SRC_DIR}/Model && {
		cd && echo Extracting ${SRC_REPO}/${qts} ...
		tar xf ${SRC_REPO}/${qts} -C ${SRC_DIR} --strip-components=1
	}
}


#
# Build media driver for each model described in MODEL_$ARCH 
# In  : $SRC_DIR - root QTS directory
#       $ARCH and $MODEL_$ARCH - architecture and model to build
#
do_build() {
	#original log for version extraction
	local log=buildlog
	eval mlist=\$MODEL_${ARCH}
	
	for model in $mlist; do
		test -n "${TEST}" && echo $model
		#build all (kernel first)
		if [ -d ${SRC_DIR}/Model/${model} ]; then
			echo to build ${SRC_DIR}/Model/${model}
			python mediaBuild.py -m ${SRC_DIR}/Model/${model}
		fi
	done
}


parse_param $@
do_build
python chownOfFirst.py media .git .ccache release media
#this might fail unless we build NasX separately
[ ${ARCH} = 'x86_64' ] && rm -rf NasX86.4.2.1 NasX86.4.2.0 NasX86.4.2.1
