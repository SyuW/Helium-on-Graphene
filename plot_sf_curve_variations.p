# ------------------------------------------------------------------------------------------- #
#    GNUPLOT SCRIPT FOR PLOTTING ALL SUPERFLUID FRACTIONS FOR VARIATIONS OF PARAMETER CHOICE  #
# ------------------------------------------------------------------------------------------- #
#   
# As an example, plot using the command:
# $ gnuplot -e "directory='path/to/directory/'" plot_all_sf.p
#
# note: you must provide the full path for the directory of your choice

# output a .png file
set terminal pngcairo

set output directory."/sf_curve_variation.png"

FILES = system("ls ".directory."/*/ensemble/sf_fractions_combined")
LABELS = system("ls ".directory."/*/ensemble/sf_fractions_combined | xargs -n 1 dirname | xargs -n 1 dirname | xargs -n 1 basename | tr _ -")

set key outside
plot for [i=1:words(FILES)] word(FILES,i) u 1:2:3 w yerr title word(LABELS, i)

unset output