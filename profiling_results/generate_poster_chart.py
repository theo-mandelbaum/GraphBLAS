#!/usr/bin/env python3
"""
Generate a pie chart visualization for the GraphBLAS poster
showing deallocation costs relative to sort operations.
"""

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

# Data from profiling analysis
labels = ['Copying Data', 'Comparing Elements', 'Other Overhead', 'Deallocation']
sizes = [56.7, 28.0, 15.3, 0.001]  # percentages
colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#FFD93D']  # distinctive colors
explode = (0, 0, 0, 0.15)  # explode the tiny deallocation slice to make it visible

# Create figure with square aspect ratio (perfect for poster)
fig, ax = plt.subplots(figsize=(10, 10), subplot_kw=dict(aspect='equal'))

# Create pie chart
wedges, texts, autotexts = ax.pie(
    sizes,
    explode=explode,
    labels=labels,
    colors=colors,
    autopct='%1.3f%%',
    shadow=True,
    startangle=90,
    textprops={'fontsize': 14, 'weight': 'bold'}
)

# Enhance the auto percentage text
for autotext in autotexts:
    autotext.set_color('white')
    autotext.set_fontsize(12)
    autotext.set_weight('bold')

# Add title
plt.title('Sort Operation Cost Breakdown\n(100K Matrix, ~15ms)', 
          fontsize=18, weight='bold', pad=20)

# Add annotation for the tiny deallocation slice
ax.annotate('Deallocation:\n0.0002ms', 
            xy=(1, 0.15), xytext=(0.7, 0.7),
            fontsize=11, weight='bold', color='#FFD93D',
            arrowprops=dict(arrowstyle='->', color='#FFD93D', lw=2),
            bbox=dict(boxstyle='round,pad=0.5', facecolor='white', edgecolor='#FFD93D', linewidth=2))

plt.tight_layout()

# Save as high-quality image for poster
plt.savefig('deallocation_pie_chart.png', dpi=300, bbox_inches='tight', facecolor='white')
plt.savefig('deallocation_pie_chart.pdf', bbox_inches='tight', facecolor='white')

print("✓ Chart saved as 'deallocation_pie_chart.png' (300 DPI)")
print("✓ Chart saved as 'deallocation_pie_chart.pdf'")
print("\nChart dimensions: 10x10 inches (square format)")
print("Resolution: 300 DPI (publication quality)")
print("\nFinding: Deallocation = 0.001% of sort operation cost")

plt.show()
