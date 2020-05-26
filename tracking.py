#!/usr/bin/env python3

import Trekker
import json
import os,sys
sys.path.append('./')
import trekkerIO

def trekker_tracking(FOD_path,count,min_fod_amp,curvatures,step_size,min_length,max_length,max_sampling,seed_max_trials,probe_length,probe_quality,probe_radius,probe_count,best_at_init):
	
    # initialize FOD
    FOD = FOD_path[-9:-7].decode()
    if FOD[0] == 'x':
        FOD =  FOD_path[-8:-7].decode()

    mytrekker=Trekker.initialize(FOD_path)

	# set white matter as seed
	seed = b"wm_bin.nii.gz"
	mytrekker.seed_image(seed)

	# set gray matter
	gm = b"gm_bin.nii.gz"

	# set csf
	csf = b"csf_bin.nii.gz"

	# set include and exclude definitions
	mytrekker.pathway_discard_if_enters(csf)
	mytrekker.pathway_require_entry(gm)

	# set non loopable parameters
	# required parameters
	mytrekker.minLength(min_length)
	mytrekker.maxLength(max_length)
	mytrekker.useBestAtInit(best_at_init)
	mytrekker.seed_count(count)

	# if = default, let trekker pick
	if probe_radius != 'default':
		mytrekker.probeRadius(probe_radius)
	if probe_quality != 'default':
		mytrekker.probeQuality(probe_quality)
	if probe_length != 'default':
		mytrekker.probeLength(probe_length)
	if probe_count != 'default':
		mytrekker.probeCount(probe_count)
	if seed_max_trials != 'default':
		mytrekker.seed_maxTrials(seed_max_trials)
	if max_sampling != 'default':
		mytrekker.maxSamplingPerStep(max_sampling)

	# resource-specific parameter
	mytrekker.numberOfThreads(8)

		# begin looping tracking
		for amps in min_fod_amp:
			if min_fod_amp != ['default']:
				print(amps)
				amps = float(amps)
				mytrekker.minFODamp(amps)
				
				if probe_length == 'default':
                    mytrekker.probeLength(amps)

			else:
				amps = 'default'

			for curvs in curvatures:
				if curvatures != ['default']:
					print(curvs)
					curvs = float(curvs)
					mytrekker.minRadiusOfCurvature(curvs)
				else:
					curvs = 'default'

				for step in step_size:
					if step_size != ['default']:
						print(step)
						step = float(step)
						mytrekker.stepSize(step)
					else:
						step = 'default'
					
					mytrekker.printParameters()
					output_name = 'track_lmax%s_FOD%s_curv%s_step%s.vtk' %(srt(FOD),str(amps),str(curvs),str(step))

					# run the tracking
					Streamlines = mytrekker.run()

		# print output
		tractogram = trekkerIO.Tractogram()
		tractogram.count = len(Streamlines)
		print(tractogram.count)
		tractogram.points = Streamlines
		trekkerIO.write(tractogram,output_name)

	del mytrekker

def tracking():
	# load and parse configurable inputs
	with open('config.json') as config_f:
		config = json.load(config_f)
		max_lmax = config["lmax"]
		count = config["count"]
		min_fod_amp = config["minfodamp"].split()
		curvatures = config["curvatures"].split()
		seed_max_trials = config["maxtrials"]
		max_sampling = config["maxsampling"]
		lmax2 = config["lmax2"]
		lmax4 = config["lmax4"]
		lmax6 = config["lmax6"]
		lmax8 = config["lmax8"]
		lmax10 = config["lmax10"]
		lmax12 = config["lmax12"]
		lmax14 = config["lmax14"]
		single_lmax = config["single_lmax"]
		step_size = config["stepsize"].split()
		min_length = config["min_length"]
		max_length = config["max_length"]
		probe_length = config["probelength"]
		probe_quality = config["probequality"]
		probe_count = config["probecount"]
		probe_radius = config["proberadius"]
		best_at_init = config["bestAtInit"]

	# begin tracking
	if single_lmax == True:

		# set FOD path
		FOD_path = eval('lmax%s' %str(max_lmax)).encode()
		
		trekker_tracking(FOD_path,count,min_fod_amp,curvatures,step_size,min_length,max_length,max_sampling,seed_max_trials,probe_length,probe_quality,probe_radius,probe_count,best_at_init)

	else:

		for csd in range(2,max_lmax,2):
			FOD_path = eval('lmax%s' %str(csd+2)).encode()
			
			trekker_tracking(FOD_path,count,min_fod_amp,curvatures,step_size,min_length,max_length,max_sampling,seed_max_trials,probe_length,probe_quality,probe_radius,probe_count,best_at_init)
		


if __name__ == '__main__':
	tracking()
