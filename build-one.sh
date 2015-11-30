#!/bin/bash

TOP_KDIR=`pwd`

#
# build media driver against CUR_KDIR, if not present, use linux-${KVER}-${ARCH} instead
# Usage:
#   build.sh -v KVER [-a ARCH] [-d CUR_KDIR]
#
usage() {
	echo "Usage: $0 -v KVER [-a ARCH] [-d CUR_KDIR]"
	echo "    KVER: kernel version, say, 3.19 or 3.12.6"
	echo "    ARCH: arm, x86_64, ... current kernel as the default"
	echo "    CUR_KDIR: configured kernel tree to build against"
	exit
}


#
# Update global variables
# In  : TOP_KDIR
# Out : TOP_MDIR, TOP_RDIR
#          KVER, KVER2, ARCH, CUR_KDIR, CUR_MDIR
#
parse_param() {
	local arch

	TOP_MDIR=${TOP_KDIR}/media
	TOP_RDIR=${TOP_KDIR}/release

	#parse option
	while getopts "v:a:d:" opt; do
		case $opt in
		v) KVER=$OPTARG;;
		a) arch=$OPTARG;;
		d) CUR_KDIR=$OPTARG;;
		*) usage;;
		esac
	done
	OPTIND=1

	#extract version
	test -z "${KVER}" && usage
	#ver with first two number
	KVER2=`echo ${KVER}| cut -f1,2 -d"."`

	#determine media directory, can be slightly different from kver
	CUR_MDIR=${TOP_MDIR}/${KVER}
	test ! -d ${CUR_MDIR} && {
		#if a.b.c is not present, try a.b instead
		if test -d ${TOP_MDIR}/${KVER2}; then
			CUR_MDIR=${TOP_MDIR}/${KVER2}
		else
			echo "Missing media directory for ${KVER}"
			exit
		fi
	}

	#architecture and release directory
	ARCH=${arch:-`uname -m`}
	export ARCH
	[ ${ARCH} = arm ] && {
		export PATH=/opt/cross-project/arm/linaro/bin:$PATH
		export CROSS_COMPILE=arm-linux-gnueabihf-
	}
	CUR_RDIR=${TOP_RDIR}/${KVER}/${ARCH}

	#determine kernel dir
	if [ -n "${CUR_KDIR}" ]; then
		test ! -d ${CUR_KDIR} && echo "${CUR_KDIR} doesn't exist" && exit
	elif [ -d ${TOP_KDIR}/linux-${KVER}-${ARCH} ]; then
		CUR_KDIR=${TOP_KDIR}/linux-${KVER}-${ARCH}
	elif [ -d ${TOP_KDIR}/linux-${KVER2}-${ARCH} ]; then
		CUR_KDIR=${TOP_KDIR}/linux-${KVER2}-${ARCH}
	else
		usage
	fi
	echo "To build media driver against ${CUR_KDIR}"
}


# modules to copy
MOD_LIST="fc0012.ko fc0013.ko fc2580.ko dvb-usb-rtl28xxu.ko rtl2832.ko af9013.ko dvb-core.ko dvb_usb_v2.ko qt1010.ko af9033.ko dvb-pll.ko fc0011.ko rtl2830.ko dib0070.ko dvb-usb-af9015.ko s5h1411.ko dib0090.ko dvb-usb-af9035.ko it913x-fe.ko tda18218.ko dib3000mc.ko dvb-usb-dib0700.ko lgdt3305.ko tda18271.ko dib7000m.ko dvb-usb-dtt200u.ko mc44s803.ko tua9001.ko dib7000p.ko dvb-usb-it913x.ko mt2060.ko tuner-xc2028.ko dib8000.ko mt2266.ko xc4000.ko dib9000.ko mxl5005s.ko xc5000.ko dibx000_common.ko dvb-usb.ko mxl5007t.ko rc-core.ko"

# $1 - top of linux-media directory
# $2 - destination directory
copy_mod() {
	SRC_DIR=$1
	DST_DIR=$2

	test -z "${SRC_DIR}" -o ! -d ${SRC_DIR} && echo Wrong source directory && exit 1
	test -z "${DST_DIR}" && echo Wrong destination directory && exit 1
	mkdir -p ${DST_DIR} &&\
		test ! -d ${DST_DIR} && echo Fail to create destination directory && exit 1

	for mm in ${MOD_LIST}; do
		find ${SRC_DIR} \-name "${mm}" \-exec cp {} ${DST_DIR} \;
		test ! -f ${DST_DIR}/${mm} && echo Fail to copy ${mm}
	done
}


#
# make sure the configured kernel is media driver ready
# In : $TOP_KDIR
#      $KVER2
#      $CUR_KDIR
#      
check_kdir() {
	test ! -f ${CUR_KDIR}/.config && echo "Kernel ${CUR_KDIR} is not configured !" && exit
	#make sure the kernel is media config enabled and make again
	if [ ! -f ${CUR_KDIR}/.add_media ]; then
		cat ${TOP_KDIR}/modify/modify-${KVER2}.cfg >> ${CUR_KDIR}/.config
		touch ${CUR_KDIR}/.add_media
		pushd ${CUR_KDIR} >/dev/null
		make >/tmp/log 2>&1
		popd >/dev/null
	fi
}

parse_param $@
check_kdir
#compile
ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make -C ${CUR_KDIR} M=${CUR_MDIR} clean
ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make -C ${CUR_KDIR} M=${CUR_MDIR}
copy_mod ${CUR_MDIR} ${CUR_RDIR}

