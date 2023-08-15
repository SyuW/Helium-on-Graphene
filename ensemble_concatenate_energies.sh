#!/bin/bash

# Purpose of this script is to concatenate together all the energy files produced from the ensemble runs of the simulations
# into one main file in order to do averaging.

module load "StdEnv/2020"
module load "scipy-stack"

ENSEMBLE_DIR="/home/syu7/graphene_helium_paper/data/ensemble_beta_0.0625/ensemble"
COMBINED_AVG_FILE="$ENSEMBLE_DIR/combined_avgs.txt"
AVGING_SCRIPT="/home/syu7/scratch/postprocessing/block_average.py"

COMBINED_HEADER="#     KINETIC     KINETIC_ERROR       POTENTIAL       POTENTIAL_ERROR     TOTAL      TOTAL_ERROR"
echo "$COMBINED_HEADER" > "$COMBINED_AVG_FILE"

# number of time slices
POSSIBLE_SLICES=( 40 80 160 320 640 )
for SLICES in "${POSSIBLE_SLICES[@]}"; do

    # Ensemble of simulations directory
    DIR="$ENSEMBLE_DIR/ensemble_slices_$SLICES"

    # name of file that concatenated output is going to
    OUTPUT_FILE="$DIR/concatenated"

    # loop over all the sub-directories in the ensemble directory, corresponding to
    # different runs within the ensemble

    echo "#  block             kinetic                potential           total" > "$OUTPUT_FILE"

    find "$DIR" -type f -name "*.en" -exec tail -q -n +2 {} >> "$OUTPUT_FILE" \;

    # output to combined averages file
    python "$AVGING_SCRIPT" --filename "$OUTPUT_FILE" --block_size 20 --throwaway 0
done
