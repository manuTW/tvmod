import argparse
import sys
import re

def usage(reason):
	if None != reason: print reason
	print 'Usage: modCfg -s cfgOrg -c cfgExt [-o cfgOut]'
	print '   cfgOrg: original configuration file'
	print '   cfgExt: extra configuration file'

# parse kernel configuration and create database
class cKconfig(object):
	DVB_CORE_SETTING=('CONFIG_DVB_CORE=m', 'CONFIG_DVB_MAX_ADAPTERS=8', \
				'CONFIG_DVB_DYNAMIC_MINORS=y')
	RC_CORE_SETTING=('CONFIG_MEDIA_RC_SUPPORT=y', 'CONFIG_RC_CORE=m')

	#Ret: None - if one of the MATCH_STR doesn't appear
	#   otherwise - return version a.b.c
	def findVersion(self, line):
		if self._version == "":
			matchCount=0
			searchObj = re.search('linux', line, re.M|re.I)
			if searchObj: matchCount += 1
			searchObj = re.search('kernel', line, re.M|re.I)
			if searchObj: matchCount += 1
			searchObj = re.search('configuration', line, re.M|re.I)
			if searchObj: matchCount += 1
			if matchCount is 3:
				matchObj=re.match(r'.*(\d+)\.(\d+)\.(\d+)', line)
				if matchObj:
					return matchObj.group(1) + '.' + matchObj.group(2) +\
						'.' + matchObj.group(3)
				matchObj=re.match(r'.*(\d+)\.(\d+)', line)
				if matchObj:
					return matchObj.group(1) + '.' + matchObj.group(2)
		return None

	def __init__(self, cfgName):
		self._rc_coreEnable=False
		self._dvb_coreEnable=False
		self._version=""
		try:	
			fcfg=open(cfgName, "r")
			for line in fcfg:
				searchObj = re.search(r'CONFIG_DVB_CORE=y', line, re.M|re.I)
				if searchObj: self._dvb_coreEnable=True
				searchObj = re.search(r'CONFIG_MEDIA_RC_SUPPORT=y', line, re.M|re.I)
				if searchObj: self._rc_coreEnable=True
				ver=self.findVersion(line)
				if ver: self._version=ver

		except IOError as e:
			print "I/O error({0}): {1}".format(e.errno, e.strerror)
			sys.exit(1)
		except:
			print "Unexpected error:", sys.exc_info()[0]
			sys.exit(1)

	#Ret : version string parsed
	#      otherwise - ""
	def getVersion(self):
		return self._version

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
		

#process parameters
#
def check_param():
	parser = argparse.ArgumentParser()
	parser.add_argument('-s', action='store', dest='cfgOrg',
			help='Original configuration file')
	parser.add_argument('-c', action='store', dest='cfgExt',
			help='Extra configuration to merge')
	parser.add_argument('-o', action='store', dest='cfgOut',
			default=".config",
			help='Output configuration')
	arg = parser.parse_args()

	if None == arg.cfgOrg:
		usage("Missing original configuration file")
		sys.exit(1)

	if None == arg.cfgExt:
		usage("Missing new configuration file")
		sys.exit(1)
	return arg


arg=check_param()
cfg=cKconfig(arg.cfgOrg)

if __name__ == '__main__':
	print "Kernel Version: " + cfg.getVersion()
	for i in cfg.getRC(): print i
	for i in cfg.getDVB(): print i
else:
	'''
	try:
		fout = open(arg.cfgOut, "w")
		forg = open(arg.cfgOrg, "r")
		fext = open(arg.cfgExt, "r")
		for line in forg:
			fout.write(line)
		for line in fext:
			fout.write(line)
	except IOError as e:
		print "I/O error({0}): {1}".format(e.errno, e.strerror)
	except:
		print "Unexpected error:", sys.exc_info()[0]
		sys.exit(1)
	'''

sys.exit(0)

