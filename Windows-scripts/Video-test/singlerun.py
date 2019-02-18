

import skvideo.io
import skvideo.measure
import os
import sys
import numpy
import mat4py
import time

def MainT(videochannels,tempr,filename):
	#create array to put in each channel(YUV) of video
	videoanalysisnr=numpy.zeros((1000,3))
	# run NIQE command on each channel	
	for n in range(0,3):
		
		videoanalysisnr[0:tempr,n] =  skvideo.measure.niqe(videochannels[:,:,:,n])		
		print('n')		
		 
	#save in matlab frindly format
	a=videoanalysisnr
	b=tempr
	c=filename


	c=c.replace('.avi','')
	dictvideo={'nr1'+c:a[:,0].tolist(),'nr2'+c:a[:,1].tolist(),'nr3'+c:a[:,2].tolist(),'countr'+c:c}
	mat4py.savemat(c+'.mat',dictvideo)
