#This is a python3 code
#input: dst_IP pcap rtt loss app run_no
#python3 compute-rt-from-display-updates-2.py 172.28.30.9 capture-1-slow.pcap 200 10 imgeView 13 5

import sys, os
import numpy as np


#======================= Main Program ===================

#=====================Initialize parameters===============
#input arguments
dst_IP=sys.argv[1]
pcap=sys.argv[2]
rtt=sys.argv[3]
loss=sys.argv[4]
app=sys.argv[5]
run_no=sys.argv[6]
count=sys.argv[7]

parsed_pcap="tshark-pckts-parsed-rtt-"+rtt+"-loss-"+loss+"-run-no-"+run_no+"-count-"+count # to keep each parsed pcap in case we want to try new threshold value
res_dir="/home/harlem1/SEEC/Windows-scripts/results"
th_time = 0.500 #threshhold interarrival time to represent new update (unit sec)
#log_dir="/home/harlem1/SEEC/Windows-scripts"

#====================Process PCAP==========================
#process the pcap file and get the marker packets timestamps
command = "tshark -r " + pcap +" \"ip.dst=="+ dst_IP +" and not icmp\" | grep UDP | awk '{print $2,$7,$10}' > "+ res_dir + "/parsed-pcap/" + parsed_pcap
os.system(command)

#load the parsed pcap file data (ts, packet size, dst port)
ts,size,port = np.loadtxt(res_dir+"/parsed-pcap/"+parsed_pcap, delimiter=' ', usecols=(0,1,2),unpack=True)

#===================Pre processing packets======================
#remove all PCoIP communication packets which are of size 110B
sizex = []
tsx = []
portx = []
for j in range(len(size)):
    if size[j]<110:
        if port[j] == 60000: #include also marker packets to compute rt
            sizex.append(size[j])
            tsx.append(ts[j])
            portx.append(port[j])
    else: #it is a display update packets add it to the array
        sizex.append(size[j])
        tsx.append(ts[j])
        portx.append(port[j])

port = np.asarray(portx)
ts = tsx
size = sizex

#==================Compute RT===============================
#find indces of marker packtes, every other index represents the start marker packets
marker_index = np.where(port==60000)

#convert it to a list structure to easily access elemts in a loop
mk_index = []
for i in range(len(marker_index[0])):
    mk_index.append(marker_index[0][i])


#find RT for each task
rt = [rtt, loss] #array for RTs, initialize it with rtt and loss to write the results to a file
sz = [] #size of the display updates for each task, unit bytes

for i in range(0,len(mk_index),2): #step by 2 because the 2nd marker would be the packetsindicate the end of task, which we don't need
    index = mk_index[i]
    temp_pckts = []

    start_ts = ts[index]
    sz_temp = 0 #to compute the total size of display updates
    for j in range(index+1,len(size)):
        if j+1<len(size): #to ensure we haven't reached hte enad of the array (avoid out of index error)
            if (ts[j+1] - ts[j]) > th_time:
                end_ts = ts[j]
                resp_time = end_ts - start_ts
                rt.append(resp_time)
                sz.append(sz_temp)
                break
            else:
                sz_temp+= size[j]
                temp_pckts.append(ts[j]) 
        else: #reached the last packet of the array
            end_ts = ts[j]
            resp_time = end_ts - start_ts
            rt.append(resp_time)
            sz.append(sz_temp)
            break

    temp_pckts = np.asarray(temp_pckts)
    ts_diff = np.ediff1d(temp_pckts)
    xx="xx-display-" + str(index)
    np.savetxt(xx, ts_diff)

'''
    #to print statistics about inter-arrival time between packets (between marker packets)
    print("New Task ")
    print("mean = ", np.mean(ts_diff))
    print("sd = ", np.std(ts_diff))
    print("median = ", np.median(ts_diff))
    print("variance = ", np.var(ts_diff))
    print("max = ", np.amax(ts_diff))
    print("min = ", np.amin(ts_diff))
    print("75th percentile = ", np.percentile(ts_diff,75))
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
#command = "rm "+ res_dir + "/parsed-pcap/" + parsed_pcap
os.system(command) 
