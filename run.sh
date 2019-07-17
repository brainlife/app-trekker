#!/bin/bash

set -e
set -x

LMAX=`jq -r '.lmax' config.json`
COUNT=`jq -r '.count' config.json`
MINLENGTH=`jq -r '.min_length' config.json`
MAXLENGTH=`jq -r '.max_length' config.json`

#running trekker
trekker/build/bin/trekker \
    -fod lmax${LMAX}.nii.gz \
    -seed_image gmwmi_seed.nii.gz \
    -seed_count ${COUNT} \
    -pathway=discard_if_ends_inside wm.nii.gz \
    -pathway=discard_if_enters csf.nii.gz \
    -minLength ${MINLENGTH} \
    -maxLength ${MAXLENGTH} \
    -output output.vtk
