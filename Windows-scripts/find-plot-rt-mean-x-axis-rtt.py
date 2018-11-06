#This is a python3 code

#This plot find the mean rt and bytes of xx runs, and plot in the x-axis: RTT, two y-axeses RT and bytes, and many lines each for specific loss rate. It produce one plot for each loaded image (or performed task)

import sys, os
import numpy as np
import matplotlib.cm as cm
import matplotlib.pyplot as plt


#=====================Initialize parameters===============
#input arguments
rtt=[0,20,50,100,200]
loss=[0,3,5]
app="ImageView"
total_runs=10
res_dir="/home/harlem1/SEEC/Windows-scripts/results"
plot_dir='/home/harlem1/SEEC/Windows-scripts/plots/new-mean'
method=["display_updates_2"] #["autoit","display_updates","display_updates_2"] #"RT_marker_packets_2"
run_no=16
no_tasks=6
#===================Read data======================

for meth in method:
    for i in range(no_tasks):
        file_name = app + "_RT_"+meth+"_run_"+str(run_no)
        if meth == "autoit": #it doesn't have total no of bytes to read
            temp1 = "rt_"+meth+"_"+str(i)
            globals()[temp1] = np.loadtxt(res_dir +'/' + file_name, delimiter=' ',usecols=(i+2,),unpack=True)
        else:
            temp1 = "rt_"+meth+"_"+str(i)  #name of array created based on parameters (for rt)
            temp2 = "by_"+meth+"_"+str(i) #array for bytes
            #globals will evaluate the array name befor assigning it the values
            globals()[temp1], globals()[temp2] = np.loadtxt(res_dir +'/' + file_name, delimiter=' ',usecols=(i+2,i+8),unpack=True)

# read rtt and loss values and create arrays based on loss values
#figure out the length of the file, read only one file , other files would have the same length
file_name = app + "_RT_"+method[0]+"_run_"+str(run_no)
rtt, loss = np.loadtxt(res_dir +'/' + file_name, delimiter=' ',usecols=(0,1),unpack=True)

#==============Pre-process data===================
#find unique loss values
loss_uniq = np.unique(loss)
print("unique loss values = ",loss_uniq)
rtt_unique = np.unique(rtt)
print("unique rtt values = ",rtt_unique)

#find indices where loss value equal to specific value
for l in loss_uniq:
    temp1 = "loss_" + str(l) 
    globals()[temp1] = np.where(loss==l)
    #print("indices, " ,temp1,"  = ",globals()[temp1]) 
    #convert it to a list structure to easily access elemts in a loop
    temp2 = "loss_" + str(l) + "_index"
    globals()[temp2] = []

    #add elements to the new list
    for i in range(len(globals()[temp1][0])):
        globals()[temp2].append(globals()[temp1][0][i])

#create arrays for each image based on loss value
for meth in method:
    for i in range(no_tasks):
        for l in loss_uniq:
            if meth == "autoit": #it doesn't have total no of bytes to read
                temp1 = "rt_"+meth+"_"+str(i)+"_loss_" + str(l) 
                globals()[temp1] = []
            else:
                temp1 = "rt_"+meth+"_"+str(i)+"_loss_" + str(l)
                temp2 = "by_"+meth+"_"+str(i)+"_loss_" + str(l)
                globals()[temp1] = []
                globals()[temp2] = []

#append values to the arrays based on loss values
for meth in method:
    for i in range(no_tasks):
        for l in loss_uniq:
            rttx = []
            index_array = "loss_" + str(l) + "_index"
            for j in range(len(globals()[index_array])):
                index = globals()[index_array][j]
                temp2 = "rt_"+meth+"_"+str(i)
                temp1 = "rt_"+meth+"_"+str(i)+"_loss_" + str(l)
                temp3 = "by_"+meth+"_"+str(i)+"_loss_" + str(l)
                rttx.append(rtt[index])
                
                globals()[temp1].append(globals()[temp2][index])
                if meth != "autoit": #it doesn't have total no of bytes to read
                    temp4 = "by_"+meth+"_"+str(i)
                    globals()[temp3].append(globals()[temp4][index])
            #reshape array to find mean 
            temp1 = "rt_"+meth+"_"+str(i)+"_loss_" + str(l)
            temp3 = "by_"+meth+"_"+str(i)+"_loss_" + str(l)
            globals()[temp1] = np.asarray(globals()[temp1])
            globals()[temp1] = np.reshape(globals()[temp1],(total_runs,len(rtt_unique)))
            if meth != "autoit":
                globals()[temp3] = np.asarray(globals()[temp3])
                globals()[temp3] = np.reshape(globals()[temp3],(total_runs,len(rtt_unique)))

#temp1 = "rt_"+method[0]+"_"+str(i)+"_loss_" + str(l)
#print(temp1, " ",globals()[temp1])
#print("len ",temp1 , len(globals()[temp1]))

# find the mean of the xx total runs
for meth in method:
    for i in range(no_tasks):
        for l in loss_uniq:
            temp1 = "rt_"+meth+"_"+str(i)+"_loss_" + str(l)
            temp3 = "by_"+meth+"_"+str(i)+"_loss_" + str(l)
            temp2 = "rt_"+meth+"_"+str(i)+"_loss_" + str(l) + "_mean"
            temp4 = "by_"+meth+"_"+str(i)+"_loss_" + str(l) + "_mean"

            globals()[temp2] = np.mean(globals()[temp1], axis=0) #take the mean across column, which means across each rtt value
            if meth != "autoit":
                globals()[temp4] = np.mean(globals()[temp3], axis=0)
                #print(temp4," ", globals()[temp4]) 


#=================================Plot======================================

rtt = np.asarray(rtt_unique)
colors = cm.rainbow(np.linspace(0, 7, 20))
markers = ['^','s','o','*','x','D','+'] 
for i in range(no_tasks):
    fig, ax1 = plt.subplots(1)
    ax1.set_xlabel('RTT (ms)',fontsize=14)
    ax1.set_ylabel(app+' load time (sec)')
    for meth in method:
        col_index = 0 #index to assign differnt colors for lines
        for l in loss_uniq:
            temp2 = "rt_"+meth+"_"+str(i)+"_loss_" + str(l) + "_mean"

            ax1.plot(rtt,globals()[temp2],color=colors[col_index],marker=markers[col_index],linewidth=2.0,markersize=10,label = meth+', loss = '+str(l)+"%")
            col_index = col_index + 1

    #create anothor axis for number of bytes
    ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
    ax2.set_ylabel('Display Update Size (Bytes)')  # we already handled the x-label with ax1
    for meth in method:
        col_index = 0 #index to assign differnt colors for lines
        for l in loss_uniq:
            if meth != "autoit":
                temp4 = "by_"+meth+"_"+str(i)+"_loss_" + str(l) + "_mean"
                ax2.plot(rtt,globals()[temp4],color=colors[col_index],marker=markers[col_index],linestyle='dashed',linewidth=2.0,markersize=10)

            col_index = col_index + 1

    ax1.legend(loc='upper left',ncol=3,bbox_to_anchor=(0,1.18))
    #save the plot for each image
    plt.savefig(plot_dir + '/mean-RT-'+app+'-image-'+str(i)+'-run-'+str(run_no)+'.png',format="png",bbox_inches='tight')
    plt.close()
        
'''
#===============================Save Results=========================
#save results to file
#change to np array to save file
rt = rt + sz #add the byte size of each task to rt array to write both rt and size to one output file
rt = np.array(rt)
#file_name = app+"_RT_marker_packets_rtt"+rtt+"_loss_"+loss 
file_name = app+"_RT_display_updates_2_run_"+run_no
f=open(res_dir + '/' + file_name,'ab') #open the file to append to
np.savetxt(f, rt.reshape(1, rt.shape[0]), fmt="%s") #the reshape function is used to convert the array to row-wise array to be saved as one row in the file
f.close()

#delete pcap and parsed file
command = "rm "+ res_dir + "/" + parsed_pcap
os.system(command) 
'''
