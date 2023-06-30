#!/bin/bash
# --------------------------------------------
#SBATCH --time=07-00:00:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=ensemble
#SBATCH --output=/home/syu7/logs/ensemble/seed_%x_%j.out
#SBATCH --array=1,2,3,4,5,6,7,8,9,10,11,12       # indices for random seeds to use
# -------------------------------------------

# script needs directory path of simulation run as a CLI arg to be restarted as an ensemble
# 
# example usage: sbatch ./run_ensemble.sh "~/scratch/2d_helium"
#

# ------------------------------------------------------------------------------------------------------------------------ #
#   PURPOSE: Run an ensemble starting where a standalone simulation ended off for production                               #
# ------------------------------------------------------------------------------------------------------------------------ #
#   Often for the longer simulations, they end abruptly when they run out of allotted time from the                        #
#   job scheduler. Therefore, provided that we are past the 'equilibration time' of the system, it would be prudent        #
#   to run several sims in parallel that branch off the original run, but all using different random seeds (otherwise the  #
#   data they produce is identical). This technique is known as 'serial farming' and allows us to accumulate more data     #
#   and reduce statistical errors during data analysis.                                                                    #
# ------------------------------------------------------------------------------------------------------------------------ #

check_sim_path() {
  local DIR=$1
  local SEED_FILE
  local LAST_POS_FILE
  local CONFIG_FILE
  local ENERGIES_FILE

  SEED_FILE=$(find "$DIR" -maxdepth 1 -type f -name '*.iseed')
  LAST_POS_FILE=$(find "$DIR" -maxdepth 1 -type f -name '*.last')
  CONFIG_FILE=$(find "$DIR" -maxdepth 1 -type f -name '*.sy')
  ENERGIES_FILE=$(find "$DIR" -maxdepth 1 -type f -name '*.en')

  if [[ -z "$SEED_FILE" || -z "$LAST_POS_FILE" || -z "$CONFIG_FILE" || -z "$ENERGIES_FILE" ]]; then
    echo -e "Missing required files\n"
    exit 1
  else
    echo -e ".run, .iseed, .sy, .last, .en files were found - proceeding\n"
  fi
}
 
SOURCEPATH=$1
echo "The provided source path for ensembling is: $SOURCEPATH"

# check if the chosen path has the correct files needed to run/restart sim
check_sim_path "$SOURCEPATH"

# get the last directory in the provided path
# e.g. if the path is '~/scratch/graphene_helium/optimal_beta_tau_0.0015625/beta_1.0', then name is 'beta_1.0'
NAME=$(basename "$SOURCEPATH")

# if the job is not submitted via Slurm, define the SLURM_ARRAY_TASK_ID yourself
# in order to access the random seed file
if [ -z "$SLURM_ARRAY_TASK_ID" ]; then
  # try a default value of 1
  SLURM_ARRAY_TASK_ID=1
  echo "Array task id is not defined. Using the following value : $SLURM_ARRAY_TASK_ID"
else
  echo "Array task id already exists: $SLURM_ARRAY_TASK_ID"
fi

# use the task ID provided by the job submitter to select the seed
SEED_NUMBER=$SLURM_ARRAY_TASK_ID

echo "Current working directory: $(pwd)"
echo "Starting run at: $(date)"
echo -e "Starting an ensemble run for $NAME with random seed no. $SEED_NUMBER\n"

# run an ensemble: run several simulations continuing where a run left off,
# but using a different random seed for different simulations

# new directory for ensemble runs
ENSEMBLE_DIR="$SOURCEPATH/ensemble"
mkdir -p "$ENSEMBLE_DIR"

# now, we need to copy over the files at $CHOICE_DIR, making a parent directory along with subdirectories
# to hold results from individual workers in the job array
NEW="$ENSEMBLE_DIR/run_$SLURM_ARRAY_TASK_ID"
mkdir -p "$NEW"
# don't copy subdirectories such as /images
find -L "$SOURCEPATH" -maxdepth 1 -type f -not -path '*.iseed' -exec cp {} "$NEW" \;

# now, we have to replace the random seed file
USER="/home/syu7"
cp "$USER/scratch/random_seeds/seed$SEED_NUMBER.iseed" "$NEW"
mv "$NEW/seed$SEED_NUMBER.iseed" "$NEW/$NAME.iseed"

CONFIG_FILE="$NEW/$NAME.sy"
# first, remove any empty lines in the config file
sed -i '/^\s*$/d' "$CONFIG_FILE"
# then add the RESTART directive if not already present
grep -qxF 'RESTART' "$CONFIG_FILE" || echo 'RESTART' >> "$CONFIG_FILE"

# start the simulation
cd "$NEW" || exit 1
echo "$NAME" | ./vpi > "$NEW/$NAME.out"

# plot the output files
gnuplot -e "dirname='$NEW'" "$USER/scratch/postprocessing/plot_files.p"