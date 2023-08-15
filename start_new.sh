#!/bin/bash
# --------------------------------------------
#SBATCH --time=20-00:00:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=start_new
#SBATCH --output=/home/syu7/logs/start_new/start_new_id_%j.out
# -------------------------------------------

# -------------------------------------------
#   BEGIN FUNCTIONS
# -------------------------------------------

usage () {
    echo "Usage: ./start_new.sh <simulation directory path>"
}

# -------------------------------------------
#   END FUNCTIONS
# -------------------------------------------

module load "StdEnv/2020"
module load "scipy-stack"
module load "gnuplot"

USER="/home/syu7"
mkdir -p "$USER/logs/start_new"
echo "Current working directory: $(pwd)"
echo -e "Starting run at: $(date)\n"

source "$USER/scratch/job_scripts/functions.sh"

DIR=$1
check_argument "$DIR" || (usage; exit 1)
check_sim_begin "$DIR"

# note: the NAME aka name of simulation directory should match the name of the config file 
NAME=$(basename "$DIR")

# make sure that you back up your energy file before running
cd "$DIR" || { echo "Cannot change to sim. directory"; exit 1; }
CURRENT=$(pwd)
echo "$NAME" | ./vpi > "$CURRENT/$NAME.out"

# --------------------------------------------
#   END MAIN BODY
# --------------------------------------------