#!/bin/bash
#SBATCH -p gpu-shared
#SBATCH -t 00:30:00
#SBATCH --gpus=1
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --account=ucd191

# Reset and load required modules
module reset
module load gcc/8.4.0/xiuwkua
module load openmpi/4.1.3/v2ei3ge
module load amber/22/ulauqq7-omp



# Ensures the directory exists or is created without error if it already exists
mkdir -p replica10

# Define variables for input files
mdin="md.in"
input_parm7="ppar.parm7"
input_rst7="bstate.rst7"


output_prefix="replica10/gamd"
pmemd.cuda -O -i $mdin -p $input_parm7 -c $input_rst7 -ref $input_rst7 \
           -o ${output_prefix}.mdout \
           -r ${output_prefix}.rst7 \
           -inf ${output_prefix}.mdinfo \
           -x ${output_prefix}.nc \
           -gamd ${output_prefix}.log