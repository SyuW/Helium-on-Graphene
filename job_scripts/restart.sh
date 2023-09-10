#!/bin/bash
# --------------------------------------------
#SBATCH --time=18-00:00:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=restart
#SBATCH --output=/home/syu7/logs/restart/restart_id_%j.out
# -------------------------------------------

# -------------------------------------------
#   BEGIN FUNCTIONS
# -------------------------------------------

usage () {
    echo "Usage: ./restart.sh <simulation directory path>"
}

# --------------------------------------------
#   END FUNCTIONS
# --------------------------------------------

# --------------------------------------------
#   MAIN BODY OF SCRIPT
# --------------------------------------------

module load "StdEnv/2020"
module load "scipy-stack"
module load "gnuplot"

USER="/home/syu7"
mkdir -p "$USER/logs/restart"
echo "Current working directory: $(pwd)"
echo -e "Starting run at: $(date)\n"

source "$USER/scratch/scripts/job_scripts/functions.sh"

DIR=$1
check_argument "$DIR"
check_sim_restart "$DIR"

NAME=$(basename "$DIR")

# make sure that you back up your energy file before running
cd "$DIR" || { echo "Cannot change to sim. directory"; exit 1; }
echo "$NAME" | ./vpi > "$DIR/$NAME.out"

# --------------------------------------------
#   END MAIN BODY
# --------------------------------------------