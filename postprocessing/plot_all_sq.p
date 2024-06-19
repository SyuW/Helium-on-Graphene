# ---------------------------------------------------------------- #
#    GNUPLOT SCRIPT FOR PLOTTING ALL STRUCTURE FACTORS TOGETHER    #
#              FOR DIFFERENT VALUES OF PARAMETER                   #
# ---------------------------------------------------------------- #
#   
# As an example, plot using the command:
# $ gnuplot -e "directory='path/to/directory/'" plot_all_sq.p
#

# output a .png file
set terminal pngcairo

set output directory."/sf_all_runs.png"

FILES = system("ls ".directory."/run_*/*.sq")
LABELS = system("ls ".directory."/run_*/*.sq | xargs dirname | xargs -n 1 basename | tr _ -")

# set xrange[0:1]
# set yrange[0:1.3]
set key outside
plot for [i=1:words(FILES)] word(FILES,i) u 1:2:3 w yerr title word(LABELS, i)

unset output