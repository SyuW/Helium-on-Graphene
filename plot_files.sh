#!/bin/bash
# --------------------------------------------
#SBATCH --time=0-00:10:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=plot_files
#SBATCH --output=/home/syu7/logs/plot_files/plot_files_id_%j.out
# --------------------------------------------

# create the directory for holding the logs
USER="/home/syu7"
mkdir -p "$USER/logs/plot_files"

module load gnuplot

source "$USER/scratch/job_scripts/functions.sh"

CHOICE_DIR=$1

check_sim_path "$CHOICE_DIR"

gnuplot -e "dirname='$CHOICE_DIR'" "$USER/scratch/postprocessing/plot_files.p"