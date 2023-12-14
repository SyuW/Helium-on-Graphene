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
def check_fit(x, y_obs, yerr, params):
    """
    Check the fit using a chi-squared test

    x - array of independent variates
    y - array of dependent variates (observed from data)
    yerr - error bars for dependent variate
    params - fitting parameters

    return:
    chisq - chi-squared measure of fit
    """
    y_fit = fitting_func(x, *params)

    return np.average((y_obs - y_fit) ** 2 / (yerr ** 2))


# plot the fitting curve on top of data
def plot_fit(x, y_obs, yerr, params, savename):
    """
    Plot the fit on top of the data

    x - array of independent variates
    y - array of dependent variates (observed from data)
    yerr - error bars for dependent variate
    params - fitting parameters
    """
    y_fit = fitting_func(x, *params)

    plt.plot(x, y_fit, zorder=2)
    plt.errorbar(x, y_obs, yerr=yerr, fmt='o', markersize=3,
                           capsize=2, label="data", zorder=1)
    plt.title(f"Fit: {fit_eqn}")
    plt.xlabel(x_label)
    plt.ylabel(y_label)
    plt.savefig(savename)
    plt.clf()


def tune_acceptance(displ, acc_rate):
    """
    Change the max displacement to achieve desired acceptance rate

    displ - displacement value to be updated for chosen parameter
    acc_rate - acceptance rate for moves involving chosen parameter

    return:
    new max displacement
    """
    return displ * 2 * acc_rate + 0.001


# propose a new value for a fitting parameter as per Metropolis recipe
def displace(p_old, delta_p):
    """
    Sample from proposal distribution

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
    exp_arg = np.sum(diff / (2 * yerr ** 2))

    if exp_arg < 0:
        new = trial
        inc = 1
    else:
        accept_ratio = np.exp(-exp_arg)
        u = rng.random()
        if u < accept_ratio:
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

    # set the start and end of the domain of x
    start, end = select_interval(x, y, args.domain, args.throwaway_first,
                                 args.throwaway_last, args.p_interval)

    # set the spacing between adjacent datapoints
    if args.max_points:
        if len(x[start:end]) > args.max_points:
            skip = ceil(len(x[start:end]) / args.max_points)
        else:
            skip = args.skip
    else:
        skip = args.skip

    # apply the modifications to data-points
    x = x[start:end:skip]
    y = y[start:end:skip]
    yerr = yerr[start:end:skip]

    # load fitting parameters from checkpoint file if available
    if args.restart:
        try:
            params = np.load(savepath + "/checkpoint.npy")
        except Exception as e:
            print("Checkpoint file not found:", e)

    # get fitting parameters using scipy.optimize.curve_fit (just to get started) 
    else:
        params, _ = curve_fit(fitting_func, x, y, sigma=yerr, absolute_sigma=True, bounds=fitting_bounds)

    print(f"Initial parameters: {params} with goodness of fit: {check_fit(x, y, yerr, params)}")

    plot_fit(x, y, yerr, params, savepath + "/prior_fit.png")

    # save files
    raw_file = savepath + "/raw.param"
    accept_file = savepath + "/accept.param"
    param_line_writer = lambda params, block, chisq: f"{block}          " + "         ".join([f"{p:.6f}" for p in params]) \
                                                       + f"     {chisq:.6f}\n"

    raw_header = "# block" + " "*6 + (" "*6).join(param_names) + " "*6 + "Chisq\n"
    acc_header = "# block" + " "*6 + "   displace   ".join(param_names) + "   displace   \n"

    # write out the headers for each output file
    with open(raw_file, "w") as rf:
        rf.write(raw_header)

    with open(accept_file, "w") as af:
        af.write(acc_header)

    # initialize master array for holding fitting parameter values after each block
    master_array = np.zeros((total_blocks, len(params)))

    # write checkpoint file every 'x' number of blocks
    write_checkpoint = 50 # set x = 50

    for _block_ in range(0, total_blocks): # results are recorded after each block
        
        # counting successful updates for calculating acceptance rates
        successes = {name:0 for name in param_names}
        attempts = {name:0 for name in param_names} 

        for _pass_ in range(total_passes): # each pass corresponds to single Metropolis update

            # randomly choose a particular parameter to update during a pass
            i = rng.integers(0, 3)

            # proposal step
            proposed = params.copy()
            proposed[i] = displace(params[i], deltas[i])

            # acceptance step
            params, inc = accept(x, y, yerr, params, proposed, fitting_func)

            # increment based on success/failure of move
            successes[param_names[i]] += inc
            attempts[param_names[i]] += 1

        # add the parameters to the master array (for histogramming later)
        master_array[_block_, :] = params

        # compute goodness of fit:
        goodness_of_fit = check_fit(x, y, yerr, params)

        # every block, write fitting parameters to file
        with open(raw_file, "a") as rf:
            rf.write(param_line_writer(params, _block_+1, goodness_of_fit))
        
        # every block, write acceptance rates and displacements to accept file
        with open(accept_file, "a") as af:
            acc_line = [str(_block_+1)]
            for i, name in enumerate(param_names):
                acc_rate = successes[name] / attempts[name]
                disp = deltas[i]
                # write out to file at end of every block
                acc_line.append(f"{acc_rate:.6f}")
                acc_line.append(f"{disp:.6f}")
                # tune the max parameter displacements to achieve desired acceptance rate
                deltas[i] = tune_acceptance(deltas[i], acc_rate)
            af.write("   ".join(acc_line) + "\n")

        if _block_ % write_checkpoint == 0:
            np.save(savepath + "/checkpoint.npy", params) 

    # write the final parameters
    with open(raw_file, "a") as rf:
        rf.write("-"*30)
        rf.write("Final parameter estimates: ")
        for i, name in enumerate(param_names):
            rf.write(f"{name}:   mean: {np.mean(master_array[:, i])}    std: {np.std(master_array[:, i])}")

    # plot the fit at the end of the simulation
    plot_fit(x, y, yerr, params, savepath + "/posterior_fit.png")

    final_params = np.mean(master_array, axis=0)
    final_param_errs = np.std(master_array, axis=0)

    return final_params, final_param_errs


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
    deltas = ALLOWED_FILETYPES[args.filetype]["displacements"]

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
    p, perr = engine(data, args.blocks, args.passes, args.filetype, save)

    # Estimation complete, print out how long it took
    end_time = time.perf_counter()

    elapsed_time = end_time - start_time

    if verbose:
        print(f"Elapsed simulation time: {elapsed_time:.6f} seconds")
        print("-----------------------------------------------------------------------")