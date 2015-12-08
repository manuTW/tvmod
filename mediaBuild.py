from kMediaCfg import *
from QTS import *

def usage(reason):
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
	#remove trailing / if any
	arg.mdPath=absModelDir=re.sub(r'/*$', "", os.path.abspath(arg.mdPath))
	return arg


# Given shell directory, pick the correct modification cfg.
# It is modify/modify-a.b.cfg
# In : dirName - shell directory
#      kver - kernel version a.b.c or a.b
# Ret : None - if not find
#       otherwise - full path config file name
def getModifyCfg(dirName, kver):
	path=dirName+'/modify/modify-'+kver+'.cfg'
	if os.path.isfile(path): return path
	matchObj=re.match(r'\d+.\d+', kver)
	if matchObj:
		path=dirName+'/modify/modify-'+matchObj.group(0)+'.cfg'
		if os.path.isfile(path): return path
	return None


#main
progDir=os.path.dirname(os.path.realpath(__file__))
arg=check_param()
qtsObj=cQTSmodel(arg.mdPath)   #create .mk
kver=qtsObj.getKver()          #maybe a.b.c or a.b
orgCfg=qtsObj.getCfg()
cfgObj=cMediaCfg(orgCfg)
modCfg=getModifyCfg(progDir, kver)
if modCfg:
	cfgObj.merge(modCfg, arg.mdPath+'/.cfg')
	#swap
	os.system('mv '+orgCfg+' '+arg.mdPath+'/.bak')
	os.system('mv '+arg.mdPath+'/.cfg '+orgCfg)
	os.system('cd '+arg.mdPath+'; make -f .mk')
	os.system('mv '+arg.mdPath+'/.bak '+orgCfg)
else:
	print 'Missing modification file'
	sys.exit(1)
