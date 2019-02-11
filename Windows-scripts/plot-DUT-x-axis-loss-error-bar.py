#plot mean DUT and bytes
#x-axis is the loss rate, left y-axis DUT, right y-axis bytes

import sys, os
import numpy as np
import matplotlib.cm as cm
import matplotlib.pyplot as plt
import math
import scipy.stats


def Compute (run_no):
    global loss_uniq
    rt = []
    by = []
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


    #==============Pre-process data===================
    #find unique loss values
    loss_uniq = np.unique(loss)
    print("unique loss values = ",loss_uniq)
    rtt_unique = np.unique(rtt)

    #find indices where loss value equal to specific value and RTT of 0
    rtt_0 = np.where(rtt==0)

    for l in loss_uniq:
        temp1 = "loss_" + str(l)
        x = np.where(loss==l)
        globals()[temp1] = np.intersect1d(x,rtt_0)
        total_runs=len(globals()[temp1])
        print("total_runs_",total_runs)
        #convert it to a list structure to easily access elemts in a loop
        temp2 = "loss_" + str(l) + "_index"
        globals()[temp2] = []



        #add indices to the list, one list for each loss value
        for i in range(len(globals()[temp1])):
            globals()[temp2].append(globals()[temp1][i])

    #create arrays based on loss value, each array has all the images in a row, where each row is different run
    for meth in method:
        for l in loss_uniq:
            rt_loss = "rt_"+meth+"_loss_" + str(l)
            globals()[rt_loss] = []

            by_loss = "by_"+meth+"_loss_" + str(l)
            globals()[by_loss] = []

            perf_loss = "perf_"+meth+"_loss_" + str(l)
            globals()[perf_loss] = []

    #add elemnts to the array based on the found indecies
    for meth in method:
        rt_meth = "rt_"+meth
        by_meth = "by_"+meth
        for l in loss_uniq:
       

            temp2 = "loss_" + str(l) + "_index"
            rt_loss = "rt_"+meth+"_loss_" + str(l)
            by_loss = "by_"+meth+"_loss_" + str(l)
            for i in globals()[temp2]:
                globals()[rt_loss].append(globals()[rt_meth][i])
                globals()[by_loss].append(globals()[by_meth][i])

    rt_gmean = []
    by_gmean = []
    rt_std = []
    by_std = []

    z=1.96 # for error bar computation
    #find DUT mean
    for meth in method:
        for l in loss_uniq:
            rt_loss = "rt_"+meth+"_loss_" + str(l)
            by_loss = "by_"+meth+"_loss_" + str(l)
            
            globals()[rt_loss] = np.asarray(globals()[rt_loss])
            globals()[by_loss] = np.asarray(globals()[by_loss])
            
            rt_loss_gmean = scipy.stats.mstats.gmean(globals()[rt_loss], axis=1) # for each loss value find gmean of each run
            by_loss_gmean = scipy.stats.mstats.gmean(globals()[by_loss], axis=1)
            rt.append(np.mean(rt_loss_gmean))
            by.append(np.mean(by_loss_gmean))
            #print(str(l)," ",scipy.stats.mstats.gmean(globals()[by_loss], axis=1))

            #find std to compute error bar
            rt_loss_std = np.std(rt_loss_gmean)
            by_loss_std = np.std(by_loss_gmean)
            rt_std.append(rt_loss_std)
            by_std.append(by_loss_std)

        #find error bar: Standared Error (SE) = std/sqrt(n), upper limit = mean + SE*z
        #change to numpy array
        rt_std = np.asarray(rt_std)
        by_std = np.asarray(by_std)
        rt = np.asarray(rt)
        by = np.asarray(by)

        rt_error = z*(rt_std / math.sqrt(total_runs))
        by_error = z*(by_std / math.sqrt(total_runs))

        print("RT ",rt)
        print("By ",by)
        print("rt_error",rt_error)

    return rt,by,rt_error,by_error

#=====================Initialize parameters===============
#input arguments
#for objective
App = ["ImageView" ,"Web360"] #"ImageView" 
method=["display_updates_2"] #["autoit","display_updates","display_updates_2"] #"RT_marker_packets_2"
Run_no = ["1-Pics14-model4", "6-model4"] #"3-model4" #"1-Pics14-model4"
legend_title = ["Image viewing", "360-degree image exploring"]
res_dir="/home/harlem1/SEEC/Windows-scripts/results"
plot_dir='/home/harlem1/SEEC/Windows-scripts/plots/2018-12-plots'

#===============plot===============

#plot RT and Bytes seperatly
plot_name='/DUT-and-bytes-'+App[0]+'-and-'+App[1]+'.png'

colors = cm.rainbow(np.linspace(0, 7, 20))
markers = ['^','s','o','*','x','D','+']
fig, ax1 = plt.subplots(1)
ax1.set_xlabel('packet loss rate (%)',fontsize=14)
ax1.set_ylabel('DUT (sec)')
#ax1.set_ylim(5,7)

i = 0
for app in App:
    rt,by,rt_error,by_error = Compute(Run_no[i])
    ax1.errorbar(loss_uniq,rt,color=colors[i],yerr=rt_error,marker=markers[i],linewidth=2.0,markersize=10,label = legend_title[i]+' DUT')
    i+=1


#create anothor axis for number of bytes
ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
ax2.set_ylabel('Display Update Size (MBytes)')  # we already handled the x-label with ax1
ax2.set_ylim(0,3)
i = 0
for app in App:
    rt,by,rt_error,by_error = Compute(Run_no[i])
    ax2.errorbar(loss_uniq,by,color=colors[i],yerr=by_error,marker=markers[i],linewidth=2.0,markersize=10,linestyle='dashed',label = legend_title[i]+' MB')
    i+=1

ax1.legend(loc='upper left',ncol=3,bbox_to_anchor=(-0.1,1.18))
ax2.legend(loc='upper left',ncol=3,bbox_to_anchor=(-0.1,-0.1))
plt.savefig(plot_dir + '/' +plot_name,format="png",bbox_inches='tight')
plt.show()
