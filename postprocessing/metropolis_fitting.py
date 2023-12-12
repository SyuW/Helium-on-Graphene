import argparse
import matplotlib.pyplot as plt
import numpy as np
import os
import time
from scipy.optimize import curve_fit
from math import ceil

# custom imports
from fits import *
from bootstrap_fit import select_interval


# check the quality of the final fit using a chi-squared test
def check_fit():
    return


# propose a new value for a fitting parameter as per Metropolis recipe
def displace(p_old, delta_p):
    """
    Metropolis sampling from parameter space

    p_old - old value of parameter
    delta_p - magnitude of parameter displacement

    return:
    p_new - proposed parameter for proceeding to accept stage
    """

    u = rng.random()
    p_new = p_old + (u - 0.5) * delta_p

    return p_new


# metropolis acceptance ratio
def accept(x, y_obs, yerr, prev, trial, fitting_func):
    """
    Metropolis acceptance test

    x - array of values for independent variate
    y_obs - array of values for dependent variate (observed from data)
    yerr - error bars for values of dependent variate
    prev - previous fitting parameters
    trial - trial fitting parameters drawn from proposal distribution
    fitting_func - fitting function for physical property of interest

    return:
    new - new fitting parameters found from Monte Carlo step
    inc - flag for whether move was accepted/rejected: 0 -- rejected, 1 -- accepted
    """

    # x, y_obs, yerr should have the same shape

    y_fit_prev = fitting_func(x, *prev)
    y_fit_trial = fitting_func(x, *trial)

    diff = (y_obs - y_fit_trial) ** 2 - (y_obs - y_fit_prev) ** 2
    accept_ratio = np.exp(-np.sum(diff / (2 * yerr ** 2)))

    if accept_ratio > 1:
        new = trial
        inc = 1
    else:
        u = rng.random()
        if u > trial:
            new = trial
            inc = 1
        else:
            new = prev
            inc = 0

    return new, inc


# main sampling engine for Monte Carlo simulation
def engine(data, total_blocks, total_passes, filetype, savepath):
    """
    Main sampling engine for Metropolis procedure

    total_blocks - total number of Monte Carlo blocks in simulation
    total_passes - total number of passes per block
    filetype - type of data file we are fitting a model towards
    savepath - path for saving output files: checkpoint file, plots, etc..

    return:
    p - optimal fitting parameters
    p_err - errors found for optimal fitting parameters
    """

    x = data[:, 0]
    y = data[:, 1]
    yerr = data[:, 2]

    deltas = {name:1 for name in param_names}       # magnitudes of parameter displacements

    # set the start and end of the domain of x
    start, end = select_interval(x, y, args.domain, args.throwaway_first, args.throwaway_last, args.p_interval)

    # save files
    raw_file = open(savepath + "/raw.param", "w")
    accept_file = open(savepath + "/accept.param", "w")

    raw_header = "# block   " + "   displace    ".join(param_names) + "   displace    \n"
    raw_file.write(raw_header)

    # set the spacing between adjacent datapoints
    if args.max_points:
        if len(x[start:end]) > args.max_points:
            skip = ceil(len(x[start:end]) / args.max_points)
        else:
            skip = args.skip
    else:
        skip = args.skip 

    # load fitting parameters from checkpoint file if available
    if args.restart:
        try:
            params = np.load(savepath + "/checkpoint.npy")
        except Exception as e:
            print("Checkpoint file not found:", e)

    # get fitting parameters using scipy.optimize.curve_fit (just to get started) 
    else:
        params, _ = curve_fit(fitting_func, x[start:end:skip], y[start:end:skip],
                            sigma=yerr[start:end:skip], absolute_sigma=True, bounds=fitting_bounds)

    for _block_ in range(1,total_blocks+1):
        
        # counting successful updates for calculating acceptance rates
        successes = {name:0 for name in param_names}
        attempts = {name:0 for name in param_names} 

        for _pass_ in range(total_passes): # each pass corresponds to single Metropolis update

            # randomly choose a particular parameter to update for a pass
            i = rng.integers(0, 3)

            # proposal step
            proposed = params
            proposed[i] = displace(params[i], deltas[param_names[i]])

            # acceptance step
            params, inc = accept(x, y, yerr, params, proposed, fitting_func)

            # increment based on success/failure of move
            successes[param_names[i]] += inc
            attempts[param_names[i]] += 1

        # write out results to output files
        raw_file.write()


    return params, param_err


if __name__ == "__main__":

    start_time = time.perf_counter()

    parser = argparse.ArgumentParser()
    # simulation options
    parser.add_argument("--blocks", type=int, help="Number of blocks in Monte Carlo simulation", default=500)
    parser.add_argument("--passes", type=int, help="Number of passes per block", default=500)
    parser.add_argument("--restart", action="store_true", help="Restart simulation from a checkpoint", default=False)
    parser.add_argument("--checkpoint_every", type=int, help="Number of blocks in-between saving to checkpoint file", default=10)
    # post-processing options
    parser.add_argument("--filename", help="Name of data file")
    parser.add_argument("--p_interval", help="fit a reduced middle range between the maximum and minimum values: \
                                              defining I = max - min, fit only projection times with s.f. taking values in [min + p*I, max - p*I]",
                                        type=float, default=0)
    parser.add_argument("--domain", help="domain of fit", default="")
    parser.add_argument("--max_points", type=int, help="Maximum number of points to fit: will skip sufficiently many to ensure this", default=1000)
    parser.add_argument("--throwaway_first", action="store_true", help="Throw away entries up until the maximum of curve", default=False)
    parser.add_argument("--throwaway_last", action="store_true", help="Throw away entries beyond minimum of curve", default=False)
    parser.add_argument("--filetype", help=f"Type of file that is being fit to: {ALLOWED_FILETYPES.keys()}", default="sf_time")
    parser.add_argument("--cores", type=int, help="Number of cores to use in multiprocessing", default=4)
    parser.add_argument("--verbose", action="store_true", help="Toggle verbosity level", default=False)
    parser.add_argument("--save", action="store_true", help="Whether or not the save plot/fit param. results to files", default=False)
    args = parser.parse_args()

    verbose = args.verbose

    fitting_func = ALLOWED_FILETYPES[args.filetype]["fit"]
    fit_eqn = ALLOWED_FILETYPES[args.filetype]["fit eqn"]
    x_label = ALLOWED_FILETYPES[args.filetype]["x-label"]
    y_label = ALLOWED_FILETYPES[args.filetype]["y-label"]
    param_names = ALLOWED_FILETYPES[args.filetype]["param names"]
    fitting_bounds = ALLOWED_FILETYPES[args.filetype]["bounds"]

    # input checking
    if args.p_interval < 0 or args.p_interval > 1:
        raise ValueError("value for p interval must be between 0 and 1")

    if args.filetype not in ALLOWED_FILETYPES:
        raise ValueError(f"Please choose one of: {ALLOWED_FILETYPES.keys()}")

    if args.domain:
        domain = [float(pt) for pt in args.domain.split(",")]
        args.domain = domain

    if verbose:
        print("-----------------------------------------------------------------------")
        print(f"Analyzing file @ {args.filename}")
        print("-----------------------------------------------------------------------")

    with open(args.filename) as f:
        lines = (line for line in f if not line.startswith('#'))
        data = np.loadtxt(lines)

    if args.save:
        save = os.path.dirname(args.filename) + "/images/metropolis"
        os.makedirs(save, exist_ok=True)
    else:
        save = ""

    # set random seed for random number generator to ensure reproducibility
    rng = np.random.default_rng(927)

    # start Metropolis estimation of fitting parameter errors
    engine(data, args.blocks, args.passes, args.filetype, save)

    # Estimation complete, print out how long it took
    end_time = time.perf_counter()

    elapsed_time = end_time - start_time

    if verbose:
        print(f"Elapsed simulation time: {elapsed_time:.6f} seconds")
        print("-----------------------------------------------------------------------")