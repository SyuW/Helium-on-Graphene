#!/bin/bash
# --------------------------------------------
#SBATCH --time=0-00:01:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=standalone
#SBATCH --output=/home/syu7/logs/standalone/%x_%j.out
#SBATCH --array=1-10%1       # syntax is 1-x%1 where 'x' is number of times the simulation will restart
# -------------------------------------------

# create the directory for holding the logs
USER="/home/syu7"
mkdir -p "$USER/logs/standalone"

# Purpose of this script is to run a standalone simulation

# ---------------------------------------- #
#           BEGIN FUNCTIONS                #
# ---------------------------------------- #

# usage function
usage() {
    echo "Usage: ./run_standalone.sh <path to directory containing simulation>"
    exit 1
}

# do post-processing such as concatenating all the energy (*.en) files together
# postprocess() {
#     return
# }

# ---------------------------------------- #
#           END FUNCTIONS                #
# ---------------------------------------- #

# assign the command-line arguments to more meaningful variables
SIMULATION_DIR=$1
TOTAL_BLOCKS=$2
PASSES_PER_BLOCK=$3

# Check if the required argument was provied
if [[ -z $SIMULATION_DIR ]]; then
    echo "Missing required argument"
    usage
fi

echo -e "Attempting to run simulation inside directory $SIMULATION_DIR\n"
echo "Using $TOTAL_BLOCKS in total with $PASSES_PER_BLOCK passes per block"

NAME=$( basename "$SIMULATION_DIR" )
CHECKPOINT_FILE="$SIMULATION_DIR/$NAME.checkpoint"

if test -e "$CHECKPOINT_FILE"; then
    # if there is a checkpoint file, restart
    echo -e "Checkpoint file detected, attempting restart"

    mkdir -p "$SIMULATION_DIR"/backups # make a backup directory if not already there

    # files that the simulation will produce assuming it ran correctly before 
    RUN_FILE=$(find "$SIMULATION_DIR" -maxdepth 1 -type f -name '*.run')
    SEED_FILE=$(find "$SIMULATION_DIR" -maxdepth 1 -type f -name '*.iseed')
    LAST_POS_FILE=$(find "$SIMULATION_DIR" -maxdepth 1 -type f -name '*.last')
    CONFIG_FILE=$(find "$SIMULATION_DIR" -maxdepth 1 -type f -name '*.sy')
    ENERGIES_FILE=$(find "$SIMULATION_DIR" -maxdepth 1 -type f -name '*.en')

    # check if these necessary files exist
    if [[ -z "$RUN_FILE" || -z "$SEED_FILE" || -z "$LAST_POS_FILE" || -z "$CONFIG_FILE" || -z "$ENERGIES_FILE" ]]; then
        echo "Missing required files"
        exit 1
    else
        echo ".run, .iseed, .sy, .last, .en files were found - proceeding"
    fi

    # count the number of backups
    BACKUPS_COUNT=$(find "$SIMULATION_DIR/backups/" -maxdepth 1 -type f -name 'backup*' | wc -l)
    CURRENT_BACKUP_NO=$((BACKUPS_COUNT+1))

    echo "$CURRENT_BACKUP_NO previous backups found" 

    # move the energies file into the backups folder so that it doesn't get overwritten
    ENERGIES_FILE_NAME=$(basename "$ENERGIES_FILE")
    mv "$ENERGIES_FILE" "$SIMULATION_DIR"/backups/backup"$CURRENT_BACKUP_NO"_"$ENERGIES_FILE_NAME"

    # get the total number of blocks from combining all backed up files
    LAST_BLOCK=$(find "$SIMULATION_DIR/backups/" -maxdepth 1 -type f -name 'backup*' -exec tail -n +2 {} \; | wc -l)

    echo "Last block completed was block no. $LAST_BLOCK"
    
    # then, modify the configuration file to ensure that after all restarts, combining all the backed up energies files
    # together gives number of entries equals to TOTAL_BLOCKS
    BLOCKS_REMAINING=$((TOTAL_BLOCKS-LAST_BLOCK))

    echo "$BLOCKS_REMAINING blocks left to simulate"

    sed -i "s/$(grep "PASS" "$CONFIG_FILE")/PASS $BLOCKS_REMAINING $PASSES_PER_BLOCK/" "$CONFIG_FILE"


    sed -i '/^\s*$/d' "$CONFIG_FILE" # first, remove any empty lines in the config file
    grep -qxF 'RESTART' "$CONFIG_FILE" || echo 'RESTART' >> "$CONFIG_FILE" # then add the RESTART directive if not already present

    # restart the simulation
    cd "$SIMULATION_DIR" || exit 1
    echo "$NAME" | ./vpi > "$SIMULATION_DIR/$NAME.out"
    
else
    # checkpoint was not found, start a new simulation
    echo "checkpoint file for simulation $NAME" > "$CHECKPOINT_FILE"
    cd "$SIMULATION_DIR" || exit 1
    echo "$NAME" | ./vpi > "$SIMULATION_DIR/$NAME.out"
fi

# after the simulation is complete, do postprocessing such as concatenating all the energy files together
# postprocess

STATUS=$?
    if ! (exit $STATUS); then
        echo "Simulation did not complete"
    else
        echo "Simulation completed successfully"
        rm "$CHECKPOINT_FILE"
    fi