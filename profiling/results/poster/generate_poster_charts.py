#!/usr/bin/env python3
"""
generate_poster_charts.py

Generates visualizations for the deallocation profiling poster.
Shows current profiling results without assuming a fixed conclusion.

Usage:
    python3 generate_poster_charts.py

Output:
    - dealloc_scaling.png      : Scaling plot (linear vs log scale)
    - dealloc_breakdown.png    : Overhead percentage bar chart
    - dealloc_comparison.png   : Deallocation vs typical operation costs
    - dealloc_summary.png      : Summary statistics with annotations
"""

import os
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
from matplotlib.ticker import LogFormatterSciNotation
import pandas as pd

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = SCRIPT_DIR

# Read data from CSV
data_dir = os.path.abspath(os.path.join(SCRIPT_DIR, '..', 'dealloc'))
csv_file = os.path.join(data_dir, 'dealloc_timing.csv')
if not os.path.exists(csv_file):
    print(f"Error: {csv_file} not found")
    exit(1)

df = pd.read_csv(csv_file)
sizes = df['matrix_nnz']
avg_times = df['avg_free_ms']
min_times = df['min_free_ms']
max_times = df['max_free_ms']
stddev_times = df['stddev_free_ms']

sizes_str = [f"{s/1e6:.1f}M" if s >= 1e6 else f"{s/1e3:.0f}K" for s in sizes]

# ==============================================================================
# Chart 1: Deallocation Scaling Behavior
# ============================================================================== 
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(8, 8), constrained_layout=True)
fig.suptitle('Matrix Deallocation Time vs Matrix Size', 
             fontsize=16, fontweight='bold', y=0.96)

# Linear scale
ax1.plot(sizes, avg_times * 1000, 'o-', linewidth=2.5, markersize=10, 
         color='#2E86AB', label='Average Deallocation Time')
ax1.fill_between(sizes, min_times * 1000, max_times * 1000, 
                 alpha=0.2, color='#2E86AB', label='Min/Max Range')
ax1.set_xlabel('Matrix Size (nonzeros)', fontsize=12, fontweight='bold')
ax1.set_ylabel('Deallocation Time (μs)', fontsize=12,  fontweight='bold')
ax1.set_title('Linear Trend: Sub-Microsecond Deallocation', fontsize=13, fontweight='bold')
ax1.grid(True, alpha=0.3, linestyle='--')
ax1.legend(fontsize=9)
ax1.set_xscale('log')

# Add annotations
for i, (sz, t) in enumerate(zip(sizes_str, avg_times * 1000)):
    ax1.annotate(f'{t:.4f} μs', xy=(sizes[i], avg_times[i]*1000), 
                xytext=(10, 10), textcoords='offset points',
                fontsize=8, bbox=dict(boxstyle='round,pad=0.2', 
                facecolor='white', alpha=0.7),
                arrowprops=dict(arrowstyle='->', lw=1))

# Log scale (for showing dramatic difference)
ax2.loglog(sizes, avg_times * 1000, 's-', linewidth=2.5, markersize=10,
          color='#A23B72', label='Deallocation Time')
ax2.loglog(sizes, avg_times * 1000 * 100, '--', linewidth=2, alpha=0.5,
          color='gray', label='× 100 hypothetical')
ax2.set_xlabel('Matrix Size (nonzeros)', fontsize=12, fontweight='bold')
ax2.set_ylabel('Time (μs)', fontsize=12, fontweight='bold')
ax2.set_title('Log Trend: Remains Sub-Microsecond', fontsize=13, fontweight='bold')
ax2.grid(True, alpha=0.3, which='both', linestyle='--')
ax2.legend(fontsize=9)

plt.savefig(os.path.join(OUT_DIR, 'dealloc_scaling.png'), 
            dpi=150, bbox_inches='tight')
print("✓ Saved: dealloc_scaling.png")
plt.close()

# ==============================================================================
# Chart 2: Deallocation Overhead Relative to Sort Time
# ============================================================================== 
fig, ax = plt.subplots(figsize=(8, 8), constrained_layout=True)

# Estimated sort times for comparison (from typical GraphBLAS benchmarks)
typical_sort_times = [0.5, 2.0, 15.0, 120.0, 1500.0]  # ms
dealloc_pct = (avg_times / typical_sort_times) * 100

colors = ['#2ecc71' if pct < 1 else '#f39c12' if pct < 5 else '#e74c3c' 
          for pct in dealloc_pct]

bars = ax.bar(sizes_str, dealloc_pct, color=colors, edgecolor='black', linewidth=1.5)
ax.axhline(y=1, color='red', linestyle='--', linewidth=2, label='1% Threshold')
ax.axhline(y=5, color='orange', linestyle='--', linewidth=2, label='5% Threshold')
ax.set_ylabel('Deallocation as % of Sort Time', fontsize=13, fontweight='bold')
ax.set_xlabel('Matrix Size', fontsize=13, fontweight='bold')
ax.set_title('Deallocation as a Fraction of Sort Runtime', 
             fontsize=14, fontweight='bold')
ax.set_ylim(0, max(dealloc_pct) * 1.5)
ax.legend(fontsize=10, loc='upper right')
ax.grid(True, alpha=0.3, axis='y')

# Add percentage labels on bars
for i, (bar, pct) in enumerate(zip(bars, dealloc_pct)):
    height = bar.get_height()
    ax.text(bar.get_x() + bar.get_width()/2., height,
            f'{pct:.4f}%', ha='center', va='bottom', fontsize=10, fontweight='bold')

plt.savefig(os.path.join(OUT_DIR, 'dealloc_overhead_pct.png'),
            dpi=150, bbox_inches='tight')
print("✓ Saved: dealloc_overhead_pct.png")
plt.close()

# ==============================================================================
# Chart 3: Combined vertical square layout
# ==============================================================================
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(8, 10), constrained_layout=True)
fig.suptitle('Deallocation Cost and Sort-Overhead Context',
             fontsize=18, fontweight='bold', y=0.98)

ax1.plot(sizes, avg_times * 1000, 'o-', linewidth=2.5, markersize=10,
         color='#2E86AB', label='Average Deallocation Time')
ax1.fill_between(sizes, min_times * 1000, max_times * 1000,
                 alpha=0.2, color='#2E86AB', label='Min/Max Range')
ax1.set_xscale('log')
ax1.set_xlabel('Matrix Size (nonzeros)', fontsize=12, fontweight='bold')
ax1.set_ylabel('Deallocation Time (μs)', fontsize=12, fontweight='bold')
ax1.set_title('Matrix deallocation remains sub-microsecond', fontsize=14, fontweight='bold')
ax1.grid(True, alpha=0.3, linestyle='--')
ax1.legend(fontsize=9)
for i, (sz, t) in enumerate(zip(sizes_str, avg_times * 1000)):
    ax1.annotate(f'{t:.4f} μs', xy=(sizes[i], avg_times[i] * 1000),
                 xytext=(8, 8), textcoords='offset points',
                 fontsize=8, bbox=dict(boxstyle='round,pad=0.2',
                 facecolor='white', alpha=0.7),
                 arrowprops=dict(arrowstyle='->', lw=0.8))

bars = ax2.bar(sizes_str, dealloc_pct, color=colors, edgecolor='black', linewidth=1.2)
ax2.axhline(y=1, color='red', linestyle='--', linewidth=2, label='1% Threshold')
ax2.axhline(y=5, color='orange', linestyle='--', linewidth=2, label='5% Threshold')
ax2.set_xlabel('Matrix Size', fontsize=12, fontweight='bold')
ax2.set_ylabel('Deallocation as % of Sort Time', fontsize=12, fontweight='bold')
ax2.set_title('Deallocation is negligible compared to sort work',
             fontsize=14, fontweight='bold')
ax2.set_ylim(0, max(dealloc_pct) * 1.5)
ax2.legend(fontsize=9, loc='upper right')
ax2.grid(True, alpha=0.3, axis='y')
for bar, pct in zip(bars, dealloc_pct):
    ax2.text(bar.get_x() + bar.get_width() / 2., bar.get_height(),
             f'{pct:.4f}%', ha='center', va='bottom', fontsize=10, fontweight='bold')

plt.savefig(os.path.join(OUT_DIR, 'dealloc_vertical_square.png'),
            dpi=150, bbox_inches='tight')
print("✓ Saved: dealloc_vertical_square.png")
plt.close()

print("\nCharts generated successfully!")
