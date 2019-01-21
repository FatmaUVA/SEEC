file="pesq_results_uam1s03_model1_ref_skype.txt"
ff=`echo $file | rev | cut -c 5- | rev` #part of output file name "remove the .txt"
echo $ff
out_file="parsed-"$ff+".csv"

#parse string (file name) by '\', then remove .wav from the last string to get the loss value
cat $file | grep wav | awk '{print $2}' | cut -d '\' -f 5 | rev | cut -c 5- | rev > file1
#read PESQ value
cat $file | grep wav | awk '{print $3}' > file2
echo PLR,pesq > $out_file
paste -d ',' file1 file2 >> $out_file

rm file1 file2

#extract the loss value from the strinf "loss-x" and write it to the file using find and replace
sed -i -e 's/loss-0-5/0.5/g' $out_file
sed -i -e 's/loss-0/0/g' $out_file
sed -i -e 's/loss-3/3/g' $out_file
sed -i -e 's/loss-5/5/g' $out_file
sed -i -e 's/loss-10/10/g' $out_file
