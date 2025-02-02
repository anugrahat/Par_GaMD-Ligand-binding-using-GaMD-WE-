#!/bin/bash
#
# node.sh

set -x
umask g+r
cd $1; shift
source env.sh
export WEST_JOBID=$1; shift
export SLURM_NODENAME=$1; shift
export CUDA_VISIBLE_DEVICES_ALLOCATED=$1; shift

# Map the current worker process to the correct GPU
export CUDA_DEVICES=(`echo $CUDA_VISIBLE_DEVICES_ALLOCATED | tr , ' '`)
export CUDA_VISIBLE_DEVICES=${CUDA_DEVICES[$WM_PROCESS_INDEX]}

echo "Starting WEST client processes on: $(hostname)"
echo "Current directory is $PWD"
echo "Environment is: "
env | sort

echo "CUDA_VISIBLE_DEVICES = $CUDA_VISIBLE_DEVICES"

# Run WESTPA worker
w_run "$@" &> west-$SLURM_NODENAME-node.log

echo "Shutting down. Hopefully, this was on purpose?"
