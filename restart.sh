#!/bin/bash
# --------------------------------------------
#SBATCH --time=08-00:00:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=restart
#SBATCH --output=/home/syu7/logs/%u_%x_%j.out
# -------------------------------------------
echo "Current working directory: `pwd`"
echo "Starting run at: `date`"
# -------------------------------------------

# Purpose of this script is to restart a stopped simulation in the same directory

# Enter the source path here
CHOICE_DIR="/home/syu7/scratch/graphene_helium/optimal_time_step_beta_0.0625/slices_320"
echo "The provided directory path is: $CHOICE_DIR"

# check if the provided directory can be restarted:
# needs a summary file, random seed file, and file with the latest many-body worldlines config
RUN_FILE=$(find "$CHOICE_DIR" -maxdepth 1 -type f -name "*.run")
SEED_FILE=$(find "$CHOICE_DIR" -maxdepth 1 -type f -name "*.iseed")
LAST_POS_FILE=$(find "$CHOICE_DIR" -maxdepth 1 -type f -name "*.last")
CONFIG_FILE=$(find "$CHOICE_DIR" -maxdepth 1 -type f -name "*.sy")
ENERGIES_FILE=$(find "$CHOICE_DIR" -maxdepth 1 -type f -name "*.en")

# check if these files exist before proceeding
if [ -z "$RUN_FILE" ] || [ -z "$SEED_FILE" ] || [ -z "$LAST_POS_FILE" ] || [ -z "$CONFIG_FILE" ]; then
  echo "Necessary files for simulation restart in provided path was not found"
  exit 1
else
  echo ".run, .iseed, .sy, and .last files were found - proceeding"
fi

# check if the last line of the configuration file contains the `RESTART` directive
# if it is not there, then add it: it will be removed at the end of the script

# first, remove any empty lines in the config file
sed -i '/^\s*$/d' "$CONFIG_FILE"
# then add the RESTART directive if not already present
grep -qxF 'RESTART' "$CONFIG_FILE" || echo 'RESTART' >> "$CONFIG_FILE"

# make a backup directory if not already there
mkdir -p $CHOICE_DIR/backups
# count the number of backups
BACKUPS_COUNT=$(ls $CHOICE_DIR/backups/backup* | wc -l)
CURRENT_BACKUP_NO=$(($BACKUPS_COUNT+1))

# move the energies file into the backups folder so that it doesn't get overwritten
ENERGIES_FILE_NAME=$(basename $ENERGIES_FILE)
mv $ENERGIES_FILE $CHOICE_DIR/backups/backup"$CURRENT_BACKUP_NO"_"$ENERGIES_FILE_NAME"

# restart the simulation
SIMULATION_NAME=$(basename $CHOICE_DIR)
cd $CHOICE_DIR
echo "$SIMULATION_NAME" | ./vpi