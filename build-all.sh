#!/bin/bash

SHELL_DIR=`pwd`
#models to build
MODEL_x86_64="TS-X71 TS-X53II"
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
			arm|x86_64) ARCH=${OPTARG};;
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
	test -z "${TEST}" && {
		#remove QTS if present
		test -d ${SRC_DIR} && rm -rf ${SRC_DIR}
		mkdir -p ${SRC_DIR}
		cd && echo Extracting ${SRC_REPO}/${qts} ...
		tar xf ${SRC_REPO}/${qts} -C ${SRC_DIR} --strip-components=1
	}
}


#
# Given input string containing file path of " xxxx/linux-abc/yyyy"
# Ret : string "linux-a.b.c" as it in Kernel of QTS tree
# $1 - intput string
extract_linux() {
	for elm in $1; do
		if [[ "${elm}" =~ linux ]]; then
			local NAME=`echo ${elm} |sed -e 's/\// /g'`
			for nn in ${NAME}; do
				if [[ ${nn} =~ linux ]]; then
					echo ${nn}
					return
				fi
			done
		fi
	done
}


#
# Build media driver for each model described in MODEL_$ARCH 
# In  : $SRC_DIR - root QTS directory
#       $ARCH and $MODEL_$ARCH - architecture and model to build
#
do_build() {
	local log=buildlog
	eval mlist=\$MODEL_${ARCH}
	for model in $mlist; do
		test -n "${TEST}" && echo $model
		#build all (kernel first)
		if [ -d ${SRC_DIR}/Model/${model} ]; then
			echo to build ${SRC_DIR}/Model/${model}
			pushd ${SRC_DIR}/Model/${model} >/dev/null
			local top_kdir=${SRC_DIR}/Kernel
			#build if log not present and not in test
			test ! -f ${log} -a -z "${TEST}" && make OPENSSL_VER=1.0 FACTORY_MODEL=no > ${log} 2>&1
			#kdir is, for example, "linux-3.12.6"
			local kstr=`grep Kernel ${log}| grep -m1 linux`
			if [ -z "${kstr}" ]; then
				echo "Find no kernel version in log ..."
			else
				local kdir=`extract_linux "${kstr}"`
				if [ -f ${top_kdir}/${kdir}/Module.symvers ]; then
					echo start building
					pushd ${SHELL_DIR} >/dev/null
					./build-one.sh -v ${kdir#linux-} -a ${ARCH} -d ${top_kdir}/${kdir}
					popd >/dev/null
				else
					echo "${top_kdir}/${kdir} might not be fully built"
				fi
			fi
			popd >/dev/null
		fi
	done
}


parse_param $@
do_build
