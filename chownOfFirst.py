import os, sys, re

#use
for i in range(1, len(sys.argv)):
	if i is 1:
		if os.path.exists(sys.argv[1]):
			uid=os.stat(sys.argv[1]).st_uid
			gid=os.stat(sys.argv[1]).st_gid
		else:
			print sys.argv+' doesn\'t exist'
	else:
		cmd='chown -R '+str(uid)+':'+str(gid)+' '+sys.argv[i]
		print cmd
