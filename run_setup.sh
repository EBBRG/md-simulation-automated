#!/bin/bash
set -e

# --------------------------------------------
# USER files
# --------------------------------------------
PROTEIN_LIG_GRO="conf_merged.gro"
TOPOL="topol.top"
LIG_GRO="LIG.gro"

# --------------------------------------------
echo -e "\n=== STEP 1: Define simulation box ===\n"
gmx editconf -f "$PROTEIN_LIG_GRO" -d 1.0 -bt triclinic -o box.gro

# --------------------------------------------
echo -e "\n=== STEP 2: Solvate system ===\n"
gmx solvate -cp box.gro -cs spc216.gro -p "$TOPOL" -o box_sol.gro

# --------------------------------------------
echo -e "\n=== STEP 3: Prepare ions TPR ===\n"
gmx grompp -f ions.mdp -c box_sol.gro -maxwarn 2 -p "$TOPOL" -o ION.tpr

# --------------------------------------------
echo -e "\n=== STEP 4: Add ions (SOD / CLA) ===\n"
# Automatically select SOL group
echo "SOL" | gmx genion -s ION.tpr -p "$TOPOL" -pname SOD -nname CLA -neutral -o box_sol_ion.gro

# --------------------------------------------
echo -e "\n=== STEP 5: Energy minimization ===\n"
gmx grompp -f EM.mdp -c box_sol_ion.gro -maxwarn 2 -p "$TOPOL" -o EM.tpr
gmx mdrun -v -deffnm EM

# --------------------------------------------
echo -e "\n=== STEP 6: Create ligand-only index ===\n"
# Create index_LIG.ndx automatically (heavy atoms only)
echo -e "0 & ! a H*\nq" | gmx make_ndx -f "$LIG_GRO" -o index_LIG.ndx

# --------------------------------------------
echo -e "\n=== STEP 7: Generate posre_LIG.itp ===\n"
# Select group 3 automatically
echo "3" | gmx genrestr -f "$LIG_GRO" -n index_LIG.ndx -o posre_LIG.itp -fc 1000 1000 1000

# --------------------------------------------
echo -e "\n=== STEP 8: Insert ligand restraint include into topol.top ===\n"

if ! grep -q "posre_LIG.itp" "$TOPOL"; then
    sed -i '/posre.itp/a ; Ligand position restraints\n#ifdef POSRES\n#include "posre_LIG.itp"\n#endif\n' "$TOPOL"
    echo "Inserted ligand restraints block."
fi

# --------------------------------------------
echo -e "\n=== STEP 9: Create index for entire system ===\n"
# 1 | 13 and 14 | 15 automatically
echo -e "1 | 13\n14 | 15\nq" | gmx make_ndx -f EM.gro -o index.ndx

echo -e "\n===================================================="
echo " ALL STEPS COMPLETED SUCCESSFULLY"
echo " Box → Solvate → Ions → EM → Lig index → posres → System index"
echo "===================================================="
