#!/bin/bash

set -e
set -x

threads=8

#parse config.json
dwi=$(jq -r .dwi config.json)
bvecs=`jq -r '.bvecs' config.json`
bvals=`jq -r '.bvals' config.json`

#creating response (should take about 15min)
mrconvert $dwi dwi.mif -force
#dwi2response tournier dwi.mif wm_response.txt -fslgrad $bvecs $bvals -nthreads $threads
dwi2response fa dwi.mif wm_response.txt -fslgrad $bvecs $bvals -nthreads $threads

#creating brain mask
bet2 $dwi brainmask

#creating fod
dwi2fod -fslgrad $bvecs $bvals -nthreads $threads -mask brainmask.nii.gz msmt_csd $dwi wm_response.txt fod.nii.gz

#running trekker
/trekker/build/bin/trekker \
    -fod fod.nii.gz \
    -seed_coordinates COORDINATES \
    -output output.vtk

#          # Example 1
#          ./trekker -fod FOD.nii.gz \
#                    -seed_image SEED.nii.gz \
#                    -seed_count 1000 \
#                    -output OUTPUT.vtk
#
#          # Example 2
#          ./trekker -fod FOD.nii.gz \
#                    -seed_coordinates COORDINATES \
#                    -output OUTPUT.vtk
#
#          # Example 3
#          ./trekker -fod FOD.nii.gz \
#                    -seed_image SEED.nii.gz \
#                    -timeLimit 15 \ # time limit is in minutes
#                    -output OUTPUT.vtk
#
