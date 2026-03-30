Profiling Strategy: Deallocation Cost Analysis
================================================

This setup implements a two-phase profiling strategy to validate whether 
matrix deallocation is a significant bottleneck in GraphBLAS, as proposed 
for your research.

---

OVERVIEW
--------

Phase 1 (COMPLETE):
  ✓ Instrumented GB_sort.c to measure cleanup time
  ✓ Output: GBSORT_PROFILE CSV lines with matrix dimensions and cleanup overhead

Phase 2 (Ready to Run):
  • Isolated micro-benchmark: measures ONLY deallocation cost
  • Output: DEALLOC_PROFILE CSV lines with per-size statistics
  • Comparison: cleanup_ms (from Phase 1) vs avg_free_ms (Phase 2)

---

INSTRUMENTATION IN GB_SORT.C
----------------------------

What was added:
  • Line 14:      #include <time.h>, #include <stdio.h>
  • Lines 337-339: clock_gettime() call at function start (t_sort_start)
  • Lines 856-860: clock_gettime() around GB_FREE_WORKSPACE
  • Lines 862-873: Calculate total time, cleanup time, output GBSORT_PROFILE

Output format (to stderr):
  GBSORT_PROFILE: rows,cols,nnz,total_time_ms,sort_work_ms,cleanup_ms,cleanup_pct

Example:
  GBSORT_PROFILE: 10000,10000,100000,123.456789,120.123456,3.333333,2.71

Fields:
  • rows, cols, nnz      = matrix dimensions and nonzero count
  • total_time_ms        = end-to-end GB_sort execution time
  • sort_work_ms         = total_time - cleanup_time
  • cleanup_ms           = time spent in GB_FREE_WORKSPACE & conform
  • cleanup_pct          = (cleanup_ms / total_time_ms) * 100

---

PHASE 2: ISOLATED DEALLOCATION MICRO-BENCHMARK
----------------------------------------------

File: benchmark_dealloc.c

What it does:
  1. Pre-allocates N matrices of increasing size (1K to 10M nonzeros)
  2. For each size, runs 100-1000 trials of GrB_Matrix_free()
  3. Records timing statistics (min, avg, max, stddev)
  4. Outputs DEALLOC_PROFILE CSV lines

Output format (to stdout):
  DEALLOC_PROFILE: matrix_nnz,avg_free_ms,min_free_ms,max_free_ms,stddev_free_ms

Example:
  DEALLOC_PROFILE: 1000,0.001234,0.000987,0.002145,0.000234

---

RUNNING THE ANALYSIS
--------------------

Step 1: Run the full profiling script

  cd /nfs/home/mandeltd/GraphBLAS
  chmod +x run_profiling_analysis.sh
  ./run_profiling_analysis.sh

  Output:
    ./profiling_results/dealloc_timing.csv          (micro-benchmark results)
    ./profiling_results/dealloc_benchmark.log       (stderr from benchmark)

Step 2: Capture GBSORT_PROFILE data from your workload

  # Rebuild GB_sort (already done in profiling script)
  cd /nfs/home/mandeltd/GraphBLAS
  make

  # Run a GraphBLAS workload and capture GBSORT_PROFILE output
  # Example with a test case:
  cd /nfs/home/mandeltd/GraphBLAS/build/Demo
  ./bfs_demo 2>&1 | grep GBSORT_PROFILE > /tmp/gbsort_profiles.csv

  # Or create your own test that calls GrB_sort() many times with 
  # different matrix sizes

Step 3: Analyze results

  # Extract relevant GBSORT_PROFILE lines
  grep GBSORT_PROFILE /tmp/gbsort_profiles.csv > results/gbsort_data.csv

  # Compare the two datasets:
  #   GBSORT_PROFILE cleanup_ms vs DEALLOC_PROFILE avg_free_ms
  #
  # If GBSORT cleanup_ms >> DEALLOC avg_free_ms:
  #   → Other cleanup logic (GB_conform, etc.) is the bottleneck
  #
  # If cleanup_pct < 1%:
  #   → Deallocation is negligible; focus on other optimizations
  #
  # If cleanup_pct >= 10% AND cleanup_ms ≈ avg_free_ms:
  #   → Matrix deallocation IS a bottleneck worth optimizing

---

EXPECTED OUTCOMES
-----------------

Best case (validation of your hypothesis):
  cleanup_pct >= 10% in GBSORT_PROFILE
  GBSORT cleanup_ms ≈ DEALLOC avg_free_ms
  → Proceed with asynchronous deallocation optimization

Most likely (not a bottleneck):
  cleanup_pct < 2% in GBSORT_PROFILE
  → Deallocation is negligible expense
  → Pivot to nested-loop parallelism opportunities

Neutral (partially applicable):
  cleanup_pct = 5-9%
  GBSORT cleanup_ms >> DEALLOC avg_free_ms
  → Other cleanup steps (conform, etc.) dominate
  → Consider optimizing those instead

---

NEXT STEPS IF BOTTLENECK CONFIRMED
-----------------------------------

If cleanup_pct >= 10%, implement:

  1. Asynchronous matrix cleanup:
     - Create a background thread/task pool
     - Enqueue deallocation work instead of blocking
     - Continue GB_sort return while cleanup happens in background

  2. Batch deallocation:
     - Accumulate multiple matrix frees
     - Deallocate in parallel via OpenMP tasks

  3. NUMA awareness:
     - If available, deallocate memory on the NUMA node where it was allocated

  Sample skeleton in GB_sort.c:
  
    // Instead of:
    GB_FREE_WORKSPACE ;
    
    // Use:
    GB_async_free_enqueue(&T) ;  // Background cleanup
    // ... continue with conform and return immediately

---

FILES IN THIS SETUP
-------------------

  GB_sort.c                  - Instrumented with timing (already modified)
  benchmark_dealloc.c        - Isolated micro-benchmark executable
  run_profiling_analysis.sh  - Automated full profiling workflow
  PROFILING_README.md        - This document

---

TROUBLESHOOTING
---------------

Q: benchmark_dealloc won't compile
A: Make sure GraphBLAS is built first:
   cd /nfs/home/mandeltd/GraphBLAS && make -j4

Q: GBSORT_PROFILE lines not appearing
A: Ensure stderr is captured (2>&1 or 2>logfile)
   Output goes to stderr, not stdout.

Q: Numbers seem too small (e.g., 0.0001 ms)
A: Check CLOCK_MONOTONIC resolution on your system.
   May need higher precision timer for very small operations.

Q: How do I run GB_sort on custom matrices?
A: See examples in GraphBLAS/Demo/ for GrB_sort() usage, or write
   a simple test case that creates matrices of your target sizes.

---

PROFESSOR'S GUIDANCE CHECKLIST
-------------------------------

Your professor advised:
  ✓ Verify deallocation is a major latency source before optimizing
  ✓ Show experimental evidence (now you have GBSORT_PROFILE + DEALLOC_PROFILE)
  ✓ Make this the primary goal for the next couple of weeks

This setup enables you to:
  ✓ Measure cleanup overhead in context (GB_sort)
  ✓ Isolate deallocation cost (micro-benchmark)
  ✓ Report cleanup_pct as hard evidence
  ✓ Decide whether to pursue async optimization

If cleanup_pct < 1%, pivot gracefully to nested-loop parallelism (also
mentioned in professor's comments).

---

Contact / References
--------------------

GraphBLAS Source: /nfs/home/mandeltd/GraphBLAS/Source/
Instrumentation: See GB_sort.c lines 337-339, 856-873
Benchmark: benchmark_dealloc.c

For questions about profiling methodology or interpretation,
consult your professor with the GBSORT_PROFILE and DEALLOC_PROFILE data.
