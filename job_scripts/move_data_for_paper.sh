#!/bin/bash
# --------------------------------------------
#SBATCH --time=0-01:00:00
#SBATCH --account=def-massimo
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=48
#SBATCH --job-name=move_data_for_paper
#SBATCH --output=/home/syu7/logs/move_data_for_paper/mode_data_for_paper_%j.out
# --------------------------------------------

# create the directory for holding the logs
USER="/home/syu7"
mkdir -p "$USER/logs/daily_analysis"

# module load gnuplot
module load scipy-stack

source "$USER/scratch/scripts/job_scripts/functions.sh"

# base directory for Jupyter notebook analysis
JUPYTER_BASE_DIRECTORY="/home/syu7/graphene_helium_paper/move_data_for_paper"


# # ------------------------------------------------------------------ # #
# # ------------------------------------------------------------------ # #
# # TIME STEP EXTRAPOLATION OF THE SUPERFLUID FRACTION @ BETA = 0.0625 # #
# # ------------------------------------------------------------------ # #
# # ------------------------------------------------------------------ # #

# -------------------------------------------------------
# for extrapolated superfluid fractions versus time step
# -------------------------------------------------------
BETA_0_0625_BASE_PATH="/home/syu7/scratch/graphene_helium/beta_0.0625_slices_40,80,160,320_big_ensemble"
BETA_0_0625_SLICES_40_PATH="$BETA_0_0625_BASE_PATH/slices_40/ensemble"      # have 100 runs
BETA_0_0625_SLICES_80_PATH="$BETA_0_0625_BASE_PATH/slices_80/ensemble"      # have 100 runs
BETA_0_0625_SLICES_160_PATH="$BETA_0_0625_BASE_PATH/slices_160/ensemble"    # have 100 runs
BETA_0_0625_SLICES_320_PATH="$BETA_0_0625_BASE_PATH/slices_320/ensemble"    # have 100 runs
# beta = 0.0625, 640 time slices run is in a different base directory
BETA_0_0625_SLICES_640_PATH="/home/syu7/scratch/graphene_helium/beta_0.0625_slices_640_big_ensemble/slices_640/ensemble" # have 100 runs

# 
BETA_0_25_BASE_PATH="/home/syu7/scratch/graphene_helium/finished/optimal_time_step_beta_0.25"
BETA_0_25_SLICES_40_PATH="$BETA_0_25_BASE_PATH/slices_40/ensemble"                                         # have 20 runs
BETA_0_25_SLICES_80_PATH="$BETA_0_25_BASE_PATH/slices_80/ensemble"                                         # have 20 runs
BETA_0_25_SLICES_160_PATH="$BETA_0_25_BASE_PATH/slices_160/ensemble"                                       # have 20 runs
BETA_0_25_SLICES_320_PATH="$BETA_0_25_BASE_PATH/slices_320/ensemble"                                       # have 20 runs
BETA_0_25_SLICES_640_PATH="$BETA_0_25_BASE_PATH/slices_640/ensemble"                                       # have 20 runs
BETA_0_25_SLICES_1280_PATH="/home/syu7/scratch/graphene_helium/beta_0.25_slices_1280/slices_1280/ensemble" # have 100 runs

# -------------------------------------------------------------------------------------------------------
# block averaging superfluid files together, 20 blocks in total amongs 100 total runs -> 5 runs per block
# -------------------------------------------------------------------------------------------------------

# # beta = 0.0625, 40 time slices
# python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
# --dirname="$BETA_0_0625_SLICES_40_PATH" \
# --extension=.sd \
# --blocksize=5 \
# --plot \
# --verbose

# # beta = 0.0625, 80 time slices
# python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
# --dirname="$BETA_0_0625_SLICES_80_PATH" \
# --extension=.sd \
# --blocksize=5 \
# --plot \
# --verbose

# # beta = 0.0625, 160 time slices
# python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
# --dirname="$BETA_0_0625_SLICES_160_PATH" \
# --extension=.sd \
# --blocksize=5 \
# --plot \
# --verbose

# # beta = 0.0625, 320 time slices
# python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
# --dirname="$BETA_0_0625_SLICES_320_PATH" \
# --extension=.sd \
# --blocksize=5 \
# --plot \
# --verbose

# # beta = 0.0625, 640 time slices
# python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
# --dirname="$BETA_0_0625_SLICES_640_PATH" \
# --extension=.sd \
# --blocksize=5 \
# --plot \
# --verbose

# beta = 0.25, 40 time slices
python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
--dirname="$BETA_0_25_SLICES_40_PATH" \
--extension=.sd \
--blocksize=3 \
--plot \
--verbose

# beta = 0.25, 80 time slices
python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
--dirname="$BETA_0_25_SLICES_80_PATH" \
--extension=.sd \
--blocksize=3 \
--plot \
--verbose

# beta = 0.25, 160 time slices
python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
--dirname="$BETA_0_25_SLICES_160_PATH" \
--extension=.sd \
--blocksize=3 \
--plot \
--verbose

# beta = 0.25, 320 time slices
python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
--dirname="$BETA_0_25_SLICES_320_PATH" \
--extension=.sd \
--blocksize=3 \
--plot \
--verbose

# beta = 0.25, 640 time slices
python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
--dirname="$BETA_0_25_SLICES_640_PATH" \
--extension=.sd \
--blocksize=3 \
--plot \
--verbose

# beta = 0.25, 1280 time slices
python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
--dirname="$BETA_0_25_SLICES_1280_PATH" \
--extension=.sd \
--blocksize=5 \
--plot \
--verbose

# # -----------------------------
# # now begin superfluid fitting
# # -----------------------------

# # beta = 0.0625, 40 time slices
# python /home/syu7/scratch/scripts/postprocessing/bootstrap_fit.py \
# --filename="$BETA_0_0625_SLICES_40_PATH/sf_fractions_combined" \
# --save \
# --bootstrap_iterations=1000000 \
# --verbose \
# --p_interval=0.2 \
# --cores=48 \
# --max_points=100 \
# --method=bootstrap

# # beta = 0.0625, 80 time slices
# python /home/syu7/scratch/scripts/postprocessing/bootstrap_fit.py \
# --filename="$BETA_0_0625_SLICES_80_PATH/sf_fractions_combined" \
# --save \
# --bootstrap_iterations=1000000 \
# --verbose \
# --p_interval=0.2 \
# --cores=48 \
# --max_points=100 \
# --method=bootstrap

# # beta = 0.0625, 160 time slices
# python /home/syu7/scratch/scripts/postprocessing/bootstrap_fit.py \
# --filename="$BETA_0_0625_SLICES_160_PATH/sf_fractions_combined" \
# --save \
# --bootstrap_iterations=1000000 \
# --verbose \
# --p_interval=0.2 \
# --cores=48 \
# --max_points=100 \
# --method=bootstrap

# # beta = 0.0625, 320 time slices
# python /home/syu7/scratch/scripts/postprocessing/bootstrap_fit.py \
# --filename="$BETA_0_0625_SLICES_320_PATH/sf_fractions_combined" \
# --save \
# --bootstrap_iterations=1000000 \
# --verbose \
# --p_interval=0.2 \
# --cores=48 \
# --max_points=100 \
# --method=bootstrap

# # beta = 0.0625, 640 time slices
# python /home/syu7/scratch/scripts/postprocessing/bootstrap_fit.py \
# --filename="$BETA_0_0625_SLICES_640_PATH/sf_fractions_combined" \
# --save \
# --bootstrap_iterations=1000000 \
# --verbose \
# --p_interval=0.2 \
# --cores=48 \
# --max_points=100 \
# --method=bootstrap

# beta = 0.25, 40 time slices
python /home/syu7/scratch/scripts/postprocessing/bootstrap_fit.py \
--filename="$BETA_0_25_SLICES_40_PATH/sf_fractions_combined" \
--save \
--bootstrap_iterations=1000000 \
--verbose \
--p_interval=0.25 \
--cores=48 \
--max_points=100 \
--method=bootstrap

# beta = 0.25, 80 time slices
python /home/syu7/scratch/scripts/postprocessing/bootstrap_fit.py \
--filename="$BETA_0_25_SLICES_80_PATH/sf_fractions_combined" \
--save \
--bootstrap_iterations=1000000 \
--verbose \
--p_interval=0.25 \
--cores=48 \
--max_points=100 \
--method=bootstrap

# beta = 0.25, 160 time slices
python /home/syu7/scratch/scripts/postprocessing/bootstrap_fit.py \
--filename="$BETA_0_25_SLICES_160_PATH/sf_fractions_combined" \
--save \
--bootstrap_iterations=1000000 \
--verbose \
--p_interval=0.25 \
--cores=48 \
--max_points=100 \
--method=bootstrap

# beta = 0.25, 320 time slices
python /home/syu7/scratch/scripts/postprocessing/bootstrap_fit.py \
--filename="$BETA_0_25_SLICES_320_PATH/sf_fractions_combined" \
--save \
--bootstrap_iterations=1000000 \
--verbose \
--p_interval=0.25 \
--cores=48 \
--max_points=100 \
--method=bootstrap

# beta = 0.25, 640 time slices
python /home/syu7/scratch/scripts/postprocessing/bootstrap_fit.py \
--filename="$BETA_0_25_SLICES_640_PATH/sf_fractions_combined" \
--save \
--bootstrap_iterations=1000000 \
--verbose \
--p_interval=0.25 \
--cores=48 \
--max_points=100 \
--method=bootstrap

# beta = 0.25, 1280 time slices
python /home/syu7/scratch/scripts/postprocessing/bootstrap_fit.py \
--filename="$BETA_0_25_SLICES_1280_PATH/sf_fractions_combined" \
--save \
--bootstrap_iterations=1000000 \
--verbose \
--p_interval=0.25 \
--cores=48 \
--max_points=100 \
--method=bootstrap


# # print the estimated superfluid fractions
# find "$BETA_0_0625_BASE_PATH" -name "sd_fit_params.txt" -exec echo "$1" \; -a -exec grep "C" "{}" \;

# # ---------------------------------------------------------------------- # #
# # ---------------------------------------------------------------------- # #
# # END TIME STEP EXTRAPOLATION OF THE SUPERFLUID FRACTION @ BETA = 0.0625 # #
# # ---------------------------------------------------------------------- # #
# # ---------------------------------------------------------------------- # #

# beta = 0.0625, 40 time slices
python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
--dirname="$BETA_0_0625_SLICES_40_PATH" \
--extension=.en \
--plot \
--verbose

# beta = 0.0625, 80 time slices
python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
--dirname="$BETA_0_0625_SLICES_80_PATH" \
--extension=.en \
--plot \
--verbose

# beta = 0.0625, 160 time slices
python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
--dirname="$BETA_0_0625_SLICES_160_PATH" \
--extension=.en \
--plot \
--verbose

# beta = 0.0625, 320 time slices
python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
--dirname="$BETA_0_0625_SLICES_320_PATH" \
--extension=.en \
--plot \
--verbose

# beta = 0.0625, 640 time slices
python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
--dirname="$BETA_0_0625_SLICES_640_PATH" \
--extension=.en \
--plot \
--verbose

# # ---------------------------------------------------------------------------- # #
# # ---------------------------------------------------------------------------- # #
# # TIME STEP EXTRAPOLATION OF GROUND STATE ENERGY PER PARTICLE @ BETA = 0.0625  # #
# # ---------------------------------------------------------------------------- # #
# # ---------------------------------------------------------------------------- # #



# # -------------------------------------------------------------------------------  # #
# # -------------------------------------------------------------------------------  # #
# # END TIME STEP EXTRAPOLATION OF GROUND STATE ENERGY PER PARTICLE @ BETA = 0.0625  # #
# # -------------------------------------------------------------------------------  # #
# # -------------------------------------------------------------------------------  # #

# # ------------------------------------------------------------------------- # #
# # ------------------------------------------------------------------------- # #
# # PROJECTION TIME EXTRAPOLATION OF THE SUPERFLUID FRACTION @ TAU = 0.015625 # #
# # ------------------------------------------------------------------------- # #
# # ------------------------------------------------------------------------- # #

BETA_0_5_SF_PATH="/home/syu7/scratch/graphene_helium/beta_0.5_tau_0.0015625/beta_0.5/ensemble" # have 100 runs
SF_VERSUS_BETA_1_2_4_BASE_PATH="/home/syu7/scratch/graphene_helium/beta_1.0,2.0,4.0_tau_0.0015625"
BETA_1_SF_PATH="$SF_VERSUS_BETA_1_2_4_BASE_PATH/beta_1.0/ensemble"             # have 100 runs 
BETA_2_SF_PATH="$SF_VERSUS_BETA_1_2_4_BASE_PATH/beta_2.0/ensemble"             # have 100 runs
BETA_4_SF_PATH_1="$SF_VERSUS_BETA_1_2_4_BASE_PATH/beta_4.0/ensemble"           # have 100 runs
BETA_4_SF_PATH_2="/home/syu7/scratch/graphene_helium/beta_1.0,2.0,4.0_tau_0.0015625_copy_2/beta_4.0/ensemble" # have 100 runs

# -------------------------------------------------------------------------------------------------------
# block averaging superfluid files together, 20 blocks in total amongs 100 total runs -> 5 runs per block
# -------------------------------------------------------------------------------------------------------

# beta = 0.5, 320 time slices
python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
--dirname="$BETA_0_5_SF_PATH" \
--extension=.sd \
--blocksize=5 \
--plot \
--verbose

# beta = 1.0, 640 time slices
python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
--dirname="$BETA_1_SF_PATH" \
--extension=.sd \
--blocksize=5 \
--plot \
--verbose

# beta = 2.0, 1280 time slices
python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
--dirname="$BETA_2_SF_PATH" \
--extension=.sd \
--blocksize=5 \
--plot \
--verbose

# beta = 4.0, 2560 time slices: first run
python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
--dirname="$BETA_4_SF_PATH" \
--extension=.sd \
--blocksize=5 \
--plot \
--verbose

# beta = 4.0, 2560 time slices: second run
python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py \
--dirname="$BETA_4_SF_PATH_2" \
--extension=.sd \
--blocksize=5 \
--plot \
--verbose

# -----------------------------
# now begin superfluid fitting
# -----------------------------

# beta = 0.5, 320 time slices
python /home/syu7/scratch/scripts/postprocessing/bootstrap_fit.py \
--filename="$BETA_0_5_SF_PATH/sf_fractions_combined" \
--save \
--bootstrap_iterations=1000000 \
--verbose \
--throwaway_first \
--throwaway_last \
--cores=48 \
--max_points=100 \
--method=bootstrap

# beta = 1.0, 640 time slices
python /home/syu7/scratch/scripts/postprocessing/bootstrap_fit.py \
--filename="$BETA_1_SF_PATH/sf_fractions_combined" \
--save \
--bootstrap_iterations=1000000 \
--verbose \
--throwaway_first \
--throwaway_last \
--cores=48 \
--max_points=100 \
--method=bootstrap

# beta = 2.0, 1280 time slices
python /home/syu7/scratch/scripts/postprocessing/bootstrap_fit.py \
--filename="$BETA_2_SF_PATH/sf_fractions_combined" \
--save \
--save_histogram \
--bootstrap_iterations=1000000 \
--verbose \
--throwaway_first \
--throwaway_last \
--cores=48 \
--max_points=100 \
--method=bootstrap

# beta = 4.0, 2560 time slices: first run
python /home/syu7/scratch/scripts/postprocessing/bootstrap_fit.py \
--filename="$BETA_4_SF_PATH_1/sf_fractions_combined" \
--save \
--save_histogram \
--bootstrap_iterations=1000000 \
--verbose \
--throwaway_first \
--throwaway_last \
--cores=48 \
--max_points=100 \
--method=bootstrap

# beta = 4.0, 2560 time slices: second run
python /home/syu7/scratch/scripts/postprocessing/bootstrap_fit.py \
--filename="$BETA_4_SF_PATH_2/sf_fractions_combined" \
--save \
--save_histogram \
--bootstrap_iterations=1000000 \
--verbose \
--throwaway_first \
--throwaway_last \
--cores=48 \
--max_points=100 \
--method=bootstrap


# # ----------------------------------------------------------------------------- # #
# # ----------------------------------------------------------------------------- # #
# # END PROJECTION TIME EXTRAPOLATION OF THE SUPERFLUID FRACTION @ TAU = 0.015625 # #
# # ----------------------------------------------------------------------------- # #
# # ----------------------------------------------------------------------------- # #

# -----------------
# structure factors
# -----------------
# BETA_0_125_SQ_DIR="/home/syu7/scratch/graphene_helium/optimal_time_step_beta_0.125/slices_80/ensemble/sq_combined" 
# BETA_0_25_SQ_DIR="/home/syu7/scratch/graphene_helium/optimal_time_step_beta_0.25/slices_160/ensemble/sq_combined"
# BETA_0_5_SQ_DIR="/home/syu7/scratch/graphene_helium/optimal_time_step_beta_0.5/slices_320/ensemble/sq_combined"
# BETA_1_SQ_DIR="/home/syu7/scratch/graphene_helium/bulk_averaging/beta_1.0/sq_combined"
# python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py --dirname=BETA_0_125_SQ_DIR --extension=.sq --plot
# python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py --dirname=BETA_0_25_SQ_DIR --extension=.sq --plot
# python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py --dirname=BETA_0_5_SQ_DIR --extension=.sq --plot
# python /home/syu7/scratch/scripts/postprocessing/combine_files_all_runs.py --dirname=BETA_1_SQ_DIR --extension=.sq --plot
# -----------------

