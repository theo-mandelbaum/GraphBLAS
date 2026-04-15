#!/bin/bash
#
# run_profiling_analysis.sh
# 
# This script implements STEP 2 of the profiling strategy:
# 1. Builds the instrumented GB_sort (already done in GB_sort.c)
# 2. Compiles the isolated deallocation micro-benchmark
# 3. Runs both and collects data in CSV format
# 4. Generates a comparison report
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRAPHBLAS_HOME="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results/dealloc"

mkdir -p "$RESULTS_DIR"

echo "========================================================================"
echo "Deallocation Profiling Analysis"
echo "========================================================================"
echo ""

# Step 2a: Rebuild GraphBLAS with instrumented GB_sort (only if needed)
echo "[1/3] Checking GraphBLAS build..."
if [ ! -f "$GRAPHBLAS_HOME/build/libgraphblas.so.10" ]; then
    echo "      Rebuilding GraphBLAS..."
    cd "$GRAPHBLAS_HOME"
    make clean >/dev/null 2>&1 || true
    make -j4 >/dev/null 2>&1
    echo "      Done."
else
    echo "      GraphBLAS already built, skipping rebuild."
fi
echo ""

# Step 2b: Build the isolated deallocation micro-benchmark
echo "[2/3] Building isolated deallocation micro-benchmark..."
gcc -std=c99 -O3 -fopenmp \
    -I"$GRAPHBLAS_HOME/Include" \
    -L"$GRAPHBLAS_HOME/build" \
    -o "$RESULTS_DIR/benchmark_dealloc" \
    "$SCRIPT_DIR/benchmark_dealloc.c" \
    -lgraphblas -lm

echo "      Done. Executable: $RESULTS_DIR/benchmark_dealloc"
echo ""

# Step 2c: Run the micro-benchmark to isolate deallocation cost
echo "[3/3] Running isolated deallocation micro-benchmark..."
echo "      (This may take a few minutes for large matrix sizes)"
export LD_LIBRARY_PATH="$GRAPHBLAS_HOME/build:$LD_LIBRARY_PATH"
timeout 600 "$RESULTS_DIR/benchmark_dealloc" 2>"$RESULTS_DIR/dealloc_benchmark.log" \
                                   >"$RESULTS_DIR/dealloc_timing.csv" || echo "Benchmark timed out after 10 minutes"

echo "      Done. Results saved to:"
echo "        - $RESULTS_DIR/dealloc_timing.csv"
echo "        - $RESULTS_DIR/dealloc_benchmark.log"
echo ""

# Step 2d: Generate analysis report
echo "========================================================================"
echo "ANALYSIS REPORT"
echo "========================================================================"
echo ""
echo "Deallocation Micro-Benchmark Results:"
echo "-------------------------------------"
echo "Header + first data rows from CSV output:"
echo ""
head -5 "$RESULTS_DIR/dealloc_timing.csv"
echo ""

echo "========================================================================"
