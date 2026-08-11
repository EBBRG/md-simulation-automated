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
# STEP 0: Detect groups
# -------------------------
echo "Detecting index groups..."

# Protein+Ligand group: try to find group containing both, fallback to Protein_LIG
PROT_GROUP=$(grep -E "^\[.*\]" "$INDEX" | grep -i "Protein" | grep -i "LIG" | head -1 | tr -d '[] ')
if [ -z "$PROT_GROUP" ]; then
    PROT_GROUP=$(grep -E "^\[.*\]" "$INDEX" | grep -i "Protein_LIG" | head -1 | tr -d '[] ')
fi

# Water+Ion group: prefer SOD_Water, else fallback to Water/SOL/SOD
WATER_GROUP=$(grep -E "^\[.*\]" "$INDEX" | grep -i "SOD_Water" | head -1 | tr -d '[] ')
if [ -z "$WATER_GROUP" ]; then
    WATER_GROUP=$(grep -E "^\[.*\]" "$INDEX" | grep -E "Water|SOL|SOD" | head -1 | tr -d '[] ')
fi

# Validate
if [ -z "$PROT_GROUP" ] || [ -z "$WATER_GROUP" ]; then
    echo "Error: Could not detect required index groups in $INDEX"
    exit 1
fi

echo "Protein+Ligand group: $PROT_GROUP"
echo "Water+Ions group:     $WATER_GROUP"

# -------------------------
# STEP 1: Update mdp files for correct tc-grps
# -------------------------
echo "Updating mdp files for temperature coupling groups..."

for mdpfile in "$NVT_MDP" "$NPT_MDP" "$MD_MDP"; do
    if [ -f "$mdpfile" ]; then
        sed -i -E "s/^tc-grps\s*=.*/tc-grps = $PROT_GROUP $WATER_GROUP/" "$mdpfile"
        sed -i -E "s/^ref_t\s*=.*/ref_t = 300 300/" "$mdpfile"
        echo "Updated $mdpfile with tc-grps: $PROT_GROUP $WATER_GROUP"
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
