IF=$1
speed=$2
log_dir=/home/seec/Desktop/SEEC9/Windows-scripts
tcpdump -i $IF -s 100 -w $log_dir/capture-1-$speed.pcap &
