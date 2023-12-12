#!/bin/bash
# --------------------------------------------
#SBATCH --time=00:30:00
#SBATCH --account=def-massimo
#SBATCH --job-name=sf_bootstrap
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=48
#SBATCH --output=/home/syu7/logs/sf_bootstrap/%x_id_%j.out
# --------------------------------------------

usage () {
     echo "Usage: ./superfluid_fit <simulation directory path> <skip value>"
     exit 1
}

if [[ -n "$SLURM_JOB_NAME" ]]; then
     echo "script submitted as a slurm job, loading necessary modules"
     module load scipy-stack
fi

# create the directory for holding the logs
USER="/home/syu7"
mkdir -p "$USER/logs/sf_bootstrap"

source "$USER/scratch/scripts/job_scripts/functions.sh"

# command-line arguments
SUPERFLUID_FILE=$1
SKIP=$2

check_argument "$SUPERFLUID_FILE" || usage
check_argument "$SKIP" || usage

SCRIPT_FILE="$USER/scratch/scripts/postprocessing/bootstrap_fit.py"

# echo "Running bootstrap analysis as part of SLURM job"

# do bootstrap analysis
python "$SCRIPT_FILE" \
     --filename="$SUPERFLUID_FILE" \
     --cores="$SLURM_CPUS_PER_TASK" \
     --throwaway_first \
     --throwaway_last \
     --p_interval=0.15 \
     --save \
     --skip="$SKIP" \
     --bootstrap_iterations=1000000 \
     --verbose \
     --filetype="sf_time"\
     --method="bootstrap"