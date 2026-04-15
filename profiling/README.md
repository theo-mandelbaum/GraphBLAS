Profiling and analysis workflow for GraphBLAS
===========================================

This directory contains the scripts used to measure GraphBLAS cleanup and scaling costs.

Directories
-----------
  ./results/dealloc   - isolated deallocation benchmark outputs
  ./results/scaling   - benchmark scaling outputs
  ./results/analysis  - analysis outputs and logs
  ./results/poster    - poster visuals and chart generation

How to run
----------
1. Build GraphBLAS and demos from the repo root:

   cd ..
   make all

   # For faster compilation, use the repository recommendation:
   # make JOBS=32 all

2. Run the deallocation workflow:

   cd profiling
   chmod +x run_profiling_analysis.sh
   ./run_profiling_analysis.sh

   Outputs:
     ./results/dealloc/dealloc_timing.csv
     ./results/dealloc/dealloc_benchmark.log

3. Run the scaling test:

   chmod +x demonstrate_scaling.sh
   ./demonstrate_scaling.sh

   Output:
     ./results/scaling/scaling_detailed.csv

4. Run the analysis summary:

   chmod +x run_analysis.sh
   ./run_analysis.sh

   Outputs:
     ./results/analysis/

Poster visuals
--------------
To regenerate or inspect poster charts:

   cd profiling/results/poster

The poster chart generator requires Python packages:
   matplotlib, numpy, pandas

It is recommended to run this in a virtual environment.

Example:
   python3 -m venv .venv
   source .venv/bin/activate
   pip install matplotlib numpy pandas
   python generate_poster_charts.py

If you do not activate the venv, use the full interpreter path:
   /nfs/home/mandeltd/.venv/bin/python generate_poster_charts.py

Notes
-----
- All profiling scripts should be executed from `GraphBLAS/profiling`.
- The deallocation benchmark uses the GraphBLAS build in `GraphBLAS/build`.
- `demonstrate_scaling.sh` and `run_analysis.sh` require `GraphBLAS/build/wathen_demo`.
- If `wathen_demo` is missing, run `cd .. && make all`.
