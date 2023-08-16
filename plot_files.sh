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


usage () {
    echo "Usage: ./plot_files.sh <directory-with-simulation>"
    exit 0
}

source "$USER/scratch/job_scripts/functions.sh"

DIR=$1

check_argument "$DIR" || usage
check_sim_restart "$DIR" || usage

cd "$DIR" || { echo "Cannot change to directory, maybe doesn't exist?" ; exit 1; }
CURRENT=$(pwd)

gnuplot -e "dirname='$CURRENT'" "$USER/scratch/postprocessing/plot_files.p"