#!/bin/bash

#$1 ver
#$2 arch

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


#path of docker container
#export ARCH=x86_64
KVER=$1
ARCH=$2
[ -z "${KVER}" ] && echo Please specify the kernel version && exit
[ -z "${ARCH}" ] && ARCH=`uname -m`

export ARCH


[ ${ARCH} = arm ] && {
	export PATH=/opt/cross-project/arm/linaro/bin:$PATH
	export CROSS_COMPILE=arm-linux-gnueabihf-
}

TOP_KDIR=`pwd`
TOP_MDIR=${TOP_KDIR}/media
TOP_RDIR=${TOP_KDIR}/release
CUR_KDIR=${TOP_KDIR}/linux-${KVER}-${ARCH}
CUR_MDIR=${TOP_MDIR}/${KVER}
CUR_RDIR=${TOP_RDIR}/${KVER}/${ARCH}

#ver with first two number
KVER2=`echo ${KVER}| cut -f1,2 -d"."`

#determine media directory
#if a.b.c is not present, try a.b instead
test ! -d ${TOP_MDIR} && echo Missing ${TOP_MDIR} ...stop build && exit
test ! -d ${CUR_MDIR} && {
	if test -d ${TOP_MDIR}/${KVER2}; then
		CUR_MDIR=${TOP_MDIR}/${KVER2}
	else
		echo "Missing media directory for ${KVER}"
		exit
	fi
}

#test -d ${CUR_KDIR} && sudo rm -rf ${CUR_KDIR}

echo "To build ${CUR_MDIR}"
echo " against ${CUR_KDIR} ..."
[ ! -d ${CUR_KDIR} ] && echo "Missing kernel directory ${CUR_KDIR}" && exit
ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make -C ${CUR_KDIR} M=${CUR_MDIR} clean
ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make -C ${CUR_KDIR} M=${CUR_MDIR}
copy_mod ${CUR_MDIR} ${CUR_RDIR}
