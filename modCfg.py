import argparse
import sys
import os
import re

def usage(reason):
	if None != reason: print reason
	print '  Usage: modCfg [-i] -s cfgOrg [-o cfgOut]'
	print '    if version of cfgOrg parsed, corresponding modify-ver is applied and output'
	print '    -i: information only'
	print '    cfgOrg: original configuration file'
	print '    cfgExt: extra configuration file. If not present, information of original'
	print '            is displayed. Otherwise, a merged configuration generated'
	print '    cfgOut: output configuration if cfgExt present. default to .config'
	print '  Ret: 0 success and 1 failure'

# parse kernel configuration and create database
class cKconfig(object):
	DVB_CORE_SETTING=('CONFIG_DVB_CORE=m', 'CONFIG_DVB_MAX_ADAPTERS=8', \
				'CONFIG_DVB_DYNAMIC_MINORS=y')
	RC_CORE_SETTING=('CONFIG_MEDIA_RC_SUPPORT=y', 'CONFIG_RC_CORE=m')

	# Check if a.b.c (or a.b), linux, kernel, and configuration present
	# extract a.b.c (or a.b) as version string
	# In : line - input string
	# Ret: None - if fail to match
	#   otherwise - return version a.b.c (or a.b)
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
		fcfg.close()

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
	parser.add_argument('-i', action='store_true', default=False, dest='infoOnly')
	parser.add_argument('-o', action='store', dest='cfgOut',
			default=".config",
			help='Output configuration')
	arg = parser.parse_args()

	if None == arg.cfgOrg:
		usage("Missing original configuration file")
		sys.exit(1)

	return arg


g_arg=check_param()
g_cfg=cKconfig(g_arg.cfgOrg)
g_shellPath=os.path.dirname(os.path.abspath(__file__))
g_ver=g_cfg.getVersion()

if g_arg.infoOnly:
	print "Kernel Version: " + g_ver
	for ln in g_cfg.getRC(): print ln
	for ln in g_cfg.getDVB(): print ln
elif g_ver != "": 
	os.system('cp ' + g_arg.cfgOrg + ' ' + g_arg.cfgOut)
	mypath=g_shellPath+'modify/modify-'+g_ver+'.cfg'
	#print 'trying a.b.c ' + mypath
	if not os.path.exists(mypath):
		mypath=g_shellPath+'/modify/modify-'+re.sub(r'\.\d+$', '', g_ver)+'.cfg'
		#print 'trying a.b ' + mypath
		if not os.path.exists(mypath): sys.exit(1)
	print 'applying ' + mypath
	os.system('cat ' + mypath + ' >>' + g_arg.cfgOut)
	with open(g_arg.cfgOut, "a") as fout:
		fout.writelines("%s\n" %ln for ln in g_cfg.getRC())
		fout.writelines("%s\n" %ln for ln in g_cfg.getDVB())
		fout.writelines("\n")
else:
	sys.exit(1)

sys.exit(0)

