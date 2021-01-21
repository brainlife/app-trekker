#!/bin/bash

set -e
set -x

NCORE=8

mkdir -p track

LMAX=`jq -r '.lmax' config.json`
lmax2=`jq -r '.lmax2' config.json`
lmax4=`jq -r '.lmax4' config.json`
lmax6=`jq -r '.lmax6' config.json`
lmax8=`jq -r '.lmax8' config.json`
lmax10=`jq -r '.lmax10' config.json`
lmax12=`jq -r '.lmax12' config.json`
lmax14=`jq -r '.lmax14' config.json`
count=`jq -r '.count' config.json`
minFODamp=`jq -r '.minfodamp' config.json`
curvatures=`jq -r '.curvatures' config.json`
minLength=`jq -r '.min_length' config.json`
maxLength=`jq -r '.max_length' config.json`
probeLength=`jq -r '.probelength' config.json`
probeQuality=`jq -r '.probequality' config.json`
probeRadius=`jq -r '.proberadius' config.json`
probeCount=`jq -r '.probecount' config.json`
step_size=`jq -r '.stepsize' config.json`
single_lmax=`jq -r '.single_lmax' config.json`

# generate sequence of lmax spherical harmonic order for single or ensemble
if [[ ${single_lmax} == true ]]; then
	lmaxs=$(seq ${LMAX} ${LMAX})
else
	lmaxs=$(seq 2 2 ${LMAX})
fi

# tracking
if [ ${probeLength} == 'default' ]; then
	probelength_line=""
else
	probelength_line="-probeLength ${probeLength}"
fi

if [ ${probeQuality} == 'default' ]; then
	probequality_line=""
else
	probequality_line="-probeQuality ${probeQuality}"
fi

if [ ${probeRadius} == 'default' ]; then
	proberadius_line=""
else
	proberadius_line="-probeRadius ${probeRadius}"
fi

if [ ${probeCount} == 'default' ]; then
	probecount_line=""
else
	probecount_line="-probeCount ${probeCount}"
fi

for LMAXS in ${lmaxs}; do
	input_csd=$(eval "echo \$lmax${LMAXS}")
	echo "running trekker tracking on lmax ${LMAXS}"

	for CURV in ${curvatures}; do
		echo "curvature ${CURV}"
		if [ ${CURV} == 'default' ]; then
			curv_line=""
		else
			curv_line="-minRadiusOfCurvature ${CURV}"
		fi

		for STEP in ${step_size}; do
			echo "step size ${STEP}"
			if [ ${STEP} == 'default' ]; then
				step_line=""
			else
				step_line="-stepSize ${STEP}"
			fi

			for FOD in ${minFODamp}; do
				echo "FOD amplitude ${FOD}"
				if [ ${FOD} == 'default' ]; then
					amp_line=""
				else
					amp_line="-minFODamp ${FOD}"
				fi

				if [ ! -f track_lmax${LMAXS}_curv${CURV}_step${STEP}_amp${FOD}.vtk ]; then
					/trekker/build/Linux/install/bin/trekker \
						-fod ${input_csd} \
						-seed_image ./wm_bin.nii.gz \
						-seed_count ${count} \
						-pathway_A=require_entry ./cortex_bin.nii.gz \
						-pathway_B=require_entry ./cortex_bin.nii.gz \
						-pathway_A=discard_if_enters ./csf_bin.nii.gz \
						-pathway_B=discard_if_enters ./csf_bin.nii.gz \
						-minLength ${minLength} \
						-maxLength ${maxLength} \
						-numberOfThreads ${NCORE} \
						${amp_line} \
						${curv_line} \
						${probelength_line} \
						${probequality_line} \
						${proberadius_line} \
						${probecount_line} \
						${step_line} \
						-writeColors \
						-verboseLevel 0 \
						-enableOutputOverwrite \
						-output track_lmax${LMAXS}_curv${CURV}_step${STEP}_amp${FOD}.vtk

					# convert output vtk to tck
					# tckconvert track_lmax${LMAXS}_curv${CURV}_step${STEP}_amp${FOD}.vtk track_lmax${LMAXS}_curv${CURV}_step${STEP}_amp${FOD}.tck
				fi
			done
		done
	done
done

# # merge outputs
# holder=(track*.tck)
# if [ ${#holder[@]} == 1 ]; then
# 	cp ${holder[0]} ./track/track.tck
# else
# 	tckedit ${holder[*]} ./track/track.tck
# fi

# # use output.json as product.Json
# tckinfo ./track/track.tck > product.json

# # clean up
# if [ -f ./track/track.tck ]; then
# 	rm -rf *.mif *.b* ./tmp *.nii.gz*
# else
# 	echo "tracking failed"
# 	exit 1;
# fi
