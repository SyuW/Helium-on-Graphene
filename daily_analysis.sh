#!/bin/bash
# --------------------------------------------
#SBATCH --time=0-00:30:00
#SBATCH --account=def-massimo
#SBATCH --mem=500M
#SBATCH --job-name=daily_analysis
#SBATCH --output=/home/syu7/logs/daily_analysis/daily_analysis_id_%j.out
# --------------------------------------------

# For this to work, the directory structure should be something like:
#   
#   |-- path_to_directory
#       |-- slices_40
#           |-- ensemble
#               |-- run_1
#               |-- run_2
#               |-- ...
#               |-- run_n
#           |-- <other files and directories>
#       |-- ...
#       |-- slices_M
#
# where 'M' is the maximum Trotter number. This would be the case if we're
# studying the dependence on time step, but obviously this would work also if instead
# we're considering dependence on projection time, in which case 'slices' would become
# 'beta' and instead of number of slices we would use the projection time value on the
# other side of the delimiter

# ------------------------------------- #
#          BEGIN FUNCTIONS              #
# ------------------------------------- #

usage () {
    echo "Usage: ./daily_analysis.sh <name of directory>"
    echo "For example, you may use: /home/syu7/scratch/graphene_helium/fixed_optimal_beta_tau_0.0015625"
    echo "or another directory such as: /home/syu7/scratch/graphene_helium/pinning_down_sf_fixed"
    exit 0
}

# ------------------------------------- #
#          END FUNCTIONS                #
# ------------------------------------- #

# create the directory for holding the logs
USER="/home/syu7"
mkdir -p "$USER/logs/daily_analysis"

module load gnuplot
module load scipy-stack

source "$USER/scratch/job_scripts/functions.sh"

# path-to-directory
DIR="$1"

# file meant for holding the extrapolated superfluid fractions vs varying parameter, obtained by fitting
# to S(t) averaged over different runs within ensemble
EXTRAPOLATED="$DIR/extrapolated_sf_fractions"
echo "# parameter  sf_fraction  error" > "$EXTRAPOLATED"

# file meant for holding average energy (kinetic, potential, total) vs varying parameter, obtained by
# averaging energies over different runs within ensemble, and then performing a final block average
ENERGIES="$DIR/energy_dependence"
echo "# parameter kinetic kinetic_err potential potential_err total total_err" > "$ENERGIES"

# -------------------------- #
#    BEGIN FILE COMBINING    #
# -------------------------- #

# iterate over all ensemble directories at the path
find "$DIR" -type d -name "*ensemble" -exec dirname {} \; | awk -F/ '{print $NF}' | sort --field-separator=_ -k 2 -n | while read -r dir
do 
    # 'dir' is the directory representing a specific instance of a parameter
    dir_path="$DIR/$dir/ensemble"
    echo "Processing directory: $dir_path"

    # ------------------------------- #
    #    BEGIN SUPERFLUID FRACTION    #
    # ------------------------------- #

    # first, fit the superfluid fractions for each individual run
    # and output extrapolated superfluid fractions S(\infty) from each run 
    SF_ALL_RUNS="$DIR/$dir/ensemble/sf_all_runs"
    echo "# run sf_fraction error" > "$SF_ALL_RUNS"
    find "$dir_path" -type d -name "run_*" | awk -F/ '{print $NF}' | sort --field-separator=_ -k 2 -n | while read -r run
    do
        run_path=$(find "$dir_path/$run" -type f -name "*.sd")
        echo "Processing directory $run_path"
        RUN_NUM=$(echo "$run" | cut -d '_' -f 2)
        OUTPUT=$(python $USER/scratch/postprocessing/superfluid_fit.py --filename "$run_path" \
                                                                       --throwaway_first \
                                                                       --throwaway_last \
                                                                       --save)
        MODIFIED_OUTPUT=$(echo "$OUTPUT" | awk -v new_val="$RUN_NUM" '{$1 = new_val}1')
        echo "$MODIFIED_OUTPUT" >> "$SF_ALL_RUNS"
    done

    # plot superfluid fractions for different random seeds all onto one plot
    gnuplot -e "directory='$dir_path'" "$USER/scratch/postprocessing/plot_all_sf.p" 

    # average S(t) over different runs within ensemble -- outputs a 'sf_fractions_combined' file
    python $USER/scratch/postprocessing/combine_files_all_runs.py --dirname "$dir_path" --extension ".sd"

    # plot the averaged S(t)
    gnuplot -e "set terminal pngcairo; set output '$dir_path/sf_fractions_combined.png'; \
                plot '$dir_path/sf_fractions_combined' u 1:2:3 w yerr t 'data'"

    # then fit the 'sf_fractions_combined' file and pipe output to extrapolated sf_fractions file
    OUTPUT=$(python $USER/scratch/postprocessing/superfluid_fit.py --filename "$dir_path/sf_fractions_combined" \
                                                                   --throwaway_first \
                                                                   --throwaway_last \
                                                                   --save)

    # Python script outputs the path of the original file as the first field, so we have to extract the value
    # of the parameter from that and change the field to it
    VALUE=$(echo "$dir" | cut -d '_' -f 2)
    MODIFIED_OUTPUT=$(echo "$OUTPUT" | awk -v new_val="$VALUE" '{$1 = new_val}1')

    echo "$MODIFIED_OUTPUT" >> "$EXTRAPOLATED"

    # --------------------------- #
    #   END SUPERFLUID FRACTION   #
    # --------------------------- #

    # --------------------- #
    #   BEGIN ENERGETICS    #
    # --------------------- #

    # average energies over different runs within ensemble -- outputs a 'energies_combined' file
    python $USER/scratch/postprocessing/combine_files_all_runs.py --dirname "$dir_path" --extension ".en"

    # perform a final block average
    # current block size is 20 for binned average, may change in the future
    # if I write a routine to determine the autocorrelation length
    OUTPUT=$(python $USER/scratch/postprocessing/block_average.py --filename "$dir_path/energies_combined" \
                                                                  --throwaway 0 \
                                                                  --block_size 20 \
                                                                  --indices '1,2,3')

    VALUE=$(echo "$dir" | cut -d '_' -f 2)
    MODIFIED_OUTPUT=$(echo "$OUTPUT" | awk -v new_val="$VALUE" '{$1 = new_val}1')

    echo "$MODIFIED_OUTPUT" >> "$ENERGIES"
    
    # --------------------- #
    #   END ENERGETICS      #
    # --------------------- #

done

# ---------------------- #
#   END FILE COMBINING   #
# ---------------------- #

# ---------------------- #
#   BEGIN VISUALIZATION  #
# ---------------------- #

# plot the superfluid fraction curves S(t) for variations in parameter
gnuplot -e "directory='$DIR'" $USER/scratch/postprocessing/plot_sf_curve_variations.p

# plot the extrapolated superfluid fractions S(\infty) for variations in parameter
gnuplot -e "set terminal pngcairo; set output '$EXTRAPOLATED.png'; \
            plot '$EXTRAPOLATED' u 1:2:3 w yerr t 'data'"

# if submitted as a job script, also visualize the files for every run
if [ -n "$SLURM_JOB_ID" ]; then
    echo "Script was submitted as SLURM job, plotting all files"
    find "$DIR" -type d -name "run_*" -exec "$USER/scratch/job_scripts/plot_files.sh" {} \;
fi

# --------------------- #
#   END VISUALIZATION   #
# --------------------- #

