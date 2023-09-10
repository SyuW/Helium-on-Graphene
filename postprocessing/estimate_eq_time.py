import numpy as np
import matplotlib.pyplot as plt

# Attempt at determining the equilibration time by using a moving average

def moving_average(w, x):
    return np.convolve(x, np.ones(w), 'valid') / w

def moving_rmsd(w, x):
    ma = moving_average(w, x)
    prefactor = 1/(w-1)
    moving_rmsd = []
    for i in range(len(x)-w):
        data = x[i:i+w]
        moving_rmsd.append(np.std(data, ddof=1))

    return np.array(moving_rmsd)


if __name__ == "__main__":
    # Enter the name of the file to be averaged
    # e.g. a file containing energies with respect to Monte Carlo block
    # example of file:
    # input_file = input("Enter a file for estimation to be done: ")
    input_file = "/home/syu7/scratch/graphene_helium/optimal_time_step/slices_160_run/slices_160.he.en"

    with open(input_file) as f:
        lines = (line for line in f if not line.startswith('#'))
        energy_data = np.loadtxt(lines)

    total_energies = energy_data[:,-1]

    # first order moving root mean square deviation
    ma = moving_average(40, total_energies)
    mrmsd = moving_rmsd(40, total_energies)

    # second order moving root mean square deviation
    second_mrmsd = moving_rmsd(20, mrmsd)

    pass

