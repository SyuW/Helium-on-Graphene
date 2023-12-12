#!/bin/bash
# --------------------------------------------
#SBATCH --time=14-00:00:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=restart
#SBATCH --output=/home/syu7/logs/restart/restart_id_%j.out
# -------------------------------------------

# -------------------------------------------
#   BEGIN FUNCTIONS
# -------------------------------------------

usage () {
    echo "Usage: ./restart.sh <simulation directory path> <input-id>"
    exit 1
}

# --------------------------------------------
#   END FUNCTIONS
# --------------------------------------------

# --------------------------------------------
#   MAIN BODY OF SCRIPT
# --------------------------------------------

# module load "StdEnv/2020"
# module load "scipy-stack"
# module load "gnuplot"

USER="/home/syu7"
source "$USER/scratch/scripts/job_scripts/functions.sh"

# CLI arguments
DIR=$1
NAME=$2

check_argument "$DIR" || usage
check_sim_restart "$DIR" || usage

if [ -z "$NAME" ]; then
    NAME=$(basename "$DIR")
    echo "Name is not defined, using the basename: $NAME"
fi

mkdir -p "$USER/logs/restart"
echo "Current working directory: $(pwd)"
echo -e "Starting run at: $(date)\n"


# make sure that you back up your energy file before running
cd "$DIR" || { echo "Cannot change to sim. directory"; exit 1; }
DIR=$(pwd)
echo "$NAME" | ./vpi > "$DIR/$NAME.out"

# --------------------------------------------
#   END MAIN BODY
# --------------------------------------------