#!/bin/bash
# --------------------------------------------
#SBATCH --time=00:30:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=sf_bootstrap
#SBATCH --cpus-per-task=20
#SBATCH --output=/home/syu7/logs/sf_bootstrap/%x_id_%j.out
# --------------------------------------------

# Purpose of script is to iterate over ROOT_PATH and do superfluid bootstrap fitting for each of the
# *.sd files inside

if [[ -n "$SLURM_JOB_NAME" ]]; then
     echo "script submitted as a slurm job, loading necessary modules"
     module load scipy-stack
fi

# create the directory for holding the logs
USER="/home/syu7"
mkdir -p "$USER/logs/sf_bootstrap"

source "$USER/scratch/job_scripts/functions.sh"

# command-line arguments
ROOT_PATH=$1

check_argument "$ROOT_PATH"

SCRIPT_FILE="$USER/scratch/postprocessing/superfluid_fit.py"

# echo "Running bootstrap analysis as part of SLURM job"

cd "$ROOT_PATH" || exit 1
CURRENT=$(pwd)

# do bootstrap analysis
# find "$ROOT_PATH" -type f -name "*.sd" -exec echo {} \;
find "$CURRENT" -type f -name "*.sd" -exec python "$SCRIPT_FILE" --filename {} \
     --cores=1 --throwaway_first --throwaway_last --xscaling 1 --no_bootstrap \;

# second layer of processing
# find "$ROOT_PATH" -type f -name "sd_fit_params.txt" -exec echo {} \;
    

# exit 1;