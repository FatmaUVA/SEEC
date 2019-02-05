# This script plot 4 AQ metrics: WSS, VISQL, LLR and E-Model
# X_axis is the loss rate, and two y-axes in the left and right each for different metric

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
ref="m_3"
method=["ViSQOL","WSS","LLR", "E-Model"]
ff=["ViSQOL_results.txt","WSS_results.txt","LLR_results.txt"]
ff=["loss-model1_ref_"+ref+"_ViSQOL_results.txt", "loss-model1_ref_"+ref+"_WSS_results.txt", "loss-model1_ref_"+ref+"_LLR_results.txt"]
#e-model = [4.41,3.18,1.31,1.10,1.00]

colors = cm.rainbow(np.linspace(0, 7, 20))
markers = ['^','s','o','*','x','D','+']

#=========setup plot enviroment
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

host.set_ylim(1,4) #for ViSQL
#par1.set_ylim(9, 15) #for WSS
par2.set_ylim(0,0.02 ) #for LLR

lines = []
#========looop through files to compute mean and error bars
index = 0
for file_name in ff:
#read data
    loss,pesq=np.loadtxt(res_dir +'/' + file_name,unpack=True)
    data = np.loadtxt(res_dir +'/' + file_name)
    #print("loss ",loss)
    #print("pesq",pesq)
    #print("data",data[:,0])

    total_runs = len(loss)
    #Find mean based on loss value
    loss_uniq = np.unique(data[:,0])
    print("unique loss values = ",loss_uniq)

    z=1.96 # for error bar computation
    pesq = []
    pesq_std = []
    for l in loss_uniq:
        print("loss = ",l)
        print("total runs ",len(np.where(loss==l)[0]))
        total_runs=len(np.where(loss==l)[0])
        pesq_loss_mean = np.mean(data[np.where(loss==l)][:,1])
        pesq_loss_std = np.std(data[np.where(loss==l)][:,1])
        pesq.append(pesq_loss_mean)
        pesq_std.append(pesq_loss_std)
    pesq_std = np.asarray(pesq_std) #change it to np array to allow array operations
    pesq_error = z*(pesq_std / math.sqrt(total_runs))

    print pesq
    print pesq_error

    if method[index] == "ViSQOL":
        p1 = host.errorbar(loss_uniq,pesq,yerr=pesq_error,color=colors[index],marker=markers[index],linewidth=2.0,markersize=10,label=method[index])
    elif method[index] == "WSS":
        p1 = par1.errorbar(loss_uniq,pesq,yerr=pesq_error,color=colors[index],marker=markers[index],linewidth=2.0,markersize=10,label=method[index])
    elif method[index] == "LLR":
        p1 = par2.errorbar(loss_uniq,pesq,yerr=pesq_error,color=colors[index],marker=markers[index],linewidth=2.0,markersize=10,label=method[index])
 
    lines.append(p1)
    index = index + 1

plot_name=app+'-many-metrics-model1-ref-total-runs-'+str(total_runs)+'.pdf'
host.legend(lines, [l.get_label() for l in lines], loc="upper left")
#plt.savefig(plot_dir + '/' +plot_name,format="pdf",bbox_inches='tight')
plt.show()
