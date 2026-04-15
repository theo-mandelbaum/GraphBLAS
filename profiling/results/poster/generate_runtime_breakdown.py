#!/usr/bin/env python3
"""
Generate a runtime breakdown chart for GraphBLAS profiling.

Usage:
    python3 generate_runtime_breakdown.py [--input path/to/runtime_breakdown.csv]

The script is data-driven: it reads runtime percentages from a CSV file,
so the chart is not fixed inside the code.
"""

import argparse
import csv
import os
import re
import sys

import matplotlib.pyplot as plt

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_CSV_FILE = os.path.join(SCRIPT_DIR, 'runtime_breakdown.csv')
DEFAULT_PERF_FILE = os.path.join(SCRIPT_DIR, '..', 'analysis', 'top_functions.txt')

GROUP_COLORS = {
    'Data movement / copy': '#E74C3C',
    'Sort kernel': '#2E86AB',
    'Scalar assignment': '#F1C40F',
    'Element update': '#8E44AD',
    'Memory management': '#27AE60',
    'Binary op': '#16A085',
    'Indexing': '#D35400',
    'OpenMP overhead': '#9B59B6',
    'Other': '#95A5A6',
}

SYMBOL_GROUPS = [
    (re.compile(r'libgomp|_omp|GOMP|parallel|thread', re.IGNORECASE), 'OpenMP overhead'),
    (re.compile(r'memmove|copy|transpose|move', re.IGNORECASE), 'Data movement / copy'),
    (re.compile(r'quicksort|sort', re.IGNORECASE), 'Sort kernel'),
    (re.compile(r'assign|setElement|insert', re.IGNORECASE), 'Element update'),
    (re.compile(r'pending|realloc|free|malloc|alloc', re.IGNORECASE), 'Memory management'),
    (re.compile(r'binary|compatible|op', re.IGNORECASE), 'Binary op'),
    (re.compile(r'nnz|index|lookup', re.IGNORECASE), 'Indexing'),
]


def parse_args():
    parser = argparse.ArgumentParser(description='Generate a profiling runtime breakdown chart.')
    parser.add_argument('--input', default=DEFAULT_CSV_FILE,
                        help='CSV input file with columns item,group,percent')
    parser.add_argument('--perf', default=None,
                        help='Optional perf top functions text file to parse if CSV is unavailable')
    return parser.parse_args()


def classify_symbol(symbol):
    for pattern, group in SYMBOL_GROUPS:
        if pattern.search(symbol):
            return group
    return 'Other'


def parse_csv(csv_file):
    items = []
    percents = []
    groups = []

    with open(csv_file, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            item = row.get('item', '').strip()
            group = row.get('group', 'Other').strip()
            percent = row.get('percent', '').strip()
            if not item or not percent:
                continue
            try:
                value = float(percent)
            except ValueError:
                continue
            items.append(item)
            percents.append(value)
            groups.append(group)

    return items, percents, groups


def parse_perf_top_functions(perf_file, max_items=8):
    pattern = re.compile(r'^\s*([0-9]+\.?[0-9]*)%\s+[0-9]+\.?[0-9]*%.*\[.\]\s+(.+)$')
    data = []
    with open(perf_file) as infile:
        for line in infile:
            match = pattern.match(line)
            if not match:
                continue
            percent = float(match.group(1))
            symbol = match.group(2).strip()
            if symbol and percent > 0:
                data.append((percent, symbol))
    if not data:
        return [], [], []
    data.sort(reverse=True)
    data = data[:max_items]
    items = [symbol for _, symbol in data]
    percents = [percent for percent, _ in data]
    groups = [classify_symbol(symbol) for symbol in items]
    return items, percents, groups


def load_data(input_file, perf_file):
    if os.path.exists(input_file):
        return parse_csv(input_file)

    if perf_file and os.path.exists(perf_file):
        items, percents, groups = parse_perf_top_functions(perf_file)
        if items:
            print(f'Loaded data from perf file: {perf_file}')
            return items, percents, groups

    if os.path.exists(DEFAULT_PERF_FILE):
        items, percents, groups = parse_perf_top_functions(DEFAULT_PERF_FILE)
        if items:
            print(f'Loaded data from default perf file: {DEFAULT_PERF_FILE}')
            return items, percents, groups

    print(f'Error: no valid input file found.')
    print(f'Expected CSV: {input_file}')
    print(f'Or perf text file: {perf_file or DEFAULT_PERF_FILE}')
    sys.exit(1)


def main():
    args = parse_args()
    items, percents, groups = load_data(args.input, args.perf)

    sorted_data = sorted(zip(percents, items, groups), reverse=True)
    percents, items, groups = zip(*sorted_data)
    colors = [GROUP_COLORS.get(group, '#7F8C8D') for group in groups]

    fig, ax = plt.subplots(figsize=(10, 6))
    y_pos = range(len(items))
    ax.barh(y_pos, percents, color=colors, edgecolor='black', height=0.6)
    ax.set_yticks(y_pos)
    ax.set_yticklabels(items, fontsize=11)
    ax.invert_yaxis()
    ax.set_xlabel('Runtime Contribution (%)', fontsize=12, fontweight='bold')
    ax.set_title('Top Runtime Contributors from GraphBLAS Profiling', fontsize=16, fontweight='bold')
    ax.grid(axis='x', linestyle='--', alpha=0.4)

    for i, value in enumerate(percents):
        ax.text(value + 1, i, f'{value:.2f}%', va='center', fontsize=10, fontweight='bold')

    unique_groups = []
    unique_handles = []
    for group, color in zip(groups, colors):
        if group not in unique_groups:
            unique_groups.append(group)
            unique_handles.append(plt.Line2D([0], [0], marker='s', color='w', markerfacecolor=color, markersize=12))
    ax.legend(unique_handles, unique_groups, title='Group', loc='lower right', framealpha=0.9)

    plt.tight_layout()
    out_png = os.path.join(SCRIPT_DIR, 'runtime_breakdown.png')
    out_pdf = os.path.join(SCRIPT_DIR, 'runtime_breakdown.pdf')
    plt.savefig(out_png, dpi=300, bbox_inches='tight')
    plt.savefig(out_pdf, bbox_inches='tight')
    print(f'✓ Saved: {out_png}')
    print(f'✓ Saved: {out_pdf}')


if __name__ == '__main__':
    main()
