

import skvideo.io
import skvideo.measure
import os
import sys
import numpy
import mat4py
import time
import singlerun

def MainT():

	 
	pathref = '/home/toan4/Desktop/0_no_clumsy'
	#make a list of files in file path pathref
	filesr=os.listdir(pathref)

	
	for filename in filesr:	
		
		filetemp=pathref+'/'+ filename
		print(filetemp)
		# read in file and determine total frame
		videochannels = skvideo.io.vread(filetemp)
		ts = videochannels.shape
		tempr= ts[0]
		print(tempr)
		#run program for doing a single run of NIQE and then saving it in a matlab file
		singlerun.MainT(videochannels,tempr,filename)
		

	

