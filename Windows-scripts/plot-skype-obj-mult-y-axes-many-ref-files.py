# This script plot 4 AQ metrics: WSS, VISQL, LLR and E-Model
# X_axis is the loss rate, and two y-axes in the left and right each for different metric
# It takes multiple ref files runs and find gmean of each run, then arth mean of all runs
# 

import sys, os
import numpy as np
import matplotlib.cm as cm
import matplotlib.pyplot as plt
import math
import scipy.stats

#This function needed to create the two y-axes
def make_patch_spines_invisible(ax):
    ax.set_frame_on(True)
    ax.patch.set_visible(False)
    for sp in ax.spines.values():
        sp.set_visible(False)

plot_dir='/home/harlem1/SEEC/Windows-scripts/plots/2018-12-plots'
res_dir="/home/harlem1/SEEC/Windows-scripts/Skype"
file_name="parsed-skype-obj"
app = "Skype"
method=["ViSQOL","WSS","LLR"]
ref1="f_1"
ref2="f_2"
ref3="m_2"

ref_list = ["ref1", "ref2", "ref3", "ref4"]
ff=["visqol_ff","wss_ff","llr_ff"]
visqol_ff = ["ViSQOL_results.txt", "loss-model1_ref_"+ref1+"_ViSQOL_results.txt","loss-model1_ref_"+ref2+"_ViSQOL_results.txt", "loss-model1_ref_"+ref3+"_ViSQOL_results.txt"]
wss_ff = ["WSS_results.txt", "loss-model1_ref_"+ref1+"_WSS_results.txt","loss-model1_ref_"+ref2+"_WSS_results.txt", "loss-model1_ref_"+ref3+"_WSS_results.txt"]
llr_ff = ["LLR_results.txt", "loss-model1_ref_"+ref1+"_LLR_results.txt","loss-model1_ref_"+ref2+"_LLR_results.txt", "loss-model1_ref_"+ref3+"_LLR_results.txt"]


#=========setup plot enviroment
colors = cm.rainbow(np.linspace(0, 7, 20))
markers = ['^','s','o','*','x','D','+']
fig, host = plt.subplots()
fig.subplots_adjust(right=0.75)

par1 = host.twinx()
par2 = host.twinx()
# Offset the right spine of par2.  The ticks and label have already been
# placed on the right by twinx above.
par2.spines["right"].set_position(("axes", 1.2))
# Having been created by twinx, par2 has its frame off, so the line of its
# detached spine is invisible.  First, activate the frame but make the patch
# and spines invisible.
make_patch_spines_invisible(par2)
# Second, show the right spine.
par2.spines["right"].set_visible(True)

#set y-axes labels
host.set_xlabel('packet loss rate (%)',fontsize=14)
host.set_ylabel("ViSQL",fontsize=14)
par1.set_ylabel("WSS",fontsize=14)
par2.set_ylabel("LLR",fontsize=14)

#host.set_ylim(1,4) #for ViSQL
#par1.set_ylim(9, 15) #for WSS
#par2.set_ylim(0,0.02 ) #for LLR

lines = []
#========looop through files to compute mean and error bars
ind = 0

#read data
for f in ff:
    index = 0
    min_len = 200
    for file_name in globals()[f]:
        print("ref ",ref_list[index]," ff ",f)
        data_ref_metric = "data_"+ref_list[index]+"_"+f
        globals()[data_ref_metric] = np.loadtxt(res_dir +'/' + file_name)
        print(len(globals()[data_ref_metric]))
        if len(globals()[data_ref_metric]) < min_len:
            min_len = len(globals()[data_ref_metric])
        index = index+1
        #find unique loss values
        loss_uniq = np.unique(globals()[data_ref_metric][:,0])
    print("minimum len ", min_len)
    
    index = 0
    #cut data based on the file that has the minimum number of runs
    for file_name in globals()[f]:
        data_ref_metric = "data_"+ref_list[index]+"_"+f
        globals()[data_ref_metric] = globals()[data_ref_metric][0:min_len,:]
        index = index + 1

    #merge all metric data in one multi-d array with format: PLR, ref1 res, ref2 res, ref3 res,ref4 res
    index = 0
    #array to hold all runs in one for each metric
    metric_all = f+"_all"
    #initialize the metric with the last file that was read 
    globals()[metric_all] = globals()[data_ref_metric] 
    for file_name in globals()[f]:
        if index < 3: #beacuse we alread add the last file to the array
            data_ref_metric = "data_"+ref_list[index]+"_"+f
            temp = globals()[data_ref_metric][:,1]
            # concatenate all arrays of the specific method
            globals()[metric_all] = np.append(globals()[metric_all], temp[:, None], axis=1)
            index = index + 1

    #find gmean for each run of each metric
    gmean_metric = "gmean_"+f
    loss = globals()[metric_all][:,0]
    globals()[gmean_metric] = loss
    temp_gmean   = scipy.stats.mstats.gmean(globals()[metric_all][:,1:4], axis=1)
    globals()[gmean_metric] = np.append(globals()[gmean_metric][:,None], temp_gmean[:,None],axis=1)
    
        

    #compute arthimetic mean and error bars
    z=1.96 # for error bar computation
    mean_metric = "mean_"+f
    globals()[mean_metric] = []
    std_metric = "std_"+f
    globals()[std_metric] = []
    pesq_std = []
    for l in loss_uniq:
        #print("loss = ",l)
        #print("total runs ",len(np.where(loss==l)[0]))
        total_runs=len(np.where(loss==l)[0])
        loss_mean = np.mean(globals()[gmean_metric] [np.where(loss==l)][:,1])
        loss_std = np.std(globals()[gmean_metric] [np.where(loss==l)][:,1])
        globals()[mean_metric].append(loss_mean)
        globals()[std_metric].append(loss_std)
    globals()[std_metric] = np.asarray(globals()[std_metric]) #change it to np array to allow array operations
    error = z*(globals()[std_metric]/ math.sqrt(total_runs))

    print globals()[std_metric]
    print error

    if method[ind] == "ViSQOL":
        p1 = host.errorbar(loss_uniq,globals()[mean_metric],yerr=error,color=colors[ind],marker=markers[ind],linewidth=2.0,markersize=10,label=method[ind])
    elif method[ind] == "WSS":
        p1 = par1.errorbar(loss_uniq,globals()[mean_metric],yerr=error,color=colors[ind],marker=markers[ind],linewidth=2.0,markersize=10,label=method[ind])
    elif method[ind] == "LLR":
        p1 = par2.errorbar(loss_uniq,globals()[mean_metric],yerr=error,color=colors[ind],marker=markers[ind],linewidth=2.0,markersize=10,label=method[ind])
 
    lines.append(p1)
    ind = ind + 1

plot_name=app+'-many-metrics-model1-ref-total-runs-'+str(total_runs)+'.pdf'
host.legend(lines, [l.get_label() for l in lines], loc="upper left")
#plt.savefig(plot_dir + '/' +plot_name,format="pdf",bbox_inches='tight')
plt.show()

