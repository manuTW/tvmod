import argparse
import glob
import os
import sys
import re

# parse kernel configuration and create database
class cQTSmodel(object):
	LOGFILE='buildlog'

	# make in model path with mkfile
	# In : mkfile - makefile
	#           none means use default makefile
	#      _path - full path of model directory
	#      _blog - build log file
	def _doMake(self, mkfile=None):
		if not mkfile: mkfile=self._mkfile
		os.system('rm -f '+self._blog)
		os.system('cd '+self._path+'; make -f '+mkfile)
		if not os.path.isfile(self._blog):
			print 'Build might fail (', self._path, ')'

	# generate a short version of makefile based on original one
	# it does only kernel make
	# In : _mkfile - original make file
	#      _path - path of model directory
	def _genKernelMk(self):
		skip=False
		kernFound=False
		with open(self._path+'/.mk', 'w') as wfd:
			with open(self._mkfile, 'r') as rfd:
				for ln in rfd:
					#determine to writ or not
					if not skip: wfd.writelines("%s" %ln)
					else:
						if not ln.strip(): #an empty line
							skip=False
							wfd.writelines("%s" %ln)
					#check if "make kernel" found
					if not kernFound:
						if re.search(r'^make kernel', ln.strip(), re.I):
							skip=True
							kernFound=True

	# check the kernel version, build if not yet
	# In : _blog
	#      _path
	def _findKver(self):
		if not os.path.isfile(self._blog):
			self._doMake()
		with open(self._blog, 'r') as rfd:
			for ln in rfd:
				#a.b
				match=re.match(r'.*?Kernel/linux-(\d+)\.(\d+)', ln)
				if match:
					#a.b.c
					match3=re.match(r'.*?Kernel/linux-(\d+)\.(\d+)\.(\d+)', ln)
					if match3:
						self._kver=match3.group(1)+'.'+match3.group(2)+\
						'.'+match3.group(3)
					else:
						self._kver=match.group(1)+'.'+match.group(2)
					return

	# In : full path of model path
	# Out: _arch - architecture string, 'x86_64', 'x86', or 'arm'
	#      _version - version string 'a.b.c' or 'a.b'
	def __init__(self, modelPath):
		self._path=None
		self._blog=None          #file name of buildlog
		self._mkfile=None
		self._kver=None          #kernel version from buildlog
		self._config=None        #the configure files in Model directory
		#determine full path
		if not os.path.isdir(modelPath):
			print 'Miss directory '+modelPath
			os.exit(1)
		else:
			#remove last / if present
			self._path=re.sub(r'/$', "", os.path.abspath(modelPath))
			self._blog=self._path+'/'+self.LOGFILE
		#determine makefile
		if os.path.isfile(self._path+'/Makefile'):
			self._mkfile=self._path+'/Makefile'
		elif os.path.isfile(self._path+'/makefile'):
			self._mkfile=self._path+'/makefile'
		else:
			print "Missing makefile"
			os.exit(1)
		self._findKver()
		#guess the configuration file
		if self._kver:
			for ff in glob.glob(self._path+'/linux-*.cfg'):
				if re.search(self._kver, ff):
					self._config=ff
					break
			self._genKernelMk()

	#Ret : kernel version string a.b.c or a.b if successful
	def getKver(self):
		return self._kver

	#Ret : configuration file corresponding to buildlog
	def getCfg(self):
		return self._config

if __name__ == '__main__':
	def usage(reason):
		if reason: print reason
		print '  Usage: QTS.py -m modelPath [-c] [-v]'
		print '    generate \'.mk\' in model path'
		print '  Ret: 0 success and 1 failure'
	
	# process parameters
	# Ret: exit 1 if fails
	#      otherwise - parsed argument object 
	def check_param():
		parser = argparse.ArgumentParser()
		parser.add_argument('-m', action='store', dest='mdPath',
			help='model path')
		parser.add_argument('-v', action='store_true', default=False, dest='verOnly')
		parser.add_argument('-c', action='store_true', default=False, dest='cfgOnly')
		arg = parser.parse_args()
		if not arg.mdPath:
			usage("Missing model path")
			sys.exit(1)
		return arg

	#main: demo the usage
	arg=check_param()
	qts=cQTSmodel(arg.mdPath)
	if arg.verOnly:
		print qts.getKver()
	if arg.cfgOnly:
		print qts.getCfg()
	sys.exit(0)

