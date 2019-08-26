#!/bin/bash

set -e
set -x

NCORE=8

mkdir -p track
mkdir -p csd
mkdir -p mask
mkdir -p mask
mkdir -p brainmask

dwi=$(jq -r .dwi config.json)
bvecs=`jq -r '.bvecs' config.json`
bvals=`jq -r '.bvals' config.json`
anat=`jq -r '.t1' config.json`
LMAX=`jq -r '.lmax' config.json`
input_csd=`jq -r "$(eval echo '.lmax$LMAX')" config.json`
mask=`jq -r '.mask' config.json`
brainmask=`jq -r '.brainmask' config.json`
#NUMFIBERS=`jq -r '.count' config.json`

MINFODAMP=$(jq -r .minfodamp config.json)
minradiusofcurvature=$(jq -r .minradiusofcurvature config.json)

# convert dwi to mrtrix format
[ ! -f dwi.b ] && mrconvert -fslgrad $bvecs $bvals $dwi dwi.mif --export_grad_mrtrix dwi.b -nthreads $NCORE

# create mask of dwi
if [[ ${brainmask} == 'null' ]]; then
	[ ! -f mask.mif ] && dwi2mask dwi.mif mask.mif -nthreads $NCORE
else
	echo "input brainmask exists. converting to mrtrix format"
	mrconvert ${brainmask} -stride 1,2,3,4 mask.mif -force -nthreads $NCORE
fi

# convert anatomical t1 to mrtrix format
[ ! -f anat.mif ] && mrconvert ${anat} anat.mif -nthreads $NCORE

# extract b0 image from dwi
[ ! -f b0.mif ] && dwiextract dwi.mif - -bzero | mrmath - mean b0.mif -axis 3 -nthreads $NCORE

# check if b0 volume successfully created
if [ ! -f b0.mif ]; then
    echo "No b-zero volumes present."
    NSHELL=`mrinfo -shell_bvalues dwi.mif | wc -w`
    NB0s=0
    EB0=''
else
    ISHELL=`mrinfo -shell_bvalues dwi.mif | wc -w`
    NSHELL=$(($ISHELL-1))
    NB0s=`mrinfo -shell_sizes dwi.mif | awk '{print $1}'`
    EB0="0,"
fi

## determine single shell or multishell fit
if [ $NSHELL -gt 1 ]; then
    MS=1
    echo "Multi-shell data: $NSHELL total shells"
else
    echo "Single-shell data: $NSHELL shell"
    MS=0
    if [ ! -z "$TENSOR_FIT" ]; then
	echo "Ignoring requested tensor shell. All data will be fit and tracked on the same b-value."
    fi
fi

## create the correct length of lmax
if [ $NB0s -eq 0 ]; then
    RMAX=${LMAX}
else
    RMAX=0
fi
iter=1

## for every shell (after starting w/ b0), add the max lmax to estimate
while [ $iter -lt $(($NSHELL+1)) ]; do
    
    ## add the $MAXLMAX to the argument
    RMAX=$RMAX,$LMAX

    ## update the iterator
    iter=$(($iter+1))

done

# extract mask
[ ! -f dt.mif ] && dwi2tensor -mask mask.mif dwi.mif dt.mif -bvalue_scaling false -force -nthreads $NCORE

# creating tensor metrics
#[ ! -f fa.mif ] && tensor2metric -mask mask.mif -adc md.mif -fa fa.mif -ad ad.mif -rd rd.mif -cl cl.mif -cp cp.mif -cs cs.mif dt.mif -force -nthreads $NCORE

# generate 5-tissue-type (5TT) tracking mask
if [[ ${mask} == 'null' ]]; then
	[ ! -f 5tt.mif ] && 5ttgen fsl anat.mif 5tt.mif -nocrop -sgm_amyg_hipp -tempdir ./tmp -force -nthreads $NCORE
else
	echo "input 5tt mask exists. converting to mrtrix format"
	mrconvert ${mask} -stride 1,2,3,4 5tt.mif -force -nthreads $NCORE
fi

# generate gm-wm interface seed mask
[ ! -f gmwmi_seed.mif ] && 5tt2gmwmi 5tt.mif gmwmi_seed.mif -force -nthreads $NCORE

# generate csf,gm,wm masks
[ ! -f wm.mif ] && mrconvert -coord 3 2 5tt.mif wm.mif -force -nthreads $NCORE
[ ! -f gm.mif ] && mrconvert -coord 3 0 5tt.mif gm.mif -force -nthreads $NCORE
[ ! -f csf.mif ] && mrconvert -coord 3 3 5tt.mif csf.mif -force -nthreads $NCORE

# create visualization output
[ ! -f 5ttvis.mif ] && 5tt2vis 5tt.mif 5ttvis.mif -force -nthreads $NCORE

#creating response (should take about 15min)
if [[ ${input_csd} == 'null' ]]; then
	if [ $MS -eq 0 ]; then
		echo "Estimating CSD response function"
		time dwi2response tournier dwi.mif wmt.txt -lmax ${LMAX} -force -nthreads $NCORE -tempdir ./tmp
	else
		echo "Estimating MSMT CSD response function"
		time dwi2response msmt_5tt dwi.mif 5tt.mif wmt.txt gmt.txt csf.txt -mask mask.mif -lmax ${RMAX} -tempdir ./tmp -force -nthreads $NCORE
	fi

	# fitting CSD FOD of lmax
	if [ $MS -eq 0 ]; then
		echo "Fitting CSD FOD of Lmax ${LMAX}..."
		time dwi2fod -mask mask.mif csd dwi.mif wmt.txt wmt_lmax${LMAX}_fod.mif -lmax ${LMAX} -force -nthreads $NCORE
	else
		echo "Estimating MSMT CSD FOD of Lmax ${LMAX}"
		time dwi2fod msmt_csd dwi.mif wmt.txt wmt_lmax${LMAX}_fod.mif  gmt.txt gmt_lmax${LMAX}_fod.mif csf.txt csf_lmax${LMAX}_fod.mif -force -nthreads $NCORE
	fi
	# convert to niftis
	mrconvert wmt_lmax${LMAX}_fod.mif -stride 1,2,3,4 ./csd/lmax${LMAX}.nii.gz -force -nthreads $NCORE

	# copy response file
	cp wmt.txt response.txt
else
	echo "csd already inputted. skipping csd generation"
	cp -v ${input_csd} ./csd/lmax${LMAX}.nii.gz
fi

## tensor outputs
#mrconvert fa.mif -stride 1,2,3,4 ./tensor/fa.nii.gz -force -nthreads $NCORE
#mrconvert md.mif -stride 1,2,3,4 ./tensor/md.nii.gz -force -nthreads $NCORE
#mrconvert ad.mif -stride 1,2,3,4 ./tensor/ad.nii.gz -force -nthreads $NCORE
#mrconvert rd.mif -stride 1,2,3,4 ./tensor/rd.nii.gz -force -nthreads $NCORE

## westin shapes (also tensor)
#mrconvert cl.mif -stride 1,2,3,4 ./tensor/cl.nii.gz -force -nthreads $NCORE
#mrconvert cp.mif -stride 1,2,3,4 ./tensor/cp.nii.gz -force -nthreads $NCORE
#mrconvert cs.mif -stride 1,2,3,4 ./tensor/cs.nii.gz -force -nthreads $NCORE

## tensor itself
#mrconvert dt.mif -stride 1,2,3,4 ./tensor/tensor.nii.gz -force -nthreads $NCORE

## 5 tissue type visualization
[ ! -f ./mask/mask.nii.gz ] && mrconvert 5tt.mif -stride 1,2,3,4 ./mask/mask.nii.gz -force -nthreads $NCORE

# masks
[ ! -f gm.nii.gz ] && mrconvert gm.mif -stride 1,2,3,4 gm.nii.gz -force -nthreads $NCORE
[ ! -f wm.nii.gz ] && mrconvert wm.mif -stride 1,2,3,4 wm.nii.gz -force -nthreads $NCORE
[ ! -f csf.nii.gz ] && mrconvert csf.mif -stride 1,2,3,4 csf.nii.gz -force -nthreads $NCORE
[ ! -f ./brainmask/mask.nii.gz ] && mrconvert mask.mif -stride 1,2,3,4 ./brainmask/mask.nii.gz -force -nthreads $NCORE

# tracking
echo "running tracking with Trekker"
/trekker/build/bin/trekker \
    -fod ./csd/lmax${LMAX}.nii.gz \
    -seed_image ./wm.nii.gz \
    -seed_count $(jq -r .count config.json) \
    -pathway_A=require_entry ./gm.nii.gz \
    -pathway_B=require_entry ./gm.nii.gz \
    -minLength $(jq -r .min_length config.json) \
    -maxLength $(jq -r .max_length config.json) \
    -numberOfThreads ${NCORE} \
    -minFODamp $(jq -r .minfodamp config.json) \
    -minRadiusOfCurvature $(jq -r .minradius config.json) \
    -probeLength $(jq -r .probelength config.json) \
    -stepSize $(jq -r .stepsize config.json) \
    -writeColors \
    -verboseLevel 0 \
    -enableOutputOverwrite \
    -output output.vtk


# convert output vtk to tck
tckconvert output.vtk track/track.tck -force -nthreads $NCORE

# use output.json as product.Json
echo "{\"track\": $(cat track.json)}" > product.json

# clean up
if [ -f ./track/track.tck ]; then
	rm -rf *.mif *.b* ./tmp *.nii.gz*
else
	echo "tracking failed"
	exit 1;
fi
