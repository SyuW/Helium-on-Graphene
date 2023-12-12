# ------------------------------------------------------------------------------- #
#    GNUPLOT SCRIPT FOR PLOTTING ALL STRUCTURE FACTORS FOR PARAMETER VARIATIONS   #
# ------------------------------------------------------------------------------- #
# As an example, plot using the command:
# $ gnuplot -e "directory='path/to/directory/'" plot_sq_curve_variations.p
#
# note: you must provide the full path for the directory of your choice

# output a .png File
set terminal pngcairo

set output directory."/sq_curve_variation.png"

FILES = system("ls ".directory."/*/ensemble/sq_combined")
LABELS = system("ls ".directory."/*/ensemble/sq_combined | xargs -n 1 dirname | xargs -n 1 dirname | xargs -n 1 basename | tr _ -")

set key outside
plot for [i=1:words(FILES)] word(FILES,i) u 1:2 w yerr title word(LABELS, i)

set title "Structure factor vs param variation"

unset output