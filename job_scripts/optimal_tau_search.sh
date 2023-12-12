#!/bin/bash
# --------------------------------------------
#SBATCH --time=00:10:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=optimal_tau
#SBATCH --output=/home/syu7/logs/optimal_tau_search/%x_slices_%t_id_%j.out
#SBATCH --array=160,320,640,1280     # Enter the time slices you want to examine here
# -------------------------------------------

# -------------------------------------------------------------------------------------------------------------------------------- #
#   PURPOSE: Search for the optimal number of time slices at fixed projection time, beyond which statistical errors are negligible #
# -------------------------------------------------------------------------------------------------------------------------------- #
#   Find the optimal timestep for the chosen system: ground state energy per particle                                              #
#   versus number of time slices used, denote tau = beta / time_slices as the imaginary time-step                                  #
#   the average total energy is then calculated as (1/(n-n_0)) * sum_{i > n_0}(E_i)                                                #
#   where n_0 is the number of steps for the system to equilibrate, i.e. become uncorrelated wrt initial config                    #
#   with datapoints representing average energies collected for different timesteps try to do a quartic fit: a + b*tau*x^4         #
#                                                                                                                                  #
#   This procedure is performed using two scripts:                                                                                 #
#     - optimal_tau_search.sh: responsible for creating all the necessary files/directories for running the simulations            #
#                               - formulated as an array job                                                                       #
#     - start_new.sh: responsible for starting the simulations                                                                     #
# -------------------------------------------------------------------------------------------------------------------------------- #

# ---------------------------------------- #
#           BEGIN FUNCTIONS                #
# ---------------------------------------- #

usage () {
    echo "Usage: ./optimal_tau_search.sh <project> <projection-time> <dirname>"
    exit 1
}

# -------------------------- #
#       END FUNCTIONS        #
# -------------------------- #

# ------------------------------- #
#    MAIN BODY OF SCRIPT BEGINS   #
# ------------------------------- #

mkdir -p "/home/syu7/logs/optimal_tau_search"

user="/home/syu7"

source "$user/scratch/scripts/job_scripts/functions.sh"

# use the first command-line argument as the project
project=$1
beta=$2
dirname=$3

# use a fixed projection time for simulations of varying time-step
# beta=0.0625

check_argument "$project" || usage
check_argument "$beta" || usage
check_argument "$dirname" || usage

# check that the provided project string is valid
assert_project "$project" || exit 1;

# path for all data to be written towards
datapath="$user/scratch/"$project"_modified_LJ"
sourcepath="$user/PIGS"
# source path for copying over files necessary for running the simulations
project_path="$sourcepath/WORK/experiments/$project"_experiment/modified_LJ

# check whether the script was submitted as part of a slurm job
default_val=40
if [ -z "$SLURM_ARRAY_TASK_ID" ]; then
    echo -e "Array task id is not defined. Using the following value : $default_val\n"
    SLURM_ARRAY_TASK_ID=$default_val
    jobless=1
else
    echo -e "Array task id already exists: $SLURM_ARRAY_TASK_ID\n"
    jobless=0
fi

# number of time slices to use in the simulation is given by the task id
num_time_slices=$SLURM_ARRAY_TASK_ID

# base directory for doing the optimal timestep search procedure
timestep_dir=""$dirname"_beta_$beta"

# sub-directory corresponding to number of time slices used in simulations
# contains executable for running simulation and any other files e.g. other executables and any data files
new="$datapath/$timestep_dir/slices_$num_time_slices"

if [ ! -d "$new" ]
then
    echo -e "Directory $new doesn't exist. Making new directory.\n"
    mkdir -p "$new"
else
    echo -e "Directory $new already exists.\n"
fi

# read the experiment configuration file in /home and then write a new configuration file in the 
# newly created directory for running the simulation. This will overwrite the old configuration file
# if the simulation directory was already created before.

new_config_file="$new/slices_$num_time_slices.sy"

# ordering of parameters to config_parser: <path to experiment config file> <path to prod config file> <time slices> <projection time>
config_parser "$project_path/$project.sy" "$new_config_file" "$num_time_slices" "$beta"

# all following commands depend on changing into the new directory.
# such as creating symlinks and running using vpi 
cd "$new" || (echo "Could not change to $new"; exit 1)

echo "Creating necessary symbolic links"
# necessary executables for running the simulations/averaging after simulation
ln -s "$sourcepath/source/tools/average" average
ln -s "$sourcepath/source/vpi" vpi

# .ic files with the initial positions of particle species
for type in "${SPECIES[@]}"; do
    ln -s "$project_path/initial.$type.ic" "initial.$type.ic"
done

# copy over the wave vectors file for computation of structure factor
if [[ -e "$project_path/wavevectors" ]]; then
    ln -s "$project_path/wavevectors" wavevectors
fi

echo -e "Creation of symbolic links has finished\n"

# new FUNCTIONALITY: Submit a SLURM job from inside the optimal time-step search job
# for running the simulation and performing any necessary restarts

echo "----------------------------------------------------------------------"
echo "Running QMC simulation with $num_time_slices time slices"
echo -e "----------------------------------------------------------------------\n"

echo "Current working directory: $(pwd)"
echo "Starting run at: $(date)"

total_blocks=$(grep "PASS" "$new_config_file" | cut -d " " -f 2)
passes_per_block=$(grep "PASS" "$new_config_file" | cut -d " " -f 2)
echo "Running simulation with $total_blocks blocks and $passes_per_block passes per block"

if [ "$jobless" = 1 ]; then 
    echo -e "Script was not submitted through Slurm"
    sbatch "$user/scratch/scripts/job_scripts/start_new.sh" "$new" "slices_$num_time_slices"
else
    echo "Script was submitted through Slurm as a job"
    echo -e "Attempting to run simulation inside directory $new" "slices_$num_time_slices"
    sbatch "$user/scratch/scripts/job_scripts/start_new.sh" "$new" "slices_$num_time_slices"
fi

# ------------------------------- #
#    MAIN BODY OF SCRIPT ENDS     #
# ------------------------------- #