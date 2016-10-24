/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: _coder_mysum_api.h
 *
 * MATLAB Coder version            : 3.2
 * C/C++ source code generated on  : 20-Oct-2016 20:07:15
 */

#ifndef _CODER_MYSUM_API_H
#define _CODER_MYSUM_API_H

/* Include Files */
#include "tmwtypes.h"
#include "mex.h"
#include "emlrt.h"
#include <stddef.h>
#include <stdlib.h>
#include "_coder_mysum_api.h"

/* Variable Declarations */
extern emlrtCTX emlrtRootTLSGlobal;
extern emlrtContext emlrtContextGlobal;

/* Function Declarations */
extern real_T mysum(real_T a, real_T b, real_T c);
extern void mysum_api(const mxArray * const prhs[3], const mxArray *plhs[1]);
extern void mysum_atexit(void);
extern void mysum_initialize(void);
extern void mysum_terminate(void);
extern void mysum_xil_terminate(void);

#endif

/*
 * File trailer for _coder_mysum_api.h
 *
 * [EOF]
 */
