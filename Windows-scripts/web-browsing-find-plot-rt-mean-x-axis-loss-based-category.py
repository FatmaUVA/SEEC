#This is a python code
#plot geometric mean RT of each category websites, x-axis is the loss rate, left y-axis RT, rigth y-axis MBytes


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
category=["news","shop","video"]   #["shop","news","bank","forum","misc","social","video"]
run_no="1"
leg_title=["DUT"] #legend title for the plot

res_dir="/home/harlem1/SEEC/Windows-scripts/results"
plot_dir='/home/harlem1/SEEC/Windows-scripts/plots/new-mean'
#plot_name='/mean-RT-image-x-axis-'+app+'-total-runs-'+str(total_runs)+'-run-'+str(run_no)+'.png'

#===================Read data======================
#two arrays RT and Bytes. each array has all the runs 
for cate in category:
    file_name = app +"-" +cate +"_RT_"+method[0]+"_run_"+str(run_no)
    #read data, one 2D array per category
    data_cate = "data-" + cate
    globals()[data_cate] = np.loadtxt(res_dir +'/' + file_name, delimiter=' ') #,unpack=True)
    no_tasks = ((globals()[data_cate][0].size - 2)/2) #find how many websotes in theis category, -2 to remove the rtt and loss values

    #seperate the data based on RT and bytes
    rt_cate = "rt_"+cate
    globals()[rt_cate] = globals()[data_cate][:,np.arange(2,2+no_tasks)] #read specific col. of rt, remember the 1st two are rtt and loss so skip
    by_cate = "by_"+cate
    globals()[by_cate] = globals()[data_cate][:,np.arange(2+no_tasks,(2+no_tasks*2))]

# read rtt and loss values and create arrays based on loss values; just read it once it is the same for all results files
rtt  = globals()[data_cate][:,0]
loss = globals()[data_cate][:,1]

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
for cate in category:
    for l in loss_uniq:
        rt_loss = "rt_"+cate+"_loss_" + str(l)
        globals()[rt_loss] = []
        if cate != "autoit":
            by_loss = "by_"+cate+"_loss_" + str(l)
            globals()[by_loss] = []

#add elemnts to the array based on the found indecies
for cate in category:
    rt_all = "rt_"+cate
    by_all = "by_"+cate
    for l in loss_uniq:
        temp2 = "loss_" + str(l) + "_index"
        rt_loss = "rt_"+cate+"_loss_" + str(l)
        by_loss = "by_"+cate+"_loss_" + str(l)
        for i in globals()[temp2]:
            globals()[rt_loss].append(globals()[rt_all][i])
            globals()[by_loss].append(globals()[by_all][i])
#        print(rt_loss," ",globals()[rt_loss])
#        print("\n")


#for plotting, find geometric mean of each run, then find arthimetic mean of geo-mean, then append to array
#create empty arrays to hold geo-mean
for cate in category:
    rt_amean = "rt_"+cate+"_loss_amean"
    by_amean = "by_"+cate+"_loss_amean"
    globals()[rt_amean] = [] #array to hold arthimetic mean for all loss values
    globals()[by_amean] = []
    for l in loss_uniq:
        rt_loss = "rt_"+cate+"_loss_" + str(l)
        rt_loss_gmean = "rt_"+cate+"_loss_" + str(l) + "_geomean"
        globals()[rt_loss_gmean] = scipy.stats.mstats.gmean(globals()[rt_loss], axis=1)
        #add it to the arthimetic meean array
        globals()[rt_amean].append(np.mean(globals()[rt_loss_gmean]))
        if cate != "autoit":
            by_loss = "by_"+cate+"_loss_" + str(l)
            by_loss_gmean = "by_"+cate+"_loss_" + str(l) + "_geomean"
            globals()[by_loss_gmean] = scipy.stats.mstats.gmean(globals()[by_loss], axis=1)
            globals()[by_amean].append(np.mean(globals()[by_loss_gmean]))
    print(rt_amean, " ", globals()[rt_amean])
    print(by_amean, " ", globals()[by_amean])


#====================Plot=======================

plot_name='/mean-RT-loss-x-axis-'+app+'-category-total-runs-'+str(total_runs)+'-run-'+str(run_no)+'.png'

colors = cm.rainbow(np.linspace(0, 7, 20))
markers = ['^','s','o','*','x','D','+']
fig, ax1 = plt.subplots(1)
ax1.set_xlabel('packet loss rate (%)',fontsize=14)
ax1.set_ylabel(app+' load time (sec)')
col_index = 0 #index to assign differnt colors for lines

for cate in category:
    rt_amean = "rt_"+cate+"_loss_amean"    
    print(rt_amean, " ", globals()[rt_amean])
    print("col_index ",col_index)
    ax1.plot(globals()[rt_amean],color=colors[col_index],marker=markers[col_index],linewidth=2.0,markersize=10,label = cate+' RT')
    col_index = col_index + 1

#create anothor axis for number of bytes
ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
ax2.set_ylabel('Display Update Size (MBytes)')  # we already handled the x-label with ax1
col_index = 0 #index to assign differnt colors for lines
for cate in category:
    by_amean = "by_"+cate+"_loss_amean"
    ax2.plot(globals()[by_amean],color=colors[col_index],marker=markers[col_index],linestyle='dashed',linewidth=2.0,markersize=10,label = cate+ 'Bytes')
    col_index = col_index + 1

ax1.legend(loc='upper left',ncol=3,bbox_to_anchor=(-0.2,1.18))
ax2.legend(loc='upper left',ncol=3,bbox_to_anchor=(-0.2,-0.1))

plt.savefig(plot_dir + '/' +plot_name,format="png",bbox_inches='tight')
plt.show()
