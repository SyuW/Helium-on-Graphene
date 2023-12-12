#!/bin/bash
# --------------------------------------------
#SBATCH --time=15-00:00:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=start_new
#SBATCH --output=/home/syu7/logs/start_new/start_new_id_%j.out
# -------------------------------------------

# -------------------------------------------
#   BEGIN FUNCTIONS
# -------------------------------------------

usage () {
    echo "Usage: ./start_new.sh <simulation directory path> <input-id>"
    exit 1
}

# -------------------------------------------
#   END FUNCTIONS
# -------------------------------------------

# --------------------------------------------
#   BEGIN MAIN BODY
# --------------------------------------------

user="/home/syu7"

source "$user/scratch/scripts/job_scripts/functions.sh"

# get_input dir "enter the simulation directory: "
# get_input name "enter the simulation's input id: "

dir=$1 
name=$2

check_argument "$dir" || usage
check_argument "$name" || usage

check_sim_begin "$dir" || usage

mkdir -p "$user/logs/start_new"
echo "Current working directory: $(pwd)"
echo -e "Starting run at: $(date)\n"

# make sure that you back up your energy file before running
cd "$dir" || { echo "Cannot change to sim. directory"; exit 1; }
current=$(pwd)
echo "$name" | vpi > "$current/$name.out"

# --------------------------------------------
#   END MAIN BODY
# --------------------------------------------