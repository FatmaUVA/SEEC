#plot mean of performance index
#performance index = bytes/rt * 100
#x-axis is the loss rate, left y-axis performance index
#It plot and find performance index for both model3 and model4, the higher the performance index the better

import sys, os
import numpy as np
import matplotlib.cm as cm
import matplotlib.pyplot as plt
import math
import scipy.stats


def Compute_perf (model):
    global perf_base
    global loss_uniq
    #===================Read data======================
    #two arrays RT and Bytes. each array has all the runs 
    if model == 3:
        run_no = run_no_model3
    else:
        run_no = run_no_model4
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
        #print("indices, " ,temp1,"  = ",globals()[temp1]) 
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

    #find performanc index
    for meth in method:
        for l in loss_uniq:
            rt_loss = "rt_"+meth+"_loss_" + str(l)
            by_loss = "by_"+meth+"_loss_" + str(l)
            perf_loss = "perf_"+meth+"_loss_" + str(l)
            globals()[rt_loss] = np.asarray(globals()[rt_loss])
            globals()[by_loss] = np.asarray(globals()[by_loss])
            
            #this division might cause inf values, because of faulty runs where bytes = 0
            globals()[perf_loss] = globals()[rt_loss]/globals()[by_loss] 
            #remove runs where one image has 0 bytes
            #row indecies where one image has inf value
            row_index = []
            # find rows where one value = inf
            for i in range(len(globals()[perf_loss])):
                for j in range(len(globals()[perf_loss][0])):
                   if np.isinf(globals()[perf_loss][i,j]):
                        row_index.append(i)
            temp = []
            #only if one or more row has inf value, remove the rows from perf_loss array
            if len(row_index) >0:
                for i in range(len(globals()[perf_loss])):
                    inf_value = False
                    for x in row_index:
                        if i == x:
                            inf_value = True
                    if not inf_value:
                        temp.append(globals()[perf_loss][i])
                globals()[perf_loss] = []
                globals()[perf_loss] = temp

    #        print(perf_loss," ",globals()[perf_loss])

    #for plotting, find geometric mean of each run, then find arthimetic mean of geo-mean, then append to array
    #find geo-mean of each run, then find arithmetic mean of geo-mean
    #create empty arrays to hold geo-mean
    for meth in method:
        perf_amean = "perf_"+meth +"_amean" #arithmetic mean for the 3 loss values
        globals()[perf_amean] = [] #array to hold arthimetic mean for all loss values
        for l in loss_uniq:
            perf_loss = "perf_"+meth+"_loss_" + str(l)
            perf_loss_gmean = "perf_"+meth+"_loss_" + str(l) + "_geomean"
            globals()[perf_loss_gmean] = scipy.stats.mstats.gmean(globals()[perf_loss], axis=1)
            #add it to the arithmetic meean array
            globals()[perf_amean].append(np.mean(globals()[perf_loss_gmean]))
            if l == 0 and model == 4:
                perf_base = np.mean(globals()[perf_loss_gmean])
    return globals()[perf_amean]
#        print(perf_amean," ",globals()[perf_amean])
#        print("perf ration = ", perf_base / globals()[perf_amean])


#=====================Initialize parameters===============
#input arguments
#for objective
app = "ImageView" #"Insta360" #"ImageView" #"Web360"
method=["display_updates_2"] #["autoit","display_updates","display_updates_2"] #"RT_marker_packets_2"
run_no_model3 = "3-Pics13-model3" #"1-model3" #"1-model4" # "3-pics2"360 #"1-Pics13"image
run_no_model4 = "1-Pics13" #"1-model4" #"1-Pics13"


res_dir="/home/harlem1/SEEC/Windows-scripts/results"
plot_dir='/home/harlem1/SEEC/Windows-scripts/plots/new-mean'

perf_base = 0
loss_uniq = []


perf_model3 = Compute_perf(3)
perf_model4 = Compute_perf(4)
perf_model3 = np.asarray(perf_model3)
perf_model4 = np.asarray(perf_model4)

print("model3 1/perf ",100/perf_model3)
print("model4 1/perf ",100/perf_model4)
#print("model3 perf ",perf_model3/perf_base)
#print("model4 perf ",perf_model4/perf_base)


#===============plot===============
#plot_name='/perf-x-axis-'+app+'-total-runs-'+str(total_runs)+'-run-'+str(run_no)+'.png'
plot_name='/perf-x-axis-'+app+'-run-'+str(run_no_model4)+'.png'

colors = cm.rainbow(np.linspace(0, 7, 20))
markers = ['^','s','o','*','x','D','+']

plt.xlabel('packet loss rate (%)',fontsize=14)
plt.ylabel(app+' Performance')
plt.plot(loss_uniq,100/perf_model3,color=colors[0],marker=markers[0],linewidth=2.0,markersize=10,label = "Model 3")
plt.plot(loss_uniq,100/perf_model4,color=colors[1],marker=markers[1],linewidth=2.0,markersize=10,label = "Model 4")

plt.legend(loc='upper left',ncol=3,bbox_to_anchor=(0.2,1.18))
plt.show()
