from kConfig import * 
import sys
import re

# parse kernel configuration and create database
class cMediaCfg(cKconfig):
	DVB_CORE_SETTING=('CONFIG_DVB_CORE=m', 'CONFIG_DVB_MAX_ADAPTERS=8', \
				'CONFIG_DVB_DYNAMIC_MINORS=y')
	RC_CORE_SETTING=('CONFIG_MEDIA_RC_SUPPORT=y', 'CONFIG_RC_CORE=m')

	@dec_parser
	def _parser(self, line):
		if re.search(r'CONFIG_DVB_CORE=y', line, re.I):
			self._dvb_coreEnable=True
			return 'continue'
		if re.search(r'CONFIG_MEDIA_RC_SUPPORT=y', line, re.I):
			self._rc_coreEnable=True
			return 'continue'
		return None
		
	# In : full path configuratin file
	# Out: _arch - architecture string, 'x86_64', 'x86', or 'arm'
	#      _version - version string 'a.b.c' or 'a.b'
	def __init__(self, cfgName):
		self._rc_coreEnable=False
		self._dvb_coreEnable=False
		super(cMediaCfg, self).__init__(cfgName)
		#append our extra lines
		if not self._rc_coreEnable:
			for item in self.RC_CORE_SETTING:
				self._extra.append(item)
		if not self._dvb_coreEnable:
			for item in self.DVB_CORE_SETTING:
				self._extra.append(item)

	#Ret : None - no alter since it is 'y'
	#      otherwise - tuple to write to configure file
	def getDVB(self):
		if self._dvb_coreEnable:
			return ()
		else:
			return self.DVB_CORE_SETTING

	#Ret : None - no alter since it is 'y'
	#      otherwise - tuple to write to configure file
	def getRC(self):
		if self._rc_coreEnable:
			return ()
		else:
			return self.RC_CORE_SETTING

if __name__ == '__main__':
	def usage(reason):
		if reason: print reason
		print '  Usage: kMediaCfg.py [-v] [-a] -s cfgOrg [-m cfgMerge] [-o cfgOut]'
		print '    if version of cfgOrg parsed, corresponding modify-ver is applied and output'
		print '    -v: show kernel version, no further operation'
		print '    -a: show architecture, no further operation'
		print '    -m: file to merge into original config to form the new config'
		print '    -o: output file of the new config. When -m, cfg is the default output'
		print '    -s: original configuration file'
		print '  Ret: 0 success and 1 failure'
	
	# process parameters
	# Ret: exit 1 if fails
	#      otherwise - parsed argument object 
	def check_param():
		parser = argparse.ArgumentParser()
		parser.add_argument('-s', action='store', dest='cfgOrg',
			help='Original configuration file')
		parser.add_argument('-v', action='store_true', default=False, dest='verOnly')
		parser.add_argument('-a', action='store_true', default=False, dest='archOnly')
		parser.add_argument('-m', action='store', dest='cfgMerge',
			help='Configuration file to merge')
		parser.add_argument('-o', action='store', dest='cfgOut',
			help='Configuration file to merge')
		arg = parser.parse_args()
		if not arg.cfgOrg:
			usage("Missing original configuration file")
			sys.exit(1)
		if arg.cfgMerge:
			if not arg.cfgOut: arg.cfgOut='cfg'     #default output name
		return arg
	#main: demo the usage
	arg=check_param()
	cfg=cMediaCfg(arg.cfgOrg)
	ver, arch=cfg.getVerArch()
	if arg.verOnly:	print ver
	elif arg.archOnly: print arch
	elif arg.cfgMerge or arg.cfgOut:
		cfg.merge(arg.cfgMerge, arg.cfgOut)
	else:
		print ver, arch
		for ln in cfg.getExtra(): print ln
	sys.exit(0)
