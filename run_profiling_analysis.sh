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

GRAPHBLAS_HOME="/nfs/home/mandeltd/GraphBLAS"
RESULTS_DIR="./profiling_results"

mkdir -p "$RESULTS_DIR"

echo "========================================================================"
echo "STEP 2: Deallocation Profiling Analysis"
echo "========================================================================"
echo ""

# Step 2a: Rebuild GraphBLAS with instrumented GB_sort
echo "[1/3] Rebuilding GraphBLAS with timing instrumentation..."
cd "$GRAPHBLAS_HOME"
make clean >/dev/null 2>&1 || true
make -j4 >/dev/null 2>&1

echo "      Done. GraphBLAS built with GB_sort timing instrumentation."
echo ""

# Step 2b: Build the isolated deallocation micro-benchmark
echo "[2/3] Building isolated deallocation micro-benchmark..."
gcc -std=c99 -O3 -fopenmp \
    -I"$GRAPHBLAS_HOME/Include" \
    -L"$GRAPHBLAS_HOME/build" \
    -o "$RESULTS_DIR/benchmark_dealloc" \
    "$GRAPHBLAS_HOME/benchmark_dealloc.c" \
    -lgraphblas -lm

echo "      Done. Executable: $RESULTS_DIR/benchmark_dealloc"
echo ""

# Step 2c: Run the micro-benchmark to isolate deallocation cost
echo "[3/3] Running isolated deallocation micro-benchmark..."
echo "      (This may take a few minutes for large matrix sizes)"
export LD_LIBRARY_PATH="$GRAPHBLAS_HOME/build:$LD_LIBRARY_PATH"
"$RESULTS_DIR/benchmark_dealloc" 2>"$RESULTS_DIR/dealloc_benchmark.log" \
                                   >"$RESULTS_DIR/dealloc_timing.csv"

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
grep "DEALLOC_PROFILE:" "$RESULTS_DIR/dealloc_timing.csv" | while read line; do
    echo "  $line"
done
echo ""

echo "Next Steps:"
echo "-----------"
echo "1. Run GB_sort with various input sizes and capture GBSORT_PROFILE output"
echo "2. Compare GBSORT_PROFILE cleanup_ms with DEALLOC_PROFILE avg_free_ms"
echo "3. If cleanup_percent < 1%%, deallocation is NOT a bottleneck"
echo "4. If cleanup_percent >= 10%%, proceed with async deallocation optimization"
echo ""
echo "To run GB_sort in production and capture GBSORT_PROFILE lines:"
echo "  export GRAPHBLAS_LIB_PATH=$GRAPHBLAS_HOME/build"
echo "  (run your GraphBLAS application) 2>&1 | grep GBSORT_PROFILE"
echo ""

echo "========================================================================"
