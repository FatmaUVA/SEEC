#This script first read the result files, then create an output in the required format for correlation
#It consider all observations (runs) it will not take the MOS value
#Note that the observations of Objective and subjectuve should be the same

import sys, os
import numpy as np
import matplotlib.cm as cm
import matplotlib.pyplot as plt
import math
import scipy.stats



#===========================Prepare objective results=================
#=====================Initialize parameters===============
#input arguments
app="ImageView"
method=["display_updates_2"] #["autoit","display_updates","display_updates_2"] #"RT_marker_packets_2"
run_no="1-Pics13"
res_dir="/home/harlem1/SEEC/Windows-scripts/results"

#===================Read data======================
#two arrays RT and Bytes. each array has all the runs 
for meth in method:
    file_name = app + "_RT_"+meth+"_run_"+str(run_no)
    #read data, all the colunm
    data_meth = "data-" + meth
    globals()[data_meth] = np.loadtxt(res_dir +'/' + file_name, delimiter=' ') #,unpack=True)
    no_tasks = ((globals()[data_meth][0].size - 2)/2) #find how many images are there in each run, -2 to remove the rtt and loss values

    #read only rt we don't need bytes
    rt_meth = "rt_"+meth
    globals()[rt_meth] = globals()[data_meth][:,np.arange(2,2+no_tasks)] #read specific col. of rt, remember the 1st two are rtt and loss so skip


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

#add elemnts to the array based on the found indecies
for meth in method:
    rt_meth = "rt_"+meth
    for l in loss_uniq:
        temp2 = "loss_" + str(l) + "_index"
        rt_loss = "rt_"+meth+"_loss_" + str(l)
        for i in globals()[temp2]:
            globals()[rt_loss].append(globals()[rt_meth][i])

#find geo-mean of each run, then find arithmetic mean of geo-mean
for meth in method:
    for l in loss_uniq:
        rt_loss = "rt_"+meth+"_loss_" + str(l)
        rt_loss_gmean = "rt_"+meth+"_loss_" + str(l) + "_geomean"
        globals()[rt_loss_gmean] = scipy.stats.mstats.gmean(globals()[rt_loss], axis=1)

        print("length of ",rt_loss_gmean," ",len(globals()[rt_loss_gmean]))

#===============prepare subjective results============
app="ImageView-pics2"
run_name = "pilot-and-trial"

data_app = "data_"+app
globals()[data_app] = np.genfromtxt(res_dir+"/merged-"+app+"-QoE-results-"+run_name+".txt", delimiter=' ')

#seperate by app and packet loss rate. rtt is always 0 so don't worry about it
#also have another array based on app only, each array in the array have all the values for one of the loss values
data_app = "data_"+app
sub_loss_all = "sub_"+ app + "_loss_all"
globals()[sub_loss_all] = []

for l in loss_uniq:
    #create array based on app and loss value to hold QoS
    app_loss = app+"_"+str(l)
    globals()[app_loss] = []
    #read rows with specific loss value colunm 2 is loss value
    temp = globals()[data_app][np.where(globals()[data_app][:,2] == l)]
    globals()[app_loss] = temp[:,3]
    globals()[sub_loss_all].append(globals()[app_loss])
    no_samples = len(globals()[app_loss])

globals()[sub_loss_all] = np.asarray(globals()[sub_loss_all])
globals()[sub_loss_all] = np.ndarray.flatten(globals()[sub_loss_all]).astype(np.float)
#globals()[sub_loss_all] = globals()[sub_loss_all].tolist()
print("length ",sub_loss_all, " " , globals()[sub_loss_all])


#======================== Create final arrays with all observations based on sample size ===========
obj_loss_all = "obj_"+app + "_loss_all"
globals()[obj_loss_all] = []
for meth in method:
    for l in loss_uniq:
        rt_loss_gmean = "rt_"+meth+"_loss_" + str(l) + "_geomean"
        globals()[obj_loss_all].append(globals()[rt_loss_gmean][range(no_samples)])
        print("length ",obj_loss_all,len(globals()[obj_loss_all]))

    #flatten the array
    globals()[obj_loss_all] = np.asarray(globals()[obj_loss_all])
    globals()[obj_loss_all] = np.ndarray.flatten(globals()[obj_loss_all]).astype(np.float)
#    globals()[obj_loss_all] = globals()[obj_loss_all].tolist()
    print("length ",obj_loss_all, " " , globals()[obj_loss_all])

#======================== find correlation=========================

#coef = scipy.stats.pearsonr(obj_loss_all, sub_loss_all)
coef = np.corrcoef(obj_loss_all, sub_loss_all)
print("coef = ",coef)
