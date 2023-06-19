#!/bin/bash

# Purpose of this script is to concatenate together all the energy files produced from the ensemble runs of the simulations
# into one main file in order to do averaging. 

# number of time slices
POSSIBLE_SLICES=( 40 80 160 320 640 )

for SLICES in ${POSSIBLE_SLICES[@]}; do
    # Ensemble of simulations directory
    ENSEMBLE_DIR="/home/syu7/scratch/graphene_helium/ensemble/ensemble_slices_"$SLICES""

    # name of file that concatenated output is going to
    OUTPUT_FILE="$ENSEMBLE_DIR/concatenated"

    # loop over all the sub-directories in the ensemble directory, corresponding to
    # different runs within the ensemble

    echo "#  block             kinetic                potential           total" > $OUTPUT_FILE

    find $ENSEMBLE_DIR -type f -name "*.en" -exec tail -q -n +2 {} >> $OUTPUT_FILE \;
done
