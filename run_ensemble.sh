#!/bin/bash
# --------------------------------------------
#SBATCH --time=07-00:00:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=ensemble_160
#SBATCH --output=/home/syu7/logs/%u_%x_%j.out
#SBATCH --array=1,2,3,4,5,6,7,8,9,10,11,12       # indices for random seeds to use
# -------------------------------------------
echo "Current working directory: `pwd`"
echo "Starting run at: `date`"
# -------------------------------------------

# script needs directory path of simulation run as a CLI arg to be restarted as an ensemble
# 
# example usage: sbatch ./run_ensemble.sh "~/scratch/2d_helium"
#

# Enter your source path here
SLICES=160
CHOICE_DIR="/home/syu7/scratch/graphene_helium/optimal_time_step_beta_0.0625/slices_"$SLICES""
echo "The provided directory path is: $CHOICE_DIR"

# check if the provided directory is valid
RUN_FILE=$(find "$CHOICE_DIR" -type f -name "*.run")
if [ -z "$RUN_FILE" ]; then
  echo "Valid simulation run file in provided path was not found"
  exit 1
fi

# get the last directory in the provided path
NAME=$(basename "$CHOICE_DIR")

# if the job is not submitted via Slurm, define the SLURM_ARRAY_TASK_ID yourself
# in order to access the random seed file
if [ -z $SLURM_ARRAY_TASK_ID ]; then
  # try a default value of 1
  SLURM_ARRAY_TASK_ID="1"
  echo "Array task id is not defined. Using the following value : $SLURM_ARRAY_TASK_ID"
else
  echo "Array task id already exists: $SLURM_ARRAY_TASK_ID"
fi

# use the task ID provided by the job submitter to select the seed
SEED_NUMBER=$SLURM_ARRAY_TASK_ID

# --------------------------------------------
echo ""
echo "Job Array ID / Job ID: $SLURM_ARRAY_JOB_ID / $SLURM_JOB_ID"
echo "Starting an ensemble run for $NAME with random seed no. $SEED_NUMBER"
echo ""
# -------------------------------------------

# run an ensemble: run several simulations continuing where a run left off,
# but using a different random seed for different simulations

# all the data for the graphene-helium project should go into the $DATAPATH folder
USER="/home/syu7"
# ------------------
# Enter your project name (which will affect the destination path)
#-------------------
PROJECT="graphene_helium"
# ------------------
DATAPATH="$USER/scratch/$PROJECT"

# new directory for ensemble runs
ENSEMBLE_DIR="$DATAPATH/ensemble"
mkdir -p "$ENSEMBLE_DIR"

# now, we need to copy over the files at $CHOICE_DIR, making a parent directory along with subdirectories
# to hold results from individual workers in the job array
NEW="$ENSEMBLE_DIR/ensemble_"$NAME"/run_$SLURM_ARRAY_TASK_ID"
mkdir -p "$NEW"
# don't copy subdirectories such as /images
find "$CHOICE_DIR" -path $CHOICE_DIR/images -prune -o -exec cp {} "$NEW" \;

# now, we have to replace the random seed file
rm "$NEW/"$NAME".iseed"
cp "$USER/scratch/random_seeds/seed"$SEED_NUMBER".iseed" "$NEW"
mv "$NEW/seed"$SEED_NUMBER".iseed" "$NEW/$NAME.iseed"

CONFIG_FILE="$NEW/"$NAME".sy"
# first, remove any empty lines in the config file
sed -i '/^\s*$/d' "$CONFIG_FILE"
# then add the RESTART directive if not already present
grep -qxF 'RESTART' "$CONFIG_FILE" || echo 'RESTART' >> "$CONFIG_FILE"

# start the simulation
cd $NEW
echo "$NAME" | ./vpi

# plot the output files
gnuplot -e "dirname='$NEW'" "$USER/scratch/postprocessing/plot_files.p"