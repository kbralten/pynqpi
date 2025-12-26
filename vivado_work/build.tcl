# =====================================================================
# Vivado Build Script for pynqpi
# Run this from inside vivado_work/
#
# Performs:
#   - Open project
#   - Synthesis
#   - Implementation
#   - Bitstream generation
#   - XSA export (including bitstream)
#
# Usage:
#   vivado -mode batch -source build.tcl
# =====================================================================

# -----------------------------
# Project settings
# -----------------------------
set proj_name "pynqpi"
set proj_dir  "."   ;# vivado_work directory

# Output XSA location (in parent repo)
set xsa_out "../vivado/pynqpi.xsa"

# -----------------------------
# Open the project
# -----------------------------
puts "Opening project..."
open_project "$proj_dir/$proj_name.xpr"

# -----------------------------
# Run Synthesis
# -----------------------------
puts "Running synthesis..."
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# -----------------------------
# Run Implementation
# -----------------------------
puts "Running implementation..."
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# -----------------------------
# Generate Bitstream
# -----------------------------
puts "Generating bitstream..."
# (Bitstream is generated as part of impl_1 above)
# But we explicitly ensure it exists:
if {![file exists "$proj_dir/$proj_name.runs/impl_1/${proj_name}.bit"]} {
    error "Bitstream not found — implementation may have failed."
}

# -----------------------------
# Export XSA (with bitstream)
# -----------------------------
puts "Exporting XSA → $xsa_out"
file mkdir [file dirname $xsa_out]

write_hw_platform \
    -fixed \
    -include_bit \
    -force \
    -file $xsa_out

# -----------------------------
# Save and close
# -----------------------------
puts "Saving project..."
save_project_as $proj_name $proj_dir

puts "Closing project..."
close_project

puts "==============================================================="
puts "Build complete."
puts "Bitstream generated and XSA exported to: $xsa_out"
puts "==============================================================="