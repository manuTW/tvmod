#!/bin/bash
#LIB_MODULE is the directory modules are placed

KERNEL_VER=`uname -r |sed s'/-/\./g' |cut -f 1,2,3 -d"."`
ARCH=`uname -m`
if [[ $ARCH =~ arm* ]]; then ARCH=arm; fi
#LIB_MODULE is defined as module path
#LIB_FIRMWARE
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
	MOD_PATH=${LIB_MODULE}
	INS_LIST=

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

  install)
    KVER2=`echo ${KERNEL_VER} |cut -f 1,2 -d"."`
    #copy fw
    cp -a firmware/* ${LIB_FIRMWARE}

    #pick module by ver/arch
    test -d release/${KERNEL_VER} && rdir=release/${KERNEL_VER}
    test -z "${rdir}" && test -d release/${KVER2} && rdir=release/${KVER2}
    if [ -z "${rdir}" ]; then
	echo "Fail to locate modules"
	exit 1
    elif [ ! -d ${rdir}/${ARCH} ]; then
	echo "Architecture not supported"
	exit 1
    fi
    cp ${rdir}/${ARCH}/*.ko ${LIB_MODULE}
    ;;
  uninstall)
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|install|uninstall}"
    exit 1
esac

exit 0
