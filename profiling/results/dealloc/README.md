Deallocation profiling results
=============================

This folder stores the isolated deallocation benchmark outputs.

Files
-----
  dealloc_timing.csv         - CSV output from the benchmark
  dealloc_benchmark.log      - stderr log from the benchmark run
  benchmark_dealloc          - compiled benchmark executable
  gbsort_test.log            - example or previous sort profiling log

Usage
-----
Run `../run_profiling_analysis.sh` from `GraphBLAS/profiling`.

Interpretation
--------------
Compare `avg_free_ms` in `dealloc_timing.csv` with cleanup times from
`GBSORT_PROFILE` output to judge whether deallocation is a real bottleneck.
