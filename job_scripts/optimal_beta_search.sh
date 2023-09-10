#!/bin/bash
# --------------------------------------------
#SBATCH --time=00:10:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=optimal_beta
#SBATCH --output=/home/syu7/logs/optimal_beta_search/%x_index_%t_id_%j.out
#SBATCH --array=1-100     # Array indices for accessing different projection times
# -------------------------------------------

# ------------------------------------------------------------------------------------------------------------------------ #
#   PURPOSE: Search for a sufficiently long projection time `beta` for convergence to the GS energy                        #
# ------------------------------------------------------------------------------------------------------------------------ #
#   This is the second stage of the process after finding the optimal time step tau                                        #
#   as before, we calculate the average total energy from simulations with varying projection times                        #
#   the average total energy is calculated as (1/(n-n_0)) * sum_{i > n_0}(E_i)                                             #
#   where n_0 is the number of steps for the system to equilibrate, i.e. become uncorrelated wrt initial config            #
#   we then perform an exponential fit of form: E_0 + b*exp(-c*beta) to the (beta, energy datapoints)                      #
#   to determine the convergent beta and also extrapolate the system's ground state energy                                 #
# ------------------------------------------------------------------------------------------------------------------------ #

# ---------------------------------------- #
#           BEGIN FUNCTIONS                #
# ---------------------------------------- #

usage () {
    echo "Usage: ./optimal_beta_search.sh <project> <time-step>"
    exit 1
}

# -------------------------- #
#       END FUNCTIONS        #
# -------------------------- #

# ------------------------------- #
#    MAIN BODY OF SCRIPT BEGINS   #
# ------------------------------- #

module load scipy-stack

USER="/home/syu7"

mkdir -p "$USER/logs/optimal_beta_search"
echo "Current working directory: $(pwd)"
echo -e "Starting run at: $(date)\n"

# get functions
source "$USER/scratch/scripts/job_scripts/functions.sh"

# use the first command-line argument as the project
PROJECT=$1
TAU=$2
# classical choice is beta_multiple=0.0625
UNIT_BETA=$3

check_argument "$PROJECT" || usage
check_argument "$TAU" || usage

# check that the provided project string is valid
assert_project "$PROJECT" || exit 1;

# check that the provided time step tau is of correct type (float)
is_float "$TAU" || { echo "Time step has to be a float" ; usage ; exit 1; }

DATAPATH="$USER/scratch/$PROJECT"
SOURCEPATH="$USER/PIGS"
# source path for copying over files necessary for running the simulations
PROJECTPATH="$SOURCEPATH/WORK/experiments/$PROJECT"_experiment

# check whether the script was submitted as part of a slurm job
DEFAULT_INDEX=1
if [ -z "$SLURM_ARRAY_TASK_ID" ]; then
    echo -e "Array task id is not defined. Using the following value: $DEFAULT_INDEX\n"
    SLURM_ARRAY_TASK_ID=$DEFAULT_INDEX
    JOBLESS=1
else
    echo -e "Array task id already exists: $SLURM_ARRAY_TASK_ID\n"
    JOBLESS=0
fi

# use a fixed projection time for simulations of varying time-step
# BETAS=( 0.0625 0.125 0.25 0.5 1.0 2.0 4.0 )
# SLICES_OPTIONS=()
# for beta in "${BETAS[@]}"; do
#     result=$(python -c "print(int($beta / $TAU))")
#     SLICES_OPTIONS+=("$result")
# done

# echo "Using the time slices: ${SLICES_OPTIONS[*]}"

# use the index coming from the array job to select projection time/number of slices

MULTIPLE="$SLURM_ARRAY_TASK_ID"

BETA=$(python -c "print('{:.5f}'.format($MULTIPLE * $UNIT_BETA))")
NUM_TIME_SLICES=$(python -c "print(int($BETA / $TAU))")

# BETA=${BETAS[$SLURM_ARRAY_TASK_ID]}
# NUM_TIME_SLICES=${SLICES_OPTIONS[$SLURM_ARRAY_TASK_ID]}

# base directory for doing the optimal timestep search procedure
BETA_DIR="fixed_optimal_beta_tau_$TAU"

# sub-directory corresponding to number of time slices used in simulations
# contains executable for running simulation and any other files e.g. other executables and any data files
NEW="$DATAPATH/$BETA_DIR/beta_$BETA"

if [ ! -d "$NEW" ]
then
    echo -e "Directory $NEW doesn't exist. Making new directory.\n"
    mkdir -p "$NEW"
else
    echo -e "Directory $NEW already exists.\n"
fi

# read the experiment configuration file in /home and then write a new configuration file in the 
# newly created directory for running the simulation. This will overwrite the old configuration file
# if the simulation directory was already created before.

NEW_CONFIG_FILE="$NEW/beta_$BETA.sy"

# ordering of parameters to config_parser: <path to experiment config file> <path to prod config file> <time slices> <projection time>
config_parser "$PROJECTPATH/$PROJECT.sy" "$NEW_CONFIG_FILE" "$NUM_TIME_SLICES" "$BETA"

# all following commands depend on changing into the new directory.
# such as creating symlinks and running using vpi 
cd "$NEW" || { echo "Could not change to $NEW"; exit 1; }

echo "Creating necessary symbolic links"
# necessary executables for running the simulations/averaging after simulation
ln -s "$SOURCEPATH/source/tools/average" average
ln -s "$SOURCEPATH/source/vpi" vpi

# copy over the wave vectors file for computation of structure factor
if [[ -e "$PROJECTPATH/wavevectors" ]]; then
    ln -s "$PROJECTPATH/wavevectors" wavevectors
fi

# .ic files with the initial positions of particle species
for type in "${SPECIES[@]}"; do
    ln -s "$PROJECTPATH/initial.$type.ic" "initial.$type.ic"
done

echo -e "Creation of symbolic links has finished\n"

# NEW FUNCTIONALITY: Submit a SLURM job from inside the optimal time-step search job
# for running the simulation and performing any necessary restarts

echo "----------------------------------------------------------------------"
echo "Running QMC simulation with $NUM_TIME_SLICES time slices"
echo -e "----------------------------------------------------------------------\n"

TOTAL_BLOCKS=$(grep "PASS" "$NEW_CONFIG_FILE" | cut -d " " -f 2)
PASSES_PER_BLOCK=$(grep "PASS" "$NEW_CONFIG_FILE" | cut -d " " -f 2)
echo "Running simulation with $TOTAL_BLOCKS blocks and $PASSES_PER_BLOCK passes per block"

if [ "$JOBLESS" = 1 ]; then 
    echo -e "Script was not submitted through Slurm"
    sbatch "$USER/scratch/scripts/job_scripts/start_new.sh" "$NEW"
else
    echo "Script was submitted through Slurm as a job"
    echo -e "Attempting to run simulation inside directory $NEW"
    sbatch "$USER/scratch/scripts/job_scripts/start_new.sh" "$NEW"
fi

# ------------------------------- #
#    MAIN BODY OF SCRIPT ENDS     #
# ------------------------------- #