#!/bin/bash

set -e
set -x

# convert to tck
tckconvert output.vtk output.tck -force -nthreads $NCORE -quiet