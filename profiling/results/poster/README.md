Poster assets
=============

This folder contains charts and text used for presentation or poster materials.

Files
-----
  dealloc_scaling.png         - deallocation scaling plot
  dealloc_overhead_pct.png    - deallocation as % of sort time
  dealloc_vs_operations.png   - comparison with other GraphBLAS costs
  dealloc_summary.png         - summary table and findings
  generate_poster_charts.py   - script that generates the charts

Usage
-----
Run `python3 generate_poster_charts.py` from this directory.

Data source
-----------
The chart script reads benchmark results from:
  ../dealloc/dealloc_timing.csv

This directory is intentionally separated from the raw benchmark outputs.

Poster summary
--------------
Key findings included here are based on the benchmark data and visual narrative:
  - Deallocation cost is sub-microsecond for typical sizes.
  - 100K nonzeros: ~0.0002 ms deallocation time.
  - 10M nonzeros: ~0.0007 ms deallocation time.
  - Deallocation represents < 0.001% of sort operation cost for typical matrices.
  - Scaling is sub-linear and highly predictable.

Recommended message
-------------------
  "Is Matrix Deallocation a Bottleneck? ANSWER: NO"

  Focus optimization where it matters:
    • sort inner-loop work
    • matrix multiply / transpose kernels
    • memory bandwidth and data movement
