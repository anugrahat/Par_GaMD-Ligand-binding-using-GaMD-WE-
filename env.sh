#!/bin/bash

# Load required modules
source ~/.bash_profile
module reset
module load gcc/8.4.0/xiuwkua
module load openmpi/4.1.3/v2ei3ge
module load amber/22/ulauqq7-omp

# Activate Conda environment
conda activate westpa || { echo "Error: Failed to activate westpa environment"; exit 1; }

# Set PATH and LD_LIBRARY_PATH
export PATH=$PATH:$HOME/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$AMBERHOME/lib

# Ensure AMBERHOME is set
if [[ -z "$AMBERHOME" ]]; then
    echo "ERROR: AMBERHOME is not properly initialized"
    exit 1
fi

# Set Amber executables
export PMEMD="$AMBERHOME/bin/pmemd.cuda"
export CPPTRAJ="$AMBERHOME/bin/cpptraj"

# Validate Amber executables
if [[ ! -x "$PMEMD" ]]; then
    echo "ERROR: PMEMD executable not found or not executable at $PMEMD"
    exit 1
fi
if [[ ! -x "$CPPTRAJ" ]]; then
    echo "ERROR: CPPTRAJ executable not found or not executable at $CPPTRAJ"
    exit 1
fi

# Define simulation root
if [[ -z "$WEST_SIM_ROOT" ]]; then
    export WEST_SIM_ROOT="$PWD"
fi
export SIM_NAME=$(basename "$WEST_SIM_ROOT")
echo "Simulation $SIM_NAME root is $WEST_SIM_ROOT"

# Ensure Amber environment is properly sourced
if [[ ! -f "$AMBERHOME/amber.sh" ]]; then
    echo "ERROR: amber.sh script not found in $AMBERHOME"
    exit 1
fi
source "$AMBERHOME/amber.sh"

# Set runtime variables for WESTPA
export NODELOC=/expanse/lustre/scratch/anugrahat/temp_project/westpa/ParGaMD-main
export USE_LOCAL_SCRATCH=1
export WM_ZMQ_MASTER_HEARTBEAT=100
export WM_ZMQ_WORKER_HEARTBEAT=100
export WM_ZMQ_TIMEOUT_FACTOR=300
export BASH=$SWROOT/bin/bash
export PERL=$SWROOT/usr/bin/perl
export ZSH=$SWROOT/bin/zsh
export IFCONFIG=$SWROOT/bin/ifconfig
export CUT=$SWROOT/usr/bin/cut
export TR=$SWROOT/usr/bin/tr
export LN=$SWROOT/bin/ln
export CP=$SWROOT/bin/cp
export RM=$SWROOT/bin/rm
export SED=$SWROOT/bin/sed
export CAT=$SWROOT/bin/cat
export HEAD=$SWROOT/bin/head
export TAR=$SWROOT/bin/tar
export AWK=$SWROOT/usr/bin/awk
export PASTE=$SWROOT/usr/bin/paste
export GREP=$SWROOT/bin/grep
export SORT=$SWROOT/usr/bin/sort
export UNIQ=$SWROOT/usr/bin/uniq
export HEAD=$SWROOT/usr/bin/head
export MKDIR=$SWROOT/bin/mkdir
export ECHO=$SWROOT/bin/echo
export DATE=$SWROOT/bin/date
export SANDER=$AMBERHOME/bin/sander
export PMEMD=$AMBERHOME/bin/pmemd.cuda
export CPPTRAJ=$AMBERHOME/bin/cpptraj

# GPU allocation for multi-node/multi-GPU
export CUDA_DEVICES=(`echo $CUDA_VISIBLE_DEVICES_ALLOCATED | tr , ' '`)
export CUDA_VISIBLE_DEVICES=${CUDA_DEVICES[$WM_PROCESS_INDEX]}

echo "CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
echo "Environment setup complete. Amber and WESTPA ready."
