
clientIP=$1
rtt=$2
loss=$3
no_tasks=$4
app=$5
runNo=$6
count=$7 #count of euns within one execution (run)

dir=/home/harlem1/SEEC/Windows-scripts

#plot marker and rate
sh $dir/compute-thru.sh capture-1-slow.pcap $clientIP $rtt $loss $dir $runNo $app

#find RT from marker packets
#python3 $dir/compute-rt-from-marker-pkts.py $clientIP $no_tasks $dir/capture-1-slow.pcap $rtt $loss $app 
python3 $dir/compute-rt-from-marker-pkts-2.py $clientIP $dir/capture-1-slow.pcap $rtt $loss $app $runNo

#find RT from display updates packets
#python3 $dir/compute-rt-from-display-updates.py $clientIP $dir/capture-1-slow.pcap $rtt $loss $app $runNo
#find RT from display updates packets
python3 $dir/compute-rt-from-display-updates-2.py $clientIP $dir/capture-1-slow.pcap $rtt $loss $app $runNo $count

#find image quality
