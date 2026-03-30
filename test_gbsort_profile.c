//------------------------------------------------------------------------------
// test_gbsort_profile.c: Simple test to exercise sort and capture timing
//------------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include "GraphBLAS.h"

int main(int argc, char **argv)
{
    GrB_init(GrB_NONBLOCKING);
    
    fprintf(stderr, "Running GxB_Matrix_sort tests...\n");
    
    // Test with varying sizes
    for (int sz = 1000; sz <= 100000; sz *= 10) {
        int64_t nrows = 100;
        int64_t ncols = sz / nrows;
        int64_t nnz = sz;
        
        fprintf(stderr, "Testing %lld x %lld matrix with %lld nnz\n", 
                (long long)nrows, (long long)ncols, (long long)nnz);
        
        GrB_Matrix A, C, P;
        GrB_Matrix_new(&A, GrB_FP64, nrows, ncols);
        GrB_Matrix_new(&C, GrB_FP64, nrows, ncols);
        GrB_Matrix_new(&P, GrB_UINT64, nrows, ncols);
        
        // Populate A
        GrB_Index *row_idx = (GrB_Index*) malloc(nnz * sizeof(GrB_Index));
        GrB_Index *col_idx = (GrB_Index*) malloc(nnz * sizeof(GrB_Index));
        double    *values  = (double*)    malloc(nnz * sizeof(double));
        
        for (int64_t k = 0; k < nnz; k++) {
            row_idx[k] = rand() % nrows;
            col_idx[k] = rand() % ncols;
            values[k]  = (double)rand() / RAND_MAX;
        }
        
        GrB_Matrix_build_FP64(A, row_idx, col_idx, values, nnz, NULL);
        
        // Call sort  
        GrB_Descriptor desc = NULL;
        GrB_Info info = GxB_Matrix_sort(C, P, GrB_LT_FP64, A, desc);
        if (info != GrB_SUCCESS) {
            fprintf(stderr, "ERROR in sort: %d\n", info);
        }

        
        // Cleanup
        GrB_Matrix_free(&A);
        GrB_Matrix_free(&C);
        GrB_Matrix_free(&P);
        free(row_idx);
        free(col_idx);
        free(values);
    }
    
    fprintf(stderr, "Tests complete.\n");
    GrB_finalize();
    return 0;
}

