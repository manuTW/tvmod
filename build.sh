#!/bin/bash

#$1 ver
#$2 arch
#    x86_64
#    arm

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
#determine media directory
#
# In : $TOP_MDIR - directory "media" should present at top directory
#      $CUR_MDIR - directory $KERV should present as subdir of "media",
#		use a.b if a.b.c is not present
# Out: KVER2 - first two number of kernel version
check_mdir() {
	#ver with first two number
	KVER2=`echo ${KVER}| cut -f1,2 -d"."`

	test ! -d ${TOP_MDIR} && echo Missing ${TOP_MDIR} ...stop build && exit
	#if a.b.c is not present, try a.b instead
	test ! -d ${CUR_MDIR} && {
		if test -d ${TOP_MDIR}/${KVER2}; then
			CUR_MDIR=${TOP_MDIR}/${KVER2}
		else
			echo "Missing media directory for ${KVER}"
			exit
		fi
	}
}


#
# export ARCH, PATH and CROSS_COMPILE if there is special settings
#
exp_vars() {
	export ARCH
	[ ${ARCH} = arm ] && {
		export PATH=/opt/cross-project/arm/linaro/bin:$PATH
		export CROSS_COMPILE=arm-linux-gnueabihf-
	}
}


#
# determine kernel dir to work with
# precedence
#  - TOP_KDIR
#  - Kernel of build system
# In : $TOP_KDIR
#      $KVER/$KVER2
#      $ARCH
#      $CUR_KDIR
#      
check_kdir() {
	CUR_KDIR=${TOP_KDIR}/linux-${KVER}-${ARCH}
	if [ ! -d ${CUR_KDIR} ]; then
		if [ -d Kernel ];then CUR_KDIR=Kernel ; fi
	fi
	test ! -f ${CUR_KDIR}/.config && echo "Kernel ${CUR_KDIR} is not configured !" && exit
	#make sure the kernel is media config enabled and make again
	if [ ! -f ${CUR_KDIR}/.add_media ]; then
		cat ${TOP_KDIR}/modify/modify-${KVER2}.cfg >> ${CUR_KDIR}/.config
		touch ${CUR_KDIR}/.add_media
		pushd ${CUR_KDIR} >/dev/null
		make
		popd >/dev/null
	fi
}

KVER=$1
ARCH=${2:-`uname -m`}
[ -z "${KVER}" ] && echo Please specify the kernel version && exit


TOP_KDIR=`pwd`
TOP_MDIR=${TOP_KDIR}/media
TOP_RDIR=${TOP_KDIR}/release
CUR_MDIR=${TOP_MDIR}/${KVER}
CUR_RDIR=${TOP_RDIR}/${KVER}/${ARCH}

#test -d ${CUR_KDIR} && sudo rm -rf ${CUR_KDIR}
exp_vars
check_mdir
check_kdir
echo "To build ${CUR_MDIR} for ${ARCH}"
echo " against ${CUR_KDIR} ..."
[ ! -d ${CUR_KDIR} ] && echo "Missing kernel directory ${CUR_KDIR}" && exit
ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make -C ${CUR_KDIR} M=${CUR_MDIR} clean
ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make -C ${CUR_KDIR} M=${CUR_MDIR}
copy_mod ${CUR_MDIR} ${CUR_RDIR}

