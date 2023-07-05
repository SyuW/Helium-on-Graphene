#!/bin/bash

# combine both files - excluding the first line mind you (which is the header)
# and uniformize the line numbers
combine_files() {
    FILE1=$1
    FILE2=$2
    OUTPUT=$3

    tail -q -n +2 "$FILE1" > "temp.txt"
    tail -q -n +2 "$FILE2" >> "temp.txt"

    FILE_HEADER="# block    kinetic     potential   total"
    echo "$FILE_HEADER" > "temp2.txt"

    awk '{ $1 = NR; print }' "temp.txt" >> "temp2.txt" && mv "temp2.txt" "$OUTPUT"
    rm "temp.txt"
}

# check whether the provided project string is valid (pertains to an existing project)
assert_project () {

    local PROJECT=$1
    local ALLOWED_PROJECTS=( "2d_helium" "graphene_helium" )

    for name in "${ALLOWED_PROJECTS[@]}"; do
        if [ "$PROJECT" = "$name" ]; then
            echo -e "Valid project '$PROJECT' given, continuing\n"
            return
        fi
    done

    echo "Given project '$PROJECT' doesn't exist, aborting"
    exit 1
}

# check whether the provided path contains the necessary files for restarting
check_sim_path() {
  local DIR=$1
  local SEED_FILE
  local LAST_POS_FILE
  local CONFIG_FILE
  local ENERGIES_FILE

  SEED_FILE=$(find "$DIR" -maxdepth 1 -type f -name '*.iseed')
  LAST_POS_FILE=$(find "$DIR" -maxdepth 1 -type f -name '*.last')
  CONFIG_FILE=$(find "$DIR" -maxdepth 1 -type f -name '*.sy')
  ENERGIES_FILE=$(find "$DIR" -maxdepth 1 -type f -name '*.en')

  if [[ -z "$SEED_FILE" || -z "$LAST_POS_FILE" || -z "$CONFIG_FILE" || -z "$ENERGIES_FILE" ]]; then
    echo -e "Missing required files\n"
    exit 1
  else
    echo -e ".run, .iseed, .sy, .last, .en files were found - proceeding\n"
  fi
}

# check that the provided arg is not empty
check_argument() {
    arg="$1"
    if [[ -z "$arg" ]]; then
      echo "Error: Empty argument found!"
      exit 1
    fi
}

# ordering of parameters to config_parser: <path to experiment config file> <path to prod config file> <time slices> <projection time>
config_parser () {

    # parameters
    local EXPERIMENT_CONFIG_FILE=$1              # reference configuration file
    local PRODUCTION_CONFIG_FILE=$2              # configuration file for production run
    local SET_SLICES=$3                          # number of time slices to be set in production config file
    local SET_BETA=$4                            # projection time to be used in production config file

    echo "Path to experiment's configuration given: $EXPERIMENT_CONFIG_FILE"

    # allowed directives
    local DIRECTIVES=( "BOX" "TYPE" "POTL" "JSTR" "QVEC" "SLICES" "BETA" "PASS" )

    # particle species in the simulation
    SPECIES=()
    
    # read every line in the experiment's configuration file, extracting the keyword
    # directives and checking that they are valid. Then, output line-by-line to the
    # production configuration file whilst modifying the 'BETA' and 'SLICES' directives
    # so that they reflect the projection time and number of slices respectively that
    # you want to use 

    # overwrite the old production file to be empty
    truncate -s 0 "$PRODUCTION_CONFIG_FILE"

    # read the experiment's reference configuration file line-by-line
    while IFS="" read -r LINE || [ -n "$LINE" ]; do

        echo "Processing line: $LINE"
        
        # extract the keyword
        local KEYWORD
        KEYWORD=$( echo "$LINE" | awk '{print $1}' )

        if [[ ! " ${DIRECTIVES[*]} " =~ ${KEYWORD} ]]; then
            # keyword is invalid
            echo "Invalid keyword $KEYWORD given in configuration file, aborting"
            rm "$PRODUCTION_CONFIG_FILE"
            exit 1

        elif [ "$KEYWORD" = "BETA" ]; then
            # modify the projection time be what you want
            echo "BETA $SET_BETA" >> "$PRODUCTION_CONFIG_FILE"

        elif [ "$KEYWORD" = "SLICES" ]; then
            # modify the number of time slices to be what you want
            echo "SLICES $SET_SLICES" >> "$PRODUCTION_CONFIG_FILE"

        elif [ "$KEYWORD" = "TYPE" ]; then
            # output the line to production as you would normally do, but
            # also extract the particle species from second word in directive
            SPECIES+=( "$( echo "$LINE" | awk '{print $2}' )" )
            echo "$LINE" >> "$PRODUCTION_CONFIG_FILE"

        else
            # else, just output the line as it is, unchanged
            echo "$LINE" >> "$PRODUCTION_CONFIG_FILE"
        fi

    done < "$EXPERIMENT_CONFIG_FILE"

    echo -e "Finished processing configuration file at: $EXPERIMENT_CONFIG_FILE\n"

    echo -e "Printing out contents of configuration file $PRODUCTION_CONFIG_FILE: "
    cat "$PRODUCTION_CONFIG_FILE"
    echo -e "Finished printing out the contents\n"
}

# Function to check if a string is a float
is_float() {
  # Regex pattern for float
  local float_regex='^[+-]?[0-9]+([.][0-9]+)?$'
  
  # Check if the string matches the float pattern
  if [[ $1 =~ $float_regex ]]; then
    return 0
  else
    return 1
  fi
}
