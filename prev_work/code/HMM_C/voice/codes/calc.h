#ifndef __H_CALC
#define __H_CALC

#define SCALE_FACTOR 0.1
#include "state.h"


float **init_delta(int n_steps, int total_states);
float calc_one_pdf(pdfType *pdf, float *input_vec);
float calc_one_ep(stateType *state, float *input_vec);
void calc_init_step(float **delta, float *input_vec);
void calc_each_step(float **delta, int **psi, float *input_vec, int n_step);

int **init_psi(int n_steps, int total_states);
int *trace_back(float **delta, int **psi, int total_states, int n_steps);
void write_recog_words(int n_steps, int *path, FILE *f);

void free_doublep(void **something, int n_steps);

#endif



