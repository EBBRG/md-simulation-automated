# pdb of ur protein name should be REC.pdb and sdf file try to rename and give LIG.sdf  and copy the files which req from req_files 
./convert_ligand.sh LIG.sdf
./fix_mol2_name.sh  LIG.mol2
perl sort_mol2_bonds.pl LIG.mol2 LIG_sorted.mol2
# goto the cgenff and make str file
unzip LIG.zip 
python cgenff_charmm2gmx_py3_nx1.py LIG LIG.mol2 LIG.str charmm36-jul2021.ff/

cat << EOF | gmx pdb2gmx -f REC.pdb -ignh -ter
1
1
0
0
EOF

./merge_lig.sh
./run_setup.sh
./auto*
nohup gmx mdrun -v -deffnm MD -cpi MD.cpt -nt 64 -pin on -nb gpu -pme gpu -bonded gpu -update gpu > MD_run.log 2>&1 &