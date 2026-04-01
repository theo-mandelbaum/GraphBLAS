#!/bin/bash

# Interactive bottleneck analysis script
# Guides you through profiling and documenting findings

OUTPUT_DIR="analysis_results"
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
if [ ! -f "GraphBLAS/build/libgraphblas.so.10" ]; then
    echo "ERROR: GraphBLAS not built. Run: cd GraphBLAS && make"
    exit 1
fi
echo "✓ GraphBLAS library found"
echo "✓ Library size: $(du -h GraphBLAS/build/libgraphblas.so.10 | awk '{print $1}')"
echo ""

# Test with perf
echo "=== PROFILING WATHEN_DEMO (100x100 matrix) ==="
if command -v perf &> /dev/null; then
    echo "Running perf profiling..."
    cd GraphBLAS/build
    perf record -o "$OLDPWD/$OUTPUT_DIR/perf.data" -g -- ./wathen_demo 100 100 2>/dev/null
    cd "$OLDPWD"
    
    echo "Recording perf results..."
    perf report -i "$OUTPUT_DIR/perf.data" --stdio > "$OUTPUT_DIR/perf_report.txt" 2>/dev/null
    
    echo "=== TOP 10 FUNCTIONS (by % of time) ==="
    grep "%" "$OUTPUT_DIR/perf_report.txt" | head -20 | tee "$OUTPUT_DIR/top_functions.txt"
else
    echo "⚠ perf not installed. Install with: sudo apt-get install linux-tools"
fi
echo ""

# Test with gprof
echo "=== PROFILING WITH GPROF ==="
if [ -f "GraphBLAS/build/wathen_demo" ]; then
    echo "Running with gprof..."
    cd GraphBLAS/build
    GMON_OUT_PREFIX="$OLDPWD/$OUTPUT_DIR" ./wathen_demo 100 100 2>/dev/null
    cd "$OLDPWD"
    
    if [ -f "$OUTPUT_DIR/gmon.out" ]; then
        gprof GraphBLAS/build/wathen_demo "$OUTPUT_DIR/gmon.out" > "$OUTPUT_DIR/gprof_report.txt" 2>/dev/null
        
        echo "=== GPROF RESULTS ==="
        head -50 "$OUTPUT_DIR/gprof_report.txt" | tee "$OUTPUT_DIR/gprof_summary.txt"
    fi
else
    echo "⚠ wathen_demo not found"
fi
echo ""

# Memory profiling
echo "=== MEMORY USAGE (via /usr/bin/time) ==="
cd GraphBLAS/build
/usr/bin/time -v ./wathen_demo 100 100 2>&1 > /dev/null | \
    grep -E "Elapsed|Maximum|Page" | tee "$OLDPWD/$OUTPUT_DIR/memory_usage.txt"
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
    cd GraphBLAS/build
    ./wathen_demo 100 100 0 $threads > /dev/null 2>&1
    cd "$OLDPWD"
    T1=$(date +%s%N)
    
    # Calculate time in seconds
    TIME=$(echo "scale=4; ($T1 - $T0) / 1000000000" | bc)
    echo "$threads,$TIME" >> "$OUTPUT_DIR/scaling_results.csv"
    echo "OK ($TIME sec)"
done
echo ""

# Code metrics
echo "=== CODE ANALYSIS ==="
echo "OpenMP pragmas:" | tee "$OUTPUT_DIR/code_metrics.txt"
grep -r "#pragma omp" GraphBLAS/Source/ 2>/dev/null | wc -l | tee -a "$OUTPUT_DIR/code_metrics.txt"

echo "" | tee -a "$OUTPUT_DIR/code_metrics.txt"
echo "Synchronization points:" | tee -a "$OUTPUT_DIR/code_metrics.txt"
grep -r "critical\|atomic\|barrier" GraphBLAS/Source/ 2>/dev/null | wc -l | tee -a "$OUTPUT_DIR/code_metrics.txt"

echo "" | tee -a "$OUTPUT_DIR/code_metrics.txt"
echo "Functions in Source/ (by size):" | tee -a "$OUTPUT_DIR/code_metrics.txt"
wc -l GraphBLAS/Source/*/*.c 2>/dev/null | sort -rn | head -10 | tee -a "$OUTPUT_DIR/code_metrics.txt"

echo ""
echo "=================================="
echo "Analysis complete!"
echo "Results saved to: $OUTPUT_DIR/"
echo ""
echo "Files generated:"
ls -lh "$OUTPUT_DIR/" | grep -v "^total" | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo "Next steps:"
echo "  1. Review results in $OUTPUT_DIR/"
echo "  2. Run: python3 plot_results.py $OUTPUT_DIR/scaling_results.csv"
echo "  3. Identify top 3 bottlenecks"
echo "  4. Document findings in your report"
