import numpy as np



"""
Fitting form for energy per particle with respect to projection time: special case in that
it commutes with the evolution operator. As a corollary, energy must exponentially decay 
with projection time.
"""
def energy_vs_proj_time_fitting_func(x, e_0, b, c):
    """
    x - array of values for independent variate
    b - fit parameter
    c - fit parameter
    e_0 - fit parameter: asymptotic energy per particle at infinite projection time
    """
    return b * np.exp(-c * x) + e_0


"""
Fitting form for energy per particle with respect to time step. Due to fourth-order propagator
used during PIGS, needs to be fitted with a quartic.
"""
def energy_vs_time_step_fitting_func(x, e_0, a):
    """
    x - array of values for independent variate
    a - fit parameter
    e_0 - fit parameter: asymptotic energy per particle at infinite projection time
    """
    return e_0 + a * x ** 4


"""
Fitting form for superfluid fraction (proportional to D(tau)^2/tau) with respect to imaginary time 0 < t < beta.
Taken from Zhang (1995).
"""
def superfluid_vs_time_fitting_func(x, a, g, c):
    """
    x - array of values for independent variate
    A - fit parameter
    G - fit parameter
    C - fit parameter: asymptotic superfluid fraction extrapolated at infinite projection time
    """
    return (a / x) * (1 - np.exp(-g * x)) + c


"""
Fitting form for superfluid fraction with respect to total projection time
"""
def superfluid_vs_proj_time_fitting_func(x, s, b, c):
    """
    x - array of values for independent variate
    b - fit parameter
    c - fit parameter
    s - fit parameter: final best estimate of superfluid fraction at infinite total projection time
    """
    return b * np.exp(-c * x) + s


"""
Variables
"""

NO_BOUNDS = (-np.inf, np.inf)
ALLOWED_METHODS = {"bootstrap", "covariance"}
ALLOWED_FILETYPES = {
                        "en_proj_time": {"fit": energy_vs_proj_time_fitting_func,
                                        "fit eqn": "E_0 + B * exp(-C * x)",
                                        "param names": ["E_0", "B", "C"],
                                        "x-label": r"Projection time ($K^{-1}$)",
                                        "y-label": r"Energy per particle ($K$)", 
                                        "bounds": NO_BOUNDS},

                        "en_time_step": {"fit": energy_vs_time_step_fitting_func,
                                        "fit eqn": "E_0 + A * x ** 4",
                                        "param names": ["E_0", "A"],
                                        "x-label": r"Time step ($K^{-1}$)",
                                        "y-label": r"Energy per particle ($K$)",
                                        "bounds": NO_BOUNDS},

                        "sf_time":      {"fit": superfluid_vs_time_fitting_func,
                                        "fit eqn": "(A / x) * (1 - exp(-G * x)) + C",
                                        "param names": ["A", "G", "C"],
                                        "x-label": r"Imaginary time ($K^{-1}$)",
                                        "y-label": r"Superfluid fraction",
                                        "bounds": ([0,0,-0.1],[1000,1000,1]),
                                        "displacements": [1, 1, 1]},

                        "sf_proj_time": {"fit": superfluid_vs_proj_time_fitting_func,
                                        "fit eqn": "B * exp(-C * x) + S",
                                        "param names": ["S", "B", "C"],
                                        "x-label": r"Projection time ($K^{-1}$)",
                                        "y-label": r"Superfluid fraction",
                                        "bounds": NO_BOUNDS}
                        }
