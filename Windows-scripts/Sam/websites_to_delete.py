# -*- coding: utf-8 -*-
"""
Created on Mon Nov  5 15:15:01 2018

@author: snadj
"""

response_times = []
bytes_ = []

with open('results.txt') as results:
    #storing all response times and bytes for each trial
    for line in results: #for each trial
        data = line.split(' ')
        single_trial_response_times = []
        single_trial_bytes = []

        # creating a list of lists containing response times for each trial
        for i in range(2, int((len(data) / 2) + 1)): # response times begin at index 2 and end at one half the number of elements in the line
            single_trial_response_times.append(float(data[i])) 
        response_times.append(single_trial_response_times) # add response times list from each trial to another total list
        single_trial_response_times = [] # reset single trial list   
        
        # following the same strategy to create a list of lists containing bytes for each trial 
        for i in range(int((len(data) / 2) + 1),len(data)): # bytes are in the second half of the line 
            single_trial_bytes.append(float(data[i])) 
        bytes_.append(single_trial_bytes)
        single_trial_bytes = []

#finding average response times across all trials
sums = [0] * len(response_times[0]) # init array of 40 zeros
for i in range(len(response_times)):
    for j in range(len(response_times[i])):
        sums[j] += response_times[i][j]
averages = [x / len(response_times) for x in sums]

#find indeces of each average response time over 20s
indeces_to_remove = []
for i in range(len(averages)):
    if averages[i] > 20:
        indeces_to_remove.append(i)
        
print(indeces_to_remove)
