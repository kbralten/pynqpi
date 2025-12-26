# Vivado Work Directory & Workflow

## Overview
This directory (`vivado_work/`) is the **ephemeral working area** for the Vivado project. It is **NOT** the primary source of truth for version control.

The actual source files (RTL, Constraints, Block Design Tcl scripts, IP configurations) are stored in the sibling `../vivado/` directory, which is version-controlled.

## Workflow

### 1. Working on the Project
*   Open the project file `pynqpi.xpr` in Vivado from this directory.
*   Make your changes (edit BD, change properties, add IPs) using the Vivado GUI.
*   **DO NOT** manually commit changes inside `vivado_work/` (except these scripts).

### 2. Exporting Changes (Save to Git)
To save your work to the version-controlled `../vivado/` directory, run the export script:

```bash
vivado -mode batch -source export.tcl
```

This script will:
*   Export the Block Designs to Tcl scripts (`../vivado/bd/`).
*   Export Standalone IP configurations (`../vivado/ip/`).
*   Copy RTL, Simulation, and Constraint files to `../vivado/src/`.
*   Save Project Info (Part/Board) and IP Repository paths.

### 3. Importing/Resetting the Project
To wipe the current project state and recreate it cleanly from the `../vivado/` sources, run the import script:

```bash
vivado -mode batch -source import.tcl
```

**WARNING**: This will delete the `pynqpi.xpr` and generated files in this directory!

This script will:
*   Delete the existing project.
*   Create a new project using the correct Part/Board.
*   Restore IP Repository paths.
*   Import all sources from `../vivado/`.
*   Recreate Block Designs from their Tcl scripts.

## Directory Structure Relation

*   `vivado_work/` (This Directory):
    *   `export.tcl`: Script to save changes.
    *   `import.tcl`: Script to restore/build the project.
    *   `pynqpi.xpr`: The active Vivado project file (generated).
    *   `pynqpi.srcs/`, `pynqpi.gen/`, etc.: Vivado generated local state.

*   `../vivado/` (Source Directory):
    *   `src/`: RTL, Simulation, and Constraint source files.
    *   `bd/`: Tcl scripts for recreating Block Designs.
    *   `ip/`: Tcl scripts for Standalone IPs.
    *   `scripts/`: Helper scripts (`ip_repos.tcl`, `project_info.tcl`).
