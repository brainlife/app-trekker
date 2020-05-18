#!/bin/bash

set -e
set -x

NCORE=8

mkdir -p track
mkdir -p mask

anat=`jq -r '.t1' config.json`
LMAX=`jq -r '.lmax' config.json`
lmax2=`jq -r '.lmax2' config.json`
lmax4=`jq -r '.lmax4' config.json`
lmax6=`jq -r '.lmax6' config.json`
lmax8=`jq -r '.lmax8' config.json`
lmax10=`jq -r '.lmax10' config.json`
lmax12=`jq -r '.lmax12' config.json`
lmax14=`jq -r '.lmax14' config.json`
mask=`jq -r '.mask' config.json`
wm_mask=`jq -r '.wm_mask' config.json`
count=`jq -r '.count' config.json`
minFODamp=`jq -r '.minfodamp' config.json`
minradius=`jq -r '.minradius' config.json`
minLength=`jq -r '.min_length' config.json`
maxLength=`jq -r '.max_length' config.json`
probeLength=`jq -r '.probelength' config.json`
probeQuality=`jq -r '.probequality' config.json`
probeRadius=`jq -r '.proberadius' config.json`
probeCount=`jq -r '.probecount' config.json`
step_size=`jq -r '.step_size' config.json`
single_lmax=`jq -r '.single_lmax' config.json`

# convert anatomical t1 to mrtrix format
[ ! -f anat.mif ] && mrconvert ${anat} anat.mif -nthreads $NCORE

# generate sequence of lmax spherical harmonic order for single or ensemble
if [[ ${single_lmax} == true ]]; then
	lmaxs=$(seq ${LMAX} ${LMAX})
else
	lmaxs=$(seq 2 2 ${LMAX})
fi

# generate 5-tissue-type (5TT) tracking mask
if [[ ${mask} == 'null' ]]; then
	[ ! -f 5tt.mif ] && 5ttgen fsl anat.mif 5tt.mif -nocrop -sgm_amyg_hipp -tempdir ./tmp -force -nthreads $NCORE
else
	echo "input 5tt mask exists. converting to mrtrix format"
	mrconvert ${mask} -stride 1,2,3,4 5tt.mif -force -nthreads $NCORE
fi

# generate csf,gm,wm masks
[ ! -f gm.mif ] && mrconvert -coord 3 0 5tt.mif gm.mif -force -nthreads $NCORE
[ ! -f csf.mif ] && mrconvert -coord 3 3 5tt.mif csf.mif -force -nthreads $NCORE
[ ! -f csf_bin.nii.gz ] && mrconvert csf.mif -stride 1,2,3,4 csf.nii.gz -force -nthreads $NCORE && fslmaths csf.nii.gz -thr 0.5 -bin csf_bin.nii.gz

# convert white matter mask
if [[ ${wm_mask} == "null" ]]; then

	[ ! -f wm.mif ] && mrconvert -coord 3 2 5tt.mif wm.mif -force -nthreads $NCORE
	[ ! -f wm.nii.gz ] && mrconvert wm.mif -stride 1,2,3,4 wm.nii.gz -force -nthreads $NCORE
else
	cp ${wm_mask} wm.nii.gz
fi

# convert 5tt mask to output
[ ! -f ./5tt/mask.nii.gz ] && mrconvert 5tt.mif -stride 1,2,3,4 ./5tt/mask.nii.gz -force -nthreads $NCORE

# tracking
for LMAXS in ${lmaxs}; do
	input_csd=$(eval "echo \$lmax${LMAXS}")
	echo "running trekker tracking on lmax ${LMAXS}"
	for CURV in ${curvatures}; do
		echo "curvature ${CURV}"
		for STEP in ${step_size}; do
			echo "step size ${STEP}"
			for FOD in ${minFODamp}; do
				echo "FOD amplitude ${FOD}"
				if [ ! -f track_lmax${LMAXS}_curv${CURV}_step${STEP}_amp${FOD}.vtk ]; then
					/trekker/build/bin/trekker \
    					-fod ${input_csd} \
    					-seed_image ./wm.nii.gz \
    					-seed_count ${count} \
    					-pathway_A=require_entry ./gm.nii.gz \
    					-pathway_B=require_entry ./gm.nii.gz \
						-pathway_A=discard_if_enters ./csf_bin.nii.gz \
						-pathway_B=discard_if_enters ./csf_bin.nii.gz \
    					-minLength ${minLength} \
    					-maxLength ${maxLength} \
    					-numberOfThreads ${NCORE} \
    					-minFODamp ${FOD} \
    					-minRadiusOfCurvature ${CURV} \
    					-probeLength ${probeLength} \
						-probeQuality ${probeQuality} \
						-probeRadius ${probeRadius} \
						-probeCount ${probeCount} \
    					-stepSize ${STEP} \
    					-writeColors \
    					-verboseLevel 0 \
    					-enableOutputOverwrite \
    					-output track_lmax${LMAXS}_curv${CURV}_step${STEP}_amp${FOD}.vtk
						# convert output vtk to tck
						tckconvert track_lmax${LMAXS}_curv${CURV}_step${STEP}_amp${FOD}.vtk track_lmax${LMAXS}_curv${CURV}_step${STEP}_amp${FOD}.tck
				fi
			done
		done
	done
done

# merge outputs
holder=(track*.tck)
if [ ${#holder[@]} == 1]; then
	cp ${holder[0]} ./track/track.tck
else
	tckedit ${holder[*]} ./track/track.tck
fi

# use output.json as product.Json
tckinfo ./track/track.tck > product.json

# clean up
if [ -f ./track/track.tck ]; then
	rm -rf *.mif *.b* ./tmp *.nii.gz*
else
	echo "tracking failed"
	exit 1;
fi
