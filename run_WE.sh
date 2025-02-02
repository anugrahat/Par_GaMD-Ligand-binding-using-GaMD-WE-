#!/bin/bash
#SBATCH --job-name="WE_run"
#SBATCH --output="job.out"
#SBATCH --partition=gpu
#SBATCH --nodes=3                 # Request 2 nodes
#SBATCH --ntasks-per-node=4        # 4 tasks per node (1 per GPU)
#SBATCH --gpus=12                   # Total 8 GPUs across nodes
#SBATCH --mem=300G                 # Memory per node
#SBATCH --cpus-per-task=10         # CPU cores per task
#SBATCH --account=ucd191
#SBATCH -t 48:00:00

set -x
cd $SLURM_SUBMIT_DIR
source ~/.bashrc

# Load required modules
module purge
module load gpu
module load gcc/8.4.0/xiuwkua
module load openmpi/4.1.3/v2ei3ge
module load amber/22/ulauqq7-omp
conda activate westpa


export LD_LIBRARY_PATH=$LD_LIBRARY_PATH

# Validate w_run exists
if ! command -v w_run &> /dev/null; then
    echo "Error: w_run not found in PATH"
    exit 1
fi
 
export WEST_SIM_ROOT=$SLURM_SUBMIT_DIR
cd $WEST_SIM_ROOT

# Ensure init.sh runs correctly
#if [[ ! -f "$WEST_SIM_ROOT/init.sh" ]]; then
   #  echo "Error: init.sh not found in $WEST_SIM_ROOT"
    # exit 1
#fi

#./init.sh
#if [[ $? -ne 0 ]]; then
#    echo "init.sh failed to execute correctly."
#    exit 1
#fi
#echo "init.sh ran successfully"

# Source environment variables
source env.sh || exit 1
env | sort
SERVER_INFO=$WEST_SIM_ROOT/west_zmq_info.json

# Set the number of GPUs per node
num_gpu_per_node=4  # Adjust this as per your system's configuration

# Remove old node list file and create a new one
rm -rf nodefilelist.txt
scontrol show hostname $SLURM_JOB_NODELIST > nodefilelist.txt

# Start the master server
w_run --work-manager=zmq --n-workers=0 --zmq-mode=master --zmq-write-host-info=$SERVER_INFO --zmq-comm-mode=tcp &> west-$SLURM_JOBID-local.log &

# Wait for the server info file to be created
for ((n=0; n<90; n++)); do
    if [ -e $SERVER_INFO ]; then
        echo "== server info file $SERVER_INFO =="
        cat $SERVER_INFO
        break
    fi
    sleep 1
done

# Exit if server fails to start
if ! [ -e $SERVER_INFO ]; then
    echo 'Server failed to start'
    exit 1
fi

# Launch workers on each node
for node in $(cat nodefilelist.txt); do
    for gpu_id in $(seq 0 $((num_gpu_per_node - 1))); do
        export CUDA_VISIBLE_DEVICES=$gpu_id
        echo "Launching worker on $node with CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES"
        
        # Launch the worker on the specific GPU
        ssh -o StrictHostKeyChecking=no $node \
            "$PWD/node.sh $SLURM_SUBMIT_DIR $SLURM_JOBID $node $CUDA_VISIBLE_DEVICES \
            --work-manager=zmq --n-workers=1 --zmq-mode=client \
            --zmq-read-host-info=$SERVER_INFO --zmq-comm-mode=tcp" \
            &> $node-worker-$gpu_id.log &

        # Error handling in case the worker fails
        if [[ $? -ne 0 ]]; then
            echo "Failed to launch worker on $node for GPU $gpu_id"
            exit 1
        fi
    done
done

# Wait for all workers to complete
wait
