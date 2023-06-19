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

do for [fn in system("ls ".dirname)] {

    len=strlen(fn)
    two_letter_suffix=substr(fn,len-2,len)
    three_letter_suffix=substr(fn,len-3,len)
    four_letter_suffix=substr(fn,len-4,len)

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

    # plot the paths of particles
    if (three_letter_suffix eq ".vis") {
        carbon_ic_file = dirname."/initial.c.ic"
        filename=sprintf(output_folder."/%s_vis.png",substr(fn,0,len-4))
        set output filename
        set ylabel "Y"
        set xlabel "X"
        set title "Paths in XY-plane traced by particles in imaginary time"
        plot [-5:40] [-5:35] data u 1:2 t "helium", carbon_ic_file using 1:2 lt 7 lc "black" title "carbon"
        unset output
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