#!/bin/bash
# Milestone 2 data download for lunar-hazard-map: NASA's 20 m south pole maps.
# Run in a normal terminal tab (NOT the JupyterLab tab):
#   conda activate geoai
#   bash download_m2.sh
# Safe to re-run: aria2c -c resumes partial files and skips finished ones.
# Total is about 4.0 GB. Sizes are from the PGDA products/90 page (sourced).
# Files are fetched one at a time (-j 1): downloading two big files at once
# gave "Invalid range header" errors from the NASA server in Milestone 1.
set -e

if ! command -v aria2c >/dev/null; then
  echo "aria2c not found. Run: conda activate geoai && conda install -c conda-forge aria2 -y"; exit 1
fi

DATA="$HOME/lunar/data"
mkdir -p "$DATA"
B20=https://pgda.gsfc.nasa.gov/data/LOLA_20mpp     # Barker et al. 2023 products (pgda products/90)

cat > "$DATA/m2_urls.txt" <<URLS
$B20/LPSR_80S_20MPP_ADJ.TIF
$B20/LDEC_80S_20MPP_ADJ.TIF
$B20/LDEM_80S_20MPP_ADJ.TIF
URLS
# Sizes: PSR map 148M, shot counts 1.3G, elevation 2.6G.

df -h "$DATA" | tail -1 | awk '{print "Free space before download: " $4 " (need about 4.1 GB)"}'

aria2c -c -x 4 -s 4 -j 1 --auto-file-renaming=false --console-log-level=warn \
       --summary-interval=120 -d "$DATA" -i "$DATA/m2_urls.txt"

echo
echo "Downloaded to $DATA:"
ls -lh "$DATA"/*20MPP*
