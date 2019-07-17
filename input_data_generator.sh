#!/bin/bash

set -e
set -x

NCORE=8

#parse config.json
dwi=$(jq -r .dwi config.json)
bvecs=`jq -r '.bvecs' config.json`
bvals=`jq -r '.bvals' config.json`
anat=`jq -r '.anat' config.json`
COUNT=`jq -r '.count' config.json`
LMAX=`jq -r '.lmax' config.json`
MINLENGTH=`jq -r '.min_length' config.json`
MAXLENGTH=`jq -r '.max_length' config.json`
NUMFIBERS=`jq -r '.num_fibers' config.json`

# convert dwi to mrtrix format
mrconvert -fslgrad $bvecs $bvals $dwi dwi.mif --export_grad_mrtrix dwi.b -force -nthreads $NCORE -quiet

# create mask of dwi
dwi2mask dwi.mif mask.mif -force -nthreads $NCORE -quiet

# convert anatomical t1 to mrtrix format
mrconvert ${anat} anat.mif -force -nthreads $NCORE -quiet

# extract b0 image from dwi
dwiextract dwi.mif - -bzero | mrmath - mean b0.mif -axis 3 -force -nthreads $NCORE -quiet

## check if b0 volume successfully created
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
    MS=0
    echo "Single-shell data: $NSHELL shell"
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
dwi2tensor -mask mask.mif dwi.mif dt.mif -bvalue_scaling false -force -nthreads $NCORE -quiet

# creating tensor metrics
tensor2metric -mask mask.mif -adc md.mif -fa fa.mif -ad ad.mif -rd rd.mif -cl cl.mif -cp cp.mif -cs cs.mif dt.mif -force -nthreads $NCORE -quiet

# generate 5-tissue-type (5TT) tracking mask
5ttgen fsl anat.mif 5tt.mif -nocrop -sgm_amyg_hipp -tempdir ./tmp -force -nthreads $NCORE -quiet

# generate gm-wm interface seed mask
5tt2gmwmi 5tt.mif gmwmi_seed.mif -force -nthreads $NCORE -quiet

generate csf,gm,wm masks
mrconvert -coord 3 2 5tt.mif wm.mif -force -nthreads $NCORE -quiet
mrconvert -coord 3 0 5tt.mif gm.mif -force -nthreads $NCORE -quiet
mrconvert -coord 3 3 5tt.mif csf.mif -force -nthreads $NCORE -quiet

# create visualization output
5tt2vis 5tt.mif 5ttvis.mif -force -nthreads $NCORE -quiet

#creating response (should take about 15min)
if [$MS -eq 0 ]; then
	echo "Estimating CSD response function"
	time dwi2response tournier dwi.mif wmt.txt -lmax ${LMAX} -force -nthreads $NCORE -tempdir ./tmp -quiet
else
	echo "Estimating MSMT CSD response function"
	time dwi2response msmt_5tt dwi.mif 5tt.mif wmt.txt gmt.txt csf.txt -mask mask.mif -lmax ${RMAX} -tempdir ./tmp -force -nthreads $NCORE -quiet
fi

# fitting CSD FOD of lmax
if [$MS -eq 0 ]; then
	echo "Fitting CSD FOD of Lmax ${LMAX}..."
	time dwi2fod -mask mask.mif csd dwi.mif wmt.txt wmt_lmax${LMAX}_fod.mif -lmax ${LMAX} -force -nthreads $NCORE -quiet
else
	echo "Estimating MSMT CSD FOD of Lmax ${LMAX}"
	time dwi2fod msmt_csd dwi.mif wmt.txt wmt_lmax${LMAX}_fod.mif  gmt.txt gmt_lmax${LMAX}_fod.mif csf.txt csf_lmax${LMAX}_fod.mif -force -nthreads $NCORE -quiet
fi

# convert to niftis
mrconvert wmt_lmax${LMAX}_fod.mif -stride 1,2,3,4 lmax${LMAX}.nii.gz -force -nthreads $NCORE -quiet

# copy response file
cp wmt.txt response.txt

## tensor outputs
mrconvert fa.mif -stride 1,2,3,4 fa.nii.gz -force -nthreads $NCORE -quiet
mrconvert md.mif -stride 1,2,3,4 md.nii.gz -force -nthreads $NCORE -quiet
mrconvert ad.mif -stride 1,2,3,4 ad.nii.gz -force -nthreads $NCORE -quiet
mrconvert rd.mif -stride 1,2,3,4 rd.nii.gz -force -nthreads $NCORE -quiet

## westin shapes (also tensor)
mrconvert cl.mif -stride 1,2,3,4 cl.nii.gz -force -nthreads $NCORE -quiet
mrconvert cp.mif -stride 1,2,3,4 cp.nii.gz -force -nthreads $NCORE -quiet
mrconvert cs.mif -stride 1,2,3,4 cs.nii.gz -force -nthreads $NCORE -quiet

## tensor itself
mrconvert dt.mif -stride 1,2,3,4 tensor.nii.gz -force -nthreads $NCORE -quiet

## 5 tissue type visualization
mrconvert 5ttvis.mif -stride 1,2,3,4 5ttvis.nii.gz -force -nthreads $NCORE -quiet
mrconvert 5tt.mif -stride 1,2,3,4 5tt.nii.gz -force -nthreads $NCORE -quiet
mrconvert gmwmi_seed.mif -stride 1,2,3,4 gmwmi_seed.nii.gz -force -nthreads $NCORE -quiet

# masks
mrconvert gm.mif -stride 1,2,3,4 gm.nii.gz -force -nthreads $NCORE -quiet
mrconvert csf.mif -stride 1,2,3,4 csf.nii.gz -force -nthreads $NCORE -quiet
mrconvert wm.mif -stride 1,2,3,4 wm.nii.gz -force -nthreads $NCORE -quiet
mrconvert mask.mif -stride 1,2,3,4 mask.nii.gz -force -nthreads $NCORE -quiet
