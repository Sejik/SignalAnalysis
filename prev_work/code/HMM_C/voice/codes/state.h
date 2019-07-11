#ifndef __H_STATE
#define __H_STATE

#include <stdio.h>
#include "parsing.h"
#include "state.h"

#define N_NODES 200
#define N_WORDS 12
#define N_PHONE_NODES 3

typedef struct {
	char *name;
	int n_phones;
	hmmType **phonesArr;

	float last_out_prob;
	int idx_start;
	int idx_last;
} wordType;

enum {PH_f, PH_k, PH_n, PH_r, PH_s, PH_t, PH_v, PH_w, PH_z,
			PH_ah, PH_ao, PH_ay, PH_eh, PH_ey, PH_ih, PH_iy, PH_ow,
			PH_th, PH_uw, PH_sil, PH_sp} phs;
enum {W_zero0, W_zero1, W_zero2, W_one, W_two,
			W_three, W_four, W_five, W_six, W_seven, W_eight, W_nine} wds;

static hmmType *ph_sil[] = {&phones[PH_sil]};
static hmmType *ph_sp[] = {&phones[PH_sp]};
static hmmType *ph_zero0[] = {&phones[PH_ow]}; /* ow */
static hmmType *ph_zero1[] = {&phones[PH_z], &phones[PH_ih], &phones[PH_r], &phones[PH_ow]}; /* zihrow */
static hmmType *ph_zero2[] = {&phones[PH_z], &phones[PH_iy], &phones[PH_r], &phones[PH_ow]}; /* ziyrow */
static hmmType *ph_one[] = {&phones[PH_w], &phones[PH_ah], &phones[PH_n]};
static hmmType *ph_two[] = {&phones[PH_t], &phones[PH_uw]};
static hmmType *ph_three[] = {&phones[PH_th], &phones[PH_r], &phones[PH_iy]};
static hmmType *ph_four[] = {&phones[PH_f], &phones[PH_ao], &phones[PH_r]};
static hmmType *ph_five[] = {&phones[PH_f], &phones[PH_ay], &phones[PH_v]};
static hmmType *ph_six[] = {&phones[PH_s], &phones[PH_ih], &phones[PH_k], &phones[PH_s]};
static hmmType *ph_seven[] = {&phones[PH_s], &phones[PH_eh], &phones[PH_v], &phones[PH_ah], &phones[PH_n]};
static hmmType *ph_eight[] = {&phones[PH_ey], &phones[PH_t]};
static hmmType *ph_nine[] = {&phones[PH_n], &phones[PH_ay], &phones[PH_n]};

extern wordType g_words[];
extern int g_cur_node;
extern int g_start_node;
extern int g_end_node;
extern int total_states;
extern stateType *idx_sts_tbl[300];
float g_tp[N_NODES][N_NODES];

float assign_one_phone(hmmType *phone);
void assign_one_word(wordType *word);
void assign_tp(float **bgmtbl);
void assign_bigram(wordType *word, int idx_word, float **bgmtbl);
void assign_begin_idxs(void);
void assign_sil_nodes(float **bgmtbl);
stateType *get_state_of_idx(int idx);

#endif
