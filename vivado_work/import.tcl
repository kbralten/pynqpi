# =====================================================================
# Vivado Import Script for pynqpi
# Run this from inside vivado_work/
#
# Recreates a clean Vivado project using sources from ../vivado/
#
# Usage:
#   vivado -mode batch -source import.tcl
# =====================================================================

# -----------------------------
# Project settings
# -----------------------------
set proj_name "pynqpi"
set proj_dir  "."   ;# vivado_work directory

# -----------------------------
# Source directory (parent)
# -----------------------------
set base_src_dir "../vivado"

set part_name "xc7z020clg400-1"   ;# PYNQ-Z1/Z2 default
set board_part ""

# -----------------------------
# Restore Project Info
# -----------------------------
set proj_info_script "$base_src_dir/scripts/project_info.tcl"
if {[file exists $proj_info_script]} {
    puts "Restoring project info from: $proj_info_script"
    source $proj_info_script
    
    # Check if the imported part is the Vivado default (Artix-7), which is likely wrong for this PYNQ project
    if {$part_name == "xc7a35tcsg324-1"} {
        puts "WARNING: Imported part is the default Artix-7 ($part_name), which is likely incorrect."
        puts "Overriding with PYNQ default: xc7z020clg400-1"
        set part_name "xc7z020clg400-1"
        set board_part "www.digilentinc.com:pynq-z1:part0:1.0"
        puts "Overriding board part with PYNQ-Z1 default: $board_part"
    }
} else {
    puts "No project info script found ($proj_info_script). Using default part: $part_name"
}

set src_rtl_dir        "$base_src_dir/src/rtl"
set src_sim_dir        "$base_src_dir/src/sim"
set src_xdc_dir        "$base_src_dir/src/constraints"
set bd_dir             "$base_src_dir/bd"
set ip_dir             "$base_src_dir/ip"

# -----------------------------
# Define Local Directories (Sandbox)
# -----------------------------
set local_src_dir      "$proj_dir/src"
set local_rtl_dir      "$local_src_dir/rtl"
set local_sim_dir      "$local_src_dir/sim"
set local_xdc_dir      "$local_src_dir/constraints"

# Create local directories
foreach d [list $local_src_dir $local_rtl_dir $local_sim_dir $local_xdc_dir] {
    file mkdir $d
}

# -----------------------------
# Clean any previous project
# -----------------------------
if {[file exists "$proj_dir/$proj_name.xpr"]} {
    puts "Removing old project..."
    file delete -force "$proj_dir/$proj_name.xpr"
    file delete -force "$proj_dir/$proj_name.cache"
    file delete -force "$proj_dir/$proj_name.hw"
    file delete -force "$proj_dir/$proj_name.ip_user_files"
    file delete -force "$proj_dir/$proj_name.runs"
    file delete -force "$proj_dir/$proj_name.sim"
}

# -----------------------------
# Create a new project
# -----------------------------
puts "Creating new project..."
if {$board_part != ""} {
    puts "Using board part: $board_part"
    create_project $proj_name $proj_dir -part $part_name -force
    if {[catch {set_property board_part $board_part [current_project]} errmsg]} {
        puts "WARNING: Failed to set board part '$board_part': $errmsg"
        puts "Continuing without board part..."
        set board_part "" ;# clear it so we don't try to use it later
    }
} else {
    create_project $proj_name $proj_dir -part $part_name -force
}
set_property target_language Verilog [current_project]

# -----------------------------
# Import HDL sources
# -----------------------------
if {[file exists $src_rtl_dir]} {
    set rtl_list [glob -nocomplain "$src_rtl_dir/*"]
    if {[llength $rtl_list] > 0} {
        puts "Copying and importing RTL sources..."
        foreach f $rtl_list {
            file copy -force $f $local_rtl_dir
        }
        set local_rtl_list [glob -nocomplain "$local_rtl_dir/*"]
        add_files -norecurse $local_rtl_list
    } else {
        puts "No RTL sources found."
    }
}


# -----------------------------
# Import simulation sources
# -----------------------------
if {[file exists $src_sim_dir]} {
    set sim_list [glob -nocomplain "$src_sim_dir/*"]
    if {[llength $sim_list] > 0} {
        puts "Copying and importing simulation sources..."
        foreach f $sim_list {
            file copy -force $f $local_sim_dir
        }
        set local_sim_list [glob -nocomplain "$local_sim_dir/*"]
        add_files -fileset sim_1 -norecurse $local_sim_list
    } else {
        puts "No simulation sources found."
    }
}


# -----------------------------
# Import constraints
# -----------------------------
if {[file exists $src_xdc_dir]} {
    set xdc_list [glob -nocomplain "$src_xdc_dir/*"]
    if {[llength $xdc_list] > 0} {
        puts "Copying and importing XDC constraints..."
        foreach f $xdc_list {
            file copy -force $f $local_xdc_dir
        }
        set local_xdc_list [glob -nocomplain "$local_xdc_dir/*"]
        add_files -fileset constrs_1 -norecurse $local_xdc_list
    } else {
        puts "No XDC constraints found."
    }
}


# -----------------------------
# Restore IP Repositories
# -----------------------------
set ip_repo_script "$base_src_dir/scripts/ip_repos.tcl"
if {[file exists $ip_repo_script]} {
    puts "Restoring IP repositories from: $ip_repo_script"
    source $ip_repo_script
} else {
    puts "No IP repository script found ($ip_repo_script)."
}

# -----------------------------
# Recreate standalone IP
# -----------------------------
set ip_scripts [glob -nocomplain "$ip_dir/*.tcl"]
foreach ip_tcl $ip_scripts {
    puts "Recreating standalone IP from: $ip_tcl"
    source $ip_tcl
}

# -----------------------------
# Recreate block designs
# -----------------------------
# -----------------------------
# Sanitize BD Tcl files (remove board dependencies if board missing)
# -----------------------------
proc sanitize_bd_tcl {file_path} {
    puts "Sanitizing BD script: $file_path (SKIPPED - Board Interface preservation enabled)"
    # Previously, this function stripped GPIO_BOARD_INTERFACE to prevent errors
    # if the board definition was missing. We now keep it to support board automation/presets.
    
    # No-op: Do not modify the file.
    return
}

# Create local bd directory
set local_bd_dir "$proj_dir/bd"
file mkdir $local_bd_dir

set bd_scripts [glob -nocomplain "$bd_dir/*.tcl"]
foreach bd_tcl $bd_scripts {
    # Determine local path
    set bd_filename [file tail $bd_tcl]
    set local_bd_tcl "$local_bd_dir/$bd_filename"
    
    # Copy to sandbox
    puts "Copying Block Design script to sandbox: $bd_tcl"
    file copy -force $bd_tcl $local_bd_tcl

    puts "Recreating Block Design from: $local_bd_tcl"
    sanitize_bd_tcl $local_bd_tcl
    source $local_bd_tcl
}


puts "==============================================================="
puts "Import complete."
puts "Vivado project recreated in vivado_work/"
puts "==============================================================="