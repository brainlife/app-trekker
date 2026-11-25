<h1 align="center">Trekker</h1>

<p align="center">
  Anatomically constrained, whole-brain ensemble tractography with Trekker's parallel transport tractography (PTT), from CSD fibre orientation distributions to a single .tck tractogram.
</p>

<p align="center">
  <a href="https://github.com/brainlife/abcd-spec"><img src="https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg" alt="ABCD Spec v1.1"></a>
  <a href="https://doi.org/10.25663/brainlife.app.214"><img src="https://img.shields.io/badge/Brainlife-brainlife.app.214-blue.svg" alt="Run on brainlife.io"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="MIT license"></a>
</p>

> ⚠️ **This branch, `v1.0`, is the deprecated brainlife.io App Trekker - v1.0** ([doi:10.25663/brainlife.app.214](https://doi.org/10.25663/brainlife.app.214)). It is kept so earlier results stay reproducible. Use **Trekker** ([doi:10.25663/brainlife.app.356](https://doi.org/10.25663/brainlife.app.356)) instead. The other Apps in this repository are listed under **Versions on brainlife.io** below.

This App wraps [Trekker](https://github.com/dmritrekker/trekker), developed by Dogu Baran Aydogan, so that it can be run on brainlife.io. All credit for the tracking algorithm belongs to its author.

## 🧠 At a glance

<!-- brainlife-app:begin (generated from the App manifest; edit the manifest, not this block) -->

> **Brainlife App (wrapper) for dMRI based fiber tracking using parallel transport tractography https://dmritrekker.github.io**

| | |
|---|---|
| 📥 **Inputs** | `neuro/anat/t1w` · `neuro/csd` · `neuro/mask` (optional) ×2 |
| 📤 **Outputs** | `neuro/track/tck` · `neuro/mask` |
| 🐳 **Container** | `brainlife/trekker:0.4` |
| ⚙️ **Resources** | 8 CPUs · 29 GB memory · 14 h walltime |
| 🔗 **Run it** | [doi.org/10.25663/brainlife.app.214](https://doi.org/10.25663/brainlife.app.214) |

#### 📥 Inputs

| Input | Datatype | Required | Description |
|---|---|---|---|
| `anat` | `neuro/anat/t1w` | yes |  |
| `csd` | `neuro/csd` | yes |  |
| `mask` | `neuro/mask` (5tt_masks) | no | 5 tissue type mask |
| `wm_mask` | `neuro/mask` (white_matter) | no |  |

#### 📤 Outputs

| Output | Datatype | Description |
|---|---|---|
| `track` | `neuro/track/tck` |  |
| `mask` | `neuro/mask` |  |

<details>
<summary><b>⚙️ Parameters</b> (12)</summary>

| Parameter | Type | Default | Description |
|---|---|---|---|
| `min_length` | number | `10` | min length of streamlines |
| `max_length` | number | `200` | max length of streamlines |
| `lmax` | number | `8` | lmax |
| `count` | number | `50000` | total number of streamlines |
| `minfodamp` | string | `0.05` | This is the minimum FOD amplitude. If multiple values are requested, please input as space separated list (example: 0.25 0.5). |
| `minradius` | string | `0.5` | Minimum radius of curvature. If multiple values are requested, please input as space separated list (example: 0.25 0.5). |
| `step_size` | string | `0.2` | Step size. If multiple values are requested, please input as space separated list (example: 0.25 0.5). |
| `probelength` | number | `0.25` | Trekker: Length of the probe. |
| `probequality` | number | `4` | Trekker: This parameter sets the number of segments to split the cylinder along the length of the probe |
| `proberadius` | number | `0` | Trekker: Radius of the probe. |
| `probecount` | number | `1` | Trekker: determines the number of parallel lines used to model the cylinder. |
| `single_lmax` | boolean | `false` | if only wanting to run on one lmax, set true. else, leave false |

</details>

<!-- brainlife-app:end -->

## 🏷️ Versions on brainlife.io

Each version is a separate App on brainlife.io, built from its own branch of this repository.

| Version | Trekker | Branch | Run it | Status |
|---|---|---|---|---|
| Trekker | 0.6 | [`v.1.2`](https://github.com/brainlife/app-trekker/tree/v.1.2) | [doi:10.25663/brainlife.app.356](https://doi.org/10.25663/brainlife.app.356) | current |
| **Trekker - v1.0** (this branch) | 0.4 | [`v1.0`](https://github.com/brainlife/app-trekker/tree/v1.0) | [doi:10.25663/brainlife.app.214](https://doi.org/10.25663/brainlife.app.214) | deprecated |

## 🔬 How it works

The App builds grey matter, white matter and CSF masks from the five-tissue-type (5TT) input with MRtrix3, then runs Trekker seeded in white matter, keeping only streamlines whose two ends reach grey matter and discarding those that enter CSF. A brain mask is computed with `dwi2mask`.

Many parameters are exposed to shape tractography: the maximum spherical harmonic order (`lmax`), streamline `count`, minimum and maximum streamline length, step size, minimum FOD amplitude and minimum radius of curvature. Tracking can be run on a single `lmax` (set `single_lmax` to true) or as an ensemble across several. For the minimum FOD amplitude, curvature and step size, several space-separated values (for example `0.25 0.5`) run one tracking pass per value; every pass is merged into the final tractogram.

Trekker-specific options (probe length, quality, count and radius, maximum sampling per step, maximum trials per seed, best direction at initialisation) are advanced options; leave them at `default` to use Trekker's own defaults. See the [Trekker documentation](https://dmritrekker.github.io) for how they affect tracking.

## 🚀 Running the App

### ☁️ On brainlife.io

Open the App at [doi.org/10.25663/brainlife.app.356](https://doi.org/10.25663/brainlife.app.356), choose a `neuro/dwi` dataset, its `neuro/csd` fibre orientation distributions and a `neuro/mask` with the `5tt_masks` tag, set the parameters and press **Execute**. The tractogram is archived to your project as a `neuro/track/tck` dataset that can be fed to white matter segmentation Apps.

### 💻 Locally

You need [Singularity/Apptainer](https://apptainer.org/) and [`jq`](https://jqlang.github.io/jq/). `main` runs the preprocessing and conversion steps in `brainlife/mrtrix3:3.0.0` and the tracking in `brainlife/trekker:0.6`.

1. Clone this repository and check out the current version: `git checkout v.1.2`.
2. Download a DWI and its CSD and 5TT datasets from brainlife.io with the [brainlife CLI](https://github.com/brainlife/cli):

   ```bash
   npm install -g brainlife
   bl login
   bl dataset download <dataset-id>
   ```

3. Create `config.json` with the paths to your inputs and the parameters you want (`lmax2` … `lmax14` are the CSD files; only those up to `lmax` are needed):

   ```json
   {
       "dwi": "testdata/dwi/dwi.nii.gz",
       "bvecs": "testdata/dwi/dwi.bvecs",
       "bvals": "testdata/dwi/dwi.bvals",
       "mask": "testdata/5tt/mask.nii.gz",
       "lmax2": "testdata/csd/lmax2.nii.gz",
       "lmax4": "testdata/csd/lmax4.nii.gz",
       "lmax6": "testdata/csd/lmax6.nii.gz",
       "lmax8": "testdata/csd/lmax8.nii.gz",
       "lmax": 8,
       "single_lmax": true,
       "count": 50000,
       "min_length": 10,
       "max_length": 200,
       "minfodamp": "default",
       "curvatures": "default",
       "stepsize": "default",
       "probelength": "default",
       "probequality": "default",
       "probecount": "default",
       "proberadius": "default",
       "maxsampling": "default",
       "maxtrials": "default",
       "bestAtInit": false
   }
   ```

4. Run the App:

   ```bash
   ./main
   ```

## 📦 Outputs

```text
track/
├── track.tck        whole-brain tractogram merging every tracking pass
└── track_info.txt   tckinfo summary of the tractogram
brainmask/
└── mask.nii.gz      brain mask used for tracking
```

## 🩺 Troubleshooting

- **`tracking failed`**: no `track/track.tck` was produced. Check the log; a common cause is that the CSD input does not contain the requested `lmax`.
- **Ensemble across lmax**: with `single_lmax` false, the code tracks on each even lmax from 2 up to, but not including, `lmax` (`range(2, lmax, 2)` in `tracking.py`), so every one of those CSD files must be present.

## 📚 Citing

> [!TIP]
> If you use this App in your work, please cite the App, the software it builds on and brainlife.io (below). GitHub's **Cite this repository** button gives the App citation in APA and BibTeX.

- Aydogan DB, Shi Y. A novel fiber tracking algorithm using parallel transport frames. *Proceedings of the 27th Annual Meeting of the International Society for Magnetic Resonance in Medicine (ISMRM)*, Montréal (2019).
- Trekker - v1.0. brainlife.io App. [doi:10.25663/brainlife.app.214](https://doi.org/10.25663/brainlife.app.214)
- Tournier et al. MRtrix3: A fast, flexible and open software framework for medical image processing and visualisation. *NeuroImage* 202:116137 (2019). [doi:10.1016/j.neuroimage.2019.116137](https://doi.org/10.1016/j.neuroimage.2019.116137)
- Aydogan and Shi. Parallel Transport Tractography. *IEEE Transactions on Medical Imaging* 40:635-647 (2021). [doi:10.1109/TMI.2020.3034038](https://doi.org/10.1109/TMI.2020.3034038)
- Hayashi S, Caron BA, Heinsfeld AS, et al. brainlife.io: a decentralized and open-source cloud platform to support neuroscience research. *Nature Methods* 21:809–813 (2024). [doi:10.1038/s41592-024-02237-2](https://doi.org/10.1038/s41592-024-02237-2)
- Avesani P, McPherson B, Hayashi S, et al. The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. *Scientific Data* 6:69 (2019). [doi:10.1038/s41597-019-0073-y](https://doi.org/10.1038/s41597-019-0073-y)

## 👥 Authors

- Brad Caron
- Dogu Baran Aydogan (author of Trekker)
- Franco Pestilli (project director)

**Contributors:** Soichi Hayashi

## 💰 Funding

[![Wellcome-226486/Z/22/Z](https://img.shields.io/badge/Wellcome-226486%2FZ%2F22%2FZ-purple.svg)](https://wellcome.org/)
[![NIH-NINDS-U24NS140384](https://img.shields.io/badge/NIH_NINDS-U24NS140384-green.svg)](https://reporter.nih.gov/project-details/11261037)
[![NIH-NINDS-UM1NS132207](https://img.shields.io/badge/NIH_NINDS-UM1NS132207-green.svg)](https://reporter.nih.gov/project-details/11411328)
[![NIH-NIBIB-R01EB029272](https://img.shields.io/badge/NIH_NIBIB-R01EB029272-green.svg)](https://reporter.nih.gov/project-details/10262925)
[![NIH-NIBIB-R01EB030896](https://img.shields.io/badge/NIH_NIBIB-R01EB030896-green.svg)](https://reporter.nih.gov/project-details/10428625)
[![NIH-NIMH-R01MH126699](https://img.shields.io/badge/NIH_NIMH-R01MH126699-green.svg)](https://reporter.nih.gov/project-details/10460628)
[![NIH-NIDCD-R01DC020088](https://img.shields.io/badge/NIH_NIDCD-R01DC020088-green.svg)](https://reporter.nih.gov/project-details/11140284)
[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-2203524](https://img.shields.io/badge/NSF_BCS-2203524-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2203524)
[![NSF-IIS-1636893](https://img.shields.io/badge/NSF_IIS-1636893-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-OAC-2148729](https://img.shields.io/badge/NSF_OAC-2148729-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2148729)
[![NSF-IIS-1912270](https://img.shields.io/badge/NSF_IIS-1912270-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1912270)
[![NSF-IIS-2148700](https://img.shields.io/badge/NSF_IIS-2148700-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2148700)
[![NSF-OAC-1916518](https://img.shields.io/badge/NSF_OAC-1916518-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1916518)

<sub>brainlife.io is publicly funded, and acknowledging that support helps keep it running. This App was developed with support from Wellcome, the U.S. National Institutes of Health (including the BRAIN Initiative BRAIN CONNECTS program: The Axonal Projectome EXchange, U24NS140384, and the Center for Mesoscale Connectomics, UM1NS132207) and the U.S. National Science Foundation.</sub>

## ⚖️ License

[MIT](LICENSE). Trekker is distributed under its own licence; see the [Trekker repository](https://github.com/dmritrekker/trekker).
