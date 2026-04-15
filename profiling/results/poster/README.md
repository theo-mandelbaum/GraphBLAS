Poster assets
=============

This folder contains charts and text used for presentation or poster materials.

Files
-----
  dealloc_scaling.png         - deallocation scaling plot
  dealloc_overhead_pct.png    - deallocation as % of sort time
  dealloc_vs_operations.png   - comparison with other GraphBLAS costs
  dealloc_summary.png         - summary table and findings
  deallocation_pie_chart.png  - poster pie chart for runtime breakdown
  deallocation_pie_chart.pdf  - poster PDF of the same chart
  runtime_breakdown.png       - runtime breakdown chart of top costs
  runtime_breakdown.pdf       - PDF export of runtime breakdown chart
  generate_poster_charts.py   - script that generates the charts
  generate_runtime_breakdown.py - script that generates the runtime breakdown chart

Usage
-----
This script requires Python and the following packages:
  - matplotlib
  - numpy
  - pandas

It is recommended to run the script from a virtual environment.

Example (MacOS/Linux):
  python3 -m venv .venv
  source .venv/bin/activate
  pip install matplotlib numpy pandas
  cd GraphBLAS/profiling/results/poster
  python generate_poster_charts.py

If you do not activate a virtual environment, use the venv Python directly:
  /nfs/home/mandeltd/.venv/bin/python generate_poster_charts.py

Data source
-----------
The poster chart script reads benchmark results from:
  ../dealloc/dealloc_timing.csv

The runtime breakdown chart uses:
  runtime_breakdown.csv (sample data)

If you want the latest runtime dominance view, remove or rename `runtime_breakdown.csv` and let the script parse `../analysis/top_functions.txt` automatically.

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
