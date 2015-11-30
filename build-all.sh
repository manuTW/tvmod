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
# Update global variables
# Output : FILENAME
#
#
parse_param() {
	#parse option
        while getopts "q:a:t" opt; do
                case $opt in
                q) QTS=$OPTARG;;
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

	test -z "${QTS}" -o ! -f "${SRC_REPO}/${QTS}" && echo "Missing QTS file ..." && usage
	local filename=`basename ${QTS}`
	SRC_DIR=${HOME}/${filename%.*}

	#untar in home dir
	test -z "${TEST}" && {
		#remove QTS if present
		test -d ${SRC_DIR} && rm -rf ${SRC_DIR}
		cd && echo Extracting ${SRC_REPO}/${QTS} ...
		tar xf ${SRC_REPO}/${QTS}
	}
}


#
# Given input string containing file path of " xxxx/linux-abc/yyyy"
# Output linux-abc
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
	KDIR=
}


#SRC_DIR
do_build() {
	local log=buildlog
	eval mlist=\$MODEL_${ARCH}
	for model in $mlist; do
		echo $model
		#build all (kernel first)
		if [ -d ${SRC_DIR}/Model/${model} ]; then
			echo to build ${SRC_DIR}/Model/${model}
			pushd ${SRC_DIR}/Model/${model} >/dev/null
			TOP_KDIR=${SRC_DIR}/Kernel
			#build if log not present and not in test
			test ! -f ${log} -a -z ${TEST} && make OPENSSL_VER=1.0 FACTORY_MODEL=no > ${log} 2>&1
			#KDIR is, for example, "linux-3.12.6"
			local kstr=`grep Kernel ${log}| grep -m1 linux`
			if [ -z "${kstr}" ]; then
				echo "Find no kernel version in log ..."
			else
				KDIR=`extract_linux "${kstr}"`
				if [ -f ${TOP_KDIR}/${KDIR}/Module.symvers ]; then
					echo start building
					pushd ${SHELL_DIR} >/dev/null
					./build-one.sh -v ${KDIR#linux-} -a ${ARCH} -d ${TOP_KDIR}/${KDIR}
					popd >/dev/null
				else
					echo "${TOP_KDIR}/${KDIR} might not be fully built"
				fi
			fi
			popd >/dev/null
		fi
	done
}


parse_param $@
do_build
