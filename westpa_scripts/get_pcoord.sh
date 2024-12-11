#!/bin/bash

# Enable debug mode if SEG_DEBUG is set
if [ -n "$SEG_DEBUG" ]; then
  set -x
  env | sort
fi

# Move to simulation root directory
cd $WEST_SIM_ROOT || exit

# Define reference topology and reference frame
TOPOLOGY="$WEST_SIM_ROOT/common_files/ppar.parm7"
REFERENCE="$WEST_SIM_ROOT/bstates/bstate.rst7"  # Use bstate.rst7 as the reference

# Define current trajectory file
TRAJ_FILE="$WEST_SIM_ROOT/traj_segs/{segment.n_iter:06d}/{segment.seg_id:06d}/seg.nc"

# Define output directory for RMSD and non-native contact files
OUTPUT_DIR="$WEST_SIM_ROOT/output_dir_prog_coord"
mkdir -p "$OUTPUT_DIR"  # Ensure the directory exists

# Generate unique output filenames using $$ (process ID) in the output directory
RMSD_FILE="$OUTPUT_DIR/rmsd_lig275_$$.xvg"
NON_NATIVE_CONTACT_FILE="$OUTPUT_DIR/nonnative_contacts_lig275_$$.dat"

# Generate cpptraj commands
COMMAND="parm $TOPOLOGY\n"
COMMAND="${COMMAND} reference $REFERENCE\n"  # Specify reference frame
COMMAND="${COMMAND} trajin $TRAJ_FILE 0 1000\n"  # Read all frames of seg.nc

# Calculate RMSD for Residue 275
COMMAND="${COMMAND} rms rmsd_lig275 :275 reference out $RMSD_FILE mass\n"

# Calculate total number of non-native contacts within 0.5 nm (5.0 Å) for each frame
COMMAND="${COMMAND} nativecontacts savenonnative :275 :1-273 distance 5.0 out $NON_NATIVE_CONTACT_FILE series\n"

COMMAND="${COMMAND} go"

# Execute cpptraj
echo -e "$COMMAND" | cpptraj > cpptraj_$$.log 2>&1
if [ $? -ne 0 ]; then
  echo "cpptraj failed. Check cpptraj_$$.log for details." >&2
  exit 1
fi

# Validate outputs
if [ ! -s $RMSD_FILE ] || [ ! -s $NON_NATIVE_CONTACT_FILE ]; then
  echo "Error: Missing or empty RMSD or non-native contact file for residue 275" >&2
  exit 1
fi

# Ensure return file is empty before writing
> $WEST_PCOORD_RETURN

# Extract RMSD and non-native contact count, then write both to progress coordinate file
paste <(tail -n +2 $RMSD_FILE | awk '{print $2}') \
      <(tail -n +2 $NON_NATIVE_CONTACT_FILE | awk '{print $3}') >> $WEST_PCOORD_RETURN

# Ensure $WEST_PCOORD_RETURN has the correct number of lines
EXPECTED_LINES=1001  # Assuming trajectory has 1000 frames + header
ACTUAL_LINES=$(wc -l < $WEST_PCOORD_RETURN)
if [ "$ACTUAL_LINES" -ne "$EXPECTED_LINES" ]; then
  echo "Error: Incorrect number of lines in $WEST_PCOORD_RETURN (expected $EXPECTED_LINES, got $ACTUAL_LINES)" >&2
  exit 1
fi

# Debug output for progress coordinates if SEG_DEBUG is set
if [ -n "$SEG_DEBUG" ]; then
  head -v $WEST_PCOORD_RETURN
fi

# Cleanup temporary log file
rm -f cpptraj_$$.log
