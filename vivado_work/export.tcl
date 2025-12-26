# =====================================================================
# Vivado Export Script for pynqpi
# Run this from inside vivado_work/
#
# Exports into ../vivado/:
#   - Block designs (write_bd_tcl)
#   - Standalone IP configuration (write_ip_tcl)
#   - HDL, constraints, and simulation sources
#
# Project recreation is done by ../vivado/scripts/import.tcl
#
# Usage:
#   vivado -mode batch -source export.tcl
# =====================================================================

# -----------------------------
# Project settings
# -----------------------------
set proj_name "pynqpi"
set proj_dir  "."   ;# vivado_work is the working directory

# -----------------------------
# Output repo structure (parent directory)
# -----------------------------
set base_out_dir      "../vivado"

set out_src_rtl       "$base_out_dir/src/rtl"
set out_src_sim       "$base_out_dir/src/sim"
set out_src_xdc       "$base_out_dir/src/constraints"
set out_bd_dir        "$base_out_dir/bd"
set out_ip_dir        "$base_out_dir/ip"
set out_scripts_dir   "$base_out_dir/scripts"

# Create directories if missing
foreach d [list $out_src_rtl $out_src_sim $out_src_xdc $out_bd_dir $out_ip_dir $out_scripts_dir] {
    file mkdir $d
}

# -----------------------------
# Open the project
# -----------------------------
puts "Opening project..."
open_project "$proj_dir/$proj_name.xpr"

# -----------------------------
# Export Project Info (Part, Board)
# -----------------------------
set proj_part [get_property PART [current_project]]
set proj_board [get_property BOARD_PART [current_project]]
set proj_info_script "$out_scripts_dir/project_info.tcl"

puts "Exporting project info..."
set fp [open $proj_info_script w]
puts $fp "set part_name \"$proj_part\""
if {$proj_board != ""} {
    puts $fp "set board_part \"$proj_board\""
} else {
    puts $fp "set board_part \"\""
}
close $fp
puts "Project info script written to: $proj_info_script"

# -----------------------------
# Export IP Repositories
# -----------------------------
set ip_repos [get_property ip_repo_paths [current_project]]
set ip_repo_script "$out_scripts_dir/ip_repos.tcl"

if {[llength $ip_repos] > 0} {
    puts "Exporting IP repositories..."
    set fp [open $ip_repo_script w]
    puts $fp "set_property ip_repo_paths \[list \\"
    foreach repo $ip_repos {
        # Normalize path to ensure it works across platforms/PWD changes
        # Assuming repo paths are relative to something or absolute. 
        # Ideally, we keep them as they are or make them relative to the project.
        # For now, let's keep them as is but formatted for Tcl list.
        puts $fp "    \"$repo\" \\"
    }
    puts $fp "\] \[current_project\]"
    puts $fp "update_ip_catalog"
    close $fp
    puts "IP repo script written to: $ip_repo_script"
} else {
    puts "No external IP repositories found."
    # Create an empty file or delete existing one to avoid stale config
    if {[file exists $ip_repo_script]} {
        file delete -force $ip_repo_script
    }
}

# -----------------------------
# Load BD files from the project
# -----------------------------
# In batch mode Vivado does NOT auto-load BDs.
# We must open the .bd files that belong to this project.
set bd_files [get_files *.bd]

if {[llength $bd_files] > 0} {
    foreach bd_file $bd_files {
        puts "Loading BD from project: $bd_file"
        open_bd_design $bd_file
    }
} else {
    puts "No block diagram files found in project."
}

# -----------------------------
# Export Block Designs (Vivado 2025.1 syntax)
# -----------------------------
set bds [get_bd_designs]

if {[llength $bds] > 0} {
    foreach bd $bds {
        set bd_name [get_property NAME $bd]
        
        # Skip generated block designs (e.g. bd_4b57)
        if {[regexp {^bd_[0-9a-f]+$} $bd_name]} {
            puts "Skipping generated/internal BD: $bd_name"
            continue
        }

        current_bd_design $bd_name
        set bd_out "$out_bd_dir/${bd_name}.tcl"
        puts "Exporting BD: $bd_name → $bd_out"
        write_bd_tcl -force $bd_out
    }
} else {
    puts "No BD designs loaded; nothing to export."
}

# -----------------------------
# Export Standalone IP (skip BD-owned IP)
# -----------------------------
set ips [get_ips]
foreach ip $ips {
    # Skip IPs that belong to a block design
    set ip_file [get_property IP_FILE $ip]
    if {[string match "*bd*" $ip_file]} {
        continue
    }

    set ip_name [get_property NAME $ip]
    set ip_out "$out_ip_dir/${ip_name}.tcl"
    puts "Exporting standalone IP: $ip_name → $ip_out"
    write_ip_tcl -force $ip $ip_out
}

# -----------------------------
# Copy HDL, XDC, and SIM files
# -----------------------------
proc copy_files {files dest} {
    foreach f $files {
        if {[file exists $f]} {
            # Normalize paths to check for equality
            set f_norm [file normalize $f]
            set dest_norm [file normalize "$dest/[file tail $f]"]
            if {$f_norm ne $dest_norm} {
                puts "Copying [file tail $f]..."
                file copy -force $f $dest
            } else {
                puts "Skipping [file tail $f] (already in destination)"
            }
        }
    }
}

# -----------------------------
# Debug matching files
# -----------------------------
set all_files [get_files]
puts "DEBUG: Found [llength $all_files] files in project."
foreach f $all_files {
    set type [get_property FILE_TYPE $f]
    puts "DEBUG: File: $f (Type: $type)"
}

# HDL
set hdl_files [get_files -filter {FILE_TYPE == "Verilog" || FILE_TYPE == "VHDL"}]
if {[llength $hdl_files] > 0} {
    puts "Copying HDL files..."
    copy_files $hdl_files $out_src_rtl
} else {
    puts "No HDL files found."
}

# Constraints
set xdc_files [get_files -filter {FILE_TYPE == "XDC"}]
if {[llength $xdc_files] > 0} {
    puts "Copying XDC files..."
    copy_files $xdc_files $out_src_xdc
} else {
    puts "No XDC files found."
}

# Simulation
set sim_files [get_files -filter {FILE_TYPE == "Simulation"}]
if {[llength $sim_files] > 0} {
    puts "Copying simulation files..."
    copy_files $sim_files $out_src_sim
} else {
    puts "No simulation files found."
}

# -----------------------------
# Cleanup
# -----------------------------
puts "Closing project..."
close_project

puts "==============================================================="
puts "Export complete."
puts "Vivado sources exported to ../vivado/"
puts "==============================================================="