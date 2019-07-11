#include <stdio.h>
#include "state.h"

int g_cur_node;
int g_start_node;
int g_end_node;
int begin_idxs[N_WORDS];
int total_states;
stateType *idx_sts_tbl[300];

wordType g_words[] = 
{
	{	"oh",
		1,
		ph_zero0
	},
	{	"zero",
		4,
		ph_zero1
	},
	{	"zero",
		4,
		ph_zero2
	},
	{	"one",
		3,
		ph_one
	},
	{	"two",
		2,
		ph_two
	},
	{	"three",
		3,
		ph_three
	},
	{	"four",
		3,
		ph_four
	},
	{	"five",
		3,
		ph_five
	},
	{ "six",
		4,
		ph_six
	},
	{	"seven",
		5,
		ph_seven
	},
	{	"eight",
		2,
		ph_eight
	},
	{	"nine",
		3,
		ph_nine
	}
};

float assign_one_phone(hmmType *phone) 
{
	int i, j;
	int p_i = 1;
	float last_out_prob;

	for (i = g_cur_node; i < g_cur_node + N_PHONE_NODES;  i++) {
		idx_sts_tbl[i] = &(phone->state[p_i-1]);

		j = i;
		g_tp[i][j] = phone->tp[p_i][p_i];
		g_tp[i][j+1] = phone->tp[p_i][p_i + 1];
		p_i++;
	}

	last_out_prob = phone->tp[3][4];
	g_cur_node = i;

	return last_out_prob;
}

void assign_one_word(wordType *word)
{
	int i, j, cur;
	float lop;

	/* Connect each phones */
	word->idx_start = g_cur_node;
	for (i = 0; i < word->n_phones; i++) 
		lop = assign_one_phone(word->phonesArr[i]);
	cur = g_cur_node;

	/* Connect a sp-HMM at the end of the word */
	/* i: the real sp-state, i+1: the end state */
	/* (*) -> (*) -> (*) -> (sp) -> (END_NODE) */
	idx_sts_tbl[cur] = &(phones[PH_sp].state[0]);
	idx_sts_tbl[cur + 1] = NULL;
	g_tp[cur-1][cur] = lop * (phones[PH_sp].tp[0][1]);
	g_tp[cur-1][cur+1] = lop * (phones[PH_sp].tp[0][2]);
	g_tp[cur][cur] = phones[PH_sp].tp[1][1];
	g_tp[cur][cur+1] = phones[PH_sp].tp[1][2];

	g_cur_node++;
	word->idx_last = g_cur_node;
	g_cur_node++;
	return;
}

void assign_bigram(wordType *word, int idx_word, float **bgmtbl)
{
	int from, to;
	int i;
	int bgm_from, bgm_to;
	wordType *target;

	if (idx_word == 0)
		bgm_from = 0;
	else if (idx_word == 1)
		bgm_from = 1;
	else if (idx_word == 2)
		bgm_from = 1;
	else
		bgm_from = idx_word - 1;

	from = word->idx_last;
	for (i = 0; i < N_WORDS; i++) {
		if (i == 0)
			bgm_to = 0;
		else if (i == 1)
			bgm_to = 1;
		else if (i == 2)
			bgm_to = 1;
		else
			bgm_to = i - 1;

		target = &g_words[i];
		to = target->idx_start;
		g_tp[from][to] = bgmtbl[bgm_from][bgm_to];
	}
	
	return;
}

void assign_begin_idxs(void)
{
	int i, j;
	int cur;
	wordType *word;

	for (i = 0; i < N_WORDS; i++) {
		word = &g_words[i];

		begin_idxs[i] = g_cur_node;
		cur = g_cur_node;
		g_cur_node++;

		g_tp[cur][cur] = phones[PH_sp].tp[1][1];
		g_tp[cur][word->idx_start] = phones[PH_sp].tp[1][2];
		idx_sts_tbl[cur] = &(phones[PH_sp].state[0]);
	
	}

	return;
}

void assign_sil_nodes(float **bgmtbl)
{
	int i, from, to;
	int st = g_cur_node;
	int end;
	wordType *word;

	/* start node */
	g_tp[st][st] = phones[PH_sil].tp[1][1];
	g_tp[st][st+1] = phones[PH_sil].tp[1][2];
	g_tp[st+1][st+1] = phones[PH_sil].tp[2][2];
	g_tp[st+1][st+2] = phones[PH_sil].tp[2][3];
	g_tp[st+2][st] = phones[PH_sil].tp[3][1];
	g_tp[st+2][st+2] = phones[PH_sil].tp[3][3];
	
	idx_sts_tbl[st] = &(phones[PH_sil].state[0]);
	idx_sts_tbl[st+1] = &(phones[PH_sil].state[1]);
	idx_sts_tbl[st+2] = &(phones[PH_sil].state[2]);

	g_cur_node += 3;

	/* from "one" to "nine" */
	for (i = 3; i < N_WORDS; i++) {
		word = &g_words[i];
		to = begin_idxs[i];
		g_tp[st + 2][to] = phones[PH_sil].tp[3][4] * phones[PH_sp].tp[0][1] * bgmtbl[B_SIL][i - 1];
		to = word->idx_start;
		g_tp[st + 2][to] = phones[PH_sil].tp[3][4] * phones[PH_sp].tp[0][2] * bgmtbl[B_SIL][i - 1];
	}
	/* oh, zihrow, ziyrow cases */
	g_tp[st + 2][begin_idxs[0]] = phones[PH_sil].tp[3][4] * phones[PH_sp].tp[0][1] * bgmtbl[B_SIL][B_OH];
	g_tp[st + 2][g_words[0].idx_start] = phones[PH_sil].tp[3][4] * phones[PH_sp].tp[0][2] * bgmtbl[B_SIL][B_OH];
	g_tp[st + 2][begin_idxs[1]] = phones[PH_sil].tp[3][4] * phones[PH_sp].tp[0][1] * bgmtbl[B_SIL][B_ZERO];
	g_tp[st + 2][g_words[1].idx_start] = phones[PH_sil].tp[3][4] * phones[PH_sp].tp[0][2] * bgmtbl[B_SIL][B_ZERO];
	g_tp[st + 2][begin_idxs[2]] = phones[PH_sil].tp[3][4] * phones[PH_sp].tp[0][1] * bgmtbl[B_SIL][B_ZERO];
	g_tp[st + 2][g_words[2].idx_start] = phones[PH_sil].tp[3][4] * phones[PH_sp].tp[0][2] * bgmtbl[B_SIL][B_ZERO];

	/* end node */
	end = g_cur_node;
	g_tp[end][end] = phones[PH_sil].tp[1][1];
	g_tp[end][end+1] = phones[PH_sil].tp[1][2];
	g_tp[end+1][end+1] = phones[PH_sil].tp[2][2];
	g_tp[end+1][end+2] = phones[PH_sil].tp[2][3];
	g_tp[end+2][end] = phones[PH_sil].tp[3][1];
	g_tp[end+2][end+2] = phones[PH_sil].tp[3][3];
	
	idx_sts_tbl[end] = &(phones[PH_sil].state[0]);
	idx_sts_tbl[end+1] = &(phones[PH_sil].state[1]);
	idx_sts_tbl[end+2] = &(phones[PH_sil].state[2]);

	g_cur_node += 3;

	/* from "one" to "nine" */
	for (i = 3; i < N_WORDS; i++) {
		word = &g_words[i];
		from = word->idx_last;
		g_tp[from][end] = bgmtbl[i-1][B_SIL];
	}

	/* oh, zihrow, ziyrow cases */
	g_tp[g_words[0].idx_last][end] = bgmtbl[B_OH][B_SIL];
	g_tp[g_words[1].idx_last][end] = bgmtbl[B_ZERO][B_SIL];
	g_tp[g_words[2].idx_last][end] = bgmtbl[B_ZERO][B_SIL];


	g_start_node = st;
	g_end_node = end;

	return;
}

void assign_tp(float **bgmtbl) 
{
	int i;
	wordType *word;

	/* phones */
	for (i = 0; i < N_WORDS; i++)
		assign_one_word(&g_words[i]);

	/* bigram */
	for (i = 0; i < N_WORDS; i++) {
		word = &g_words[i];
		assign_bigram(word, i, bgmtbl);
	}

	/* each beginning sp nodes */
	assign_begin_idxs();

	/* sil nodes */
	assign_sil_nodes(bgmtbl);

	total_states = g_cur_node - 1;

	return;
}
		
stateType *get_state_of_idx(int idx)
{
	return idx_sts_tbl[idx];
}
	
