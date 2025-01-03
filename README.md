ParGaMD combines Gaussian Accelerated Molecular Dynamics (GaMD) with the Weighted Ensemble (WE) framework to enhance sampling efficiency in molecular simulations.

**Simulation Steps:**

1. **Run a Conventional GaMD Simulation:**
   - Navigate to the `cMD` directory.
   - Execute: `sbatch run_cmd.sh`
   - This generates `gamd-restart.dat` for ParGaMD setup.

2. **Configure the WE Framework:**
   - In the main directory, run: `./run_WE.sh`
   - This copies `gamd-restart.dat` and `bstate.rst` to the appropriate WE directories.

3. **Update `west.cfg`:**
   - Set `pcoord_len` to `nstlim/ntpr + 1` in `west.cfg`.
   - Ensure `nstlim` and `ntpr` in `common_files/md.in` are correctly specified.

4. **Submit the ParGaMD Simulation:**
   - Retrieve the cGaMD job ID: `squeue -u <username>`
   - Submit ParGaMD as a dependent job:
     ```bash
     sbatch --dependency=afterok:<jobid> run_WE.sh
     ```
   - Update `NODELOC` in `env.sh` to the current directory.

5. **Post-Processing:**
   - After completion, process data to obtain `gamd.log` and `PC.dat`:
     ```bash
     sbatch run_data.sh
     ```
   - **Note:** Submit `run_data.sh` on a compute node to avoid memory issues.

**Reweighting for Free Energy Surfaces (FES):**

1. **Extract Weights:**
   - Generate `weights.dat` from `gamd.log`:
     ```bash
     awk 'NR%1==0' gamd.log | awk '{print ($8+$7)/(0.001987*300)" "$2" "($8+$7)}' > weights.dat
     ```

2. **Prepare Coordinates:**
   - Combine `PC1.dat` and `PC2.dat` for a 2D surface:
     ```bash
     awk 'NR==FNR{a[NR]=$2; next} {print a[FNR], $2}' PC1.dat PC2.dat > output.dat
     ```

3. **Generate Free Energy Surface:**
   - Run the reweighting script:
     ```bash
     ./reweight-2d.sh 50 50 0.1 0.1 output.dat 300
     ```
     - `50 50`: Cutoffs for both progress coordinates.
     - `0.1 0.1`: Bin spacing for the coordinates.
     - `300`: Temperature in Kelvin.

For detailed instructions and resources, refer to the [ParGaMD GitHub repository](https://github.com/Sonti974948/ParGaMD).

By following these steps, you can effectively perform ParGaMD simulations to explore biomolecular dynamics with enhanced sampling and parallelization. 

Sources: 

1. For installing WESTPA see instructions at https://github.com/westpa/westpa
2. GamD information at Yinglong Miao, Victoria A. Feher, and J. Andrew McCammon
Journal of Chemical Theory and Computation 2015 11 (8), 3584-3595
DOI: 10.1021/acs.jctc.5b00436 and https://www.med.unc.edu/pharm/miaolab/resources/gamd/
3. https://github.com/westpa
4. https://github.com/Sonti974948/ParGaMD (ParGaMD for protein folding example if you want to start with a tutorial and smaller system)
   
