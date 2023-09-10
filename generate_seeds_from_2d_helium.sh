#!/bin/bash
# --------------------------------------------
#SBATCH --time=0-01:00:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=generate_seeds_from_2d_helium
#SBATCH --output=/home/syu7/logs/generate_seeds_from_2d_helium/generate_seeds_from_2d_helium_id_%j.out
# --------------------------------------------

# ------------------------------- #
#    MAIN BODY OF SCRIPT BEGINS   #
# ------------------------------- #

# module load scipy-stack

USER="/home/syu7"

mkdir -p "$USER/logs/generate_seeds_from_2d_helium"

SOURCEPATH="$USER/PIGS"
PROJECTPATH="$SOURCEPATH/WORK/experiments/2d_helium_experiment"

NUM_SEEDS=100
OUT_DIR="$USER/scratch/random_seeds/seeds_from_2d_helium_2"
SEED_GEN_DIR="$USER/scratch/2d_helium/seed_gen"

mkdir -p "$SEED_GEN_DIR"

SLICES_MULTIPLE=2
BETA_MULTIPLE=0.1

for ((i=1; i<="$NUM_SEEDS"; i++))
do
    NUM_SLICES=$(python -c "print(int($SLICES_MULTIPLE * $i))")
    BETA=$(python -c "print('{:.1f}'.format(0.25 + $BETA_MULTIPLE * $i))")

    echo "slices: $NUM_SLICES, beta: $BETA"

    # create simulation directory for seed number we want to extract
    SEED_NUMBER_DIR="$SEED_GEN_DIR/seed_$i"

done