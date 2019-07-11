#include "parsing.h"

inputType *get_input_from_file(const char *path)
{
	int i;
	char buf[BUF_SIZE];
	char *token;
	FILE *f = fopen(path, "r");
	inputType *inp = (inputType *)malloc(sizeof(inputType));

	if (f == NULL)
		return NULL;

	fgets(buf, BUF_SIZE, f);
	token = strtok(buf, " ");
	inp->n_vecs = atoi(token);
	inp->vecs = (float **)calloc(inp->n_vecs, sizeof(float *));
	
	for (i = 0; i < inp->n_vecs; i++)
		inp->vecs[i] = process_one_vector(f);

	fclose(f);
	return inp;
}

float *process_one_vector(FILE *f) 
{
	int i;
	char buf[BUF_SIZE];
	char *token;
	float *vec = (float *)calloc(N_DIMENSION, sizeof(float));

	fgets(buf, BUF_SIZE, f);

	token = strtok(buf, " ");
	for (i = 0; i < N_DIMENSION; i++) {
		vec[i] = atof(token);	
		token = strtok(NULL, " ");
	}

	return vec;
}

int process_one_word(FILE *f, float **bigram_tbl)
{
	int i;
	char buf[BUF_SIZE];
	char *token;
	int idx_from, idx_to;
	float prob;
	char *flag;
	
	flag = fgets(buf, BUF_SIZE, f);
	if (flag == NULL)
		return EOF;

	token = strtok(buf, "\t");
	for (i = 0; i < N_BIGRAM; i++)
		if (!strcmp(token, bigram_words[i])) {
			idx_from = i;
			break;
		}

	token = strtok(NULL, "\t");
	for (i = 0; i < N_BIGRAM; i++)
		if (!strcmp(token, bigram_words[i])) {
			idx_to = i;
			break;
		}
	
	token = strtok(NULL, "\t");
	prob = atof(token);

	bigram_tbl[idx_from][idx_to] = prob;

	return 0;
}

float** get_bigram(const char *path)
{
	FILE *f = fopen(path, "r");
	int i;
	float **bigram_tbl = (float **)calloc(N_BIGRAM, sizeof(float *));

	for (i = 0; i < N_BIGRAM; i++)
		bigram_tbl[i] = (float *)calloc(N_BIGRAM, sizeof(float));

	if (f == NULL)
		return NULL;

	while (1) {
		i = process_one_word(f, bigram_tbl);
		if (i == EOF)
			break;
	}

	fclose(f);
	return bigram_tbl;
}

void free_input(inputType *input)
{
	int i;
	
	for (i = 0; i < input->n_vecs; i++)
		free(input->vecs[i]);

	free(input);

	return;
}