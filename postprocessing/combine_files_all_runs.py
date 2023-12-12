import matplotlib.pyplot as plt
import multiprocessing as mp
import numpy as np
import argparse
import datetime
import os
import glob

# from scipy.stats import iqr


"""
Average files (of a given extension) over all runs within ensemble to reduce
errorbars on computed physical quantities
"""


"""
Get a list of files with a particular extension
"""
def find_files_with_extension(directory, pattern):
    search_pattern = os.path.join(directory, pattern)
    file_list = glob.glob(search_pattern, recursive=True)
    return file_list


"""
Get line containing a particular string
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
def combine_sf(dirname, extension, blocksize):
    fractions = []
    errors = []
    if args.verbose:
        print("----------------------------------------------")
        print(f"Combining superfluid files inside {dirname}:")
        print("----------------------------------------------")
    file_list = find_files_with_extension(dirname, pattern=f'**/*{extension}')
    # print(file_list)
    betas_found = False
    for filename in file_list:
        if args.verbose:
            print(f"processing: {filename}")
        data = np.loadtxt(filename)
        if data.any():
            if not betas_found:
                betas = data[:, 0]
                betas_found = True
            fractions.append(data[:, 1])
            errors.append(data[:, 2])
        else:
            continue

    if args.verbose:
        print("Done processing superfluid files, now estimating the standard error in sample mean")

    # stack arrays into the form: row -- time, column -- run
    fraction_array = np.column_stack(fractions)
    error_array = np.column_stack(errors)

    # number of points is equal to number of time slices
    num_points = fraction_array.shape[0]
    # total number of runs in ensemble
    num_runs = fraction_array.shape[1]
    num_blocks = num_runs // blocksize
    # excess = num_runs - num_blocks * blocksize

    # print(fraction_array.shape)

    # block the superfluid fractions and estimate error as standard deviation of blocked values
    block_avg = np.average(fraction_array[:, :num_blocks*blocksize].reshape(num_points, num_blocks, blocksize), axis=-1)

    # blocksize does not divide the number of runs evenly, there will be excess runs for which we have to determine what will happen
    # decide to take the average of the excess runs and then add to pool of blocked values
    if num_runs % blocksize != 0:
        excess_avg = np.average(fraction_array[:, num_blocks*blocksize:], axis=1)
        block_avg = np.column_stack([block_avg, excess_avg])

    # I will figure out at some point what to do with the standard deviations of each block
    # block_std = np.std(fraction_array.reshape(num_points, num_blocks, blocksize), axis=-1)
    avg = np.average(block_avg, axis=1)
    avg_err = np.std(block_avg, axis=1)

    if args.verbose:
        print("Done block averaging superfluid fractions")

    # compare this with the error in the mean superfluid fraction (computed over a sample of `blocksize`) using the central
    # limit theorem
    # blocked_errors = np.sum(error_array.reshape(num_points, num_blocks, blocksize) ** 2, axis=-1)
    # error_in_blocked_mean = np.sqrt(blocked_errors) / blocksize

    if args.plot:

        if args.verbose:
            print("--plot option detected, starting to plot histograms")

        # histograms to see block averaging in action
        slice_index = int(300 * num_points / 640)
        raw_slice = fraction_array[slice_index, :]
        blocked_slice = block_avg[slice_index, :]

        # raw points
        plt.scatter(np.arange(len(raw_slice)), raw_slice)
        plt.axhline(np.mean(raw_slice), label=f"mean: {np.mean(raw_slice)}")
        plt.title(f"beta={betas[-1]}, t={betas[slice_index]}, raw")
        plt.savefig("/home/syu7/scratch/tests/raw_points.png")
        plt.clf() 

        # raw histogram
        _, edges, _ = plt.hist(raw_slice, bins='fd')
        plt.title(f"beta={betas[-1]}, t={betas[slice_index]}, raw")
        plt.savefig("/home/syu7/scratch/tests/raw_hist.png")
        plt.clf()

        # blocked points
        plt.scatter(np.arange(len(blocked_slice)), blocked_slice)
        plt.axhline(np.mean(blocked_slice), label=f"mean: {np.mean(blocked_slice)}")
        plt.title(f"beta={betas[-1]}, t={betas[slice_index]}, {num_blocks} blocks")
        plt.legend()
        plt.savefig("/home/syu7/scratch/tests/blocked_points.png")
        plt.clf()

        # blocked histogram
        plt.hist(blocked_slice, bins='fd')
        plt.title(f"beta={betas[-1]}, t={betas[slice_index]}, {num_blocks} blocks")
        plt.savefig("/home/syu7/scratch/tests/blocked_hist.png")
        plt.clf()

        if args.verbose:
            print("Done plotting histograms")

    # errors_array = np.column_stack(errors)
    # avg = np.average(fraction_array, axis=1)

    # avg_err = np.sqrt(np.sum(errors_array ** 2, axis=1)) / errors_array.shape[1]
    final = np.column_stack([betas, avg, avg_err])

    # save the summed superfluid fractions into a combined file
    save_file = os.path.join(dirname, 'sf_fractions_combined')
    np.savetxt(save_file, final, fmt='%.4e', delimiter='\t', header="block  fraction  error")

    if args.plot:

        if args.verbose:
            print("--plot option detected, starting to plot combined superfluid fractions file")

        max_points = 100
        if num_points > max_points:
            spacing = num_points // max_points
        else:
            spacing = 1
        plt.errorbar(betas[::spacing], avg[::spacing], yerr=avg_err[::spacing],
                     fmt='o', markersize=3, capsize=2, label="data", zorder=1)
        plt.xlabel("Projection time, beta")
        plt.ylabel("Superfluid fraction")
        plt.title(f"beta={betas[-1]}, {num_blocks} blocks, date: {datetime.date.today()}")
        os.makedirs(os.path.join(dirname, "images"), exist_ok=True)
        plt.savefig(os.path.join(dirname, "images", "sf_fractions_combined.png"))

        if args.verbose:
            print("Done plotting combined superfluid fractions file")


"""
Compute a weighted average of the structure factor
"""
def combine_sq(dirname, extension, block):
    structure_factors = []
    weights = []
    if args.verbose:
        print("----------------------------------------------")
        print(f"Combining structure factor files inside {dirname}:")
        print("----------------------------------------------")
    file_list = find_files_with_extension(dirname, f'**/*{extension}')
    for filename in file_list:
        if args.verbose:
            print(f"processing: {filename}")
        data = np.loadtxt(filename)
        # need to sort each file, since .sq files are not necessarily in order
        sorted_indices = np.argsort(data[:, 0])
        wavevectors = data[:, 0][sorted_indices]
        sq = data[:, 1][sorted_indices]
        w = data[:, 2][sorted_indices]
        # now add them to container to be combined before averaging
        structure_factors.append(sq)
        weights.append(w)

    if args.verbose:
        print("Done processing structure factor files, now block averaging")

    # stack arrays into the form: row -- wavevector/weight, column -- run
    structure_factors_array = np.column_stack(structure_factors)
    weights_array = np.column_stack(weights)

    # perform the weighted average
    sq_avg = np.sum(weights_array * structure_factors_array, axis=1) / np.sum(weights_array, axis=1)

    num_points = sq_avg.shape[0]

    final = np.column_stack([wavevectors, sq_avg])

    # save the averaged structure factor into a combined file
    save_file = os.path.join(args.dirname, 'sq_combined')
    np.savetxt(save_file, final, fmt='%.4e', delimiter='\t', header="q  S(q)")

    if args.verbose:
        print("Done block averaging structure factors")

    if args.plot:
        
        if args.verbose:
            print("--plot option detected, starting to plot combined structure factors file")

        max_points = 100
        if num_points > max_points:
            spacing = num_points // max_points
        else:
            spacing = 1
        plt.scatter(wavevectors[::spacing], sq_avg[::spacing], marker='d')
        plt.xlabel("wavevector, q")
        plt.ylabel("structure factor")
        plt.savefig(os.path.join(dirname, "images", "sq_combined.png"))


"""
Average kinetic, potential, total energies as a function of simulation block
"""
def combine_en(dirname, extension, block):
    file_list = find_files_with_extension(dirname, f'**/*{extension}')
    file_list = sorted(file_list, key=lambda s: int([t for t in s.split("/") if "run_" in t][0].split("_")[1]))

    config_file = find_files_with_extension(dirname, f'run_1/*.sy')[0]
    found_line = get_line_containing_string(config_file, "PASS")

    num_of_blocks = int(found_line.split(" ")[-1]) # last field in line is number of blocks

    kinetic_array = np.full((num_of_blocks, len(file_list)), np.nan) # number of blocks by number of files
    potential_array = np.full((num_of_blocks, len(file_list)), np.nan)
    total_array = np.full((num_of_blocks, len(file_list)), np.nan)

    for i, filename in enumerate(file_list):
        data = np.loadtxt(filename)
        found_blocks = len(data[:, 0])
        kinetic_array[:found_blocks, i] = data[:, 1]
        potential_array[:found_blocks, i] = data[:, 2]
        total_array[:found_blocks, i] = data[:, 3]

    # stack the arrays into the form row -- time, column -- run
    # if the simulations haven't completed yet, this nanmean will raise a RuntimeWarning since some
    # rows will be all NaN, that's okay
    kin_avg = np.nanmean(kinetic_array, axis=1)
    pot_avg = np.nanmean(potential_array, axis=1)
    total_avg = np.nanmean(total_array, axis=1)

    # remove entries which are NaN (corresponding to all NaN rows in original array)
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
    parser.add_argument("--blocksize", help="size of block during block averaging", type=int, default=20)
    parser.add_argument("--dirname", help="ensemble directory containing the runs")
    parser.add_argument("--extension", help="common extension of the files you want to combine \
                                             e.g. '.sd' for combining superfluid density files together")
    parser.add_argument("--plot", action="store_true", help="whether to plot the combined file", default=False)
    parser.add_argument("--method", help="select which method to use: [bootstrap, blocking]", default="blocking")
    parser.add_argument("--verbose", action="store_true", help="verbosity level")
    args = parser.parse_args()

    allowed_methods = ["bootstrap", "blocking"]
    if args.method not in allowed_methods:
        raise ValueError(f"Please choose one of: {allowed_methods}")

    allowed_modes = [".sd", ".en", ".sq"]
    if args.extension == ".sd":
        combine_sf(args.dirname, args.extension, args.blocksize)
    elif args.extension == ".en":
        combine_en(args.dirname, args.extension, args.blocksize)
    elif args.extension == ".sq":
        combine_sq(args.dirname, args.extension, args.blocksize)
    else:
        raise ValueError(f"The provided extension is invalid, please choose from {allowed_modes}")