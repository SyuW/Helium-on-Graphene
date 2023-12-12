#!/bin/bash
# --------------------------------------------
#SBATCH --time=0-01:00:00
#SBATCH --account=def-massimo
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=48
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

# For each run directory, fit the superfluid fractions (found in .sd file), outputting
# a plot of the fit as well as a file with the optimal fitting parameters. 
#

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

source "$USER/scratch/scripts/job_scripts/functions.sh"

# path-to-directory
DIR="$1"

check_argument "$DIR" || usage

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

    # count the number of runs in the directory
    NUM_RUNS=$(find "$dir_path" -maxdepth 1 -type d -name "run_*" | wc -l)

    # ------------------------------- #
    #    BEGIN SUPERFLUID FRACTION    #
    # ------------------------------- #

    printf "\n"
    echo "# --------------------------------------------------- #"
    echo "#        Processing Superfluid Fractions              #"
    echo "# --------------------------------------------------- #"
    printf "\n"

    # first, fit the superfluid fractions for each individual run
    # and output extrapolated superfluid fractions S(\infty) from each run

    # SF_ALL_RUNS="$DIR/$dir/ensemble/sf_all_runs"
    # echo "Fitting superfluid fractions for each individual run, and outputting to $SF_ALL_RUNS:"
    # printf "\n"

    # echo "# run sf_fraction error" > "$SF_ALL_RUNS"
    # find "$dir_path" -type d -name "run_*" | awk -F/ '{print $NF}' | sort --field-separator=_ -k 2 -n | while read -r run
    # do
    #     run_path=$(find "$dir_path/$run" -type f -name "*.sd")
    #     echo "Processing superfluid fraction file $run_path"
    #     RUN_NUM=$(echo "$run" | cut -d '_' -f 2)
    #     OUTPUT=$(python $USER/scratch/scripts/postprocessing/bootstrap_fit.py --filename "$run_path" \
    #                                                                            --throwaway_first \
    #                                                                            --throwaway_last \
    #                                                                            --max_points=100 \
    #                                                                            --bootstrap_iterations=100000 \
    #                                                                            --cores="$SLURM_CPUS_PER_TASK" \
    #                                                                            --save \
    #                                                                            --method=bootstrap)
    #     MODIFIED_OUTPUT=$(echo "$OUTPUT" | awk -v new_val="$RUN_NUM" '{$1 = new_val}1')
    #     echo "$MODIFIED_OUTPUT" >> "$SF_ALL_RUNS"
    # done

    # plot superfluid fractions for different random seeds all onto one plot
    # echo "Plotting superfluid fractions for different random seeds all onto one plot:"
    # gnuplot -e "directory='$dir_path'" "$USER/scratch/scripts/postprocessing/plot_all_sf.p" 

    # average S(t) over different runs within ensemble -- outputs a 'sf_fractions_combined' file
    # use ~20 blocks for determining the error via blocking
    NUM_BLOCKS=20
    BLOCK_SIZE=$(python -c "from math import ceil; print(ceil($NUM_RUNS/$NUM_BLOCKS))")
    echo "averaging superfluid fractions over different runs within ensemble > sf_fractions_combined"
    echo "using $NUM_BLOCKS blocks with $BLOCK_SIZE runs per block"
    python $USER/scratch/scripts/postprocessing/combine_files_all_runs.py --blocksize "$BLOCK_SIZE" \
                                                                          --dirname "$dir_path" \
                                                                          --extension ".sd"

    # plot the averaged S(t)
    echo "plotting the averaged superfluid fraction > sf_fractions_combined.png"
    gnuplot -e "set terminal pngcairo; set output '$dir_path/sf_fractions_combined.png'; \
                plot '$dir_path/sf_fractions_combined' u 1:2:3 w yerr t 'data'"

    # then fit the 'sf_fractions_combined' file and pipe output to extrapolated sf_fractions file
    echo "fitting the averaged superfluid fraction"
    OUTPUT=$(python $USER/scratch/scripts/postprocessing/bootstrap_fit.py --filename "$dir_path/sf_fractions_combined" \
                                                                           --throwaway_first \
                                                                           --throwaway_last \
                                                                           --max_points=100 \
                                                                           --bootstrap_iterations=100000 \
                                                                           --cores="$SLURM_CPUS_PER_TASK" \
                                                                           --save \
                                                                           --method=bootstrap)

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

    printf "\n"
    echo "# --------------------------------------------------- #"
    echo "#               Processing Energies                   #"
    echo "# --------------------------------------------------- #"
    printf "\n"

    # average energies over different runs within ensemble -- outputs a 'energies_combined' file
    python $USER/scratch/scripts/postprocessing/combine_files_all_runs.py --dirname "$dir_path" --extension ".en"

    # plot the energies therein
    AVGED_ENERGIES="$dir_path/energies_combined"
    gnuplot -e "set terminal pngcairo; set output '$AVGED_ENERGIES.png'; \
                set xlabel 'Block'; \
                set ylabel 'Total energy (per particle)'; \
                set title 'Averaged total energy'; \
                plot '$AVGED_ENERGIES' u 1:4 w yerr t 'data'"

    # perform a final block average
    # current block size is 20 for binned average, may change in the future
    # if I write a routine to determine the autocorrelation length
    OUTPUT=$(python $USER/scratch/scripts/postprocessing/block_average.py --filename "$dir_path/energies_combined" \
                                                                          --throwaway 0 \
                                                                          --block_size 20 \
                                                                          --indices '1,2,3')

    VALUE=$(echo "$dir" | cut -d '_' -f 2)
    MODIFIED_OUTPUT=$(echo "$OUTPUT" | awk -v new_val="$VALUE" '{$1 = new_val}1')

    echo "$MODIFIED_OUTPUT" >> "$ENERGIES"
    
    # --------------------- #
    #   END ENERGETICS      #
    # --------------------- #

    # ------------------------------- #
    #   BEGIN STRUCTURAL QUANTITIES   #
    # ------------------------------- #

    printf "\n"
    echo "# -------------------------------------------------- #"
    echo "#         Processing Structural Quantities           #"
    echo "# -------------------------------------------------- #"
    printf "\n"

    # try to calculate a weighted average of structure factor
    python $USER/scratch/scripts/postprocessing/combine_files_all_runs.py --dirname "$dir_path" --extension ".sq"

    # plot the structure factor therein
    AVGED_SQ="$dir_path/sq_combined"
    gnuplot -e "set terminal pngcairo; set output '$AVGED_SQ.png'; \
                set title 'Averaged structure factor'; \
                plot '$AVGED_SQ' u 1:2 t 'data' ps 2 pt 10;" \

    # ----------------------------- #
    #   END STRUCTURAL QUANTITIES   #
    # ----------------------------- #

done

# ---------------------- #
#   END FILE COMBINING   #
# ---------------------- #

# ---------------------- #
#   BEGIN VISUALIZATION  #
# ---------------------- #

printf "\n"
echo "# -------------------------------------------------- #"
echo "#               CREATING VISUALIZATIONS              #"
echo "# -------------------------------------------------- #"
printf "\n"

# plot the superfluid fraction curves S(t) for variations in parameter
echo "plotting superfluid fraction curves versus parameter variations"
gnuplot -e "directory='$DIR'" $USER/scratch/scripts/postprocessing/plot_sf_curve_variations.p

# plot the extrapolated superfluid fractions S(\infty) for variations in parameter
echo "plotting extrapolated superfluid fractions versus parameter variations"
gnuplot -e "set terminal pngcairo; set output '$EXTRAPOLATED.png'; \
            set ylabel 'Extrapolated superfluid fraction'; \
            set xlabel 'Parameter'; \
            set title 'Extrapolated superfluid fraction versus parameter variations'; \
            plot '$EXTRAPOLATED' u 1:2:3 w yerr t 'data' pt 7"

# plot the structure factor with respect to parameter variations
echo "Plotting structure factor S(q) versus parameter variations"
gnuplot -e "directory='$DIR'" $USER/scratch/scripts/postprocessing/plot_sq_curve_variations.p

# if submitted as a job script, also visualize the files for every run
echo "creating plots for each and every run"
if [ -n "$SLURM_JOB_ID" ]; then
    echo "Script was submitted as SLURM job, plotting all files"
    find "$DIR" -type d -name "run_*" -exec "$USER/scratch/scripts/job_scripts/plot_files.sh" {} \;
fi

# plot the total energy dependence versus variations in parameter
echo "plotting energy dependence on parameter"
gnuplot -e "set terminal pngcairo; set output '$ENERGIES.png'; \
            set xlabel 'parameter'; \
            set ylabel 'total energy'; \
            set title 'Dependence of total energy on parameter'; \
            plot '$ENERGIES' u 1:6:7 w yerr t 'data' pt 7"

# --------------------- #
#   END VISUALIZATION   #
# --------------------- #

# create a note so that I know when daily analysis was last successfully run start to finish
NOTE="$DIR/daily_analysis_note"
echo "Last daily analysis successfully finished: $(date)" > "$NOTE"

