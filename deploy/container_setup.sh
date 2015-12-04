#!/bin/bash

GIT_DOTFILES=http://172.17.23.195:10080/QNAP/dotfiles.git
GIT_DOTVIM=http://172.17.23.195:10080/QNAP/dotvim.git

BUILDER_1="192.168.81.5:5000/builder"
BUILDER_2="192.168.81.5:5000/mindspeed-builder"
BUILDER_3="172.17.23.195:5000/pure_builder"
CT_IMAGE="172.17.23.195:5000/ct_volume"
CT_NAME="ct_volume_container"
HOSTDIR=/home/$USER/working

BUILDER_OPTS="
	--privileged \
	--net=host \
	--rm \
	-e PNAME=$1-builder-`date +%s` \
	-u root \
	-w /root \
	-v /mnt/sourcetgz:/mnt/sourcetgz:ro \
	-v $HOSTDIR:/root \
	-v /mnt/pub:/mnt/pub:rw \
	-v /etc/localtime:/etc/localtime:ro \
	-v /etc/timezone:/etc/timezone:ro \
	--name=$USER-$1-`date +%s`"

get_toolchain(){
	CT_RUNNING=$(docker inspect --format="{{.State.Running}}" $CT_NAME 2> /dev/null)
	if [ "$CT_RUNNING" != "false" ]; then
		docker pull $CT_IMAGE
		docker run -id --read-only=true --name $CT_NAME $CT_IMAGE /bin/busybox
	fi
}

# env setting can only be setup before the working is created
setup_env(){
	if [ ! -d "$HOSTDIR" ]; then
		mkdir -p $HOSTDIR
		cd $HOSTDIR
		git clone $GIT_DOTVIM .vim
		ln -sf .vim/vimrc .vimrc
		git clone $GIT_DOTFILES dotfiles
		dotfiles/link.sh
	fi
}

# check /mnt/pub mounting status
MNT_PUB_FILES=$(ls -l /mnt/pub | wc -l)
if [ "$MNT_PUB_FILES" -lt 5 ]; then
	echo
	echo "Please NFS mount 172.17.21.5:/pub to /mnt/pub"
	echo "Otherwise, you cannot use this Docker builder"
	echo
	echo "Example command:"
	echo "mount.nfs -o ro,nolock 172.17.21.5:/pub /mnt/pub"
	echo
	exit
fi

i686=(TS-X79 SS-X79 ATHENS CMS-2000 HS-200 HS-251 IS-400 SS-1279 SS-1879 SS-2479 SS-439 SS-469 SS-839 SS-X53 TS-1079 TS-1259U TS-1269 TS-1270 TS-1279 TS-1679 TS-230 TS-239 TS-259 TS-269H TS-269 TS-270 TS-439 TS-439U TS-459 TS-469 TS-470 TS-509 TS-559 TS-569 TS-609 TS-639 TS-659 TS-669 TS-670 TS-809 TS-809U TS-839 TS-859 TS-869 TS-870 TS-879 TS-X480 TS-X51 TS-X53II TS-X53 TS-X62 TS-X63 TS-X64 TS-X71 TS-X80 TS-X89 TS-XXX VMWare VS-12100UPro+ VS-12100UProSeries VS-2000ProSeries VS-2100 VS-2100Pro+ VS-2200 VS-2300Series VS-4000ProSeries VS-4000UProSeries VS-4100Pro+ VS-4100Series VS-4100UPro+ VS-4300 VS-5000Series VS-6000ProSeries VS-6100Pro+ VS-8000 VS-8000U VS-8100UPro VS-8100UPro+ VS-Bromolow VSM-2000 VS-M4000 VS-M4000Series VSM-4000U)
arm_marvell=(TS-420 HS-210 TS-119 TS-118 TS-419 TS-221 TS-220 NMP-4000 TS-410U HV-8000 TS-120 TS-121 TS-421 TS-422 TS-419U HV-4000 TS-218 NMP-2000 TS-219 TS-420U TS-410)
arm_al=(TS-X43 TS-X60 TS-X48 TS-X41)
arm_ms=(TS-X31)
x86_64=(TS-X51 TS-X53 TS-X71 TS-X79 SS-X79 HS-251 IS-400 SS-X53 TS-X480 TS-X63 TS-X80 TS-X89 VS-2200 TS-X53II SS-1279 SS-1879 SS-2479 TS-1079 TS-1279 TS-1679 TS-879)

array_builder1=(${arm_al[@]} ${arm_marvell[@]} ${i686[@]})
array_builder2=(${arm_ms[@]})
array_builder3=(${x86_64[@]})

models_mapping(){
	if [ "$2" == "x86_64" ] && [[ ${x86_64[*]} =~ $1 ]]; then
		echo "x86_64 pass, use BUILDER 3"
	elif [ "$2" == "i686" ] && [[ ${i686[*]} =~ $1 ]]; then
		echo "i686 pass, use BUILDER 1"
	elif [ "$2" == "" ] && [[ ${arm_ms[*]} =~ $1 ]]; then
		echo "arm_ms pass, use BUILDER 2"
	elif [ "$2" == "" ] && [[ ${arm_al[*]} =~ $1 ]]; then
		echo "arm_al pass, use BUILDER 1"
	elif [ "$2" == "" ] && [[ ${arm_marvell[*]} =~ $1 ]]; then
		echo "arm_marvell pass, use BUILDER 1"
	fi
}

# models_mapping $1 $2

case $1 in
	cleanup)
		if [ "$EUID" -ne 0 ]; then
		    echo
		    echo "Please run as root or sudo user."
		    echo
		    exit
		fi
		docker rm -f $(docker ps -aq)
		docker rmi $(docker images -q)
		echo
		echo "Removed all containers & images"
		echo
		exit
		;;
	i686|arm_al|arm_marvell)
		setup_env
		docker pull $BUILDER_1
		if [ -z "$2" ]; then
			docker run  $BUILDER_OPTS -ti $BUILDER_1 /usr/bin/linux32 /bin/bash
		else
			docker-compose -f arm_al.yml up
		fi
		;;
	x86_64)
		setup_env
		get_toolchain
		docker pull $BUILDER_3
		if [ -z "$2" ]; then
			docker run  $BUILDER_OPTS --volumes-from $CT_NAME:ro -ti $BUILDER_3 /bin/bash
		else
			docker-compose -f x86_64.yml up
		fi
		;;
	arm_ms)
		setup_env
		docker pull $BUILDER_2
		docker run  $BUILDER_OPTS -ti $BUILDER_2 /usr/bin/linux32 /bin/bash
		;;
	*)
		echo 
		echo "-------------------------------------------------------------------"
		echo 
		echo "Command format:"
		echo "./container_setup.sh [i686|arm_al|arm_marvell|x86_64|arm_ms|cleanup]"
		echo 
		echo "[cleanup]"
		echo "remove all containers & images (root only!!)"
		echo 
		echo "[arm_marvell]"
		echo "TS-420 HS-210 TS-119 TS-118 TS-419 TS-221 TS-220 NMP-4000 TS-410U"
		echo "HV-8000 TS-120 TS-121 TS-421 TS-419U HV-4000 TS-218 NMP-2000 TS-219"
		echo "HV-8000 TS-120 TS-121 TS-421 TS-419U HV-4000 TS-218 NMP-2000 TS-219"
		echo "TS-420U TS-410 TS-422"
		echo 
		echo "[arm_al]"
		echo "TS-X43 TS-X60 TS-X48 TS-X41"
		echo 
		echo "[arm_ms]"
		echo "TS-X31"
		echo
		echo "[x86_64]"
		echo "TS-X51 TS-X53 TS-X71 TS-X79 SS-X79 HS-251 IS-400 SS-X53 TS-X480"
		echo "SS-1279 SS-1879 SS-2479 TS-1079 TS-1279 TS-1679 TS-879"
		echo "TS-X63 TS-X80 TS-X89 VS-2200 TS-X53II"
		echo
		echo "[i686]"
		echo "TS-X79 SS-X79 ATHENS CMS-2000 HS-200 HS-251 IS-400 SS-1279 SS-1879"
		echo "SS-2479 SS-439 SS-469 SS-839 SS-X53 TS-1079 TS-1259U TS-1269 TS-1270"
		echo "TS-1279 TS-1679 TS-230 TS-239 TS-259 TS-269H TS-269 TS-270 TS-439"
		echo "TS-439U TS-459 TS-469 TS-470 TS-509 TS-559 TS-569 TS-609 TS-639"
		echo "TS-659 TS-669 TS-670 TS-809 TS-809U TS-839 TS-859 TS-869 TS-870"
		echo "TS-879 TS-X480 TS-X51 TS-X53II TS-X53 TS-X62 TS-X63 TS-X64 TS-X71"
		echo "TS-X80 TS-X89 TS-XXX VMWare VS-12100UPro+ VS-12100UProSeries VS-2000ProSeries"
		echo "VS-2100 VS-2100Pro+ VS-2200 VS-2300Series VS-4000ProSeries VS-4000UProSeries"
		echo "VS-4100Pro+ VS-4100Series VS-4100UPro+ VS-4300 VS-5000Series VS-6000ProSeries"
		echo "VS-6100Pro+ VS-8000 VS-8000U VS-8100UPro VS-8100UPro+ VS-Bromolow"
		echo "VSM-2000 VS-M4000 VS-M4000Series VSM-4000U"
		echo
		echo "-------------------------------------------------------------------"
		echo 
		;;
esac
