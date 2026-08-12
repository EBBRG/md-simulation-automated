# MD Simulation Automated

### An Automated CHARMM36 Protein–Ligand Molecular Dynamics Workflow for GROMACS
<div align="justify">
MD Simulation Automated is a scripted, end-to-end molecular dynamics (MD) pipeline that takes a prepared protein–ligand complex and produces an equilibrated, production-ready GROMACS system — including CHARMM-GUI-style ligand parameterisation, topology assembly, solvation, ion neutralisation, energy minimisation, and NVT/NPT equilibration.

The pipeline removes the manual step-by-step `gmx` choreography of a typical MD setup and replaces it with a deterministic, repeatable workflow, suitable for drug-discovery and computational-biophysics projects.

Developed and maintained by the **Evo Biology and Bioinformatics Research Group (EBBRG)**, University of Agriculture Faisalabad.

---



## Table of Contents

- [Features](#features)
- [Workflow](#workflow)
- [Installation](#installation)
- [Usage](#usage)
- [Inputs & Outputs](#inputs--outputs)
- [Script Reference](#script-reference)
- [Dependencies](#dependencies)
- [Repository Structure](#repository-structure)
- [Citation](#citation)
- [License](#license)
- [Contact](#contact)

---

## Features

- **Ligand parameterisation** — CHARMM-GUI style `cgenff` → GROMACS conversion with corrected MOL2 handling
- **Automated box setup** — triclinic box definition, solvation, and ion neutralisation (0.1 M optional)
- **Energy minimisation** — steepest descent followed by conjugate-gradient refinement
- **Equilibration** — automatic NVT → NPT with position restraints and Berendsen temperature/pressure coupling
- **Production-ready output** — indexed system, topology, and parameter files ready for a production MD run
- **Robust merging** — CHARMM36 protein–ligand merger with bond-order corrections (`sort_mol2_bonds.pl`)
- **Idempotent, safe defaults** — `set -e` guarded scripts, clear failure points, per-step logging

---

## Workflow

```
REC.pdb + LIG.sdf
        │
        ▼
 1. Ligand conversion (SDF → PDB/MOL2/PDBQT, hydrogens + Gasteiger)
        │
        ▼
 2. CHARMM-GUI cgenff parameterisation (cgenff_charmm2gmx)
        │
        ▼
 3. Topology assembly + protein–ligand merge (merge_lig.sh)
        │
        ▼
 4. Box definition → solvation → ion neutralisation (run_setup.sh)
        │
        ▼
 5. Energy minimisation (EM)
        │
        ▼
 6. NVT equilibration ──► 7. NPT equilibration (auto_nvt_npt_md*.sh)
        │
        ▼
 Production-ready system
```

---

## Installation

### Requirements

- **GROMACS** ≥ 2021 (with MPI/thread-MPI as needed)
- **Python 3** with `numpy` and `networkx` (1.x series for `cgenff_charmm2gmx`)
- **Perl** (for `sort_mol2_bonds.pl`)
- **Open Babel** (ligand conversion)
- A CHARMM36 force-field directory (e.g. `charmm36.ff`)

### Clone

```bash
git clone https://github.com/EBBRG/md-simulation-automated.git
cd md-simulation-automated
chmod +x *.sh
```

---

## Usage

### 1. Prepare your input files

- Protein structure → `REC.pdb`
- Ligand structure → `LIG.sdf`
- Generate the ligand `.str` parameters with CHARMM-GUI cgenff

### 2. Convert and parameterise the ligand

```bash
./convert_ligand.sh LIG.sdf
python cgenff_charmm2gmx_py3_nx1.py DRUG drug.mol2 drug.str charmm36.ff
```

### 3. Merge protein and ligand

```bash
./merge_lig.sh
```

### 4. Build the simulation box

```bash
./run_setup.sh
```

### 5. Equilibrate

```bash
# From EM.gro onward — automatic NVT → NPT:
./auto_nvt_npt_md.sh
# Alternative with modified settings:
./auto_nvt_npt_md_m.sh
```

---

## Inputs & Outputs

**Inputs:** `REC.pdb` (protein), `LIG.sdf` (ligand), cgenff `.str` parameters, CHARMM36 force field.

**Outputs:** solvated/neutralised box files (`box.gro`, `box_sol.gro`), topology (`topol.top`), minimised and equilibrated trajectories (`EM.gro`, `nvt.gro`, `npt.gro`), index and parameter files ready for production MD.

---

## Script Reference

| Script | Purpose |
|---|---|
| `convert_ligand.sh` | SDF → PDB/MOL2/PDBQT with hydrogens and Gasteiger charges |
| `cgenff_charmm2gmx_py3_nx1.py` | CHARMM-GUI `cgenff` ligand → GROMACS parameterisation (Python 3) |
| `fix_mol2_name.sh` | Renormalise MOL2 molecule name to `LIG` |
| `merge_lig.sh` | CHARMM36 protein–ligand topology merger |
| `sort_mol2_bonds.pl` | Bond-order reordering for `@<TRIPOS>BOND` blocks |
| `run_setup.sh` | Box definition, solvation, ion neutralisation |
| `auto_nvt_npt_md.sh` / `_m.sh` | Automatic NVT + NPT equilibration from `EM.gro` |
| `complete_auto_algo_script.sh` | End-to-end driver (REC.pdb + LIG.sdf → equilibration) |

---

## Dependencies

| Tool | Purpose |
|---|---|
| GROMACS | Core MD engine |
| Python 3 (numpy, networkx 1.x) | cgenff→GROMACS conversion |
| Open Babel | Ligand format conversion |
| Perl | MOL2 bond sorting |
| CHARMM36 FF | Force field |

---

## Repository Structure

```
md-simulation-automated/
│
├── auto_nvt_npt_md.sh / _m.sh   # NVT → NPT equilibration
├── cgenff_charmm2gmx_py3_nx1.py # Ligand parameterisation
├── convert_ligand.sh            # Ligand conversion
├── fix_mol2_name.sh             # MOL2 name normalisation
├── merge_lig.sh                 # Protein–ligand merge
├── sort_mol2_bonds.pl           # Bond-order sorting
├── run_setup.sh                 # Box/solvation/ions
├── complete_auto_algo_script.sh # End-to-end driver
├── LICENSE
└── README.md
```

---

## Citation

If you use this pipeline in your research, please cite the EBBRG group and link to this repository:

> Evo Biology and Bioinformatics Research Group (EBBRG). *MD Simulation Automated: CHARMM36 Protein–Ligand MD Workflow for GROMACS.* University of Agriculture Faisalabad. https://github.com/EBBRG/md-simulation-automated

---

## License

Released under the **MIT License**. See `LICENSE`.

---

## Contact

**Evo Biology and Bioinformatics Research Group (EBBRG)**
University of Agriculture Faisalabad, Pakistan

For questions, bug reports, or feature requests, please use the GitHub issue tracker.

</div>
