import os
import sys
import re
import subprocess
import glob


# process release data base
class cMediaStore(object):
	# full path of model directory
	# In : storeDir - the path earlier ko are stored
	# Out : _shellDir, _storeDir
	def __init__(self, storeDir):
		self._storeDir=re.sub(r'/*$', "", os.path.abspath(storeDir))
		#shell directory
		self._shellDir=os.path.dirname(os.path.realpath(__file__))
		if not os.path.exists(self._storeDir):
			os.system('mkdir -p '+self._storeDir)


	# add a directory to the store and it becomes
	# top-dir - kver - arch - vermagic 
	# In : verDir - full path version directory in release
	#      archDir - arch path and verDir+'/'+archDir contains dvb-core.ko ...
	# Ret : if the vermagic is duplicated in the arch
	def _addDir(self, verDir, archDir):
		koPath=verDir+'/'+archDir         #full release path
		koFile=None
		for koFile in glob.glob(koPath+'/*.ko'): break
		if koFile: 
			cmd='/sbin/modinfo '+koFile+' |grep vermagic'
			p=subprocess.Popen([cmd], stdout=subprocess.PIPE, shell=True)
			output=p.stdout.read()
			#turn ' ' into '-'
			vermagic=re.sub(r'.*?vermagic:\ *', "", output)
			s='-'
			vermagic=s.join(vermagic.split())
			#determine version of vermagic
			matchObj=re.match(r'(\d+)\.(\d+)\.(\d+)', vermagic)
			if matchObj:
				koVer=matchObj.group(1) + '.' + matchObj.group(2) +	'.' + matchObj.group(3)
			else:
				matchObj=re.match(r'(\d+)\.(\d+)', vermagic)
				if matchObj:
					koVer=matchObj.group(1) + '.' + matchObj.group(2)
			path=self._storeDir+'/'+koVer+'/'+archDir+'/'+vermagic
			if os.path.isdir(path):
				print vermagic+' already presents'
			else:
				print 'Creating '+path
				os.system('mkdir -p '+path)
				os.system('cp '+koPath+'/*.ko '+path)
		else:
			print 'Missing ko files in '+koPath


	# Given release path which should be
	#	top-dir - kver - arch - xxx.ko
	def addRelease(self, releaseDir=None):
		archTup=('arm', 'x86_64')
		if not releaseDir:
			releaseDir=self._shellDir+'/release'
		#find all arch directory which is leaf directories
		#ko should right be there
		for root, dirs, files in os.walk(releaseDir):
			for arch in dirs:
				if arch in archTup:
					self._addDir(root, arch)


#main
if '__main__' == __name__:
	def usage(reason=None):
		if reason: print reason
		print '  Usage: mediaCollect.py repositoryPath'
		print '  Ret: 0 success and 1 failure'

	#main
	if len(sys.argv) is 1:
		usage()
		sys.exit(1)
	else:
		store=cMediaStore(sys.argv[1])
		store.addRelease()
		sys.exit(0)
