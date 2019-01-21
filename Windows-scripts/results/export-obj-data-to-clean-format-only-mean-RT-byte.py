# This script find mean RT and bytes across of each run and export the mean RT, B to the following format: PLR, RT, Bytes


import sys, os
import numpy as np
import matplotlib.cm as cm
import matplotlib.pyplot as plt
import math
import scipy.stats
from sklearn.preprocessing import MinMaxScaler, StandardScaler




#=====================Initialize parameters===============
#input arguments
#for objective
App = ["ImageView" ,"Web360"] #"ImageView" 
method=["display_updates_2"] #["autoit","display_updates","display_updates_2"] #"RT_marker_packets_2"
Run_no = ["1-Pics14-model4", "6-model4"] #"3-model4" #"1-Pics14-model4"

res_dir="/home/harlem1/SEEC/Windows-scripts/results"
output_dir="/home/harlem1/SEEC/Windows-scripts/results/formatted_results/"

header = ["PLR", "RT", "MB"]
#===============plot===============


i = 0
for app in App:
    print app
    #Compute(Run_no[i])
    run_no = Run_no[i]
    i+=1

    #===================Read data======================
    #two arrays RT and Bytes. each array has all the runs 

    for meth in method:
        file_name = app + "_RT_"+meth+"_run_"+str(run_no)
        #read data, all the colunm
        data_meth = "data-" + meth
        globals()[data_meth] = np.loadtxt(res_dir +'/' + file_name, delimiter=' ') #,unpack=True)
        no_tasks = ((globals()[data_meth][0].size - 2)/2) #find how many images are there in each run, -2 to remove the rtt and loss values

        #read rt
        rt_meth = "rt_"+meth
        globals()[rt_meth] = globals()[data_meth][:,np.arange(2,2+no_tasks)] #read specific col. of rt, remember the 1st two are rtt and loss so skip

        #read bytes
        by_meth = "by_"+meth
        globals()[by_meth] = globals()[data_meth][:,np.arange(2+no_tasks,(2+no_tasks*2))]
        globals()[by_meth] = globals()[by_meth] /10e6 # change it to MB

    # read rtt and loss values and create arrays based on loss values; just read it once it is the same for all results files
    rtt  = globals()[data_meth][:,0]
    loss = globals()[data_meth][:,1]

    #find mean for each run
    rt_mean = scipy.stats.mstats.gmean(globals()[rt_meth], axis=1) # for each loss value find gmean of each run
    by_mean = scipy.stats.mstats.gmean(globals()[by_meth], axis=1)
    final_arr = np.column_stack((loss,rt_mean,by_mean))
    final_arr = np.vstack((header,final_arr))
    print final_arr

    #export it to csv file
    np.savetxt(output_dir+app+"-objective-mean-rt-bytes.csv", final_arr, delimiter=",",fmt='%s')
