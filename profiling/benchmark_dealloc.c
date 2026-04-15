// benchmark_dealloc.c: Micro-benchmark to isolate matrix deallocation cost
//
// Build: gcc -std=c99 -O3 -o benchmark_dealloc benchmark_dealloc.c
//        -I/path/to/GraphBLAS/Include -L/path/to/GraphBLAS/lib -lgraphblas -lm
//
// Usage: ./benchmark_dealloc > dealloc_timing.csv

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include "GraphBLAS.h"

// Timing utility
typedef struct {
    struct timespec start, end;
} Timer;

double elapsed_ms(Timer *t) {
    return (t->end.tv_sec - t->start.tv_sec) * 1000.0 +
           (t->end.tv_nsec - t->start.tv_nsec) / 1000000.0;
}

void timer_start(Timer *t) {
    clock_gettime(CLOCK_MONOTONIC, &t->start);
}

void timer_end(Timer *t) {
    clock_gettime(CLOCK_MONOTONIC, &t->end);
}

//------------------------------------------------------------------------------
// Micro-benchmark: Isolated deallocation cost
//------------------------------------------------------------------------------

typedef struct {
    int64_t matrix_size;    // approximate number of nonzeros
    double avg_free_time_ms;
    double min_free_time_ms;
    double max_free_time_ms;
    double stddev_free_time_ms;
} dealloc_result_t;

dealloc_result_t bench_dealloc_isolated(int64_t nnz, int ntrials)
{
    GrB_Matrix *matrices = (GrB_Matrix*) malloc(ntrials * sizeof(GrB_Matrix));
    if (matrices == NULL) {
        fprintf(stderr, "Out of memory\n");
        exit(1);
    }

    int64_t nrows = 10000;
    int64_t ncols = 10000;
    
    // Phase 1: Pre-allocate all matrices with data
    fprintf(stderr, "  Allocating %d matrices with %lld nonzeros each...\n", 
            ntrials, (long long)nnz);
    
    // Pre-generate random indices and values for reuse across trials
    GrB_Index *row_indices = (GrB_Index*) malloc(nnz * sizeof(GrB_Index));
    GrB_Index *col_indices = (GrB_Index*) malloc(nnz * sizeof(GrB_Index));
    double    *values      = (double*)    malloc(nnz * sizeof(double));
    
    for (int64_t k = 0; k < nnz; k++) {
        row_indices[k] = rand() % nrows;
        col_indices[k] = rand() % ncols;
        values[k] = (double)rand() / RAND_MAX;
    }
    
    for (int trial = 0; trial < ntrials; trial++) {
        GrB_Matrix_new(&matrices[trial], GrB_FP64, nrows, ncols);
        // Bulk-build the matrix using the faster build method
        GrB_Matrix_build_FP64(matrices[trial], row_indices, col_indices, values, nnz, NULL);
    }
    
    free(row_indices);
    free(col_indices);
    free(values);
    
    fprintf(stderr, "  Done. Now measuring deallocation...\n");
    
    // Phase 2: Time the free operations
    double *times = (double*) malloc(ntrials * sizeof(double));
    
    for (int trial = 0; trial < ntrials; trial++) {
        Timer t;
        timer_start(&t);
        GrB_Matrix_free(&matrices[trial]);
        timer_end(&t);
        times[trial] = elapsed_ms(&t);
    }
    
    // Phase 3: Compute statistics
    double sum = 0.0, sum_sq = 0.0;
    double min_t = times[0], max_t = times[0];
    
    for (int trial = 0; trial < ntrials; trial++) {
        sum += times[trial];
        sum_sq += times[trial] * times[trial];
        if (times[trial] < min_t) min_t = times[trial];
        if (times[trial] > max_t) max_t = times[trial];
    }
    
    double avg = sum / ntrials;
    double variance = (sum_sq / ntrials) - (avg * avg);
    double stddev = (variance > 0) ? sqrt(variance) : 0.0;
    
    dealloc_result_t result = {
        .matrix_size = nnz,
        .avg_free_time_ms = avg,
        .min_free_time_ms = min_t,
        .max_free_time_ms = max_t,
        .stddev_free_time_ms = stddev
    };
    
    free(times);
    free(matrices);
    
    return result;
}

//------------------------------------------------------------------------------
// Main benchmark driver
//------------------------------------------------------------------------------

int main(void)
{
    GrB_init(GrB_NONBLOCKING);
    
    // Output CSV header
    printf("matrix_nnz,avg_free_ms,min_free_ms,max_free_ms,stddev_free_ms\n");
    
    // Test different matrix sizes
    int64_t test_sizes[] = {
        1000,
        10000,
        100000,
        1000000,
        10000000,
        0  // sentinel
    };
    
    for (int s = 0; test_sizes[s] > 0; s++) {
        int64_t nnz = test_sizes[s];
        int ntrials = (nnz <= 100000) ? 1000 : 100;  // fewer trials for huge matrices
        
        fprintf(stderr, "\nTesting matrix with %lld nonzeros (%d trials)...\n", 
                (long long)nnz, ntrials);
        
        dealloc_result_t result = bench_dealloc_isolated(nnz, ntrials);
        
        printf("%lld,%.6f,%.6f,%.6f,%.6f\n",
               (long long)result.matrix_size,
               result.avg_free_time_ms,
               result.min_free_time_ms,
               result.max_free_time_ms,
               result.stddev_free_time_ms);
    }
    
    GrB_finalize();
    return 0;
}
