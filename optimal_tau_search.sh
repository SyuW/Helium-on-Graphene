#!/bin/bash
# --------------------------------------------
#SBATCH --time=00:10:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=optimal_tau
#SBATCH --output=/home/syu7/logs/optimal_tau_search/%x_slices_%t_id_%j.out
#SBATCH --array=40,80,160,320,640      # Enter the time slices you want to examine here
# -------------------------------------------

# ------------------------------------------------------------------------------------------------------------------------   #
#   PURPOSE: Search for the optimal number of time slices at fixed projection time, beyond which statistical errors are negligible                    #
# ------------------------------------------------------------------------------------------------------------------------   #
#   Find the optimal timestep for the chosen system: ground state energy per particle                  #
#   versus number of time slices used, denote tau = beta / time_slices as the imaginary time-step                            #
#   the average total energy is then calculated as (1/(n-n_0)) * sum_{i > n_0}(E_i)                                          #
#   where n_0 is the number of steps for the system to equilibrate, i.e. become uncorrelated wrt initial config              #
#   with datapoints representing average energies collected for different timesteps try to do a quartic fit: a + b*tau*x^4   #
#   
#   This procedure is performed using two scripts:
#     - optimal_tau_search.sh: responsible for creating all the necessary files/directories for running the simulations 
#                               - formulated as an array job 
#     - run_standalone.sh: responsible for running the simulations and restarting
# ------------------------------------------------------------------------------------------------------------------------ #

# ---------------------------------------- #
#           BEGIN FUNCTIONS                #
# ---------------------------------------- #

usage () {
    echo "Usage: ./optimal_tau_search.sh <project>"
}

# -------------------------- #
#       END FUNCTIONS        #
# -------------------------- #

# ------------------------------- #
#    MAIN BODY OF SCRIPT BEGINS   #
# ------------------------------- #

mkdir -p "/home/syu7/logs/optimal_tau_search"
echo "Current working directory: $(pwd)"
echo "Starting run at: $(date)"

USER="/home/syu7"

source "$USER/scratch/job_scripts/functions.sh"

# use the first command-line argument as the project
PROJECT=$1
BETA=$2

# use a fixed projection time for simulations of varying time-step
# BETA=0.0625

check_argument "$PROJECT"
check_argument "$BETA"

# check that the provided project string is valid
assert_project "$PROJECT"

DATAPATH="$USER/scratch/$PROJECT"
SOURCEPATH="$USER/PIGS"
# source path for copying over files necessary for running the simulations
PROJECTPATH="$SOURCEPATH/WORK/experiments/$PROJECT"_experiment

# check whether the script was submitted as part of a slurm job
DEFAULT_VAL=40
if [ -z "$SLURM_ARRAY_TASK_ID" ]; then
    echo -e "Array task id is not defined. Using the following value : $DEFAULT_VAL\n"
    SLURM_ARRAY_TASK_ID=$DEFAULT_VAL
    JOBLESS=1
else
    echo -e "Array task id already exists: $SLURM_ARRAY_TASK_ID\n"
    JOBLESS=0
fi

# number of time slices to use in the simulation is given by the task id
NUM_TIME_SLICES=$SLURM_ARRAY_TASK_ID

# base directory for doing the optimal timestep search procedure
TIMESTEP_DIR="optimal_time_step_beta_$BETA"

# sub-directory corresponding to number of time slices used in simulations
# contains executable for running simulation and any other files e.g. other executables and any data files
NEW="$DATAPATH/$TIMESTEP_DIR/slices_$NUM_TIME_SLICES"

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

NEW_CONFIG_FILE="$NEW/slices_$NUM_TIME_SLICES.sy"

# ordering of parameters to config_parser: <path to experiment config file> <path to prod config file> <time slices> <projection time>
config_parser "$PROJECTPATH/$PROJECT.sy" "$NEW_CONFIG_FILE" "$NUM_TIME_SLICES" "$BETA"

# all following commands depend on changing into the new directory.
# such as creating symlinks and running using vpi 
cd "$NEW" || (echo "Could not change to $NEW"; exit 1)

echo "Creating necessary symbolic links"
# necessary executables for running the simulations/averaging after simulation
ln -s "$SOURCEPATH/source/tools/average" average
ln -s "$SOURCEPATH/source/vpi" vpi

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
    $USER/scratch/job_scripts/run_standalone.sh "$NEW" "$TOTAL_BLOCKS" "$PASSES_PER_BLOCK"
    $USER/scratch/job_scripts/run_standalone.sh "$NEW" "$TOTAL_BLOCKS" "$PASSES_PER_BLOCK"
    $USER/scratch/job_scripts/run_standalone.sh "$NEW" "$TOTAL_BLOCKS" "$PASSES_PER_BLOCK"
else
    echo "Script was submitted through Slurm as a job"
    echo -e "Attempting to run simulation inside directory $NEW"
    sbatch "$USER/scratch/job_scripts/run_standalone.sh" "$NEW" "$TOTAL_BLOCKS" "$PASSES_PER_BLOCK"
fi

# plot the output files using a gnuplot script
# PLOTTING_SCRIPT="$USER/scratch/postprocessing/plot_files.p"
# gnuplot -e "dirname='$NEW'" "$PLOTTING_SCRIPT"

# ------------------------------- #
#    MAIN BODY OF SCRIPT ENDS     #
# ------------------------------- #