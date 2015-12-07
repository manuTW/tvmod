import argparse
import os
import sys
import re

# parse kernel configuration and create database
class cQTSmodel(object):
	LOGFILE='buildlog'
	# check the kernel version, build if not yet
	# In : _blog
	#      _path
	def _findKver(self):
		if not os.path.isfile(self._blog):
			os.system('cd '+self._path+'; make')
			if not os.path.isfile(self._blog):
				print 'Fail to build '+self._path
				sys.exit(1)
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
		self._blog=None
		self._mkfile=None
		self._kver=None
		if not os.path.isdir(modelPath):
			print 'Miss directory '+modelPath
			os.exit(1)
		else:
			#remove last / if present
			self._path=re.sub(r'/$', "", modelPath)
			self._blog=self._path+'/'+self.LOGFILE
		self._findKver()

	def getKver(self):
		return self._kver

if __name__ == '__main__':
	qts=cQTSmodel('../NasX86.4.2.1/Model/TS-X71/')
	print qts.getKver()
	sys.exit(0)

