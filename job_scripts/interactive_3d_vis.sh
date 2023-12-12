#!/bin/bash
# --------------------------------------------

usage () {
    echo "Usage: ./interactive_3d_vis.sh <directory-with-vis-file>"
    exit 0
}

user="/home/syu7"
source "$user/scratch/scripts/job_scripts/functions.sh"

filepath=$1

check_argument "$filepath" || usage

basedir=$(dirname "$filepath")

cd "$basedir" || { echo "Cannot change to directory, maybe doesn't exist?" ; exit 1; }
current=$(pwd)
file=$(basename "$filepath")

echo "Attempting 3d visualization of $current/$file"

gnuplot --persist -e "splot '"$current/$file"' w points t 'helium'; \
                      replot '"$current/initial.c.ic"' lt 7 lc 'black' t 'carbon'; \
                      set xlabel 'X' font ',13'; \
                      set ylabel 'Y' font ',13'; \
                      set zlabel 'Z' font ',13'; \
                      set title 'Imaginary time world-lines in 3d: "$file"' font ',13' noenhanced; \
                      pause mouse close"
