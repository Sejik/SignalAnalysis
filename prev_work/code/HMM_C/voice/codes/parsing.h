#ifndef __H_PARSING
#define __H_PARSING

#include "hmm.h"
#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include <stdlib.h>

#define BUF_SIZE 1024
#define N_BIGRAM 12
#define WORD_MAX_LEN 6

#define ERR_F -1

enum {
	B_OH, B_ZERO, B_ONE, B_TWO, B_THREE, B_FOUR,
	B_FIVE, B_SIX, B_SEVEN, B_EIGHT, B_NINE, B_SIL
} b_idx;

typedef struct {
	int n_vecs;
	float **vecs;
} inputType;

static const char bigram_words[N_BIGRAM][WORD_MAX_LEN] = 
{	
	"oh", "zero", "one", "two", "three", "four",
	"five", "six", "seven", "eight", "nine", "<s>"
};

inputType *get_input_from_file(const char *path);
float *process_one_vector(FILE *file);
float **get_bigram(const char *path);
int process_one_word(FILE *f, float **bgmtbl);

void free_input(inputType *input);
#endif
