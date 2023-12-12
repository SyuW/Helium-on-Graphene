import argparse
import glob
import os

import numpy as np
# import matplotlib.pyplot as plt


def find_files_with_extension(directory, pattern):
    search_pattern = os.path.join(directory, pattern)
    file_list = glob.glob(search_pattern, recursive=True)
    return file_list


def detect_evap(dirname):

    file_list = find_files_with_extension(dirname, pattern=f'**/*.vis')
    master_array = []
    evaporation = False
    for name in file_list:
        if args.verbose:
            print(f"processing: {name}")
        data = np.loadtxt(name, usecols=2)
        if data[data > 10].size > 0:
            print(f"Evaporation detected in {name}")
            evaporation = True
    if not evaporation:
        print(f"Evaporation not detected in {dirname}")
    else:
        print(f"Evaporation detected in {dirname}!!")

    #     master_array.append(data)

    # save_path = os.path.join(dirname, "images", "all_zhist.png")
    # plt.hist(master_array, bins='fd', density=True)
    # plt.xlabel("Z position", fontsize=13)
    # plt.ylabel("Frequency", fontsize=13)
    # plt.savefig(save_path)

    # return


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dirname", help="ensemble directory containing the runs")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    detect_evap(args.dirname)