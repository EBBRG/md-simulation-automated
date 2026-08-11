#!/bin/bash
# fix_mol2_name.sh
# Usage: ./fix_mol2_name.sh input.mol2
# This script updates the molecule name in a MOL2 file to "LIG"

# Check input
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 input.mol2"
    exit 1
fi

INPUT_FILE="$1"

# Check file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found."
    exit 1
fi

# Replace the molecule name (second line after @<TRIPOS>MOLECULE) with "LIG"
awk '{
    if($0=="@<TRIPOS>MOLECULE"){print $0; getline; print "LIG"; next}
    print
}' "$INPUT_FILE" > "${INPUT_FILE}_tmp.mol2" && mv "${INPUT_FILE}_tmp.mol2" "$INPUT_FILE"

echo "Molecule name in '$INPUT_FILE' has been changed to 'LIG'."
