# ---------------------------------------------------------------------- #
#    GNUPLOT SCRIPT FOR PLOTTING OUTPUT FILES FROM QMC SIMULATION        #
# ---------------------------------------------------------------------- #
#
# Guide to command-line arguments for this script:
#   `dirname`: name of directory containing files to be plotted
#   
# As an example, plot using the command:
# $ gnuplot -e "dirname='/home/syu7/scratch/graphene_helium/optimal_time_step/slices_80_run'" plot_files.p
#

output_folder = dirname."/images"

# make directory containing the plots
system("mkdir -p ".output_folder)

# output a .png file
set terminal pngcairo

# binning function (for histograms)
bin(w,x)=w*floor(x/w)+w/2.0

do for [fn in system("ls ".dirname)] {

    len=strlen(fn)
    two_letter_suffix=substr(fn,len-2,len)
    three_letter_suffix=substr(fn,len-3,len)
    four_letter_suffix=substr(fn,len-4,len)
    five_letter_suffix=substr(fn,len-5,len)

    data = sprintf(dirname."/%s",fn)

    # Plot the pair distribution function files
    if (two_letter_suffix eq ".gr") {
        filename=sprintf(output_folder."/%s_g(r).png",substr(fn,0,len-3))
        set output filename
        set xlabel "Distance, r"
        set ylabel "Pair distribution function, g(r)"
        set title "Pair distribution function"
        plot data using 1:2 title "Data"
        unset output
    }

    # Plot the file containing the energies with respect to block
    if (two_letter_suffix eq ".en") {

        # 'Block' x-axis is common to all plots of '*.en' file
        set xlabel "Block"

        # do the kinetic energy
        kinetic_filename=sprintf(output_folder."/%s_kinetic.png",substr(fn,0,len-3))
        set output kinetic_filename
        set ylabel "Kinetic energy per particle"
        set title "Kinetic energy per particle versus block"
        plot data using 1:2 w lines title "data"
        unset output

        # do the potential energy
        potential_filename=sprintf(output_folder."/%s_potential.png",substr(fn,0,len-3))
        set output potential_filename
        set ylabel "Potential energy per particle"
        set title "Potential energy per particle versus block"
        plot data using 1:3 w lines title "data"
        unset output

        # do the total energy
        total_filename=sprintf(output_folder."/%s_total.png",substr(fn,0,len-3))
        set output total_filename
        set ylabel "Total energy per particle"
        set title "Total energy per particle versus block"
        plot data using 1:4 w lines title "data"
        unset output
    }

    # Plot the superfluid density
    if (two_letter_suffix eq ".sd") {
        filename=sprintf(output_folder."/%s_sd.png",substr(fn,0,len-3))
        set output filename
        set ylabel "Superfluid density"
        set xlabel "Projection time"
        set title "Superfluid density as function of projection time"
        plot data u 1:2:3 w yerr title "data"
        unset output
    }

    # plot the structure factor
    if (two_letter_suffix eq ".sq") {
        filename=sprintf(output_folder."/%s_sq.png",substr(fn,0,len-3))
        set output filename
        set ylabel "S(q)"
        set xlabel "Wavevector q"
        set title "Structure factor S(q)"
        plot data u 1:2 w yerr title "data" pt 10
        unset output
    }

    # positions of particles with all periodic images brought back into fundamental domain
    if (three_letter_suffix eq ".vis") {


        carbon_ic_file = dirname."/initial.c.ic"

        # X-Y plane: plot the paths of particles and compare with graphene absorption sites
        filename=sprintf(output_folder."/%s_vis_xy.png",substr(fn,0,len-4))
        set output filename
        set ylabel "Y"
        set xlabel "X"
        set title "Imaginary time world-lines in XY-plane"
        plot data u 1:2 t "helium", carbon_ic_file using 1:2 lt 7 lc "black" title "carbon"
        unset output

        # X-Z plane
        filename=sprintf(output_folder."/%s_vis_xz.png",substr(fn,0,len-4))
        set output filename
        set ylabel "Z"
        set xlabel "X"
        set title "Imaginary time world-lines in XZ-plane"
        plot data u 1:3 t "helium", carbon_ic_file using 1:3 lt 7 lc "black" title "carbon"
        unset output

        # Y-Z plane
        filename=sprintf(output_folder."/%s_vis_yz.png",substr(fn,0,len-4))
        set output filename
        set ylabel "Z"
        set xlabel "Y"
        set title "Imaginary time world-lines in YZ-plane"
        plot data u 2:3 t "helium", carbon_ic_file using 2:3 lt 7 lc "black" title "carbon"
        unset output

        # plot a histogram of the z positions of particles: should be roughly centered about well?
        filename=sprintf(output_folder."/%s_zhist.png",substr(fn,0,len-4))
        stats data using 3 nooutput
        # Freedman-Diaconis rule
        binwidth = 2 * (STATS_up_quartile - STATS_lo_quartile) / (STATS_records) ** (1/3.0)
        binwidth = 0.1
        set output filename
        set xlabel "Z"
        set ylabel "Frequency"
        set title "Histogram of z positions of particles"
        set boxwidth binwidth
        set style fill solid 0.5 # fill style
        plot data using (bin(binwidth,$3)):(1.0/STATS_records) smooth freq with boxes lc "green" notitle
    }


    # Plot the effective mass pseudo-current
    if (four_letter_suffix eq ".mass") {
        filename=sprintf(output_folder."/%s_pseudocurrent.png",substr(fn,0,len-5))
        set output filename
        set xlabel "Projection time"
        set ylabel "Center-of-mass Pseudocurrent"
        set title "Center-of-mass Pseudocurrent as function of projection time"
        plot data using 1:2:3 w yerr title "Data"
        unset output
    }

    # Plot a histogram of the uniform variates generated by random seed
    if (five_letter_suffix eq ".iseed") {
        filename=sprintf(output_folder."/%s_variates.png", substr(fn,0,len-6))
        # use Freedman-Diaconis rule to select the binwidth
        stats data using 1 nooutput
        # Freedman-Diaconis rule
        binwidth = 2 * (STATS_up_quartile - STATS_lo_quartile) / (STATS_records) ** (1/3.0)
        binwidth = 0.1
        set output filename
        set xlabel "Value"
        set ylabel "Frequency"
        set title "Histogram of generated random variates"
        set boxwidth binwidth
        records_to_use = STATS_records - 5
        plot [:] [0:1] data using (bin(binwidth,$1)):(1.0/records_to_use) every ::1::records_to_use smooth freq with boxes notitle
    }

}

# now plot in xy-plane the initial positions of the Helium and Carbon atoms
# carbon_ic_file = dirname."/initial.c.ic"
# helium_ic_file = dirname."/initial.he.ic"
# filename = output_folder."/initial_config.png"
# 
# set output filename
# set title "Initial positions for Helium-graphene system"
# set xlabel "X"
# set ylabel "Y"
# set xrange [-5:40]
# set yrange [-5:40]
# 
# plot carbon_ic_file using 1:2 lt 7 lc "black" title "Carbon", helium_ic_file using 1:2 lt 7 lc "cyan" title "Helium-4"
# 
# unset output
# 
# # now plot in 3d the initial positions of the Helium and Carbon atoms
# filename = output_folder."/3d_initial_config.png"
# set zrange [-5:10]
# set zlabel "Z"
# set title "Initial positions of Helium-graphene system"
# 
# set output filename
# splot carbon_ic_file using 1:2:3 lt 7 lc "black" title "Carbon", helium_ic_file using 1:2:3 lt 7 lc "cyan" title "Helium-4"
# unset output