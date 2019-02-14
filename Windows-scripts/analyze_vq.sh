#!/bin/bash

#This is the new script for the new video objective script "obj-fps-slow-mot-vq.au3"
#run this script with another script (
#sudo ./vq-expt.sh vnc wifi 1
#88888888
#run the script with sudo and change the IP address in the tshark command below

#runNo=$1


total_time_slow=$1
total_time_regular=$2
loss=$3
run_no=$4

log_dir=/home/harlem1/SEEC/Windows-scripts
pcap_file=capture-1

total_bytes_slow=`tshark -q -z "io,stat,0,ip.src==172.28.30.13" -r $log_dir/$pcap_file-slow.pcap | grep '<>' | awk '{print $8}'`
echo "total bytes slow" $total_bytes_slow


total_bytes_regular=`tshark -q -z "io,stat,0,ip.src==172.28.30.13" -r $log_dir/$pcap_file-regular.pcap | grep '<>' | awk '{print $8}'`

echo "total bytes regular" $total_bytes_regular

#rm $log_dir/$pcap_file-slow.pcap $log_dir/$pcap_file-regular.pcap

#========== video quality

vq=$(bc <<< "scale=4; (($total_bytes_regular/$total_time_regular)/23.9) / (($total_bytes_slow/$total_time_slow)/1)")
echo "vq is" $vq
echo $loss $total_time_slow $total_bytes_slow $total_time_regular $total_bytes_regular $vq >> $log_dir/vq-results-$run_no
