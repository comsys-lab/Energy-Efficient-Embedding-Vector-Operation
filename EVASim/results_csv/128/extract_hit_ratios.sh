#!/bin/bash
# filepath: extract_hit_ratios.sh

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

# Create output filename (replace .log with .csv)
output_file="${filename%.log}.csv"

# Extract hit ratios and save to CSV
echo "Extracting hit ratios from $input_file..."
echo "batch_id,hit_ratio" > "$output_file"

# Find lines with "[Batch" and extract hit ratio
grep -E "\[Batch [0-9]+\] hit ratio:" "$input_file" | \
    sed -E 's/.*\[Batch ([0-9]+)\] hit ratio: ([0-9]+\.[0-9]+).*/\1,\2/' >> "$output_file"

# Calculate the number of entries correctly
total_entries=$(grep -c "^[0-9]" "$output_file")

echo "Hit ratios saved to $output_file"
echo "Total entries: $total_entries batches"