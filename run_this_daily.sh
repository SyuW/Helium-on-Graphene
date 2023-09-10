#!/bin/bash
# --------------------------------------------
#SBATCH --time=0-02:00:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=daily_analysis
#SBATCH --output=/home/syu7/logs/daily_analysis/daily_analysis_id_%j.out
# --------------------------------------------

# Purpose of script:
# Every day I got to run plot_files.sh or daily_analysis.sh
# for different directories containing different experiments,
# so it's convenient have one 'master' script which runs all
# the necessary scripts for all the different directories I'm
# interested in

USER="/home/syu7"
PLOTTING_SCRIPT="$USER/scratch/scripts/job_scripts/plot_files.sh"
DAILY_ANALYSIS_SCRIPT="$USER/scratch/scripts/job_scripts/daily_analysis.sh"

PROJECT="graphene_helium"

# need to change directories first to scratch in order to submit jobs
cd "$USER/scratch" || exit 1

# -------------------------------------------------------- #
#    Structure factor calculation: beta = 1.0, 2.0, 4.0    #
#    at time-step of tau = 0.0015625. Plot all related     #
#    files for these directories.                          #
# -------------------------------------------------------- #

find "$USER/scratch/$PROJECT/structure_factor_study" -maxdepth 1 -name "beta_*" -exec sbatch "$PLOTTING_SCRIPT" {} \;

# ------------------------------------------------------------ #
#   Superfluid fraction calculation: beta = 0.0625, 0.125,     #
#   0.25, 0.5, 1.0, 2.0, 4.0 at time-step of tau = 0.0015625.  #
#   Run daily analysis for this directory, which will do all   #
#   of the ensemble averaging and plotting                     #
# ------------------------------------------------------------ #

sbatch "$DAILY_ANALYSIS_SCRIPT" "$USER/scratch/$PROJECT/fixed_optimal_beta_tau_0.0015625"

# ------------------------------------------------------------ #
#   Superfluid fraction calculation: varying time-steps at     #
#   fixed projection time beta = 0.0525. Trying to assess      #
#   time-step dependence of superfluid fraction. Run daily     #
#   analysis for this directory.                               #
# ------------------------------------------------------------ #

sbatch "$DAILY_ANALYSIS_SCRIPT" "$USER/scratch/$PROJECT/pinning_down_sf_fixed"

# ----------------------------------------------------------- #
#   Assess the superfluid fraction dependence on the time     #
#   step, but for a larger projection time: beta = 0.125.     #
#   Run daily analysis. Structure factor also calculated      #
# ----------------------------------------------------------- #

sbatch "$DAILY_ANALYSIS_SCRIPT" "$USER/scratch/$PROJECT/optimal_time_step_beta_0.125"

# ----------------------------------------------------------- #
#   Assess the superfluid fraction dependence on the time     #
#   step, but for a larger projection time: beta = 0.25.      #
#   Run daily analysis. Structure factor also calculated      #
# ----------------------------------------------------------- #

sbatch "$DAILY_ANALYSIS_SCRIPT" "$USER/scratch/$PROJECT/optimal_time_step_beta_0.25"

# ----------------------------------------------------------- #
#   Assess the superfluid fraction dependence on the time     #
#   step, but for a larger projection time: beta = 0.5.       #
#   Run daily analysis. Structure factor also calculated      #
# ----------------------------------------------------------- #

sbatch "$DAILY_ANALYSIS_SCRIPT" "$USER/scratch/$PROJECT/optimal_time_step_beta_0.5"

# ----------------------------------------------------------- #
#   Assess the superfluid fraction dependence at fixed        #  
#   time-step: 0.00078125 and projection time: 2.0            #
# ----------------------------------------------------------- #

sbatch "$PLOTTING_SCRIPT" "$USER/scratch/$PROJECT/optimal_time_step_beta_2.0/slices_2560"


