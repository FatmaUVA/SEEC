# This script process PCoIP SSV log and find the average fps

import sys, os
import numpy as np
import fnmatch


loss = sys.argv[1]
run_no = sys.argv[2]
log_dir= r'C:\Users\Harlem5\SEEC\Windows-scripts\Video-test\fps-logs'
res_file=log_dir +'\\fps_run_'+str(run_no)+'.txt'
parsed_res='C:\\Users\\Harlem5\\SEEC\\Windows-scripts\\Video-test\\parsed-raw-fps\\fps_run_'+str(run_no)+'-loss-'+str(loss)+'.txt'

#find the file
#since PCoIP log file naming convension depends on time
#then the easiest was is to read the file based on a pattern, then delete it
print(os.listdir(log_dir))

for file1 in os.listdir(log_dir):
    if fnmatch.fnmatch(file1, '*.csv'):
        print(file1);
        print(log_dir + '\\' + file1)
        #read the CSV file
        #by,fps = np.loadtxt(log_dir + '\\' + file1,delimiter=',', usecols=(15,18), unpack=True,skiprows=1)
        by,fps = np.genfromtxt(log_dir + '\\' + file1,delimiter=',', usecols=(15,18), unpack=True,skip_header=3,skip_footer=2)
        
        print(fps)
        print("mean",np.mean(fps))
        x=[loss,np.nanmean(fps), np.nanmean(by)]
        x=np.asarray(x)
        print("x",x)
        #save to file
        f = open(res_file,'ab')
        np.savetxt(f, x[None,:], fmt='%s')
        f.close()
        
        f = open(parsed_res,'ab')
        #save raw (all fps for each loss value)
        np.savetxt(f, fps[None,:], fmt='%s')
        f.close()

        os.remove(log_dir + '\\' +file1)

