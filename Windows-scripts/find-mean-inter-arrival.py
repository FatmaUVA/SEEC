
#for this script, you need first to run another script
import numpy as np

file_name="results/inter_arrival_between_marker.txt"
ts_diff = np.loadtxt(file_name)

print("mean = ", np.mean(ts_diff))
print("max = ", np.amax(ts_diff))
print("sd = ", np.std(ts_diff))
print("75th percentile = ", np.percentile(ts_diff,75))
print("90th percentile = ", np.percentile(ts_diff,90))
print("99th percentile = ", np.percentile(ts_diff,99))

'''
105 files, with loss 0, 3,5 each 35 runs
('mean = ', 0.005280087250241471)
('max = ', 0.4920879999999954)
('sd = ', 0.028528944350291317)
('75th percentile = ', 6.700000000137152e-05)
('90th percentile = ', 0.007621999999997797)
('99th percentile = ', 0.17528752999999014)
'''
