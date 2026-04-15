#!/bin/bash

# GraphBLAS Scaling Demonstration Script
# Produces a CSV of timing, speedup, and efficiency for the benchmark binary.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRAPHBLAS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/results/scaling"
mkdir -p "$OUTPUT_DIR"

WATHEN_BIN="$GRAPHBLAS_ROOT/build/wathen_demo"
if [ ! -x "$WATHEN_BIN" ]; then
    echo "ERROR: Benchmark binary not found: $WATHEN_BIN"
    echo "Build GraphBLAS with demos first:"
    echo "  cd $GRAPHBLAS_ROOT"
    echo "  make all"
    echo "Then rerun this script from GraphBLAS/profiling."
    exit 1
fi

echo "=== GRAPHBLAS SCALING DEMONSTRATION ==="
echo "Generating CSV timing results for the GraphBLAS benchmark."
echo ""

# Test different matrix sizes
MATRIX_SIZES=(10 25 50 100 200 500 1000 2000)
THREAD_COUNTS=(1 2 4 8 16)

echo "Testing matrix sizes: ${MATRIX_SIZES[*]}"
echo "Thread counts: ${THREAD_COUNTS[*]}"
echo ""

# Create CSV header
echo "matrix_size,threads,time_sec,speedup,efficiency" > "$OUTPUT_DIR/scaling_detailed.csv"

# Run tests for each matrix size
for size in "${MATRIX_SIZES[@]}"; do
    echo "=== Testing ${size}x${size} matrix ==="

    # Run single-threaded baseline
    cd "$GRAPHBLAS_ROOT/build"
    export OMP_NUM_THREADS=1
    T0=$(date +%s%N)
    "$WATHEN_BIN" "$size" "$size" 0 1 > /dev/null 2>&1
    T1=$(date +%s%N)
    BASELINE=$(echo "scale=6; ($T1 - $T0) / 1000000000" | bc)
    cd "$GRAPHBLAS_ROOT"

    echo "  1 thread (baseline): ${BASELINE} sec"

    # Run with different thread counts
    for threads in "${THREAD_COUNTS[@]}"; do
        # Force run all thread counts (system has 16 cores)
        echo "  Testing with $threads threads..."

        cd "$GRAPHBLAS_ROOT/build"
        export OMP_NUM_THREADS=$threads
        T0=$(date +%s%N)
        "$WATHEN_BIN" "$size" "$size" 0 "$threads" > /dev/null 2>&1
        T1=$(date +%s%N)
        TIME=$(echo "scale=6; ($T1 - $T0) / 1000000000" | bc)
        cd "$GRAPHBLAS_ROOT"

        # Calculate speedup and efficiency
        if [ "$threads" -eq 1 ]; then
            SPEEDUP="1.000"
            EFFICIENCY="100.0"
        else
            SPEEDUP=$(echo "scale=3; $BASELINE / $TIME" | bc)
            EFFICIENCY=$(echo "scale=1; $SPEEDUP * 100 / $threads" | bc)
        fi

        echo "  $threads threads: ${TIME} sec (speedup: ${SPEEDUP}x, efficiency: ${EFFICIENCY}%)"
        echo "$size,$threads,$TIME,$SPEEDUP,$EFFICIENCY" >> "$OUTPUT_DIR/scaling_detailed.csv"
    done
    echo ""
done

echo "=== RESULTS ==="
echo "Results saved to: $OUTPUT_DIR/scaling_detailed.csv"