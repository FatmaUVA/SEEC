#This is a python3 code
#input: dst_IP pcap rtt loss app run_no
#python3 compute-rt-from-display-updates-2.py 172.28.30.9 capture-1-slow.pcap 200 10 imgeView 13 5
#This script print the bytes of one packet trace: X-axis Time in ms, Y-axis is the total Bytes sent every ms,
#and two lines indicate start and end of market-timer and DUT timer

import sys, os
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

#======================= Main Program ===================

#=====================Initialize parameters===============
#input arguments
dst_IP="172.28.30.9"
#pcap=sys.argv[2]
rtt=0
loss=0
app="imgeView"
run_no="2-Pics14-model4"
#count=10
c=9

res_dir="/home/harlem1/SEEC/Windows-scripts/results"
th_time = 1 #threshhold interarrival time to represent new update (unit sec)
res_file="inter_arrival_between_marker.txt"

#for c in range(1,count): #if I want plot many in a loop
#parsed_pcap="tshark-pckts-parsed-rtt-"+str(rtt)+"-loss-"+str(loss)+"-run-no-"+run_no+"-count-"+str(c)
pcap="/home/harlem1/capture-delay-0-loss-0.pcap"
parsed_pcap="xx"
command = "tshark -r " + pcap +" \"ip.dst=="+ dst_IP +" and not icmp\" | grep UDP | awk '{print $2,$7,$10}' > "+ res_dir + "/parsed-pcap/" + parsed_pcap
os.system(command)
#====================Process PCAP==========================
#load the parsed pcap file data (ts, packet size, dst port)
ts,size,port = np.loadtxt(res_dir+"/parsed-pcap/"+parsed_pcap, delimiter=' ', usecols=(0,1,2),unpack=True)

#============Find total Bytes every 1 ms================
#loop thru the packet trace and find total bytes every 1ms
Bytes = []
Bytes_all = size
ts_all = ts
interval = 0
ts_ms = [] #x-axis in ms
temp_bytes = size[0]
for j in range(len(ts)):
    if j+1<len(size): # tomake sure we haven't reach the end of the array
        diff = ts[j+1]-ts[j]
        interval = interval + diff
        if interval <= 0.001:
            temp_bytes = temp_bytes + size[j+1]
        else:
            ts_ms.append(ts[j]*1e3)
            interval = 0
            Bytes.append(temp_bytes)
            temp_bytes = size[j+1]

Bytes = np.asarray(Bytes)


#===================Pre processing packets======================
#remove all PCoIP communication packets which are of size 110B
sizex = []
tsx = []
portx = []
for j in range(len(size)):
    if size[j]<=110:
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

#==================Compute DUT RT===============================
th_time = 0.500 #threshhold interarrival time to represent new update (unit sec)
DUT = [] #array hold start and end time of each image
marker_rt = []
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
    DUT.append(ts[index]) #append start
    marker_rt.append(ts[index]) #start marker
    marker_rt.append(ts[index+1]) #end marker

    for j in range(index+1,len(ts)):
        if j+1<len(ts): #to ensure we haven't reached hte enad of the array (avoid out of index error)
            if (ts[j+1] - ts[j]) > th_time:
                DUT.append(ts[j])
                #end_ts = ts[j]
                #resp_time = end_ts - start_ts
                #rt.append(resp_time)
                #sz.append(sz_temp)
                break
            #else:
            #    sz_temp+= size[j]
            #    temp_pckts.append(ts[j])
        #else: #reached the last packet of the array
        #    end_ts = ts[j]
        #    resp_time = end_ts - start_ts
        #    rt.append(resp_time)
        #    sz.append(sz_temp)
        #    break

    #temp_pckts = np.asarray(temp_pckts)
DUT = np.asarray(DUT)
print "DUT ",DUT
print "marker_rt ",marker_rt

#========================Plot=======================
plot_dir='/home/harlem1/SEEC/Windows-scripts/plots/'
plot_name1 = "packets-vs-time-DUT-Marker-"+str(rtt)+"-loss-"+str(loss)+"-run-no-"+run_no+"-count-"+str(c)

fig, ax1 = plt.subplots(1)
ax1.set_xlabel('Time (sec)',fontsize=14)
ax1.set_ylabel('Packet size (Bytes)')
ax1.plot(ts_all,Bytes_all,linewidth=2.0)
for i in range(len(DUT)):
    ax1.axvline(x=DUT[i],color="y",linewidth=2.0,label='DUT')
    ax1.axvline(x=marker_rt[i],color="orange",linewidth=2.0,label='Marker-RT')

custom_lines = [Line2D([0], [0], color='y', lw=2,label='DUT'), Line2D([0], [0], color='orange', lw=2,label='Marker-RT')]
ax1.legend(loc='upper left', bbox_to_anchor=(0.2,1.18),ncol=2, handles=custom_lines)
plt.savefig(plot_dir + plot_name1+'.png',format="png",bbox_inches='tight')

#plot 2 with ms x-axis, and aggregated packets every ms
plot_name2 = "Kbits-vs-time-ms-DUT-Marker-"+str(rtt)+"-loss-"+str(loss)+"-run-no-"+run_no+"-count-"+str(c) 
fig, ax1 = plt.subplots(1)
ax1.set_xlabel('Time (ms)',fontsize=14)
ax1.set_ylabel('KBits/1 ms')
ax1.plot(ts_ms,(Bytes*8)/1e3,linewidth=2.0)
for i in range(len(DUT)):
    ax1.axvline(x=DUT[i]*1e3,color="y",linewidth=2.0)
    ax1.axvline(x=marker_rt[i]*1e3,color="orange",linewidth=2.0)
custom_lines = [Line2D([0], [0], color='y', lw=2,label='DUT'), Line2D([0], [0], color='orange', lw=2,label='Marker-RT')]
ax1.legend(loc='upper left', bbox_to_anchor=(0.2,1.18),ncol=2, handles=custom_lines)
plt.savefig(plot_dir + plot_name2+'.png',format="png",bbox_inches='tight')
plt.show()


