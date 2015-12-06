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
		return None

	# In : full path configuratin file
	# Out: _arch - architecture string, 'x86_64', 'x86', or 'arm'
	#      _version - version string 'a.b.c' or 'a.b'
	def __init__(self, cfgName):
		super(cMediaCfg, self).__init__(cfgName)

	#Ret : version and architecture string parsed
	#      otherwise - ""
	def getVerArch(self):
		return self._version, self._arch

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
		print '  Usage: modCfg [-v] [-a] -s cfgOrg [-o cfgOut]'
		print '    if version of cfgOrg parsed, corresponding modify-ver is applied and output'
		print '    -i: show all information, no further operation'
		print '    -v: show kernel version, no further operation'
		print '    -a: show architecture, no further operation'
		print '    cfgOrg: original configuration file'
		print '    cfgExt: extra configuration file. If not present, information of original'
		print '            is displayed. Otherwise, a merged configuration generated'
		print '    cfgOut: output configuration if cfgExt present. default to .config'
		print '  Ret: 0 success and 1 failure'
	
	# process parameters
	# Ret: exit 1 if fails
	#      otherwise - parsed argument object 
	def check_param():
		parser = argparse.ArgumentParser()
		parser.add_argument('-s', action='store', dest='cfgOrg',
			help='Original configuration file')
		parser.add_argument('-i', action='store_true', default=False, dest='infoOnly')
		parser.add_argument('-v', action='store_true', default=False, dest='verOnly')
		parser.add_argument('-a', action='store_true', default=False, dest='archOnly')
		parser.add_argument('-o', action='store', dest='cfgOut',
			default=".config",
			help='Output configuration')
		arg = parser.parse_args()
		if not arg.cfgOrg:
			usage("Missing original configuration file")
			sys.exit(1)
		return arg
	#main: demo the usage
	arg=check_param()
	cfg=cMediaCfg(arg.cfgOrg)
	ver, arch=cfg.getVerArch()
	if arg.verOnly:	print ver
	elif arg.archOnly: print arch
	else: print ver, arch
	sys.exit(0)