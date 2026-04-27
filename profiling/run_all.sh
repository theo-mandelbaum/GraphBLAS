#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Step 2: deallocation workflow
chmod +x run_profiling_analysis.sh
./run_profiling_analysis.sh

# Step 3: scaling test
chmod +x demonstrate_scaling.sh
./demonstrate_scaling.sh

# Step 4: analysis summary
chmod +x run_analysis.sh
./run_analysis.sh

# Poster visuals
cd results/poster

if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi
source .venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install matplotlib numpy pandas

python3 generate_poster_charts.py
python3 generate_runtime_breakdown.py
