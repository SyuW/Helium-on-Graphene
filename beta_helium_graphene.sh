#!/bin/bash
# --------------------------------------------
#SBATCH --time=7-00:00:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=tau_he_c
#SBATCH --output=/home/syu7/logs/%u_%x_%j.out
#SBATCH --array=0,1,2,3,4,5       # array indices for accessing different projection times
# -------------------------------------------
echo "Current working directory: `pwd`"
echo "Starting run at: `date`"
# -------------------------------------------
echo ""
echo "Job Array ID / Job ID: $SLURM_ARRAY_JOB_ID / $SLURM_JOB_ID"
echo ""
# -------------------------------------------

USER="/home/syu7"
PROJECT="graphene_helium"
DATAPATH="$USER/scratch/$PROJECT"
SOURCEPATH="$USER/PIGS"
# source path for copying over files necessary for running the simulations
HELIUM_GRAPHENE="$USER/PIGS/WORK/tasks/helium_graphene_experiment"

# find a sufficiently long projection time `beta` for convergence to the ground state energy
# this is the second stage of the process after finding the optimal time step tau
# as before, we calculate the average total energy from simulations with varying projection times
# we then perform an exponential fit of form: E_0 + b*exp(-c*beta) to the (beta, energy) datapoints
# to determine the convergent beta and also extrapolate the system's ground state energy

# use a fixed time step for simulations of varying projection time
TAU=0.0015625
BETAS=( 0.0625 0.125 0.25 0.5 1.0 2.0 )
SLICES_OPTIONS=( 40 80 160 320 640 1280 )

BETA=${BETAS[$SLURM_ARRAY_TASK_ID]}
SLICES=${SLICES_OPTIONS[$SLURM_ARRAY_TASK_ID]}
# base directory for doing the long projection time search procedure
BETA_DIR="long_projection_time_tau_"$TAU""

echo "Running Helium-Graphene simulation with projection time "$BETA" and optimal time-step "$TAU""

# sub-directory corresponding to the projection time used
# contains executable for running simulation and any other files e.g. other executables and any data files
NEW="$DATAPATH/$BETA_DIR/beta_"$BETA""

if [ ! -d "$NEW" ]
then
    echo "Directory "$NEW" doesn't exist. Making new directory."
    mkdir -p $NEW
else
    echo "Directory "$NEW" already exists."
fi

# all following commands depend on changing into the new directory.
# such as creating symlinks and running using vpi 
cd $NEW

# necessary executables for running the simulations/averaging after simulation
ln -s "$SOURCEPATH/source/tools/average" average
ln -s "$SOURCEPATH/source/vpi" vpi

# .ic files with the initial positions of carbon/helium atoms
ln -s "$HELIUM_GRAPHENE/initial.he.ic" initial.he.ic
ln -s "$HELIUM_GRAPHENE/initial.c.ic" initial.c.ic

CONFIG_FILE=$NEW/"beta_"$BETA".sy"

# We should create a new configuration file if one doesn't exist already
# Simulation needs the following configuration file so it knows what parameters to use
if [ ! -f "$CONFIG_FILE" ]; then
    # create the '.sy' configuration file
    BOX="BOX 3 34.079914 29.514072 50"
    HE_TYPE="TYPE he bose 6.0596415 64  initial.he.ic"
    C_TYPE="TYPE c  bose 0         384 initial.c.ic"
    HE_HE_POTL="POTL he he 11 0.2 14.7 50000 SHIFT"
    C_HE_POTL="POTL c  he 1  0.2 14.7 50000 16.25 2.74 SHIFT" 
    JASTROW="JSTR PADE he he 38. 0. 0 1. 0.12 5 0.2 14.7 50000 SHIFT"
    NUM_SLICES="SLICES "$SLICES""
    PROJECTION_TIME="BETA "$BETA""
    NUM_PASSES="PASS 500 500"
    RESTART="RESTART"

    echo "File $CONFIG_FILE not found, making new."
    echo $BOX               >> $CONFIG_FILE
    echo $HE_TYPE           >> $CONFIG_FILE
    echo $C_TYPE            >> $CONFIG_FILE
    echo $HE_HE_POTL        >> $CONFIG_FILE
    echo $C_HE_POTL         >> $CONFIG_FILE
    echo $JASTROW           >> $CONFIG_FILE
    echo $NUM_SLICES        >> $CONFIG_FILE
    echo $PROJECTION_TIME   >> $CONFIG_FILE
    echo $NUM_PASSES        >> $CONFIG_FILE
    # if the random seed file exists, restart the simulation
    # else, the simulations will start from scratch
    # note: you should back up your data files to avoid them being overwritten
    if [ -f "beta_"$BETA".iseed" ] || [ -f "" ]; then
        echo $RESTART           >> $CONFIG_FILE
    fi
else
    echo "File $CONFIG_FILE exists"
fi

# start the simulation
echo "beta_"$BETA"" | ./vpi

# plot the output files
gnuplot -e "dirname='$NEW'" plot_files.p