#!/bin/bash
# --------------------------------------------
#SBATCH --time=7-00:00:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=ensemble_run
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
# in order to try an ensemble run for a 2d system of Helium-4
#
#if [ -z "$1" ]; then
#  echo "Please provide the path of the simulation run as a command line argument."
#  exit 1
#fi

CHOICE_DIR="/home/syu7/scratch/2d_helium/trial"
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

SEED_NUMBER=$SLURM_ARRAY_TASK_ID

# --------------------------------------------
echo ""
echo "Job Array ID / Job ID: $SLURM_ARRAY_JOB_ID / $SLURM_JOB_ID"
echo "Starting an ensemble run for $NAME with random seed no. $SEED_NUMBER"
echo ""
# -------------------------------------------

# with the sufficiently long projection time, run an ensemble: several simulations of the same run,
# but using a different random seed for different simulations

# all the data for the graphene-helium project goes into the $DATAPATH folder
USER="/home/syu7"
PROJECT="2d_helium"
DATAPATH="$USER/scratch/$PROJECT"

# new directory for ensemble runs
ENSEMBLE_DIR="$DATAPATH/ensemble"
mkdir -p "$ENSEMBLE_DIR"

# now, we need to copy over the files at $CHOICE_DIR, making a parent directory along with subdirectories
# to hold results from individual workers in the job array
NEW="$ENSEMBLE_DIR/ensemble_"$NAME"/run_$SLURM_ARRAY_TASK_ID"
mkdir -p "$NEW"
find "$CHOICE_DIR" -type f -exec cp {} "$NEW" \;

# now, we have to replace the random seed file
rm "$NEW/"$NAME".iseed"
cp "$USER/scratch/random_seeds/seed"$SEED_NUMBER".iseed" "$NEW"
mv "$NEW/seed"$SEED_NUMBER".iseed" "$NEW/$NAME.iseed"

# also, add the restart option to the config file before running using `vpi`
#CONFIG_FILENAME="$NEW/"$NAME".sy"
#LAST_LINE=$(tail -n 1 "$CONFIG_FILENAME")
#EXPECTED_STRING="RESTART"
#if echo "$LAST_LINE" | grep -qF "$EXPECTED_STRING"; then
#    echo "Restart option found in run configuration file"
#else
#    echo "Adding restart option to run configuration file"
#    echo -e "\nRESTART" >> $CONFIG_FILENAME
#fi

# start the simulation
cd $NEW
echo "$NAME" | ./vpi

# plot the output files
# gnuplot -e "dirname='$NEW'" "$USER/scratch/postprocessing/plot_files.p"