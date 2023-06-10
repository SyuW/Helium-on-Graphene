#!/bin/bash
# --------------------------------------------
#SBATCH --time=7-00:00:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=tau_he_c
#SBATCH --output=/home/syu7/logs/%u_%x_%j.out
#SBATCH --array=40,80,160,320,640,1280       # Enter the time slices you want to examine here
# -------------------------------------------
echo "Current working directory: `pwd`"
echo "Starting run at: `date`"
# -------------------------------------------
echo ""
echo "Job Array ID / Job ID: $SLURM_ARRAY_JOB_ID / $SLURM_JOB_ID"
echo "Running Helium-Graphene simulation with "$SLURM_ARRAY_TASK_ID" time slices"
echo ""
# -------------------------------------------

USER="/home/syu7"
DATAPATH="$USER/scratch/graphene_helium"
SOURCEPATH="$USER/PIGS"
HELIUM_GRAPHENE="$USER/PIGS/WORK/tasks/helium_graphene_experiment"

echo "Writing data to $DATAPATH"

# find the optimal timestep for this system: ground state energy per particle
# versus number of time slices used, denote tau = beta / time_slices as the imaginary time-step
# then try to do a quartic fit on data points: a + b*tau*x^4

BETA=0.0625

# base directory for doing the optimal timestep search procedure
TIMESTEP_DIR="optimal_time_step_beta_"${BETA}""

NUM_TIME_SLICES=$SLURM_ARRAY_TASK_ID

# sub-directory corresponding to number of time slices used in simulations
# contains executable for running simulation and any other files e.g. other executables and any data files
NEW="$DATAPATH/$TIMESTEP_DIR/slices_"${NUM_TIME_SLICES}""

if [ ! -d "$NEW" ]
then
    echo "Directory "$NEW" doesn't exist. Making new directory."
    mkdir -p $NEW
else
    echo "Directory "$NEW" already exists."
fi

# all following commands depend on changing into the new directory 
cd $NEW

# necessary executables for running the simulations/averaging after simulation
ln -s "$SOURCEPATH/source/tools/average" average
ln -s "$SOURCEPATH/source/vpi" vpi

# .ic files with the initial positions of carbon/helium atoms
ln -s "$HELIUM_GRAPHENE/initial.he.ic" initial.he.ic
ln -s "$HELIUM_GRAPHENE/initial.c.ic" initial.c.ic

CONFIG_FILENAME=$NEW/"slices_"${NUM_TIME_SLICES}".sy"

# We should create a new configuration file if one doesn't exist already
# Simulation needs the following configuration file so it knows what parameters to use
if [ ! -f "$CONFIG_FILENAME" ]
then
    # create the '.sy' configuration file
    BOX="BOX 3 34.079914 29.514072 50"
    HE_TYPE="TYPE he bose 6.0596415 64  initial.he.ic"
    C_TYPE="TYPE c  bose 0         384 initial.c.ic"
    HE_HE_POTL="POTL he he 11 0.2 14.7 50000 SHIFT"
    C_HE_POTL="POTL c  he 1  0.2 14.7 50000 16.25 2.74 SHIFT" 
    JASTROW="JSTR PADE he he 38. 0. 0 1. 0.12 5 0.2 14.7 50000 SHIFT"
    NUM_SLICES="SLICES "${SLURM_ARRAY_TASK_ID}""
    PROJECTION_TIME="BETA "${BETA}""
    NUM_PASSES="PASS 500 500"
    RESTART="restart"

    echo "File $CONFIG_FILENAME not found, making new."
    echo $BOX               >> $CONFIG_FILENAME
    echo $HE_TYPE           >> $CONFIG_FILENAME
    echo $C_TYPE            >> $CONFIG_FILENAME
    echo $HE_HE_POTL        >> $CONFIG_FILENAME
    echo $C_HE_POTL         >> $CONFIG_FILENAME
    echo $JASTROW           >> $CONFIG_FILENAME
    echo $NUM_SLICES        >> $CONFIG_FILENAME
    echo $PROJECTION_TIME   >> $CONFIG_FILENAME
    echo $NUM_PASSES        >> $CONFIG_FILENAME
    # if the random seed file exists, restart the simulation
    # else, the simulations will start from scratch
    # note: you should back up your data files to avoid them being overwritten
    if [ -f "slices_"${SLURM_ARRAY_TASK_ID}".iseed" ]
    then
    echo $RESTART           >> $CONFIG_FILENAME
    fi
else
    echo "File $CONFIG_FILENAME exists"
fi

# start the simulation
echo "slices_"${NUM_TIME_SLICES}"" | ./vpi

# plot the output files
gnuplot -e "dirname='$NEW'" plot_files.p
