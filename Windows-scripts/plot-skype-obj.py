
import sys, os
import numpy as np
import matplotlib.cm as cm
import matplotlib.pyplot as plt
import math
import scipy.stats

plot_dir='/home/harlem1/SEEC/Windows-scripts/plots/2018-12-plots'
res_dir="/home/harlem1/SEEC/Windows-scripts/Skype"
file_name="parsed-skype-obj"
app = "Skype"
method=["PESQ"]

#read data
loss,pesq=np.loadtxt(res_dir +'/' + file_name,unpack=True)
data = np.loadtxt(res_dir +'/' + file_name)
#print("loss ",loss)
#print("pesq",pesq)
#print("data",data[:,0])

#Find mean based on loss value
loss_uniq = np.unique(data[:,0])
print("unique loss values = ",loss_uniq)

pesq = []
for l in loss_uniq:
    print("loss = ",l)
    print("total runs ",len(np.where(loss==l)[0]))
    total_runs=len(np.where(loss==l)[0])
    pesq.append(np.mean(data[np.where(loss==l)][:,1]))

print pesq

#plot
plot_name=app+'-pesq-model1-ref-total-runs-'+str(total_runs)+'.png'

colors = cm.rainbow(np.linspace(0, 7, 20))
markers = ['^','s','o','*','x','D','+']

plt.xlabel('packet loss rate (%)',fontsize=14)
plt.ylabel(app+' PESQ')
#plt.ylim(1,4.5)
plt.plot(loss_uniq,pesq,color=colors[0],marker=markers[0],linewidth=2.0,markersize=10)

plt.savefig(plot_dir + '/' +plot_name,format="png",bbox_inches='tight')
plt.show()
