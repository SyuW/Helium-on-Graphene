import numpy as np
import argparse

def block_average(X, block_size, throw_away):

    # throw away an initial number of datapoints so that remaining are 'equilibrated'
    X = X[throw_away:]

    # want to distribute the data evenly: same number of datapoints per bin
    # so again, throw away the first couple of datapoints if necessary to achieve this
    cutoff = X.shape[0] % block_size
    X = X[cutoff:, 1:]

    kinetic = X[:, 0]
    potential = X[:, 1]
    total = X[:, 2]

    num_blocks = X.shape[0] // block_size

    # block averaging
    block_avged_kinetic = np.mean(kinetic.reshape(num_blocks, block_size), axis=1)
    block_avged_potential = np.mean(potential.reshape(num_blocks, block_size), axis=1)
    block_avged_total = np.mean(total.reshape(num_blocks, block_size), axis=1)

    # simple average over run
    kinetic_avg = np.mean(block_avged_kinetic)
    potential_avg = np.mean(block_avged_potential)
    total_avg = np.mean(block_avged_total)

    # estimated error
    kinetic_error = np.sqrt(np.var(block_avged_kinetic, ddof=1) / num_blocks)
    potential_error = np.sqrt(np.var(block_avged_potential, ddof=1) / num_blocks)
    total_error = np.sqrt(np.var(block_avged_total, ddof=1) / num_blocks)

    output = f'''{'{:.4f}'.format(kinetic_avg)} {'{:.6f}'.format(kinetic_error)} \
                 {'{:.3f}'.format(potential_avg)} {'{:.5f}'.format(potential_error)} \
                 {'{:.3f}'.format(total_avg)} {'{:.6f}'.format(total_error)}'''
    
    print(output)

if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("filename", help="Name of file to be block averaged")
    parser.add_argument("throwaway", help="number of initial datapoints to throw away")
    parser.add_argument("block_size", help="number of datapoints per bin for block average")
    args = parser.parse_args()

    with open(args.filename) as f:
        lines = (line for line in f if not line.startswith('#'))
        data = np.loadtxt(lines)
        print(np.shape(data))

    block_average(data, args.block_size, args.throwaway)