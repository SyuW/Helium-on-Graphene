#!/bin/bash

# Take in the following command-line arguments:
# 
# 1 : path to directory containing the data files
#

POSSIBLE_SLICES=( 40 80 160 320 640 1280 )

for SLICE in "${POSSIBLE_SLICES[@]}"; do
    # gnuplot -e "dirname='$DATAPATH/slices_"$SLICE"_run'" ${GNUPLOT_SCRIPT_PATH}
    gnuplot -e "dirname='$1'" ${GNUPLOT_SCRIPT_PATH}
done