#!/bin/bash

# Take in the following command-line arguments:
# 
# 1 : path to directory containing the data files
#

POSSIBLE_SLICES=( 40 80 160 320 640 1280 )
SCRATCH="/home/syu7/scratch"
DATAPATH="$SCRATCH/graphene_helium/optimal_time_step_beta_0.0625"
GNUPLOT_SCRIPT_PATH="$SCRATCH/postprocessing/plot_files.p"

for SLICE in ${POSSIBLE_SLICES[@]}; do
    # gnuplot -e "dirname='$DATAPATH/slices_"$SLICE"_run'" ${GNUPLOT_SCRIPT_PATH}
    gnuplot -e "dirname='$1'" ${GNUPLOT_SCRIPT_PATH}
done