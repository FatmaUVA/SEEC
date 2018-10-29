#This is a python code
#plot geometric mean RT of all websites, x-axis is the loss rate, left y-axis RT, rigth y-axis MBytes

import sys, os
import numpy as np
import matplotlib.cm as cm
import matplotlib.pyplot as plt
import math
import scipy.stats


#=====================Initialize parameters===============
#input arguments
rtt=[0,20,50,100,200]
loss=[0,3,5]
app="WebBrowsing"
method=["display_updates_2"] #["autoit","display_updates","display_updates_2"] #"RT_marker_packets_2"
run_no="3"
no_tasks=40 #number of websites
leg_title=["DUT"]

res_dir="/home/harlem1/SEEC/Windows-scripts/results"
plot_dir='/home/harlem1/SEEC/Windows-scripts/plots/new-mean'
#plot_name='/mean-RT-image-x-axis-'+app+'-total-runs-'+str(total_runs)+'-run-'+str(run_no)+'.png'

#===================Read data======================
#two arrays RT and Bytes. each array has all the runs 
for meth in method:
    file_name = app + "_RT_"+meth+"_run_"+str(run_no)
    #one array for each task (image)
    rt_all = "rt_"+meth
    globals()[rt_all] = np.loadtxt(res_dir +'/' + file_name, delimiter=' ',usecols=np.arange(2,2+no_tasks+1),unpack=True)
    if meth != "autoit": #it doesn't have total no of bytes to read
        by_all = "by_"+meth #array for bytes
        #globals will evaluate the array name befor assigning it the values
        globals()[by_all] = np.loadtxt(res_dir +'/' + file_name, delimiter=' ',usecols=np.arange(2+no_tasks,1+no_tasks*2),unpack=True)
        globals()[by_all] = globals()[by_all]/10e6 # change it to MB


# read rtt and loss values and create arrays based on loss values
#figure out the length of the file, read only one file , other files would have the same length
file_name = app + "_RT_"+method[0]+"_run_"+str(run_no)
rtt, loss = np.loadtxt(res_dir +'/' + file_name, delimiter=' ',usecols=(0,1),unpack=True)

#==============Pre-process data===================
#find unique loss values
loss_uniq = np.unique(loss)
print("unique loss values = ",loss_uniq)
rtt_unique = np.unique(rtt)


#find indices where loss value equal to specific value and RTT of 0
rtt_0 = np.where(rtt==0)
print("rtt_0 ", rtt_0)

for l in loss_uniq:
    temp1 = "loss_" + str(l)
    x = np.where(loss==l)
    globals()[temp1] = np.intersect1d(x,rtt_0)
    total_runs=len(globals()[temp1])
    print("total_runs_",total_runs)
    #print("indices, " ,temp1,"  = ",globals()[temp1]) 
    #convert it to a list structure to easily access elemts in a loop
    temp2 = "loss_" + str(l) + "_index"
    globals()[temp2] = []



    #add indices to the list, one list for each loss value
    for i in range(len(globals()[temp1])):
        globals()[temp2].append(globals()[temp1][i])

#create arrays based on loss value, each array has all the tasks in a row, where each row is different run
for meth in method:
    for l in loss_uniq:
        rt_loss = "rt_"+meth+"_loss_" + str(l)
        globals()[rt_loss] = []
        if meth != "autoit":
            by_loss = "by_"+meth+"_loss_" + str(l)
            globals()[by_loss] = []

#add elemnts to the array based on the found indecies
for meth in method:
    rt_all = "rt_"+meth
    by_all = "by_"+meth
    for l in loss_uniq:
        temp2 = "loss_" + str(l) + "_index"
        rt_loss = "rt_"+meth+"_loss_" + str(l)
        by_loss = "by_"+meth+"_loss_" + str(l)
        for i in globals()[temp2]:
            globals()[rt_loss].append(globals()[rt_all][i])
        if meth != "autoit":
            for i in globals()[temp2]:
                globals()[by_loss].append(globals()[by_all][i])

#for plotting, find geometric mean of each run, then find arthimetic mean of geo-mean, then append to array
#create empty arrays to hold geo-mean
for meth in method:
    rt_amean = "rt_"+meth+"_loss_amean"
    by_amean = "by_"+meth+"_loss_amean"
    globals()[rt_amean] = [] #array to hold arthimetic mean for all loss values
    globals()[by_amean] = []
    for l in loss_uniq:
        rt_loss = "rt_"+meth+"_loss_" + str(l)
        rt_loss_gmean = "rt_"+meth+"_loss_" + str(l) + "_geomean"
        globals()[rt_loss_gmean] = scipy.stats.mstats.gmean(globals()[rt_loss], axis=1)
        #add it to the arthimetic meean array
        globals()[rt_amean].append(np.mean(globals()[rt_loss_gmean]))
        if meth != "autoit":
            by_loss = "by_"+meth+"_loss_" + str(l)
            by_loss_gmean = "by_"+meth+"_loss_" + str(l) + "_geomean"
            globals()[by_loss_gmean] = scipy.stats.mstats.gmean(globals()[by_loss], axis=1)
            globals()[by_amean].append(np.mean(globals()[by_loss_gmean]))
    print(rt_amean, " ", globals()[rt_amean])
    print(by_amean, " ", globals()[by_amean])



#====================Plot=======================

plot_name='/mean-RT-loss-x-axis-'+app+'-total-runs-'+str(total_runs)+'-run-'+str(run_no)+'.png'

colors = cm.rainbow(np.linspace(0, 7, 20))
markers = ['^','s','o','*','x','D','+']
fig, ax1 = plt.subplots(1)
ax1.set_xlabel('packet loss rate (%)',fontsize=14)
ax1.set_ylabel(app+' load time (sec)')

for meth in method:
    col_index = 0 #index to assign differnt colors for lines
    rt_amean = "rt_"+meth+"_loss_amean"    
    print(rt_amean, " ", globals()[rt_amean])
    ax1.plot(globals()[rt_amean],color=colors[col_index],marker=markers[col_index],linewidth=2.0,markersize=10,label = leg_title[0]+', loss = '+str(l)+"%")
    col_index = col_index + 1

#create anothor axis for number of bytes
ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
ax2.set_ylabel('Display Update Size (MBytes)')  # we already handled the x-label with ax1
for meth in method:
    col_index = 0 #index to assign differnt colors for lines
    if meth != "autoit":
        by_loss_amean = "by_"+meth+"_loss_amean"
        ax2.plot(globals()[by_amean],color=colors[col_index],marker=markers[col_index],linestyle='dashed',linewidth=2.0,markersize=10,label = 'Bytes, loss = '+str(l)+"%")

    col_index = col_index + 1

ax1.legend(loc='upper left',ncol=3,bbox_to_anchor=(-0.2,1.18))
ax2.legend(loc='upper left',ncol=3,bbox_to_anchor=(-0.2,-0.1))

#plt.savefig(plot_dir + '/' +plot_name,format="png",bbox_inches='tight')
plt.show()
