#!/bin/bash

# purpose of this script is to visualize energies produced from the ensemble runs together on one plot and also separately
# one reason for this is to check if the original simulation had equilibrated sufficiently prior to starting the ensemble runs
# also, checking that there is continuity between the ensemble run and original run i.e. no big jumps where the original ends, new starts
# to verify that the restart was done correctly

visualize_ensemble_dir() {
    # number of time slices used
    SLICES="$1"

    echo ""
    echo "Number of time slices chosen is "$SLICES", looking inside the relevant directory."

    # base directory containing ensemble simulations
    ENSEMBLE_DIR="/home/syu7/scratch/graphene_helium/ensemble/ensemble_slices_"$SLICES""

    # the nature of the ensemble simulations is that they continue where some source simulation left off:
    # want to read the energies file of the source simulation in order to perform postprocessing tasks such as visualization
    # BASE_FILE="/home/syu7/scratch/graphene_helium/optimal_time_step_beta_0.0625/slices_"$SLICES"/slices_"$SLICES".he.en"

    BASE_FILE="/home/syu7/scratch/graphene_helium/optimal_time_step_beta_0.0625/slices_"$SLICES"/backups/backup1_slices_"$SLICES".he.en"

    # output directory for storing visualizations
    OUTPUT_DIR="$ENSEMBLE_DIR/post"
    mkdir -p "$OUTPUT_DIR/images"

    # name of generated gnuplot script
    GNUPLOT_SCRIPT="$OUTPUT_DIR/plot.p"
    echo "set terminal pngcairo" > "$GNUPLOT_SCRIPT"
    echo "set xlabel 'Block'" >> "$GNUPLOT_SCRIPT"
    echo "set ylabel 'Total energy per particle'" >> "$GNUPLOT_SCRIPT"

    FILE_HEADER="#  block             kinetic                potential           total"

    # loop over paths found by find
    for RUN_FILE in $(find $ENSEMBLE_DIR -type f -name "*.en"); do
        echo "Processing: $RUN_FILE"
        # perform actions on each path
        RUN_NAME=$(basename "$(dirname $RUN_FILE)")
        OUTPUT_FILE="$OUTPUT_DIR/$RUN_NAME"_combined_energies

        # concatenate together energies files of run and also original
        tail -q -n +2 $BASE_FILE > $OUTPUT_FILE
        tail -q -n +2 $RUN_FILE >> $OUTPUT_FILE

        # modify the first column to be line-number - 1 (in order to reflect the block number of original + run combined simulation)
        # but ignoring the first row, which is the header
        echo "$FILE_HEADER" > "temp.txt"
        awk '{ $1 = NR; print }' "$OUTPUT_FILE" >> "temp.txt" && mv "temp.txt" "$OUTPUT_FILE"  

        TITLE="${RUN_NAME//_/ }"

        # add plot command to gnuplot script
        echo "set output '$OUTPUT_DIR/images/$RUN_NAME.png'" >> "$GNUPLOT_SCRIPT"
        echo "set title 'Combined energies plot for $TITLE'" >> "$GNUPLOT_SCRIPT"
        echo "plot '$OUTPUT_FILE' using 1:4 with lines t 'combined', '$BASE_FILE' using 1:4 w lines lc 'red' t 'original'" >> "$GNUPLOT_SCRIPT"
        echo "unset output" >> "$GNUPLOT_SCRIPT"
    done

    echo "Production of combined files is complete, invoking now the generated gnuplot script"

    # invoke the generated script
    gnuplot "$GNUPLOT_SCRIPT"
}

main () {
    if $1; then
        POSSIBLE_SLICES=( 40 80 160 320 640 )
        for SLICES in "${POSSIBLE_SLICES[@]}"; do
            visualize_ensemble_dir $SLICES
        done
    else
        visualize_ensemble_dir 320
    fi
}

do_all=false

main $do_all


