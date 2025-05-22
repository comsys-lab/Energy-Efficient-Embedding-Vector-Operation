#!/bin/bash
# filepath: energy_extract.sh

# Check if a file path was provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <log_file_path>"
    exit 1
fi

input_file="$1"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: File '$input_file' not found."
    exit 1
fi

# Extract the filename without path
filename=$(basename "$input_file")

# Create output filename (replace .log with .energy.csv)
output_file="energy_${filename%.log}.csv"

# Extract energy data and save to CSV
echo "Extracting batch energy data from $input_file..."
echo "batch_id,total_energy_pJ" > "$output_file"

# Process the file section by section
# Find lines with batch numbers and their corresponding total energy values
grep -A 5 "Batch [0-9]\+:" "$input_file" | grep -B 5 "Total Energy:" | 
awk '
/Batch ([0-9]+):/ { 
    match($0, /Batch ([0-9]+):/, arr);
    batch = arr[1];
}
/Total Energy: [0-9.]+/ { 
    match($0, /Total Energy: ([0-9.]+)/, arr);
    energy = arr[1];
    if (batch != "") {
        printf "%s,%s\n", batch, energy;
        batch = "";
    }
}
' >> "$output_file"

total_entries=$(grep -c "^[0-9]" "$output_file")
echo "Batch energy data saved to $output_file"
echo "Total entries: $total_entries batches"