#!/bin/bash

# Load required modules
source ~/.bash_profile
module reset
module load gcc/8.4.0/xiuwkua
module load openmpi/4.1.3/v2ei3ge
module load amber/22/ulauqq7-omp
# Activate Conda environment
conda activate westpa

# Set PATH and LD_LIBRARY_PATH
export PATH=$PATH:$HOME/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$AMBERHOME/lib

# Define simulation root
if [[ -z "$WEST_SIM_ROOT" ]]; then
    export WEST_SIM_ROOT="$PWD"
fi
export SIM_NAME=$(basename $WEST_SIM_ROOT)
echo "simulation $SIM_NAME root is $WEST_SIM_ROOT"

# Source Amber environment
source $AMBERHOME/amber.sh

# Set runtime variables
export NODELOC=/expanse/lustre/scratch/anugrahat/temp_project/westpa/ParGaMD-main
export USE_LOCAL_SCRATCH=1
export WM_ZMQ_MASTER_HEARTBEAT=100
export WM_ZMQ_WORKER_HEARTBEAT=100
export WM_ZMQ_TIMEOUT_FACTOR=300

# Set Amber executables
export PMEMD=$AMBERHOME/bin/pmemd.cuda
export CPPTRAJ=$AMBERHOME/bin/cpptraj



