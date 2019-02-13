# This script process PCoIP SSV log and find the average fps

import sys, os
import numpy as np
import fnmatch


loss = sys.argv[1]
run_no = sys.argv[2]
log_dir = 'fps-logs'
res_file = log_dir +'/fps_run_'+run_no+'.txt'

#find the file
#since PCoIP log file naming convension depends on time
#then the easiest was is to read the file based on a pattern, then delete it
for file1 in os.listdir(log_dir):
    if fnmatch.fnmatch(file1, '*.csv'):
        print file1
        #read the CSV file
        by,fps = np.loadtxt(log_dir + '/' + file1,delimiter=',', usecols=(15,18), unpack=True,skiprows=1)

        print(fps)
        print("mean",np.mean(fps))
        x=[loss,np.mean(fps), np.mean(by)]
        x=np.asarray(x)
        print("x",x)
        #save to file
        f = open(res_file,'ab')
        np.savetxt(f, x[None,:], fmt='%s')
        f.close()

        os.remove(log_dir + '/' +file1)
