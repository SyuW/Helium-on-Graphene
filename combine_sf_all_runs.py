import numpy as np
import matplotlib.pyplot as plt
import argparse
import os
import glob


"""
Average superfluid fraction as function of imaginary time S(t)
over all of the runs in an ensemble in order to reduce error bars 
"""


def find_files_with_extension(directory, pattern):
    search_pattern = os.path.join(directory, f'{pattern}')
    file_list = glob.glob(search_pattern)
    return file_list


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dirname", help="ensemble directory containing the runs")
    args = parser.parse_args()

    fractions = []
    errors = []
    file_list = find_files_with_extension(args.dirname, 'run_*/*.sd')
    for filename in file_list:
        with open(filename) as f:
            lines = (line for line in f if not line.startswith('#'))
            data = np.loadtxt(lines)
            betas = data[:, 0]
            fractions.append(data[:, 1])
            errors.append(data[:, 2])
    
    fraction_array = np.column_stack(fractions)
    errors_array = np.column_stack(errors)

    avg = np.average(fraction_array, axis=1)
    avg_err = np.sqrt(np.sum(errors_array ** 2, axis=1)) / errors_array.shape[1]

    final = np.column_stack([betas, avg, avg_err])

    # save the summed superfluid fractions into a combined file
    save_file = os.path.join(args.dirname, 'sf_fractions_combined')
    np.savetxt(save_file, final, fmt='%.4e', delimiter='\t', header="block  fraction  error")

    # plot the newly created file
    # plt.errorbar(betas, avg, yerr=avg_err, fmt='x', color='purple', capsize=2)
    # plt.savefig(os.path.join(args.dirname, 'sf_fractions_combined.png'))
    # plt.clf()