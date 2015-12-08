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
	return arg

arg=check_param()
absModelDir=re.sub(r'/$', "", os.path.abspath(arg.mdPath))
qtsObj=cQTSmodel(absModelDir)
kver=qtsObj.getKver()          #maybe a.b.c or a.b
cfgObj=cMediaCfg(qtsObj.getCfg())
cfgObj.merge(xxxxarg.cfgMerge, xxxxarg.cfgOut)