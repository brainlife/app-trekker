# app-trekker

Trekker implements a state-of-the-art tractography algorithm, parallel transport tractography (PTT). This repo wraps Baran Ayodogan's Trekker github repo so that it can be executed on brainlife.io. All credits for this App belongs to Baran Ayodogan <baran.aydogan@aalto.fi>

# How does it work?

TODO - explain how this App works and how it's different from other tractograph algorithm. 

# Run this App

You can run this App on brainlife.io, or if you'd like to run it locally, you ca do the following.

1) git clone this repo on your machine

2) Stage input file (dwi)

```
bl dataset download <dataset id for any neuro/dwi data and neuro/anat/t1w data from barinlife>
```

3) Create config.json (you can copy from config.json.sample)

```
{
    "dwi": "testdata/dwi.nii.gz",
    "bvecs": "testdata/dwi.bvecs",
    "bvals": "testdata/dwi.bvals",
    "anat": "testdata/t1.nii.gz",
    "count":    50000,
    "lmax":  8,
    "min_length":   10,
    "max_length":   200
}
```

4) run `./main`

# Citation

[Aydogan2019a]	Aydogan DB, Shi Y., “Parallel transport tractography”, in preparation
[Aydogan2019b]	Aydogan DB, Shi Y., “A novel fiber tracking algorithm using parallel transport frames”, ISMRM 2019, Montreal


