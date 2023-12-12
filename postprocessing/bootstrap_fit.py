import argparse
import os
import sys
import time
import numpy as np
import matplotlib.pyplot as plt
import multiprocessing as mp
from fits import *
from math import ceil
from scipy.optimize import curve_fit
from scipy import stats


"""
Select the imaginary time interval on which the fitting will be done:
only for superfluid fraction
"""
def select_interval(x, y, domain, throwaway_first, throwaway_last, p_interval):
    """
    x - array of values for independent variate
    y - array of values for dependent variate
    domain - manually provided start and end points
    throwaway_first - whether to throw away points before first max
    throwaway_last - whether to throw away points after last min
    p_interval - number in [0, 1] telling what percentage of points on [start, end] to throw away
    """

    start = 0
    end = len(x)-1

    if throwaway_first:
        start = np.argmax(y)
        
    if throwaway_last:
        end = np.argmin(y)

    # manually setting the endpoints overrides throwaway_first and throwaway_last
    if domain:
        a, b = domain
        start = np.argmin(np.abs(x - a))
        end = np.argmin(np.abs(x - b))

    # start, end is altered if throwaway_first, throwaway_last, or domain options specified
    elif p_interval:

        a = x[start]
        b = x[end]

        delta = np.abs(b - a)

        new_a = a + p_interval * delta / 2
        new_b = b - p_interval * delta / 2

        # get the index of closest x value to p_interval cutoff
        start = np.argmin(np.abs(x - new_a))
        end = np.argmin(np.abs(x - new_b))

    return start, end


"""
Function for fitting a batch of bootstrap iterations
"""
def process_batch(fitting_func, iterations, seed, x, y, yerr, guess, fitting_bounds):
    rng = np.random.default_rng(seed)
    generated_params = np.zeros((iterations, 3))
    for i in range(iterations):
        resampled_y = rng.normal(size=y.size, loc=y, scale=yerr)
        popt, _ = curve_fit(fitting_func, x, resampled_y, p0=guess,
                            bounds=fitting_bounds)
        generated_params[i, :] = popt
    
    if verbose:
        print(f"Batch of {iterations} bootstrap iterations finished")

    return generated_params


"""
Fit using the bootstrap method (with multiprocessing)
"""
def fit_with_bootstrap(fitting_func, x, y, yerr, start, end, skip, guess, total_iterations, cores, fitting_bounds):
    """
    x - array of values for independent variate 
    y - array of values for dependent variate
    yerr - errors for dependent variate
    start - array index to begin fitting
    end - array index to end fitting
    skip - number of points to skip between `start` and `end` when fitting
    guess - initial params to use for fitting
    total_iterations - total number of bootstrap iterations to perform
    cores - number of cores to use for multiprocessing
    filetype - type of file we are fitting to
    """

    if verbose:
        start_time = time.perf_counter()

    if not cores:
        cores = int(os.environ.get('SLURM_CPUS_PER_TASK', default=1))
    if verbose:
        print(f"using {cores} cores")

    # use multiprocessing
    pool = mp.Pool(processes=cores)

    iterations_per_batch = total_iterations // cores

    # a single batch consists of a set of iterations, batches are executed in parallel
    # last batch will have a bit more iterations if not dividing evenly
    last_batch = iterations_per_batch + (total_iterations % iterations_per_batch)
    divisions = [iterations_per_batch for i in range(cores-1)] + [last_batch]

    # generate a random seed for each batch
    seeding_rng = np.random.default_rng(666)
    seeds = seeding_rng.choice(len(divisions), size=cores, replace=False)

    # perform bootstrap fitting, multiprocessing with `cores` number of parallel processes
    results = [pool.apply_async(process_batch,
                                args=(fitting_func, batch, seeds[i], x[start:end:skip],
                                      y[start:end:skip], yerr[start:end:skip],
                                      guess, fitting_bounds, ))
               for i, batch in enumerate(divisions)]
    
    generated = np.concatenate([p.get() for p in results], axis=0)

    if verbose:
        end_time = time.perf_counter()
        print(f"Bootstrap fitting with {total_iterations} total iterations took {end_time - start_time} seconds")

    return generated


"""
Fit using the covariance method
"""
def fit_with_covariance(fitting_func, x, y, yerr, start, end, skip, fitting_bounds):
    """

    """
    params, covariance = curve_fit(fitting_func, x[start:end:skip],
                                   y[start:end:skip], sigma=yerr[start:end:skip],
                                   absolute_sigma=True, bounds=fitting_bounds)

    param_err = np.sqrt(np.diag(covariance))

    return params, param_err


"""
Fit the superfluid fraction curve using the fitting form
"""
def perform_fit(data, savepath, args, filetype):

    x = data[:, 0]
    y = data[:, 1]
    yerr = data[:, 2]
    fitting_func = ALLOWED_FILETYPES[filetype]["fit"]
    fit_eqn = ALLOWED_FILETYPES[filetype]["fit eqn"]
    x_label = ALLOWED_FILETYPES[filetype]["x-label"]
    y_label = ALLOWED_FILETYPES[filetype]["y-label"]
    param_names = ALLOWED_FILETYPES[filetype]["param names"]
    fitting_bounds = ALLOWED_FILETYPES[filetype]["bounds"]

    start, end = select_interval(x, y, args.domain, args.throwaway_first, args.throwaway_last, args.p_interval)
    
    if args.max_points:
        if len(x[start:end]) > args.max_points:
            skip = ceil(len(x[start:end]) / args.max_points)
        else:
            skip = args.skip
    else:
        skip = args.skip 
    
    if verbose:
        print(f"Using x-range {x[start]} < x < {x[end]}, "\
              f"fitting only every {skip}-th point, yielding {len(x[start:end:skip])} points total")

    if savepath:
        params_file = open(savepath + "/fit_params.txt", "w")
        params_file.write("#    Parameter   Value   Error:\n")

    guess, covariance = fit_with_covariance(fitting_func, x, y, yerr, start, end, skip, fitting_bounds)

    if verbose:
        errors = np.sqrt(np.diag(covariance))
        print("Parameters found using covariance method:")
        for i, name in enumerate(param_names):
            print(f"Parameter {name}:   {guess[i]}, {errors[i, i]}")

    if args.method == "covariance":

        fitting_params = guess
        fitting_param_errors = np.sqrt(np.diag(covariance)).diagonal()

    elif args.method == "bootstrap":
        
        if verbose:
            print("Bootstrap estimation starting")

        generated_params = fit_with_bootstrap(fitting_func, x, y, yerr, start, end, skip,
                                              guess, args.bootstrap_iterations, args.cores, fitting_bounds)
        
        fitting_params = np.mean(generated_params, axis=0)
        fitting_param_errors = np.std(generated_params, axis=0) 

        if verbose:
            print("Bootstrap estimation complete")
            print("Now creating histograms for fitting parameter distributions")

        for i, name in enumerate(param_names):

            # distribution of values found for parameter
            distribution = generated_params[:, i]

            # abbreviated names
            p = fitting_params[i]
            err = fitting_param_errors[i]

            # create histograms for fitting parameter_distributions
            if savepath:
                
                if args.save_histogram:
                    np.save(savepath + f"/{name}_hist.npy", distribution)

                # plot histograms for each of the parameters in fit
                xdata = np.arange(np.min(distribution), np.max(distribution),
                                  np.abs(np.min(distribution) - np.max(distribution)) / 1000)
                plt.hist(distribution, bins=50, edgecolor="black", density=True)
                plt.plot(xdata, stats.norm.pdf(xdata, p, err),
                                color="red", lw=2.5, label="Normal dist.")
                plt.title(f"Histogram for parameter {name} in fit")
                plt.xlabel(f"{name}")
                plt.ylabel("Frequency")
                plt.legend()
                plt.savefig(savepath + f"/{name}_hist.png")
                plt.clf()

    if verbose:
        print(f"Parameter estimation for fit: {fit_eqn}")
        for i, name in enumerate(param_names):
            print(f"Parameter {name} estimation: \
                  mean - {fitting_params[i]}, std - {fitting_param_errors[i]}")
            
    best_fit = fitting_func(x, *fitting_params)

    if savepath:

        # write fitted parameters and errors to file
        second_label = ""
        for i, name in enumerate(param_names):
            params_file.write(f"{name}  {fitting_params[i]}  {fitting_param_errors[i]}\n")
            second_label += f"{name}={fitting_params[i]:.3f},"
        params_file.close()

        # plot superfluid curve (with errorbars) along with fitting curve
        plt.plot(x[start:end:skip], best_fit[start:end:skip], label=second_label, zorder=2)
        plt.errorbar(x[start:end:skip], y[start:end:skip], yerr=yerr[start:end:skip],
                     fmt='o', markersize=3, capsize=2, label="data", zorder=1)
        plt.title(f"Fit: {fit_eqn}")
        plt.xlabel(x_label)
        plt.ylabel(y_label)
        plt.legend()
        plt.savefig(savepath + f"/fit_to_{filetype}.png")
        plt.clf()

    return fitting_params, fitting_param_errors


if __name__ == "__main__":

    start_time = time.perf_counter()

    parser = argparse.ArgumentParser()
    parser.add_argument("--filename", help="Name of file containing superfluid y")
    parser.add_argument("--cores", type=int, help="Number of cores to use in multiprocessing", default=4)
    parser.add_argument("--max_points", type=int, help="Maximum number of points to fit: will skip sufficiently many to ensure this", default=1000)
    parser.add_argument("--percentage_of_points", type=float, help="Percentage of points to fit: overrides max_points")
    parser.add_argument("--throwaway_first", action="store_true", help="Throw away entries up until the maximum of curve", default=False)
    parser.add_argument("--throwaway_last", action="store_true", help="Throw away entries beyond minimum of curve", default=False)
    parser.add_argument("--p_interval", help="fit a reduced middle range between the maximum and minimum values: \
                                              defining I = max - min, fit only projection times with s.f. taking values in [min + p*I, max - p*I]",
                                        type=float, default=0)
    parser.add_argument("--domain", help="domain of fit", default="")
    parser.add_argument("--bootstrap_iterations", help="number of iterations to do with bootstrap", type=int, default=int(1e5))
    parser.add_argument("--filetype", help=f"type of file that is being fit to: {ALLOWED_FILETYPES.keys()}", default="sf_time")
    parser.add_argument("--method", help=f"select which method to use: {ALLOWED_METHODS}", default="covariance")
    parser.add_argument("--xscaling", type=float, help="Amount the scale the x-axis by", default=1)
    parser.add_argument("--verbose", action="store_true", help="Toggle verbosity level", default=False)
    parser.add_argument("--save", action="store_true", help="Whether or not the save plot/fit param. results to files", default=False)
    parser.add_argument("--skip", help="only fit every n points in dataset", default=1, type=int)
    parser.add_argument("--save_histogram", action="store_true",
                                            help="Whether or not to save histogram file of extrapolated superfluid y", default=False)
    args = parser.parse_args()

    # set verbosity to a global variable, passing this as an argument for all of the functions
    # is kind of a pain in the ass
    verbose = args.verbose

    # input checking
    if args.p_interval < 0 or args.p_interval > 1:
        raise ValueError("value for p interval must be between 0 and 1")

    if args.filetype not in ALLOWED_FILETYPES:
        raise ValueError(f"Please choose one of: {ALLOWED_FILETYPES.keys()}")
    
    if args.method not in ALLOWED_METHODS:
        raise ValueError(f"Please choose one of: {ALLOWED_METHODS}")
    
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
        save = os.path.dirname(args.filename) + "/images/bootstrap"
        os.makedirs(save, exist_ok=True)
    else:
        save = ""

    params, errors = perform_fit(data, save, args, filetype=args.filetype)

    # don't print anything except for to a file
    if not verbose:
        print(f"{args.filename} {params[-1]} {errors[-1]}")

    end_time = time.perf_counter()

    elapsed_time = end_time - start_time

    if verbose:
        print(f"Elapsed time: {elapsed_time:.6f} seconds")
        print("-----------------------------------------------------------------------")

    