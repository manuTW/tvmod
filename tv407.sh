#!/bin/sh
KERNEL_VER=`/bin/uname -r`
DVB_DIR=`pwd`
LOG_FILE=/tmp/dvb.log
PATH=/bin:/sbin:$PATH

# the modules to load, in this order
MOD_LIST="i2c-core rc-core dvb-core dvb-usb dvb_usb_v2 mxl5005s qt1010 mt2060 tda18218 tua9001\
	fc0013 af9013 dvb-pll tda18271 mc44s803 mxl5007t dvb-usb-af9015 dibx000_common\
	dib8000 dib0090 dib7000p dib7000m dib3000mc dib0070 s5h1411 lgdt3305 mt2266 tuner-xc2028\
	xc5000 xc4000 tveeprom videobuf-core videobuf-vmalloc tda18272 cx2341x cx231xx s5h1432\
	cx231xx-dvb cx231xx-alsa au8522 au0828 dib9000 dvb-usb-dib0700\
	dvb-usb-rtl2832 rtl2832 rtl2830 dvb-usb-rtl28xxu it913x-fe\
	dvb-usb-it913x af9033 fc0011 dvb-usb-af9035 dvb-usb-dtt200u"


# Insert kernel modules
function check_load_modules()
{
	KERNEL_ARCH=${KERNEL_VER}/`/bin/uname -m`
	MOD_PATH=${DVB_DIR}/modules/${KERNEL_ARCH}
	FW_PATH=${DVB_DIR}/firmware
	SYS_FW_PATH=/lib/firmware
	INS_LIST=

	#deal with firmware
	if [ -f ${SYS_FW_PATH} ]; then
		if [ ! -e ${SYS_FW_PATH}/dvb-core.ko -a -d ${SYS_FW_PATH} ]; then
			cp ${FW_PATH}/* ${SYS_FW_PATH}
		fi
	else
		ln -s ${FW_PATH} ${SYS_FW_PATH}
	fi
}
	#load
	for mm in ${MOD_LIST}; do
		test -e ${MOD_PATH}/${mm}.ko && {
			insmod ${MOD_PATH}/${mm}.ko >/dev/null 2>&1
			INS_LIST="${mm} ${INS_LIST}"
		}
	done

	for mm in ${INS_LIST}; do
		test ${mm} = dvb-usb-it9135 && mm=dvb-usb-it913x
		SUCCESS=`lsmod |grep ${mm}`
		test -z "${SUCCESS}" && {
			MM=`echo ${mm} |sed s/-/_/g`
			SUCCESS=`lsmod |grep ${MM}`
			test -z "${SUCCESS}" && echo "Fail to insert ${mm} ${MM}" >${LOG_FILE}
		}
	done
}


# Remove kernel modules
function remove_load_modules()
{
	RMMOD_LIST=

	for mm in ${MOD_LIST}; do
		RMMOD_LIST="${RMMOD_LIST} ${mm}"
	done

	for mm in ${RMMOD_LIST}; do
		rmmod ${mm} >/dev/null 2>&1
	done
}


case "$1" in
  start)
    >${LOG_FILE}
    check_load_modules
    ;;

  stop)
    remove_load_modules
    ;;

  restart)
    $0 stop
    $0 start
    ;;

  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit 0
