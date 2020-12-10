[![Abcdspec-compliant](https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg)](https://github.com/brain-life/abcd-spec)
[![Run on Brainlife.io](https://img.shields.io/badge/Brainlife-brainlife.app.214-blue.svg)](https://doi.org/10.25663/brainlife.app.214)

# Trekker 

This app will perform ensemble whole brain tracking using Trekker's parallel transport probabilistic tractography functionality. This app requires an anatomical (T1w) datatype and a CSD datatype as inputs. Optionally, the user can also input a five tissue type segmentation datatype and/or a white matter mask datatype. If these are empty, the app will compute the 5tt probability mask using MrTrix3.0's 5ttgen function and segment the gray matter, white matter, and CSF masks.

This app provides the user with a large number of exposed parameters to guide and shape tractography. These include a maximum spherical harmonic order (lmax), number of repetitions, minimum and maximum length of streamlines, step size, maximum number of attempts, streamline count, minimum FOD amplitude, and maximum angle of curvature. For lmax, the user can specify whether or not to track on a single lmax or 'ensemble' across lmax's. If the user wants to track in just a single lmax, set the 'single_lmax' field to true. Else, leave as false.  For minimum FOD amplitude, minimum radius of curvature, and step size, the user can input multiple values to perform 'ensemble tracking'. If this is desired, the user can input each value separated by a space in the respective fields (example: 0.25 0.5). The outputs of each iteration will be merged together in the final output.

There are also Trekker-specific parameters that can be set for tracking, including probe quality, probe length, probe count, and probe radius. These are set as advanced options. Please see Trekker's documentation for an explanation of these parameters and how they might affect the quality of tracking. 

### Authors 

- Brad Caron (bacaron@iu.edu)
- Dogu Baran (baran.aydogan@aalto.fi) 

### Contributors 

- Soichi Hayashi (hayashis@iu.edu) 

### Funding 

[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-1636893](https://img.shields.io/badge/NSF_BCS-1636893-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-ACI-1916518](https://img.shields.io/badge/NSF_ACI-1916518-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1916518)
[![NSF-IIS-1912270](https://img.shields.io/badge/NSF_IIS-1912270-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1912270)
[![NIH-NIBIB-R01EB029272](https://img.shields.io/badge/NIH_NIBIB-R01EB029272-green.svg)](https://grantome.com/grant/NIH/R01-EB029272-01)

### Citations 

Please cite the following articles when publishing papers that used data, code or other resources created by the brainlife.io community. 

1. Aydogan D.B., Shi Y., “A novel fiber tracking algorithm using parallel transport frames”, Proceedings of the 27th Annual Meeting of the International Society of Magnetic Resonance in Medicine (ISMRM) 2019 

## Running the App 

### On Brainlife.io 

You can submit this App online at [https://doi.org/10.25663/brainlife.app.214](https://doi.org/10.25663/brainlife.app.214) via the 'Execute' tab. 

### Running Locally (on your machine) 

1. git clone this repo 

2. Inside the cloned directory, create `config.json` with something like the following content with paths to your input files. 

```json 
{
   "anat":    "testdata/anat/t1.nii.gz",
   "lmax2":    "testdata/csd/lmax2.nii.gz/",
   "min_length":    10,
   "max_length":    200,
   "lmax":    2,
   "minfodamp":    "0.025",
   "stepsize":    "0.25",
   "count":    500,
   "minradius":    "45",
   "single_lmax":    true,
   "probelength":    0.25,
   "probequality":    4,
   "proberadius":    0,
   "probecount":    1
} 
``` 

### Sample Datasets 

You can download sample datasets from Brainlife using [Brainlife CLI](https://github.com/brain-life/cli). 

```
npm install -g brainlife 
bl login 
mkdir input 
bl dataset download 
``` 

3. Launch the App by executing 'main' 

```bash 
./main 
``` 

## Output 

The main output of this App is contains the whole-brain tractogram (tck) and the internally computed masks. If masks were inputted, the output is simply copies of the inputs. The tractogram output can be fed into white matter segmentation apps. 

#### Product.json 

The secondary output of this app is `product.json`. This file allows web interfaces, DB and API calls on the results of the processing. 

### Dependencies 

This App requires the following libraries when run locally. 

- MRtrix3: https://mrtrix.readthedocs.io/en/3.0_rc3/installation/linux_install.html
- Matlab: https://www.mathworks.com/help/install/install-products.html
- jsonlab: https://github.com/fangq/jsonlab
- singularity: https://singularity.lbl.gov/quickstart
- FSL: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation
- Trekker: https://github.com/dmritrekker/trekker
