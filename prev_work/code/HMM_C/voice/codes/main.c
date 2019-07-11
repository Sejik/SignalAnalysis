#include <stdio.h>
#include "parsing.h"
#include "state.h"
#include "calc.h"

extern int begin_idxs[N_WORDS];

int proc_one_routine(const char *input_fname, FILE *rec)
{
	int t, last;
	int n_vecs;
	int *path;
	int len = strlen(input_fname) + 5;
	char *name_txt = (char *)calloc(len, sizeof(char));
	char *name_rec = (char *)calloc(len, sizeof(char));
	strcpy(name_txt, input_fname);
	strcpy(name_rec, input_fname);
	strcat(name_txt, ".txt");
	strcat(name_rec, ".rec");

	printf("WORKING ON: %s, NOT SLEEPING... \n", input_fname);
	/* Get an input structure from the file */
	inputType *input = get_input_from_file(name_txt);
	if (input == NULL) {
		printf("ERROR: cannot read %s \n", input_fname);
		return -1;
	}
	n_vecs = input->n_vecs;

	/* Init. delta and psi */
	float **delta = init_delta(n_vecs, total_states);
	int **psi = init_psi(n_vecs, total_states);
	calc_init_step(delta, input->vecs[0]);

	/* Calculate each step */
	for (t = 1; t < n_vecs; t++)
		calc_each_step(delta, psi, input->vecs[t], t);
	path = trace_back(delta, psi, total_states, n_vecs);

	/* Write on the rec. file */
	fputs("\"", rec);
	fputs(name_rec, rec);
	fputs("\"\n", rec);
	write_recog_words(n_vecs, path, rec);

	/* Free delta, psi, path, input data, and name string. */
	free_doublep((void **)delta, n_vecs);
	free_doublep((void **)psi, n_vecs);
	free(path);
	free_input(input);
	free(name_txt);
	free(name_rec);

	return 0;
}



int main()
{
	int i;
	char *fname;
	char buf[256];
	float **bigram_tbl;
	FILE *ref, *rec;

	bigram_tbl = get_bigram("./bigram.txt");
	if (!bigram_tbl) {
		printf("ERROR: cannot find \"bigram.txt\"\n");
		return -1;
	}

	assign_tp(bigram_tbl);
	ref = fopen("reference.txt", "r");
	rec = fopen("recognized.txt", "w");


	fputs("#!MLF!#\n", rec);
	while (!feof(ref)) {
		fgets(buf, 256, ref);
		if (fgets == NULL)
			break;

		if ((strstr(buf, ".lab\"")) != NULL) {
			fname = strtok(buf, ".");
			fname = fname + sizeof(char);
			proc_one_routine(fname, rec);
		} else
			continue;
	}

	fclose(rec);
	fclose(ref);

	return 0;
}

