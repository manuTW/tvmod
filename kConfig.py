import argparse
import os
import sys
import re

# to call sub-class methods
def dec_parser(func):
	def inner(*args, **kwargs):
		return func(*args, **kwargs)
	return inner

# parse kernel configuration and create database
class cKconfig(object):
	# parse a line, subclass implement its own parser here
	# Out : _extra - line to append
	# Ret : 'rm' : the line will be removed in output config
	#       'continue' : stop processing this line since processed
	#       otherwise : keep processing
	@dec_parser
	def _parser(self, line):
		return None

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
		self._srcFileName=cfgName
		self._version=None
		self._arch=None
		self._extra=[]                 #lines to append by subclass
		self._rmList=[]                #lines to remove by subclass
		isX86=False
		try:
			fcfg=open(cfgName, "r")
			lineNr=0                #1-based
			for line in fcfg:
				lineNr+=1
				if not self._arch and re.search(r'CONFIG_X86_64=y', line, re.M|re.I):
					self._arch='x86_64'
					continue
				if re.search(r'CONFIG_X86=y', line, re.M|re.I):
					isX86=True
					continue
				action=self._parser(line)
				if 'rm' == action:
					self._rmList.append(lineNr)
					continue
				elif 'continue' == action: continue
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
		self._rmList.sort(reverse=True)     #so as to pop

	#Ret : version and architecture string parsed
	#      otherwise - ""
	def getVerArch(self):
		return self._version, self._arch

	def getExtra(self):
		return self._extra

	def getRmList(self):
		return self._rmList

	# Add configuration frome an to-merge file and those _extra
	# NOTE: The original config file name is used
	def merge(self, toMerge,output):
		#no remove for now
		os.system('cp '+self._srcFileName+' '+output)
		if toMerge:
			os.system('cat '+toMerge+' >>'+output)
		for ln in self._extra:
			os.system('echo '+ln+' >>'+output)

if __name__ == '__main__':
	def usage(reason):
		if reason: print reason
		print '  Usage: kConfig.py [-v] [-a] -s cfgOrg [-m cfgMerge] [-o cfgOut]'
		print '    if version of cfgOrg parsed, corresponding modify-ver is applied and output'
		print '    -i: show all information, no further operation'
		print '    -v: show kernel version, no further operation'
		print '    -a: show architecture, no further operation'
		print '    -m: file to merge into original config to form the new config'
		print '    -o: output file of the new config. When -m, cfg is the default output'
		print '    cfgOrg: original configuration file'
		print '  Ret: 0 success and 1 failure'
	
	# process parameters
	# Ret: exit 1 if fails
	#      otherwise - parsed argument object 
	def check_param():
		parser = argparse.ArgumentParser()
		parser.add_argument('-s', action='store', dest='cfgOrg',
			help='Original configuration file')
		parser.add_argument('-m', action='store', dest='cfgMerge',
			help='Configuration file to merge')
		parser.add_argument('-o', action='store', dest='cfgOut',
			help='Configuration file to merge')
		parser.add_argument('-i', action='store_true', default=False, dest='infoOnly')
		parser.add_argument('-v', action='store_true', default=False, dest='verOnly')
		parser.add_argument('-a', action='store_true', default=False, dest='archOnly')
		arg = parser.parse_args()
		if not arg.cfgOrg:
			usage("Missing original configuration file")
			sys.exit(1)
		if arg.cfgMerge:
			if not arg.cfgOut: arg.cfgOut='cfg'     #default output name
		return arg
	#main: demo the usage
	arg=check_param()
	cfg=cKconfig(arg.cfgOrg)
	ver, arch=cfg.getVerArch()
	if arg.verOnly:	print ver
	elif arg.archOnly: print arch
	elif arg.cfgMerge or arg.cfgOut:
		cfg.merge(arg.cfgMerge, arg.cfgOut)
	else:
		print ver, arch
		for ln in cfg.getExtra(): print ln
		rmList=cfg.getRmList()
		if len(rmList):
			print 'Lines to remove: ' + rmList
	sys.exit(0)
