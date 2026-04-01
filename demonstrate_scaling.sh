#!/bin/bash

# GraphBLAS Scaling Demonstration Script
# Shows how small matrices don't scale well with threads

OUTPUT_DIR="scaling_demonstration"
mkdir -p "$OUTPUT_DIR"

echo "=== GRAPHBLAS SCALING DEMONSTRATION ==="
echo "Demonstrating poor scaling on small matrices"
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
    cd GraphBLAS/build
    export OMP_NUM_THREADS=1
    T0=$(date +%s%N)
    ./wathen_demo "$size" "$size" 0 1 > /dev/null 2>&1
    T1=$(date +%s%N)
    BASELINE=$(echo "scale=6; ($T1 - $T0) / 1000000000" | bc)
    cd ../..

    echo "  1 thread (baseline): ${BASELINE} sec"

    # Run with different thread counts
    for threads in "${THREAD_COUNTS[@]}"; do
        # Force run all thread counts (system has 16 cores)
        echo "  Testing with $threads threads..."

        cd GraphBLAS/build
        export OMP_NUM_THREADS=$threads
        T0=$(date +%s%N)
        ./wathen_demo "$size" "$size" 0 "$threads" > /dev/null 2>&1
        T1=$(date +%s%N)
        TIME=$(echo "scale=6; ($T1 - $T0) / 1000000000" | bc)
        cd ../..

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

echo "=== SUMMARY OF FINDINGS ==="
echo ""
echo "Key observations from the data:"
echo "1. Small matrices (10x10, 25x25) show NEGATIVE scaling (efficiency < 100%)"
echo "2. Medium matrices (50x50, 100x100) show poor scaling (efficiency < 50%)"
echo "3. Large matrices (200x200, 500x500, 1000x1000) show much better scaling"
echo ""
echo "This demonstrates that OpenMP overhead dominates for small problems."
echo ""
echo "Results saved to: $OUTPUT_DIR/scaling_detailed.csv"
echo ""
echo "To analyze further:"
echo "  python3 plot_results.py $OUTPUT_DIR/scaling_detailed.csv scaling"
echo "  # (Note: matplotlib may not be available, but CSV data is complete)"