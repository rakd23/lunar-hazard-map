#!/bin/bash
# Milestone 1 data download for lunar-hazard-map.
# Run in a normal terminal tab (NOT the JupyterLab tab):
#   conda activate geoai
#   bash download_m1.sh
# Safe to re-run: aria2c -c resumes partial files and skips finished ones.
# Total is about 0.8 GB. File sizes below are from the PGDA listing (sourced).
set -e

if ! command -v aria2c >/dev/null; then
  echo "aria2c not found. Run: conda activate geoai && conda install -c conda-forge aria2 -y"; exit 1
fi

DATA="$HOME/lunar/data"
mkdir -p "$DATA"

B20=https://pgda.gsfc.nasa.gov/data/LOLA_20mpp        # Barker et al. 2023 products (pgda products/90)
B5=https://pgda.gsfc.nasa.gov/data/LOLA_5mpp/87S      # 5 m mosaic, 87-90 S

cat > "$DATA/m1_urls.txt" <<EOF
$B20/LDEM_80S_80MPP_ADJ.TIF
$B20/LDSM_80S_80MPP_ADJ.TIF
$B20/LDEC_80S_80MPP_ADJ.TIF
$B20/LDEM_80S_80MPP_ADJ_HILL.TIF
$B20/LDRM_80S_1000MPP_ADJ_ROUGH_100M.TIF
$B20/LPSR_80S_20MPP_ADJ_1km2.SHP
$B20/LPSR_80S_20MPP_ADJ_1km2.SHX
$B20/LPSR_80S_20MPP_ADJ_1km2.DBF
$B20/LPSR_80S_20MPP_ADJ_1km2.PRJ
$B5/ldec_87s_5mpp.tif
EOF
# Sizes: LDEM 181M, LDSM 231M, LDEC 111M, HILL 85M, ROUGH 1.5M,
#        PSR >1 km2 shapefile ~20M, 5 m count map 140M.

# -x/-s 4: four connections per file (polite to the NASA server); -j 3: three files at a time.
aria2c -c -x 4 -s 4 -j 3 --auto-file-renaming=false --console-log-level=warn \
       -d "$DATA" -i "$DATA/m1_urls.txt"

echo
echo "Downloaded to $DATA:"
ls -lh "$DATA"
