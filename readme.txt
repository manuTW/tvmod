The TV tuner drivers are to build for running on NAS. The directories are arranged as followings:
	- deploy: NAS build environment against which the driver has to be built
	- firmware: contain firmware for drivers
	- media: be composed of various tuner drivers for each version of kernel
	- modify: change of NAS kernel configurations to be applied during build

Basically the tuner drivers are built for selected models. They are
	- x86_64: TS-X71 and TS-X53II
	- ARM: TS-X31P
Please refer to 'MODEL_xxx' in build-all.sh. A model is built till kernel done and we determine the
kernel version in this stage. Then modify kernel configuration and build kernel again. Finally with
such kernel tree we build TV tuner driver for the NAS model.

Whenever drivers for a model are built, they are collected into directory 'release' by architecture
and by kernel version. When all built done, they are place in /var/lib/jenkins/modules and further
categorized by vermagic. The whole directory 'modeules' is tar'ed and will be inserted into 
tvheadend docker image during image build.

There is also a file 'install' being put into tvheadend image as well. It serves as an installer
during docker image create and also the RC file (rename as run.sh) on NAS before starting a
container instance. To work as installer, there are some environment variable must be set.
	- VERMAGIC: the magic version code of running NAS.
	            Only those drivers matching VERMAGIC will be copied.
	- LIB_MODULE: the directory the drivers are copied to
	- LIB_FIRMWARE: the directory the firmwares are copied to
	- APP_DIR: that is '/app_dir' into which we duplicate the RC file
When serving as a RC file, the 'install' file, i.e. run.sh this moment, requires LIB_MODULE defined
as the directory the drivers are located.