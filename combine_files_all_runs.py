import numpy as np
import argparse
import os
import glob


"""
Average files (of a given extension) over all runs within ensemble to reduce
errorbars on computed physical quantities
"""


"""
Get a list of files with a particular extension
"""
def find_files_with_extension(directory, pattern):
    search_pattern = os.path.join(directory, f'{pattern}')
    file_list = glob.glob(search_pattern)
    return file_list


"""
Get line containing a particular strings
"""
def get_line_containing_string(file_path, target_string):
    try:
        with open(file_path, 'r') as file:
            for line in file:
                if target_string in line:
                    return line.strip()  # Return the line without leading/trailing whitespace
    except FileNotFoundError:
        print(f"File '{file_path}' not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

    return None  # Return None if the string is not found or an error occurs


"""
Average superfluid fraction as function of imaginary time S(t)
"""
def combine_sf(dirname, extension):
    fractions = []
    errors = []
    file_list = find_files_with_extension(dirname, f'run_*/*{extension}')
    for filename in file_list:
        with open(filename) as f:
            lines = (line for line in f if not line.startswith('#'))
            data = np.loadtxt(lines)
            betas = data[:, 0]
            fractions.append(data[:, 1])
            errors.append(data[:, 2])
    # stack arrays into the form: row -- time, column -- run
    fraction_array = np.column_stack(fractions)
    errors_array = np.column_stack(errors)
    avg = np.average(fraction_array, axis=1)
    avg_err = np.sqrt(np.sum(errors_array ** 2, axis=1)) / errors_array.shape[1]
    final = np.column_stack([betas, avg, avg_err])

    # save the summed superfluid fractions into a combined file
    save_file = os.path.join(args.dirname, 'sf_fractions_combined')
    np.savetxt(save_file, final, fmt='%.4e', delimiter='\t', header="block  fraction  error")


"""
Average kinetic, potential, total energies as a function of simulation block
"""
def combine_en(dirname, extension):
    file_list = find_files_with_extension(dirname, f'run_*/*{extension}')
    file_list = sorted(file_list, key=lambda s: int([t for t in s.split("/") if "run_" in t][0].split("_")[1]))

    config_file = find_files_with_extension(dirname, f'run_1/*.sy')[0]
    found_line = get_line_containing_string(config_file, "PASS")

    num_of_blocks = int(found_line.split(" ")[-1]) # last field in line is number of blocks

    kinetic_array = np.full((num_of_blocks, len(file_list)), np.nan) # number of blocks by number of files
    potential_array = np.full((num_of_blocks, len(file_list)), np.nan)
    total_array = np.full((num_of_blocks, len(file_list)), np.nan)

    for i, filename in enumerate(file_list):
        with open(filename) as f:
            lines = (line for line in f if not line.startswith('#'))
            data = np.loadtxt(lines)
            found_blocks = len(data[:, 0])
            kinetic_array[:found_blocks, i] = data[:, 1]
            potential_array[:found_blocks, i] = data[:, 2]
            total_array[:found_blocks, i] = data[:, 3]

    # stack the arrays into the form row -- time, column -- run
    kin_avg = np.nanmean(kinetic_array, axis=1)
    pot_avg = np.nanmean(potential_array, axis=1)
    total_avg = np.nanmean(total_array, axis=1)

    kin_avg = kin_avg[~np.isnan(kin_avg)]
    pot_avg = pot_avg[~np.isnan(pot_avg)]
    total_avg = total_avg[~np.isnan(total_avg)]

    max_blocks = len(total_avg)

    final = np.column_stack([np.arange(1,max_blocks+1), kin_avg, pot_avg, total_avg])

    save_file = os.path.join(args.dirname, 'energies_combined')
    np.savetxt(save_file, final, fmt=['%d', '%1.6e', '%1.6e', '%1.6e'], delimiter='\t', 
               header='block     kinetic     potential       total')


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dirname", help="ensemble directory containing the runs")
    parser.add_argument("--extension", help="common extension of the files you want to combine \
                                             e.g. '.sd' for combining superfluid density files together")
    args = parser.parse_args()

    allowed_modes = [".sd", ".en"]
    if args.extension == ".sd":
        combine_sf(args.dirname, args.extension)
    elif args.extension == ".en":
        combine_en(args.dirname, args.extension)
    else:
        raise ValueError(f"The provided extension is invalid, please choose from {allowed_modes}")