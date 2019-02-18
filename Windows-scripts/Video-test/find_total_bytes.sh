#This script is used to find total bytes in a pcap
#It is used for the video objective measurements
#to test the script: sh find_total_bytes.sh 172.28.30.9 0 0 0 0 0
# The unit of the parsed results is 'Bytes'

#input param
clientIP=$1
rtt=$2
loss=$3
no_tasks=$4
app=$5
runNo=$6
count=$7 #count of euns within one execution (run)

log_dir=/home/seec/Desktop/SEEC9/Windows-scripts #TODO

#find total bytes usibg tshark and parse the bytes out of tshark output
filter="io,stat,0,ip.dst=="$clientIP
tshark -q -z $filter -r $log_dir/capture-1-slow.pcap | grep '<>' | awk '{print $8}' >> $log_dir/$app-total-bytes-runNo-$runNo

