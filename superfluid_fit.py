import argparse
import os
import sys
import time
import numpy as np
import matplotlib.pyplot as plt
import multiprocessing as mp
from math import ceil
from scipy.optimize import curve_fit
from scipy import stats


"""
Fit the superfluid fraction curves with the fitting form from Zhang (1995)
"""


def fitting_func(x, A, G, C):
    return (A / x) * (1 - np.exp(-G * x)) + C


def process_batch(iterations, seed, betas, sff, sff_err, guess):
    rng = np.random.default_rng(seed)
    generated_params = np.zeros((iterations, 3))
    for i in range(iterations):
        resampled_sff = rng.normal(size=sff.size, loc=sff, scale=sff_err)
        popt, _ = curve_fit(fitting_func, betas, resampled_sff, p0=guess,
                            bounds=([0,0,0],[1000,1000,1]))
        generated_params[i, :] = popt
    
    if args.verbose:
        print(f"Batch of {iterations} bootstrap iterations finished")

    return generated_params


def jacobian(x, A, G, C):
    d_A = (1 - np.exp(-G * x)) / x
    d_G = A * np.exp(-G * x)
    d_C = np.ones_like(x)

    return np.transpose([d_A, d_G, d_C])


def compute_uncertainty(x, yerr, A, G, C):

    d_A = (1 - np.exp(-G * x)) / x
    d_G = A * np.exp(-G * x)
    d_C = np.ones_like(x)

    A = np.row_stack([d_A / yerr, d_G / yerr, d_C / yerr])
    H = np.zeros((3, 3))

    for i in range(3):
        for j in range(3):
            H[i, j] = A[i, :] @ A[j, :]
    
    C = np.linalg.inv(H)

    return C


def fit_superfluid_fraction(data, cores, x_scaling, skip, savepath):

    betas = data[:, 0]
    fractions = data[:, 1]
    errorbars = data[:, 2]

    start = 0
    end = len(data)

    if len(data) > args.max_points:
        skip = ceil(len(data) / args.max_points) 

    if args.throwaway_first:
        start = np.argmax(fractions)
    
    if args.throwaway_last:
        end = np.argmin(fractions)
    
    if args.verbose:
        print(f"Using imaginary times {betas[start]} < beta < {betas[end]}")
        print("Bootstrap estimation starting")

    param_names = ["a", "g", "c"]
    param_means = []
    param_stds = []

    guess, covariance = curve_fit(fitting_func, betas[start:end:skip] * x_scaling,
                                                    fractions[start:end:skip],
                                                    sigma=errorbars[start:end:skip],
                                                    absolute_sigma=True,
                                                    jac=jacobian,
                                                    bounds=([0,0,0],[1000,1000,1]))

    if savepath:
        params_file = open(savepath + "/sd_fit_params.txt", "w")
        params_file.write("#    param    mean    stderror\n")

    if args.bootstrap:

        # use multiprocessing
        pool = mp.Pool(processes=cores)

        total_iterations = 10000
        iterations_per_batch = total_iterations // cores

        seeding_rng = np.random.default_rng(666)
        seeds = seeding_rng.choice(100, size=cores, replace=False)
    
        # a single batch consists of a set of iterations, batches are executed in parallel
        # last batch will have a bit more iterations if not dividing evenly
        last_batch = iterations_per_batch + (total_iterations % iterations_per_batch)
        divisions = [iterations_per_batch for i in range(cores-1)] + [last_batch]
        # rescale the x-axis for robustness
        results = [pool.apply_async(process_batch,
                                    args=(batch, seeds[i], betas[start:end:skip] * x_scaling,
                                                        fractions[start:end:skip],
                                                        errorbars[start:end:skip], guess, ))
                for i, batch in enumerate(divisions)]

        generated_params = np.concatenate([p.get() for p in results], axis=0)

        if args.verbose:
            print("Bootstrap estimation complete")
            print(f"Parameter estimation for fit: (A / tau) * (1 - exp(-G * tau)) + C")

        for col in range(3):
            params = generated_params[:, col]

            # parameters A and G need to be transformed back since we rescaled x axis
            if col == 0:
                params = params / x_scaling
            elif col == 1:
                params *= x_scaling 

            param_mean = np.mean(params)
            param_std = np.std(params)
            param_means.append(param_mean)
            param_stds.append(param_std)
            capitalized_param_name = param_names[col].upper()

            if args.verbose:
                print(f"Parameter {capitalized_param_name} estimation: mean - {param_mean}, std - {param_std}")

            if savepath:
                params_file.write(f"{capitalized_param_name}  {param_mean}  {param_std}\n")

                # plot histograms for each of the parameters in fit
                xdata = np.arange(np.min(params), np.max(params), np.abs(np.min(params) - np.max(params)) / 1000)
                plt.hist(params, 50, edgecolor="black", density=True)
                plt.plot(xdata, stats.norm.pdf(xdata, param_mean, param_std), color="red", lw=2.5, label="Normal dist.")
                plt.title(f"Histogram for parameter {capitalized_param_name} in fit")
                plt.xlabel(f"{capitalized_param_name}")
                plt.ylabel("Frequency")
                plt.legend()
                plt.savefig(savepath + f"/{capitalized_param_name}_hist.png")
                plt.clf()

        # plot the fit using the means of the parameters
        fit_using_mean = fitting_func(betas, *param_means)
        a = param_means[0]
        g = param_means[1]
        c = param_means[2]

    # test out using pcov in scipy.optimize.curve_fit
    guess[0] /= x_scaling
    guess[1] *= x_scaling
    param_err = np.sqrt(np.diag(covariance))

    alt_cov = compute_uncertainty(betas[start:end:skip], errorbars[start:end:skip], *guess)
    alt_param_err = np.sqrt(np.diag(alt_cov))

    if args.verbose:
        print("Calculating parameters and errors using pcov:")
        for i, err in enumerate(param_err):
            print(f"Parameter {param_names[i]} estimation: mean - {guess[i]}, std - {err}")

    if savepath:
        params_file.write("#    Parameter error using `pcov`:\n")
        for i, err in enumerate(param_err):
            params_file.write(f"#  {param_names[i].upper()}  {guess[i]}  {err}\n")
        params_file.close()

    # bootstrapped fit
    if args.bootstrap:
        if savepath:
            plt.plot(betas, fit_using_mean, label=fr"fit using $({a:.5f}/\tau)(1-\exp(-{g:.2f}\tau))+{c:.3f}$", zorder=2)

    # fit using numpy pcov
    p_a = guess[0] 
    p_g = guess[1]
    p_c = guess[2]

    if savepath:
        second_label=fr"fit using $({p_a:.5f}/\tau)(1-\exp(-{p_g:.2f}\tau))+{p_c:.3f}$"
        plt.plot(betas, fitting_func(betas, *guess), label=second_label, zorder=2)
        plt.errorbar(betas, fractions, yerr=errorbars, fmt='o', markersize=3, capsize=2, label="data", zorder=1)
        plt.title(r"Fit to s.f. : $(A / \tau)(1 - e^{-\gamma\tau}) + C$")
        plt.xlabel("Projection time")
        plt.ylabel("Superfluid fraction")
        plt.legend()
        plt.savefig(savepath + "/fit_to_superfluid_fraction.png")
        plt.clf()

    if param_means and param_stds:
        return param_means, param_stds
    else:
        return guess, param_err


if __name__ == "__main__":

    start_time = time.perf_counter()

    parser = argparse.ArgumentParser()
    parser.add_argument("--filename", help="Name of file containing superfluid fractions")
    parser.add_argument("--cores", type=int, help="Number of cores to use in multiprocessing", default=4)
    parser.add_argument("--max_points", type=int, help="Maximum number of points to fit: will skip sufficiently many to ensure this", default=1000)
    parser.add_argument("--throwaway_first", action="store_true", help="Throw away entries up until the maximum of curve", default=False)
    parser.add_argument("--throwaway_last", action="store_true", help="Throw away entries beyond minimum of curve", default=False)
    parser.add_argument("--xscaling", type=float, help="Amount the scale the x-axis by", default=1)
    parser.add_argument("--verbose", action="store_true", help="Toggle verbosity level", default=False)
    parser.add_argument("--bootstrap", action="store_true", help="Whether not to use bootstrap method", default=False)
    parser.add_argument("--save", action="store_true", help="Whether or not the save results to files", default=False)
    parser.add_argument("--skip", help="only fit every n points in dataset", default=1, type=int)
    args = parser.parse_args()

    if args.verbose:
        print("-----------------------------------------------------------------------")
        print(f"Analyzing file @ {args.filename}")
        print("-----------------------------------------------------------------------")

    with open(args.filename) as f:
        lines = (line for line in f if not line.startswith('#'))
        data = np.loadtxt(lines)

    basedir = os.path.dirname(args.filename)

    if args.save:
        save = os.path.dirname(args.filename) + "/images/sd_bootstrap"
        os.makedirs(save, exist_ok=True)
    else:
        save = ""

    params, errors = fit_superfluid_fraction(data, int(args.cores), args.xscaling, args.skip, savepath=save)

    filename = os.path.basename(args.filename)
    if not args.verbose:
        print(f"{args.filename} {params[-1]} {errors[-1]}")

    end_time = time.perf_counter()

    elapsed_time = end_time - start_time

    if args.verbose:
        print(f"Elapsed time: {elapsed_time:.6f} seconds")

        print("-----------------------------------------------------------------------")

    