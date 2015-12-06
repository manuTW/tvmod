import argparse
import sys
import re

def usage(reason):
	if reason: print reason
	print '  Usage: modCfg [-i] [-v] [-a] -s cfgOrg [-o cfgOut]'
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


# parse kernel configuration and create database
class cKconfig(object):
	DVB_CORE_SETTING=('CONFIG_DVB_CORE=m', 'CONFIG_DVB_MAX_ADAPTERS=8', \
				'CONFIG_DVB_DYNAMIC_MINORS=y')
	RC_CORE_SETTING=('CONFIG_MEDIA_RC_SUPPORT=y', 'CONFIG_RC_CORE=m')

	# Check if a.b.c (or a.b), linux, kernel, and configuration present
	# extract a.b.c (or a.b) as version string
	# In : line - input string
	# Out: _version - a.b.c (or a.b) updated if not set
	def findVersion(self, line):
		if not self._version:
			matchCount=0
			if re.search('linux', line, re.M|re.I): matchCount += 1
			if re.search('kernel', line, re.M|re.I): matchCount += 1
			if re.search('configuration', line, re.M|re.I): matchCount += 1
			if matchCount is 3:
				matchObj=re.match(r'.*?(\d+)\.(\d+)\.(\d+)', line)
				if matchObj:
					self._version=matchObj.group(1) + '.' + matchObj.group(2) +\
						'.' + matchObj.group(3)
					return
				matchObj=re.match(r'.*?(\d+)\.(\d+)', line)
				if matchObj:
					self._version=matchObj.group(1) + '.' + matchObj.group(2)

	# In : full path configuratin file
	# Out: _arch - architecture string, 'x86_64', 'x86', or 'arm'
	#      _version - version string 'a.b.c' or 'a.b'
	def __init__(self, cfgName):
		self._rc_coreEnable=False
		self._dvb_coreEnable=False
		self._version=None
		self._arch=None
		isX86=False
		try:
			fcfg=open(cfgName, "r")
			for line in fcfg:
				if re.search(r'CONFIG_DVB_CORE=y', line, re.M|re.I):
					self._dvb_coreEnable=True
					continue
				if re.search(r'CONFIG_MEDIA_RC_SUPPORT=y', line, re.M|re.I):
					self._rc_coreEnable=True
					continue
				if not self._arch and re.search(r'CONFIG_X86_64=y', line, re.M|re.I):
					self._arch='x86_64'
					continue
				if re.search(r'CONFIG_X86=y', line, re.M|re.I):
					isX86=True
					continue
				self.findVersion(line)
		except IOError as e:
			print "I/O error({0}): {1}".format(e.errno, e.strerror)
			sys.exit(1)
		except:
			print "Unexpected error:", sys.exc_info()[0]
			sys.exit(1)
		if not self._arch:
			if isX86: self._arch='x86'
			else: self._arch='arm'
		fcfg.close()

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
	arg=check_param()
	cfg=cKconfig(arg.cfgOrg)
	ver, arch=cfg.getVerArch()
	if arg.verOnly:	print ver
	elif arg.archOnly: print arch
	elif arg.infoOnly:
		print ver, arch
		for ln in cfg.getRC(): print ln
		for ln in cfg.getDVB(): print ln

sys.exit(0)