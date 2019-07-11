#include "calc.h"
#include <math.h>
#define PI 3.1415926535

float **init_delta(int n_steps, int total_states) 
{
	int i;
	float **delta = (float **)calloc(n_steps, sizeof(float *));

	for (i = 0; i < n_steps; i++)
		delta[i] = (float *)calloc(total_states, sizeof(float));

	return delta;
}

float calc_one_pdf(pdfType *pdf, float *input_vec)
{
	int i;
	float denom;
	float t1, t2;
	float sum = 0.0f;

	float weight = pdf->weight;
	float *mean = pdf->mean;
	float *var = pdf->var;

	for (i = 0; i < N_DIMENSION; i++) {
		denom = sqrtf(2 * PI * var[i]);
		t1 = (input_vec[i] - mean[i]);
		t1 = pow(t1, 2.0f);
		t2 = t1 / (2.0f * var[i]);

		denom = logf(1.0f / denom);

		sum += (denom - t2);
	}

	return sum;
}

float calc_one_ep(stateType *state, float *input_vec)
{
	int i, max_id = 0;
	pdfType *pdf;
	float weight;
	float ep = 0;

	for (i = 0; i < N_PDF; i++) {
		pdf = &(state->pdf[i]);
		ep += exp(calc_one_pdf(pdf, input_vec) * SCALE_FACTOR) * pdf->weight;
	}
	ep = logf(ep);

	return ep;
}

void calc_init_step(float **delta, float *input_vec)
{
	int i;
	int	start = g_start_node;
	float ep;
	stateType *state;

	for (i = 0; i < total_states; i++) {
		state = get_state_of_idx(i);
		if (state != NULL)
			ep = calc_one_ep(state, input_vec);
		else
			ep = 0.0f;
		delta[0][i] = logf(g_tp[start][i]) + ep;
	}

	return;
}

void calc_each_step(float **delta, int **psi, float *input_vec, int n_step)
{
	int i, j;
	int t = n_step;
	int max_idx;
	float ep;
	float candidate;
	float current;
	stateType *state;
	
	for (i = 0; i < total_states; i++) {
		/* The emission probability of the current state.*/
		state = get_state_of_idx(i);
		if (state != NULL)
			ep = calc_one_ep(state, input_vec);
		else
			ep = 0.0f;

		/**
		 * Choose the max one below:
		 * (delta[t-1][j]) + log(tp[j][i])
		 * delta is already in the log scale.
		*/
		max_idx = i;
		candidate = -INFINITY;
		for (j = 0; j < total_states; j++) {
			current = delta[t - 1][j] + logf(g_tp[j][i]);
			if (current > candidate) {
				candidate = current;
				max_idx = j;
			}
		}

		psi[t][i] = max_idx;
		delta[t][i] = candidate + ep;
	}
	return;
}
	
int **init_psi(int n_steps, int total_states)
{
	int i;
	int **psi = (int **)calloc(n_steps, sizeof(int*));

	for (i = 0; i < n_steps; i++)
		psi[i] = (int *)calloc(total_states, sizeof(int));

	for (i = 0; i < total_states; i++)
		psi[0][i] = g_start_node;

	return psi;
}	

int *trace_back(float **delta, int **psi, int total_states, int n_steps)
{
	int i, q, t;
	int last = 0;
	float prob;
	float current;
	int *path = (int *)calloc(n_steps, sizeof(int));

	/* Find the max prob. */
	prob = delta[n_steps - 1][0];
	for (i = 0; i < total_states; i++) {
		current = delta[n_steps - 1][i];

		if (current > prob) {
			prob = current;
			last = i;
		}
	}

	/* Backward trace from (T-1) time step. */
	path[n_steps - 1] = last;
	path[0] = g_start_node;

	q = last;
	for (t = (n_steps - 2); t > 0; t --) {
		q = psi[t][q];
		path[t] = q;
	}

	return path;
}

void write_recog_words(int n_steps, int *path, FILE *f)
{
	/* The file must be opened in advance */
	int i, j;
	int cur;
	wordType *word;

	for (i = 0; i < n_steps; i++) {
		cur = path[i];
		for (j = 0; j < N_WORDS; j++) {
			word = &g_words[j];
			if (word->idx_last == cur) {
				fputs(word->name, f);
				fputs("\n", f);
				printf("%s\n", word->name);
			}
		}	
	}

	fputs(".\n", f);

	return;
}

void free_doublep(void **thing, int n_steps)
{
	int i;

	for (i = 0; i < n_steps; i++)
		free(thing[i]);

	free(thing);

	return;
}
