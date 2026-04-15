#!/bin/bash

# Interactive bottleneck analysis script
# Guides you through profiling and documenting findings

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/results/analysis"
mkdir -p "$OUTPUT_DIR"

echo "=================================="
echo "GraphBLAS Bottleneck Analysis Tool"
echo "=================================="
echo ""

# System info
echo "=== SYSTEM INFORMATION ==="
echo "Date: $(date)" | tee "$OUTPUT_DIR/system_info.txt"
echo "Hostname: $(hostname)" | tee -a "$OUTPUT_DIR/system_info.txt"
echo "CPU cores: $(nproc)" | tee -a "$OUTPUT_DIR/system_info.txt"
echo "RAM: $(free -h | grep Mem | awk '{print $2}')" | tee -a "$OUTPUT_DIR/system_info.txt"
echo "GCC version: $(gcc --version | head -1)" | tee -a "$OUTPUT_DIR/system_info.txt"
echo "OpenMP version: $(echo | gcc -E -dM - | grep -i omp_version | head -1)" | tee -a "$OUTPUT_DIR/system_info.txt"
echo ""

# Check GraphBLAS build
echo "=== CHECKING GRAPHBLAS BUILD ==="
if [ ! -f "$REPO_ROOT/build/libgraphblas.so.10" ]; then
    echo "ERROR: GraphBLAS not built. Run: cd $REPO_ROOT && make all"
    exit 1
fi
if [ ! -x "$REPO_ROOT/build/wathen_demo" ]; then
    echo "ERROR: wathen_demo not found. Build GraphBLAS demos with:"
    echo "  cd $REPO_ROOT"
    echo "  make all"
    exit 1
fi
echo "✓ GraphBLAS library found"
echo "✓ Library size: $(du -h "$REPO_ROOT/build/libgraphblas.so.10" | awk '{print $1}')"
echo ""

# Test with perf
echo "=== PROFILING WATHEN_DEMO (100x100 matrix) ==="
if command -v perf &> /dev/null; then
    echo "Running perf profiling..."
    cd "$REPO_ROOT/build"
    perf record -o "$OUTPUT_DIR/perf.data" -g -- ./wathen_demo 100 100 2>/dev/null
    cd "$OLDPWD"
    
    echo "Recording perf results..."
    perf report -i "$OUTPUT_DIR/perf.data" --stdio > "$OUTPUT_DIR/perf_report.txt" 2>/dev/null
    
    echo "=== TOP 10 FUNCTIONS (by % of time) ==="
    grep "%" "$OUTPUT_DIR/perf_report.txt" | head -20 | tee "$OUTPUT_DIR/top_functions.txt"
else
    echo "⚠ perf not installed. Install with: sudo apt-get install linux-tools"
fi
echo ""

# Memory profiling
echo "=== MEMORY USAGE (via /usr/bin/time) ==="
cd "$REPO_ROOT/build"
/usr/bin/time -v ./wathen_demo 100 100 2>&1 > /dev/null | \
    grep -E "Elapsed|Maximum|Page" | tee "$OUTPUT_DIR/memory_usage.txt"
cd "$OLDPWD"
echo ""

# Scaling test
echo "=== STRONG SCALING TEST ==="
echo "Testing with increasing thread counts..."
echo "threads,time_sec" > "$OUTPUT_DIR/scaling_results.csv"

for threads in 1 2 4 8 16 32; do
    # Skip if more threads than cores
    if [ "$threads" -gt "$(nproc)" ]; then
        echo "Skipping $threads threads (> $(nproc) cores)"
        continue
    fi
    
    echo -n "  Threads: $threads ... "
    export OMP_NUM_THREADS=$threads
    
    # Time the command
    T0=$(date +%s%N)
    cd "$REPO_ROOT/build"
    ./wathen_demo 100 100 0 $threads > /dev/null 2>&1
    cd "$OLDPWD"
    T1=$(date +%s%N)
    
    # Calculate time in seconds
    TIME=$(echo "scale=4; ($T1 - $T0) / 1000000000" | bc)
    echo "$threads,$TIME" >> "$OUTPUT_DIR/scaling_results.csv"
    echo "OK ($TIME sec)"
done
echo ""

echo "=================================="
echo "Analysis complete!"
echo "Results saved to: $OUTPUT_DIR/"
