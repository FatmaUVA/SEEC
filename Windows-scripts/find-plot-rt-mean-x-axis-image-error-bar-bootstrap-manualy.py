#This is a python3 code
#plot mean RT where the x axis is the image unique pixels or different image with different dimension
#error bar is added to the plot

import sys, os
import numpy as np
import matplotlib.cm as cm
import matplotlib.pyplot as plt
import math


#=====================Initialize parameters===============
#input arguments
rtt=[0,20,50,100,200]
loss=[0] #,3,5]
app="ImageView"
#total_runs=23
method=["display_updates_2"] #["autoit","display_updates","display_updates_2"] #"RT_marker_packets_2"
run_no="3-Pics10"
no_tasks=6
pixels_count = [18675,24639,129190,309237,563443,733950] #no of unique pixels in each image
pixels_count = [1,2,3,4,5,6]
#pxels_count = [18675, 24639,41646,129190, 212414, 309237, 389874, 563443, 733950, 1844451]

res_dir="/home/harlem1/SEEC/Windows-scripts/results"
plot_dir='/home/harlem1/SEEC/Windows-scripts/plots/new-mean'
#plot_name='/mean-RT-image-x-axis-'+app+'-total-runs-'+str(total_runs)+'-run-'+str(run_no)+'.png'

#===================Read data======================

for meth in method:
    for i in range(no_tasks):
        file_name = app + "_RT_"+meth+"_run_"+str(run_no)
        #one array for each task (image)
        if meth == "autoit": #it doesn't have total no of bytes to read
            temp1 = "rt_"+meth+"_"+str(i)
            globals()[temp1] = np.loadtxt(res_dir +'/' + file_name, delimiter=' ',usecols=(i+2,),unpack=True)
        else:
            temp1 = "rt_"+meth+"_"+str(i)  #name of array created based on parameters (for rt)
            temp2 = "by_"+meth+"_"+str(i) #array for bytes
            #globals will evaluate the array name befor assigning it the values
            globals()[temp1], globals()[temp2] = np.loadtxt(res_dir +'/' + file_name, delimiter=' ',usecols=(i+2,i+8),unpack=True)
            globals()[temp2] = globals()[temp2]/10e6 # change it to MB


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



    #add elements to the new list
    for i in range(len(globals()[temp1])):
        globals()[temp2].append(globals()[temp1][i])

#create arrays based on method, loss, and task(or image)
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
#each image will have xx values (based on the total_runs) for each loss rate
#find mean of each image and append it to an array of mean value for each loss rate
#also find upper and lower values for error bar for each point
z=1.96 # fro error bar
for meth in method:
    for l in loss_uniq:
        #create arrays to hold the mean value of rt for each image based on loss value (each array withh have the mean of each image as one row)
        temp5 = "rt_"+meth+"_loss_" + str(l) + "_mean"
        temp6 = "by_"+meth+"_loss_" + str(l) + "_mean"
        std_rt = "rt_"+meth+"_loss_" + str(l) + "_std"
        std_by = "by_"+meth+"_loss_" + str(l) + "_std"
        error_rt = "rt_"+meth+"_loss_" + str(l) + "_error"
        error_by = "by_"+meth+"_loss_" + str(l) + "_error"
        globals()[temp5] = []
        globals()[temp6] = []
        globals()[error_rt] = [] #for error bar
        globals()[error_by] = [] #for error bar
        globals()[std_rt] = [] #for stdiance to compute error bar
        globals()[std_by] = []

        for i in range(no_tasks):
            rttx = []
            index_array = "loss_" + str(l) + "_index"
            temp2 = "rt_"+meth+"_"+str(i)
            temp1 = "rt_"+meth+"_"+str(i)+"_loss_" + str(l)
            temp3 = "by_"+meth+"_"+str(i)+"_loss_" + str(l)
            for j in range(len(globals()[index_array])):
                index = globals()[index_array][j]                
                globals()[temp1].append(globals()[temp2][index])
                if meth != "autoit": #it doesn't have total no of bytes to read
                    temp4 = "by_"+meth+"_"+str(i)
                    globals()[temp3].append(globals()[temp4][index])
        #print("temp1, ",temp1," ",globals()[temp1])
            #find the mean and add it to an array that have all images in one row, also find std for error bar
            globals()[temp5].append(np.mean(globals()[temp1]))
            globals()[std_rt].append(np.std(globals()[temp1]))
            if meth != "autoit": 
                globals()[temp6].append(np.mean(globals()[temp3]))
                globals()[std_by].append(np.std(globals()[temp3]))

        print(temp6," ",globals()[temp6])
        print(std_by," ",globals()[std_by])

        #find error bar: Standared Error (SE) = std/sqrt(n), upper limit = mean + SE*z
        #change it to numpy array
        globals()[error_rt] = np.asarray(globals()[error_rt])
        globals()[error_by] = np.asarray(globals()[error_by])
        globals()[std_rt] = np.asarray(globals()[std_rt])
        globals()[std_by] = np.asarray(globals()[std_by])
        globals()[temp5] = np.asarray(globals()[temp5])
        globals()[temp6] = np.asarray(globals()[temp6])
        #compute error bar
        globals()[error_rt] = (globals()[std_rt]/ math.sqrt(total_runs))
        globals()[error_rt] = z*globals()[error_rt]
        if meth != "autoit":
            globals()[error_by] = (globals()[std_by]/ math.sqrt(total_runs))
            globals()[error_by] = z*globals()[error_by]
        #globals()[error_rt] = globals()[temp5] + (globals()[temp6]/ math.sqrt(total_runs))
        print(error_by," ",globals()[error_by])
        


#=================================Plot======================================

plot_name='/mean-RT-image-x-axis-'+app+'-errorbar-total-runs-'+str(total_runs)+'-run-'+str(run_no)+'.png'

#pixels_count = [] #no of unique pixels in each image
colors = cm.rainbow(np.linspace(0, 7, 20))
markers = ['^','s','o','*','x','D','+']
fig, ax1 = plt.subplots(1)
ax1.set_xlabel('Number of unique pixels',fontsize=14)
ax1.set_ylabel(app+' load time (sec)')

for meth in method:
    col_index = 0 #index to assign differnt colors for lines
    for l in loss_uniq:
        temp5 = "rt_"+meth+"_loss_" + str(l) + "_mean"
        error_rt = "rt_"+meth+"_loss_" + str(l) + "_error"

        #ax1.plot(pixels_count,globals()[temp5],color=colors[col_index],marker=markers[col_index],linewidth=2.0,markersize=10,label = meth+', loss = '+str(l)+"%")
        ax1.errorbar(pixels_count,globals()[temp5], yerr=globals()[error_rt],color=colors[col_index] ,linewidth=2.0,marker=markers[col_index],markersize=10,label = meth+', loss = '+str(l)+"%")
        col_index = col_index + 1

#create anothor axis for number of bytes
ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
ax2.set_ylabel('Display Update Size (MBytes)')  # we already handled the x-label with ax1
for meth in method:
    col_index = 0 #index to assign differnt colors for lines
    for l in loss_uniq:
        if meth != "autoit":
            temp6 = "by_"+meth+"_loss_" + str(l) + "_mean"
            error_by = "by_"+meth+"_loss_" + str(l) + "_error"
#            ax2.plot(pixels_count,globals()[temp6],color=colors[col_index],marker=markers[col_index],linestyle='dashed',linewidth=2.0,markersize=10,label = meth+',bytes, loss = '+str(l)+"%")
            ax2.errorbar(pixels_count,globals()[temp6], yerr=globals()[error_by],color=colors[col_index], linestyle='dashed',linewidth=2.0,marker=markers[col_index],markersize=10,label = meth+',bytes, loss = '+str(l)+"%")
            print(error_by," ",globals()[error_by])

        col_index = col_index + 1

ax1.legend(loc='upper left',ncol=3,bbox_to_anchor=(-0.5,1.18))
ax2.legend(loc='upper left',ncol=3,bbox_to_anchor=(-0.5,-0.1))

plt.show()
#save the plot for each image
plt.savefig(plot_dir + '/' +plot_name,format="png",bbox_inches='tight')
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
