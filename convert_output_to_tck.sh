#!/bin/bash

set -e
set -x

NCORE=8

# convert to tck
tckconvert output.vtk output.tck -force -nthreads $NCORE -quiet
