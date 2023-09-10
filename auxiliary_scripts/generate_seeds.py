import argparse
import numpy as np


def create_seed(seed_num):

    np.set_printoptions(precision=12)

    data = np.zeros(100)
    u = np.random.rand(97)
    c = 362436/16777216
    cd = 7654321/16777216
    cm = 16777213/16777216
    sampled = np.random.choice(range(1,98), size=2, replace=False)
    i = sampled[0]
    j = sampled[1]

    data[:97] = u
    data[97] = c
    data[98] = cd
    data[99] = cm

    return i, j, data


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--outdir", help="name of output directory with seed files")
    parser.add_argument("--num", type=int, help="number of random seeds to generate")
    args = parser.parse_args()

    for ind in range(args.num):
        i, j, seed_data = create_seed(ind+1)
        np.savetxt(args.outdir + f"/seed{ind+1}.iseed", seed_data.T, fmt="%2.12e")
        with open(args.outdir + f"/seed{ind+1}.iseed", "a") as file:
            file.write(f"{i}\n")
            file.write(f"{j}\n")
