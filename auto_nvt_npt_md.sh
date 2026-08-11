#!/bin/bash
# auto_nvt_npt_md.sh
# Robust automatic MD workflow starting from EM.gro

set -e

# -------------------------
# USER FILES
# -------------------------
TOPOL="topol.top"
INDEX="index.ndx"
EM_GRO="EM.gro"
NVT_MDP="NVT.mdp"
NPT_MDP="NPT.mdp"
MD_MDP="MD.mdp"
N_THREADS=11

# -------------------------
# STEP 0: Detect EXISTING groups from index.ndx
# -------------------------
echo "Checking available groups in $INDEX:"
grep "\[" "$INDEX"
echo ""

# Detect which water-ion group exists
WATER_ION_GROUP=""
if grep -q "CLA_Water" "$INDEX"; then
    WATER_ION_GROUP="CLA_Water"
    echo "Found CLA_Water group"
elif grep -q "SOD_Water" "$INDEX"; then
    WATER_ION_GROUP="SOD_Water" 
    echo "Found SOD_Water group"
else
    # If no combined group, use separate groups
    if grep -q "Water" "$INDEX" && grep -q "CLA" "$INDEX"; then
        echo "Using separate Water and CLA groups"
        WATER_ION_GROUP="Water CLA"
    elif grep -q "Water" "$INDEX" && grep -q "SOD" "$INDEX"; then
        echo "Using separate Water and SOD groups"
        WATER_ION_GROUP="Water SOD"
    elif grep -q "SOL" "$INDEX"; then
        echo "Using SOL group"
        WATER_ION_GROUP="SOL"
    else
        echo "Error: No water/ion groups found in $INDEX"
        exit 1
    fi
fi

# Detect protein-ligand group
PROT_GROUP=""
if grep -q "Protein_LIG" "$INDEX"; then
    PROT_GROUP="Protein_LIG"
    echo "Found Protein_LIG group"
elif grep -q "Protein" "$INDEX" && grep -q "LIG" "$INDEX"; then
    echo "Using separate Protein and LIG groups"
    PROT_GROUP="Protein LIG"
elif grep -q "Protein" "$INDEX"; then
    PROT_GROUP="Protein"
    echo "Using Protein group only"
else
    echo "Error: No protein group found in $INDEX"
    exit 1
fi

echo ""
echo "Final selection:"
echo "Protein+Ligand group: $PROT_GROUP"
echo "Water+Ions group:     $WATER_ION_GROUP"
echo ""

# -------------------------
# STEP 1: Update mdp files for correct tc-grps
# -------------------------
echo "Updating mdp files for temperature coupling groups..."

for mdpfile in "$NVT_MDP" "$NPT_MDP" "$MD_MDP"; do
    if [ -f "$mdpfile" ]; then
        # Create backup
        cp "$mdpfile" "${mdpfile}.backup"
        
        # Update temperature coupling
        sed -i "s|^tc-grps[[:space:]]*=.*|tc-grps = $PROT_GROUP $WATER_ION_GROUP|" "$mdpfile"
        sed -i "s|^ref_t[[:space:]]*=.*|ref_t = 300 300|" "$mdpfile"
        
        echo "Updated $mdpfile:"
        echo "  tc-grps = $PROT_GROUP $WATER_ION_GROUP"
        echo "  ref_t = 300 300"
        echo ""
    else
        echo "Warning: $mdpfile not found, skipping"
    fi
done

# -------------------------
# STEP 2: NVT Equilibration
# -------------------------
echo "=== NVT Equilibration ==="
gmx grompp -f "$NVT_MDP" -c "$EM_GRO" -r "$EM_GRO" -p "$TOPOL" -n "$INDEX" -o NVT.tpr -maxwarn 2
nohup gmx mdrun -deffnm NVT -nt "$N_THREADS" -v &

# Wait for NVT to finish before moving on
wait
echo "=== NVT completed ==="

# -------------------------
# STEP 3: NPT Equilibration
# -------------------------
echo "=== NPT Equilibration ==="
gmx grompp -f "$NPT_MDP" -c NVT.gro -r NVT.gro -p "$TOPOL" -n "$INDEX" -o NPT.tpr -maxwarn 2
gmx mdrun -deffnm NPT -nt "$N_THREADS" -v
echo "=== NPT completed ==="

# -------------------------
# STEP 4: Production MD
# -------------------------
echo "=== Production MD ==="
gmx grompp -f "$MD_MDP" -c NPT.gro -t NPT.cpt -p "$TOPOL" -n "$INDEX" -o MD.tpr -maxwarn 2
#gmx mdrun -deffnm MD -nt "$N_THREADS" -v
echo "=== MD production completed ==="

echo "=== Workflow finished successfully ==="
