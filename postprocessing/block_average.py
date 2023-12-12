import numpy as np
import argparse


def compute_average(arr, block_size):

    num_blocks = arr.shape[0] // block_size

    # block averaging
    reshaped = arr.reshape(num_blocks, block_size)
    block_avged = np.mean(reshaped, axis=1)

    # mean and estimated error in mean
    avg = np.mean(block_avged)
    error = np.sqrt(np.var(block_avged, ddof=1) / num_blocks)

    return avg, error


# assumes that the data is two-dimensional
def average_all(X, block_size, throwaway, indices):
    X = X[throwaway:]

    cutoff = X.shape[0] % block_size
    X = X[cutoff:, indices]

    avgs = []
    errs = []
    for col in range(X.shape[1]):
        column = X[:, col]
        avg, err = compute_average(column, block_size)
        avgs.append('{:.4f}'.format(avg))
        errs.append('{:.5f}'.format(err))
    
    output = ""
    for i, a in enumerate(avgs):
        output += f"{a} {errs[i]} "
    
    return output


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("--filename", help="name of file to be block averaged")
    parser.add_argument("--throwaway", help="number of initial datapoints to throw away", type=int)
    parser.add_argument("--block_size", help="number of datapoints per bin for block average", type=int)
    parser.add_argument("--indices", help="indices for accessing the array: pass as string '1,2,3' etc.", type=str)
    parser.add_argument("--include_filename", help="whether to include the filename in the output", action="store_true", default=False)
    args = parser.parse_args()

    data = np.loadtxt(args.filename)

    output = average_all(data, args.block_size, args.throwaway, [int(x) for x in args.indices.split(',')])
    if args.include_filename:
        print(f"{args.filename} {output}")
    else:
        print(f"{output}")