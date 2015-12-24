from kMediaCfg import *
from QTS import *
import os
import sys
import re
import argparse
import glob

class cQTSmedia(object):
	MOD_LIST=('fc0012.ko', 'fc0013.ko', 'fc2580.ko', 'dvb-usb-rtl28xxu.ko', 'rtl2832.ko', \
		'af9013.ko', 'dvb-core.ko', 'dvb_usb_v2.ko', 'qt1010.ko', 'af9033.ko', 'dvb-pll.ko', \
		'fc0011.ko', 'rtl2830.ko', 'dib0070.ko', 'dvb-usb-af9015.ko', 's5h1411.ko', 'dib0090.ko', \
		'dvb-usb-af9035.ko', 'it913x-fe.ko', 'tda18218.ko', 'dib3000mc.ko', 'dvb-usb-dib0700.ko', \
		'lgdt3305.ko', 'tda18271.ko', 'dib7000m.ko', 'dvb-usb-dtt200u.ko', 'mc44s803.ko', \
		'tua9001.ko', 'dib7000p.ko', 'dvb-usb-it913x.ko', 'mt2060.ko', 'tuner-xc2028.ko', \
		'dib8000.ko', 'mt2266.ko', 'xc4000.ko', 'dib9000.ko', 'mxl5005s.ko', 'xc5000.ko', \
		'dibx000_common.ko', 'dvb-usb.ko', 'mxl5007t.ko', 'rc-core.ko')
		
	# Given shell directory, pick the correct modification cfg.
	# It is modify/modify-a.b.cfg
	# In : _shellDir - shell directory
	#      _kver - kernel version a.b.c or a.b
	#      _kver2 - a.b
	# Ret : None - if not find
	#       otherwise - full path config file name
	def _getModifyCfg(self):
		path=self._shellDir+'/modify/modify-'+self._kver+'.cfg'
		if os.path.isfile(path): return path
		path=self._shellDir+'/modify/modify-'+self._kver2+'.cfg'
		if os.path.isfile(path): return path
		return None


	# full path of model directory
	# Prepare kernel version, architecture, and many directory path variables
	# In : modelDir - full path of model directory
	# Out : _shellDir, _modelDir, _qts, _qtsCfgName, _cfg
	#       _arch, _kver2, _kver, _preCmd, _releaseDir
	#       _moduleDir, _modifyCfg, _qtsKernelDir
	def __init__(self, modelDir):
		#directory in shell directory
		self._shellDir=os.path.dirname(os.path.realpath(__file__))
		#removing trailing '/'
		self._modelDir=re.sub(r'/*$', "", os.path.abspath(modelDir))
		self._qts=cQTSmodel(self._modelDir)   #create .mk
		#get configure from buildlog of model
		self._qtsCfgName=self._qts.getCfg()
		self._cfg=cMediaCfg(self._qtsCfgName)

		#get version of configuration
		#get a.b.c or a.b, arch=arm, x86, or x86_64
		self._kver, self._arch = self._cfg.getVerArch()
		matchObj=re.match(r'\d+\.\d+', self._kver)
		if not matchObj:
			print 'Wrong kernel version', self._kver
			sys.exit(1)
		self._kver2=matchObj.group(0)
		if 'arm' == self._arch:
			self._preCmd='ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- '
		else: self._preCmd='ARCH='+self._arch+' CROSS_COMPILE= '
		
		#set directory vars
		self._releaseDir=self._shellDir+'/release/'+self._kver+'/'+self._arch
		#for network driver today
		self._releaseMiscDir=self._shellDir+'/release_misc/'+self._kver+'/'+self._arch
		self._moduleDir=self._shellDir+'/media/'+self._kver2
		self._modifyCfg=self._getModifyCfg()
		if not self._modifyCfg:
			print 'Missing modified configuration'
		self._qtsKernelDir=self._qts.getKdir()
		if not self._qtsKernelDir:
			print 'Find no kernel '+self._kver+' for '+self._modelDir
			sys.exit(1)


	# 1. synthesize a configuration file in model dir
	# 2. build model (kernel only most likely)
	# 3. restore configuration
	def prepareKernel(self):
		#remove config in kernel tree
		os.system('rm -f '+self._qtsKernelDir+'/.config')
		#generate .cfg in model dir
		self._cfg.merge(self._modifyCfg, self._modelDir+'/.cfg')
		#add net
		path=self._shellDir+'/net/modify.cfg'
		if os.path.isfile(path):
			os.system('cat '+path+' >>'+self._modelDir+'/.cfg')
		#swap
		os.system('mv '+self._qtsCfgName+' '+self._modelDir+'/.bak')
		os.system('mv '+self._modelDir+'/.cfg '+self._qtsCfgName)
		self._qts.doMake()
		os.system('mv '+self._modelDir+'/.bak '+self._qtsCfgName)
		if not os.path.isfile(self._qtsKernelDir+'/.config'):
			print 'Build '+self._qtsKernelDir+' might fail'
		#misc object in kernel tree
		os.system('mkdir -p '+self._releaseMiscDir)
		cmd='cp '+self._qtsKernelDir+'/driver/net/vxlan.ko '+
			self._qtsKernelDir+'/net/ipv4/udp_tunnel.ko '+
			self._qtsKernelDir+'/net/ipv6/ip6_udp_tunnel.ko '+
			self._releaseMiscDir
		os.system(cmd)


	# 1. build media against kernel tree of this model
	# 2. collect ko into release directory
	def buildMedia(self):
		print 'Building media driver'
		log=self._shellDir+'/kmedia.log'
		cmd=self._preCmd+'make -C '+self._qtsKernelDir+' M='+self._moduleDir
		os.system(cmd+' clean >/dev/null 2>&1')
		os.system(cmd+' >>'+log+' 2>&1')
		if not os.path.isfile(self._moduleDir+'/dvb-core/dvb-core.ko'):
			print "Missing dvb-core.ko, build might fail !"
		os.system('mkdir -p '+self._releaseDir)
		for root, dirs, files in os.walk(self._moduleDir):
			for ff in files:
				if ff in self.MOD_LIST:
					os.system('cp '+root+'/'+ff+' '+self._releaseDir)

#main
if '__main__' == __name__:
	def usage(reason=None):
		if reason: print reason
		print '  Usage: mediaBuild.py -m modelPath'
		print '  Ret: 0 success and 1 failure'
	
	# process parameters
	# Ret: exit 1 if fails
	#      otherwise - parsed argument object 
	def check_param():
		parser = argparse.ArgumentParser()
		parser.add_argument('-m', action='store', dest='mdPath',
			help='model path')
		arg = parser.parse_args()
		if not arg.mdPath:
			usage("Missing model path")
			sys.exit(1)
		return arg

	#main
	arg=check_param()
	model=cQTSmedia(arg.mdPath)
	model.prepareKernel()
	model.buildMedia()
