#!/bin/bash

# --------------------------------------------------------------------------------------------------------------------------------- #
#   PURPOSE: Auxiliary script for optimal tau search - calculates average energies and outputs to a data file                       #
# --------------------------------------------------------------------------------------------------------------------------------- #
#                                                                                                                                   #
# --------------------------------------------------------------------------------------------------------------------------------- #


USER="/home/syu7"
DATAPATH="$USER/graphene_helium_paper/data/optimal_time_step_beta_0.0625"
AVERAGING_SCRIPT="$USER/scratch/postprocessing/block_average.py"

SLICES=(40 80 160)

FILES_TO_BE_AVERAGED=$(find "$DATAPATH" -maxdepth 2 -type f -name 'slices_*.en')

for file in $FILES_TO_BE_AVERAGED; do
    echo "Processing: $file"

    name="$(basename "$(dirname "$file")")"
    used_slices=$(echo "$name" | cut -d "_" -f 2)

    AVG_RESULT=$(python "$AVERAGING_SCRIPT" --filename "$file" --block_size 20 --throwaway 5)
    echo "$used_slices  $AVG_RESULT"
done