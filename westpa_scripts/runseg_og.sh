#!/bin/bash

# Enable debugging if SEG_DEBUG is set
if [ -n "$SEG_DEBUG" ]; then
  set -x
  env | sort
fi

# Dynamically assign GPU for this worker
if [ -z "$CUDA_VISIBLE_DEVICES_ALLOCATED" ]; then
  echo "CUDA_VISIBLE_DEVICES_ALLOCATED is empty. Falling back to SLURM_LOCALID."
  export CUDA_VISIBLE_DEVICES=$((SLURM_LOCALID % 4))  # Assumes 4 GPUs per node
else
  CUDA_DEVICES=($(echo $CUDA_VISIBLE_DEVICES_ALLOCATED | tr ',' ' '))
  export CUDA_VISIBLE_DEVICES=${CUDA_DEVICES[$WM_PROCESS_INDEX]}
fi

echo "Assigned GPU: $CUDA_VISIBLE_DEVICES for WM_PROCESS_INDEX: $WM_PROCESS_INDEX"

# Set up the simulation environment
cd $WEST_SIM_ROOT
mkdir -pv $WEST_CURRENT_SEG_DATA_REF
cd $WEST_CURRENT_SEG_DATA_REF

ln -sv $WEST_SIM_ROOT/common_files/ppar.parm7 .
ln -sv $WEST_SIM_ROOT/common_files/gamd-restart.dat .

# Prepare the input file based on initialization type
case $WEST_CURRENT_SEG_INITPOINT_TYPE in
    SEG_INITPOINT_CONTINUES)
        sed "s/RAND/$WEST_RAND16/g" $WEST_SIM_ROOT/common_files/md.in > md.in
        ln -sv $WEST_PARENT_DATA_REF/seg.rst ./parent.rst
    ;;
    SEG_INITPOINT_NEWTRAJ)
        sed "s/RAND/$WEST_RAND16/g" $WEST_SIM_ROOT/common_files/md_init.in > md.in
        if [ "$WEST_RUN_STATUS" = "Init" ]; then
            ln -sv $WEST_PARENT_DATA_REF parent.rst
        else
            ln -sv $WEST_SIM_ROOT/common_files/bstate.rst7 ./parent.rst
        fi
    ;;
    *)
        echo "Unknown init point type $WEST_CURRENT_SEG_INITPOINT_TYPE"
        exit 2
    ;;
esac

# Run the molecular dynamics simulation
pmemd.cuda -O -i md.in -p ppar.parm7 -c parent.rst \
           -r seg.rst -x seg.nc -o seg.log -inf seg.nfo -gamd gamd.log

# Analysis: RMSD and Non-Native Contacts for Residue 275
RMSD_FILE="rmsd_lig275_$$.xvg"
NON_NATIVE_CONTACT_FILE="nonnative_contacts_lig275_$$.dat"
CPPTRAJ_LOG="cpptraj_$$.log"

COMMAND="parm ppar.parm7\n"
COMMAND+="trajin $WEST_CURRENT_SEG_DATA_REF/seg.nc\n"
COMMAND+="reference $WEST_SIM_ROOT/bstates/bstate.rst7\n"
COMMAND+="rms rmsd_lig275 :275 reference out $RMSD_FILE mass\n"
COMMAND+="nativecontacts savenonnative :275 :1-273 distance 5.0 out $NON_NATIVE_CONTACT_FILE series\n"
COMMAND+="go\n"

# Run cpptraj and log the output
echo -e "${COMMAND}" | cpptraj > $CPPTRAJ_LOG 2>&1

# Collect data for WEST_PCOORD_RETURN
> $WEST_PCOORD_RETURN
paste <(awk 'NR>1 {print $2}' $RMSD_FILE) \
      <(awk 'NR>1 {print $3}' $NON_NATIVE_CONTACT_FILE) >> $WEST_PCOORD_RETURN

if [ -n "$SEG_DEBUG" ]; then
  head -v $WEST_PCOORD_RETURN
fi

# Clean up temporary files
rm -f $CPPTRAJ_LOG $RMSD_FILE $NON_NATIVE_CONTACT_FILE
