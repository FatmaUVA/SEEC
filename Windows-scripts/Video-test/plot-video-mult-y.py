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

#plot_dir='/home/harlem1/SEEC/Windows-scripts/Video-test'
#res_dir="/home/harlem1/SEEC/Windows-scripts/Video-test/fps-logs"
plot_dir='/Users/fatmaalali/Documents/UVA/Scripts/SEEC/Windows-scripts/Video-test'
res_dir="/Users/fatmaalali/Documents/UVA/Scripts/SEEC/Windows-scripts/Video-test/fps-logs"

method=["slow-mo-VQ","Total update size (MBytes)","recv-PCoIP-fps"]

colors = cm.rainbow(np.linspace(0, 7, 20))
markers = ['^','s','o','*','x','D','+']

#ff=["vq-results-3-model4", "vq-results-3-model4", "fps_run_3-model4.txt"]
ff=["vq-results-3-and-4-model4", "vq-results-3-and-4-model4", "fps_run_3_and_4-model4.txt"]
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
host.set_xlabel('Packet loss rate (%)',fontsize=14)
host.set_ylabel("Received PCoIP fps (recv-PCoIP-fps)",fontsize=14)
par1.set_ylabel("Video quality (slow-mo-VQ)",fontsize=14)
par2.set_ylabel("Total update size (MBytes)",fontsize=14)

host.set_ylim(1,25) #for FPS
par1.set_ylim(0,1) #for VQ
par2.set_ylim(0,40) #for MB

lines = []
#========looop through files to compute mean and error bars
index = 0
for file_name in ff:
#read data
    if file_name == ff[2]:
        loss,pesq=np.loadtxt(res_dir +'/' + file_name, delimiter=' ',usecols=(0,1), unpack=True)
    else:
        if index == 0:
            loss,pesq=np.loadtxt(res_dir +'/' + file_name, delimiter=' ',usecols=(0,5), unpack=True) #read vq which is col5
        else:
            loss,pesq=np.loadtxt(res_dir +'/' + file_name, delimiter=' ',usecols=(0,4), unpack=True) #read bytes which is col4
            pesq = pesq/10e6 #change the unit to MB

    #Find mean based on loss value
    loss_uniq = np.unique(loss)
    print("unique loss values = ",loss_uniq)

    z=1.96 # for error bar computation
    pesq_mean = []
    pesq_std = []
    for l in loss_uniq:
        print("loss = ",l)
        print("total runs ",len(np.where(loss==l)[0]))
        total_runs=len(np.where(loss==l)[0])
        pesq_loss_mean = np.mean(pesq[np.where(loss==l)[0]])
        pesq_loss_std = np.std(pesq[np.where(loss==l)[0]])
        pesq_mean.append(pesq_loss_mean)
        pesq_std.append(pesq_loss_std)
    pesq_std = np.asarray(pesq_std) #change it to np array to allow array operations
    pesq_error = z*(pesq_std / math.sqrt(total_runs))

    print pesq_mean
    print pesq_error

    if method[index] == "recv-PCoIP-fps":
        p1 = host.errorbar(loss_uniq,pesq_mean,yerr=pesq_error,color=colors[index],marker=markers[index],linewidth=2.0,markersize=10,label=method[index])
    elif method[index] == "slow-mo-VQ":
        p1 = par1.errorbar(loss_uniq,pesq_mean,yerr=pesq_error,color=colors[index],marker=markers[index],linewidth=2.0,markersize=10,label=method[index])
    elif method[index] == "Total update size (MBytes)":
        p1 = par2.errorbar(loss_uniq,pesq_mean,yerr=pesq_error,color=colors[index],marker=markers[index],linewidth=2.0,markersize=10,label=method[index])
 
    lines.append(p1)
    index = index + 1

plot_name='new-metric-name-video-vq-fps-bytes-total-runs-'+str(total_runs)+'.pdf'
host.legend(lines, [l.get_label() for l in lines], loc="upper right")
plt.savefig(plot_dir + '/' +plot_name,format="pdf",bbox_inches='tight')
#plt.show()
