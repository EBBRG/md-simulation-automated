#!/bin/bash
# convert_ligand.sh
# Converts SDF → PDB, MOL2, PDBQT with hydrogens and Gasteiger charges

if ! command -v obabel &> /dev/null; then
    echo "Error: Open Babel is not installed."
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 inputfile.sdf"
    exit 1
fi

INPUT_FILE="$1"
BASE_NAME=$(basename "$INPUT_FILE" .sdf)

# SDF -> PDB with hydrogens
obabel "$INPUT_FILE" -O "${BASE_NAME}.pdb" -h || { echo "Failed to create PDB"; exit 1; }

# SDF -> MOL2
obabel "$INPUT_FILE" -O "${BASE_NAME}.mol2" -h || { echo "Failed to create MOL2"; exit 1; }

# PDB -> PDBQT for AutoDock with Gasteiger charges
obabel "${BASE_NAME}.pdb" -O "${BASE_NAME}.pdbqt" --partialcharge gasteiger || { echo "Failed to create PDBQT"; exit 1; }

echo "Conversion completed successfully!"
echo "Generated files: ${BASE_NAME}.pdb, ${BASE_NAME}.mol2, ${BASE_NAME}.pdbqt"
