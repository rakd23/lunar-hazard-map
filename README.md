# Lunar Hazard Map

A terrain-hazard map of the lunar south pole built from NASA LRO LOLA laser-altimeter data. It feeds safe-route planning for the Aggie Space Initiative NASA RASC-AL 2027 Theme 1 proposal.

**Status:** Milestones 1 (data exploration) and 2 (training patches) done. Milestone 3 (U-Net vs slope rule) done. Milestone 4 (Shackleton analysis for Lantern) in progress.

## Setup (one time)

Run these in a normal terminal tab, not the one running JupyterLab:

```zsh
conda activate geoai
conda install -c conda-forge scikit-image aria2 -y
mkdir -p ~/lunar && cd ~/lunar
# put this repo here as ~/lunar/lunar-hazard-map
cd lunar-hazard-map
bash download_m1.sh        # ~0.8 GB into ~/lunar/data, resumable
```

Then, in the JupyterLab tab:

```zsh
conda activate geoai
cd ~/lunar/lunar-hazard-map
jupyter lab
```

Open `01_explore_lola.ipynb` and choose **Run > Run All Cells**. Section F reads a 12 × 12 km window of the 5 m maps from NASA over HTTP the first time, then caches it in `~/lunar/data/crops/`.

## Milestone 2: training patches

In a normal terminal tab: `bash download_m2.sh` (NASA 20 m elevation, shot counts and PSR map, about 4 GB, resumable). Then open `02_make_labels.ipynb` and choose **Run > Run All Cells**. It writes about 4,000 patches (estimated, ~0.6 GB) to `~/lunar/data/patches/` with an `index.csv`, and re-scores the plain 20 m slope rule over all of 87–90°S, split by terrain type.

Each patch is 2.56 km square: six 20 m input layers (128 × 128) and the 5 m safe / caution / no-go answer (512 × 512). Train, val and test are whole ~20 km blocks; the Milestone 1 Shackleton window is always in test.

**Milestone 2 result (measured, test split, NASA 20 m map, 25° rule):** no-go recall 0.98 on mostly steep patches, 0.75 on mixed, 0.38 on mostly drivable. The Milestone 1 window number (0.98) holds on the real 20 m map (0.979) but only describes steep ground.

## Milestone 3: train and test the U-Net

Open `03_train_hazard.ipynb` and choose **Run > Run All Cells**. Training takes roughly 30–60 minutes on an M2 (estimated). Keep the laptop plugged in; `caffeinate -d` in a separate terminal tab stops it sleeping. Checkpoints go to `~/lunar/data/models/`. If training stops, re-running the notebook resumes it.

The test is designed to be fair to the slope rule:

- **Same false-alarm level.** The U-Net is compared to the 20 m slope rule at every cutoff, using precision–recall curves and average precision. It is also compared at the 25° rule's own precision, so it can't win just by flagging more ground.
- **Map noise.** Scores are reported twice. "Raw" counts every 5 m no-go pixel. "Big patches" leaves out isolated no-go specks smaller than 4 pixels (placeholder), which may be gaps filled in between laser tracks.
- **Real data only.** Scores are also given for pixels with an actual LOLA shot.

Section A measures how much of the 5 m no-go is isolated specks before any training happens.

**Milestone 3 result (measured, held-out test areas):** the U-Net matches the tuned 20 m slope rule but does not beat it (no-go average precision on mostly drivable ground 0.525 vs 0.526). Per the plan's fallback, the proposal uses the rule-based map, and the 5 m map wherever it exists.

## Milestone 4: Shackleton (Lantern Profile 1)

Open `04_shackleton.ipynb` and choose **Run > Run All Cells** (a few minutes; no new downloads). Using the 5 m map around Shackleton, it:

- checks the crater's measured diameter and depth against published values
- finds the slope a rover must handle to drive from the rim to the floor, and how much floor a scout can reach at each slope limit
- plans the tether route from the rim tower to the floor, preferring permanent shadow, with a 45° limit (T-REX tests)
- places hubs by driving distance (farthest-point k-center) and measures the floor cable (minimum spanning tree)
- checks laser line of sight from the tower to each hub, including the Moon's curvature
- compares Lantern's placeholder numbers to the measured ones

The tower site is a placeholder (the highest rim point) until it is picked from NASA illumination maps.

## Outputs

- `figures/`: PNGs for each section (A–H)
- `results/m1_summary.json`: every measured number, plus the threshold settings and their source labels

## Hazard thresholds

| Setting | Value | Label |
| --- | --- | --- |
| Safe below | 15° | Sourced: NASA VIPER rover page, "capable of traversing an incline of as much as 15 degrees" |
| No-go at or above | 25° | Placeholder: confirm once the team picks a rover concept |

Both are settings at the top of the notebook.

## Data

- LOLA south pole products, PGDA: https://pgda.gsfc.nasa.gov/products/90. Cite Barker et al. 2023, *Planet. Sci. J.* 4, 183, doi:10.3847/PSJ/acf3e1.
- 5 m mosaic, 87–90°S: https://pgda.gsfc.nasa.gov/data/LOLA_5mpp/87S/. Cite Barker et al. 2021, *Planet. Space Sci.* 203, 105119, doi:10.1016/j.pss.2020.105119.
