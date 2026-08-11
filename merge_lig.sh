#!/bin/bash
# merge_lig_clean.sh
# Safe, robust CHARMM36 protein–ligand merger for GROMACS

set -e

### ----------------------------
### USER INPUT FILES
### ----------------------------
PROTEIN_GRO="conf.gro"
LIG_PDB="lig_ini.pdb"
LIG_GRO="LIG.gro"
LIG_ITP="lig.itp"
LIG_PRM="lig.prm"
TOPOL="topol.top"
MERGED_GRO="conf_merged.gro"

### ----------------------------
### STEP 1: Convert ligand PDB → GRO
### ----------------------------
echo "Converting ligand PDB → GRO..."
gmx editconf -f "$LIG_PDB" -o "$LIG_GRO"

### ----------------------------
### STEP 2: Merge ligand into protein GRO
### ----------------------------
natoms_protein=$(sed -n '2p' "$PROTEIN_GRO")
natoms_ligand=$(sed -n '2p' "$LIG_GRO")
total_atoms=$((natoms_protein + natoms_ligand))

echo "Protein atoms: $natoms_protein"
echo "Ligand atoms:  $natoms_ligand"
echo "Total atoms:   $total_atoms"

# Write merged GRO
head -n 1 "$PROTEIN_GRO" > "$MERGED_GRO"
echo "$total_atoms" >> "$MERGED_GRO"
sed -n "3,$((natoms_protein+2))p" "$PROTEIN_GRO" >> "$MERGED_GRO"
sed -n "3,$((natoms_ligand+2))p" "$LIG_GRO" >> "$MERGED_GRO"
tail -n 1 "$PROTEIN_GRO" >> "$MERGED_GRO"

echo "Merged structure saved: $MERGED_GRO"

### ----------------------------
### STEP 3: Backup topology
### ----------------------------
cp "$TOPOL" "${TOPOL}.bak"
echo "Backup created: ${TOPOL}.bak"

### ----------------------------
### STEP 4: Insert ligand parameters & topology
### ----------------------------

# Insert lig.prm after forcefield.itp
if ! grep -q "lig.prm" "$TOPOL"; then
    sed -i '/forcefield.itp/a ; Include ligand parameters\n#include "lig.prm"' "$TOPOL"
fi

# Insert lig.itp after TIP3P
if ! grep -q "lig.itp" "$TOPOL"; then
    sed -i '/tip3p.itp/a ; Include ligand topology\n#include "lig.itp"' "$TOPOL"
fi

### ----------------------------
### STEP 5: Correct POSRES block (NO NESTING — valid syntax)
### ----------------------------

# Remove any old ligand posres includes
sed -i '/posre_LIG.itp/d' "$TOPOL"

# Ensure main POSRES block exists
if ! grep -q '#include "posre.itp"' "$TOPOL"; then
    sed -i '/lig.prm/a ; Position restraints\n#ifdef POSRES\n#include "posre.itp"\n#endif' "$TOPOL"
fi

# Insert ligand posres INSIDE the same POSRES block
sed -i '/#include "posre.itp"/a #include "posre_LIG.itp"' "$TOPOL"

### ----------------------------
### STEP 6: Remove duplicated #endif if created
### ----------------------------
sed -i '/^#endif$/N;/\n#endif$/D' "$TOPOL"

### ----------------------------
### STEP 7: Fix [ molecules ] section
### ----------------------------

awk '
/\[ molecules \]/ {print; inmol=1; next}
/^\[/ {inmol=0}
inmol && NF>0 {if(!seen[$1]++){print; next}}
!inmol {print}
' "$TOPOL" > topol_clean.tmp
mv topol_clean.tmp "$TOPOL"

# Ensure correct molecule entries
grep -q "^Protein_chain_A" "$TOPOL" || echo "Protein_chain_A     1" >> "$TOPOL"
grep -q "^LIG" "$TOPOL" || echo "LIG                 1" >> "$TOPOL"

echo ""
echo "------------------------------------------------------"
echo "SUCCESS: Merged GRO + cleaned topol.top are ready!"
echo "Run next: gmx grompp -f ions.mdp -c conf_merged.gro -p topol.top -o ION.tpr"
echo "------------------------------------------------------"
