#This is a python3 code
#input: dst_IP pcap rtt loss app run_no
#python3 compute-rt-from-display-updates-2.py 172.28.30.9 capture-1-slow.pcap 200 10 imgeView 13 5

import sys, os
import numpy as np


#======================= Main Program ===================

#=====================Initialize parameters===============
#input arguments
dst_IP="172.28.30.9"
#pcap=sys.argv[2]
rtt=0
loss=5
app="imgeView"
run_no="1-Pics13"
count=35

res_dir="/home/harlem1/SEEC/Windows-scripts/results"
th_time = 0.500 #threshhold interarrival time to represent new update (unit sec)
res_file="inter_arrival_between_marker.txt"

for c in range(1,count):
    parsed_pcap="tshark-pckts-parsed-rtt-"+str(rtt)+"-loss-"+str(loss)+"-run-no-"+run_no+"-count-"+str(c)
    #====================Process PCAP==========================
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

        #===============================Save Results=========================
        #save results to file
        file_name = res_file # app+"_RT_display_updates_2_run_"+run_no
        f=open(res_dir + '/' + file_name,'ab') #open the file to append to
        np.savetxt(f, ts_diff)
        f.close()


#========compute mean and max===========

#file_name="results/inter_arrival_between_marker.txt"
ts_diff = np.loadtxt(res_dir + '/' + file_name)

print("mean = ", np.mean(ts_diff))
print("max = ", np.amax(ts_diff))
print("sd = ", np.std(ts_diff))
print("75th percentile = ", np.percentile(ts_diff,75))
