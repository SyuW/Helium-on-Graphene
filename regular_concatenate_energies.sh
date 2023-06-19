#!/bin/bash

USER="/home/syu7"
PROJECT="graphene_helium"
FILE1="$USER/scratch/$PROJECT/optimal_time_step_beta_0.0625/slices_320/backups/backup1_slices_320.he.en"
FILE2="$USER/scratch/$PROJECT/optimal_time_step_beta_0.0625/slices_320/slices_320.he.en"

cat $FILE1 $FILE2 > combined.txt

tail -q -n +2 $BASE_FILE > $OUTPUT_FILE
tail -q -n +2 $RUN_FILE >> $OUTPUT_FILE