/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_tf2coh_min4_AmH_calc_mex.c
 *
 * Code generation for function '_coder_tf2coh_min4_AmH_calc_mex'
 *
 */

/* Include files */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "mex.h"

#define		no	else
#define		nf	no if
#define		lSH	16							//�������� ���� �����(left shift)

typedef	long long	INT64;
typedef	enum	{	FALSE = 0, TRUE = 1,	}	BOOL;

float sqrtf(const float x)	//-[
{
	union
	{
		int i;
		float x;
	} u;
	u.x		=	x;
	u.i		=	(1<<29) + (u.i >> 1) - (1<<22);

	// Two Babylonian Steps
	// (simplified from:)
	// u.x	=	0.5f * (u.x + x/u.x);
	// u.x	=	0.5f * (u.x + x/u.x);
	u.x		=			u.x + x/u.x;
	u.x		=	0.25f * u.x + x/u.x;

	return	u.x;
}	//-]
double sqrtd(const double num)	//-[
{	//working Babylonian methods
	double	tmp, next	=	0.5 * (1 + num/1);

	while (TRUE)
	{
			tmp			=	next;
			next		=	0.5 * ( next + num/next );

			if (tmp-next < 0.005 || tmp-next < -0.005)	break;
	}

	return	next;
}	//-]

INT64 isqrt(const INT64 x)	//-[
{
	INT64	next;
	// Two Babylonian Steps
	// (simplified from:)
	// u.x	=	0.5f * (u.x + x/u.x);
	// u.x	=	0.5f * (u.x + x/u.x);

//	next	=			0.5 * ( 1 + x/1 );
	next	=			( 1 + x ) >> 1;

//	next	=			next + x/next;
	next	+=			x/next;

//	next	=	0.25f * next + x/next;
	next	=			(next >> 2) + x/next;

	return	next;
}	//-]


#include <stdio.h>
#include <conio.h>
#include <math.h>

int* submatrix(int mat[], int m, int k, int order);
int determinant(int mat[],int order);

int main()
{
	int i;
	int mat[] = {0,0,2,3,4,5,6,7,8};

	int det = determinant(mat,3);

	printf("%d",det);

	getch();
	return 0;
}

int* submatrix(int mat[], int m, int n, int order)
{
	int* sub = (int*)malloc(order*order*sizeof(int));
	int i,j;

	for(i = 0, j=0; i<(order+1)*(order+1) &&
			j<order*order; i++)
	{
		if(i>=(order+1)*m && i< (order+1)*(m+1))
			i = (order+1)*(m+1);

		if(i>=n)
			if((i-n)%(order+1)==0)        
				continue;

		*(sub + j++) = mat[i];
	}     
	return sub;     
}     

int determinant(int mat[], int order)
{    
	if(order==1)
		return mat[0];

	int i,d = 0;

	for(i=0; i< order; i++)
		d += (int)pow(-1,i)*mat[i]*determinant(submatrix(mat, 0, i,order -1), order-1);

	return d;
}

//static BOOL	Permutation(int *EpochTable, double *TFch2r, double *TFch2i, int nEpoch, BOOL bPerm)
static BOOL	Permutation(double *TFch2r, double *TFch2i, int nEpoch, BOOL bPerm)
{
register int	r, e, cnt;

//	for (cnt= 0; cnt< nEpoch; cnt++)	EpochTable[cnt] = cnt;
	if (!bPerm)							return (FALSE);
/*
	for (srand(time()), cnt= 0; cnt< nEpoch; cnt++)
	{
		r				=	rand() % nEpoch;

		e				=	EpochTable[cnt];
		EpochTable[cnt]	=	EpochTable[r];
		EpochTable[r]	=	e;
	}
*/
		int		nEp[1000]	=	{	//matlab ���� �����ؼ� -1 �ؾ� index ��Ī��
	32,  22,   6,   3,  16,  11,  30,  33,   7,  28,  17,  14,   8,
	 5,  29,  21,  25,  31,  27,  26,  19,  15,   1,  23,   2,   4,
	18,  24,  13,   9,  20,  10,  12	};
		double	tmp;
	for (cnt= 0; cnt< nEpoch; cnt++)
	{
		e				=	nEp[cnt]-1;
//		EpochTable[cnt] =	e;

		tmp				=	TFch2r[e];						//�� ��ȯ
		TFch2r[e]		=	TFch2r[cnt];
		TFch2r[cnt]		=	tmp;

		tmp				=	TFch2i[e];						//�� ��ȯ
		TFch2i[e]		=	TFch2i[cnt];
		TFch2i[cnt]		=	tmp;
	}

	return (TRUE);
}

#include <complex.h>
#include <cmath.h>
//using namespace std;
void	mexFunction(int32_T nlhs, mxArray *plhs[],
					int32_T nrhs, const mxArray *prhs[])
{
//1st. store a parameter(array) data to stimulus file -> will be use the test
	//parameter ���� ����� ���� : ���� �Է� ����
	int		nDimNum	=	mxGetNumberOfDimensions(prhs[0]);	//���� ����
const int	*pDims	=	mxGetDimensions(prhs[0]);			//������ ����

	double	*MVAR	=	(double *)mxGetPr(prhs[0]);			//���Ҽ� �� �Ǽ�
//	double	*MVAR	=	(double (*)[mChan][nChan])mxGetPr(prhs[0]);			//���Ҽ� �� �Ǽ�
//	double	*TFch1i	=	(double *)mxGetPi(prhs[0]);			//���Ҽ� �� ���
	//�Ǽ����� �ƴ� ������ ���� array�ε� �Ϸ���, (void *)mxGetData(...) �� ��

	INT64	mChan	=	pDims[0];
	INT64	nChan	=	pDims[1];							// mChan == nChan !
	INT64	nOrder	=	pDims[2];							// p == optimal order

//	double	fLow	=	mxGetScalar(prhs[1]);				// �⺻ double return
//	double	fHigh	=	mxGetScalar(prhs[2]);				// �⺻ double return
	INT64	fLow	=	(INT64)mxGetScalar(prhs[1]);		// ���� double ���!
	INT64	fHigh	=	(INT64)mxGetScalar(prhs[2]);		// ���ļ� upper
	INT64	Order	=	(INT64)mxGetScalar(prhs[3]);
	INT64	eFS		=	(INT64)mxGetScalar(prhs[4]);
//	BOOL	bPerm	=	(BOOL)mxGetScalar(prhs[2]);			//== 0 or 1

	INT64	nFreq	=	fHigh - fLow + 1;					// �� ���ļ� ����
//	INT64	nFxT	=	nFreq * nTime;						//f, t matrix
//	INT64	nSize	=	nFxT * nEpoch;						//��ü �� �� ��

	//parameter ���� ����� ���� : ��� ����
//	int		iv4[2]	=	{ nFreq, nTime };
//	plhs[0]			=	mxCreateNumericArray(2,iv4, mxSINGLE_CLASS,mxREAL);
	plhs[0]			=	mxCreateDoubleMatrix(mChan, nChan, nFreq);	// �� ũ��
	doudle	*gamma2	=	(double *)mxGetPr(plhs[0]);			//����� �Ǽ���

//	float	*TF3R	=	(float *)mxMalloc(sizeof(float) * nSize);
//	float	*TF3I	=	(float *)mxMalloc(sizeof(float) * nSize);
//	INT64	*TF3R	=	(INT64 *)malloc(sizeof(INT64) * nSize);
//	INT64	*TF3I	=	(INT64 *)malloc(sizeof(INT64) * nSize);
#if	0
	mwSize	sz[2]	=	{	nFreq, nTime	};
	plhs[0]			=	mxCreateNumericArray(2, sz, mxDOUBLE_CLASS, mxREAL);
	float	*plv	=	(float *)mxGetData(plhs[0]);	//Get a pointer to pOUT
//	     *p2 = B[0];
#else
//	float	plv[9000];
//	plv				=	(float (*)[9000])mxMalloc(sizeof(float [nFreq*nTime]));
#endif

// 2nd, �Ϲ� ��� ����
//	const   complex<double> i(0.0,1.0);						// �����
//	i = -1;
//	i = sqrt(i);

//	float	ch1r, ch1i, ch2r, ch2i;							// ���Ҽ�
	int		k, x, y, h;										// iter ����

//	FILE	*sti	=	fopen("STIMULUS.by_Cmex.txt", "wt");
//	FILE	*rst	=	fopen("RESULT.by_Cmex.txt", "wt");
/*	//�Է� �����͸� �������Ͽ� ���Ϸ� ����Ѵ�.				//-[

mexPrintf(			"nFreq=%d, nTime=%d, nEpoch=%d\n", nFreq, nTime, nEpoch);
fprintf(sti,		"nFreq=%d, nTime=%d, nEpoch=%d\n", nFreq, nTime, nEpoch);
*/

// 3rd, Calculate the DTF value
	Af				=	(double complex (*)[nChan])mxMalloc(		\
											sizeof(double complex)*mChan*nChan);
	for (k = 0; k < nFreq; k++)
	{
		for (x=0;x<mChan;x++) for(y=0;y<nChan; Af[x][y]=0, y++);	// �ʱ�ȭ

// 4th, Calculate the non-normalized DTF value
		curFreq		=	fLow + k;							// ���� ���ļ�

		for (x = 0; x < mChan; x++)
		for (y = 0; y < nChan; y++)
		for (h = 0; h < Order; h++)
		{
			w		=	cexp(-M_PI * curFreq * 1/eFS * h * 2I);			//DTF
			Af[i][j]-=	MVAR[x + y * mChan + h * (mChan * nChan)] * w;	//DTF
		}

// 5th, Calculate the normalized DTF value
  //call LU decomposition
  rc = LUDCMP(A,n,INDX,&id);

  //calculate determinant and display
  det = id;
  if (rc==0)  {
    for (i=1; i<=n; i++)  det *= A[i][i];
    printf("\n Determinant = %f\n\n", det);
	return 0;
  }
  else {
    printf("\n Error in LU decomposition.\n\n");
    return 2;
  }
		detA		=	det(Af);
	}

//	int		*EpochTable	=	malloc(nEpoch);
//	int		EpochTable[1024];								//enough size?
//	Permutation(EpochTable, TFch2r, TFch2i, nEpoch, bPerm);	//rand ��迭
	Permutation(TFch2r, TFch2i, nEpoch, bPerm);				//rand ��迭

//register INT64	regR, regI, SumR, SumI;			//���� �����
//register INT64	reg1r, reg1i, reg2r, reg2i;		//���� �����
register INT64	reg1r,reg1i,reg2r,reg2i,regR,regI, SumR,SumI, tmp,tmpR,tmpI;
	INT64	l, m, n;
//	float complex 	z1, z2, z, EpSum;
//	float reg1r,reg1i,reg2r,reg2i,regR,regI, SumR,SumI, tmp,tmpR,tmpI;

	//20150720A. ���Ҽ� ������ �ִ�ӵ��� �����ϱ� ����, coder�� ���⹰�� ����
	//	�Ͽ�, ���Ҽ� conjugate�� ��ü�� �ϰ� �����Ѵ�.
	for (n= 0; n< nSize; n++)								//��ü cell �ϰ�����
	{
//			E			=	EpochTable[e];					//��迭 or ����

			reg1r		=	(INT64)(TFch1r[n]* (1L<<lSH));	//INT64 �� ����
			reg1i		=	(INT64)(TFch1i[n]* (1L<<lSH));
			reg2r		=	(INT64)(TFch2r[n]* (1L<<lSH));
			reg2i		=	(INT64)(TFch2i[n]* (1L<<lSH));
//	TFch	=	TFch1 .* conj(TFch2);
			TF3R[n]		=	reg1r*reg2r - reg1i*(-reg2i);	//real:ch2 conj ���
			TF3I[n]		=	reg1r*(-reg2i) + reg1i*reg2r;	//imag:ch2 conj ���
//mexPrintf(	"%dth/%d conv: z1(%f+%fi), z2(%f+%fi) -> "
//			"INT1(%lli+%llii),INT2(%lli+%llii)\n",
//n, nSize, TFch1r[n],TFch1i[n], TFch2r[n],TFch2i[n], reg1r,reg1i, reg2r,reg2i);
//mexPrintf(	"z[%lli+%llii]",	TF3R[n], TF3I[n]);
				
	}

	for (m= 0; m< nFxT; m++)							//f, t matrix ����
	{
			SumR		=	SumI	=	0.0;
		for (n= m, l= 0; l< nEpoch; l++, n+= nFxT)		//Epoch idx�� ���� & ���
		{
//	TFch ./ abs(TFch)
//			SumR	+=	regR / sqrt(regR*regR - regI*regI*-1);	//real��
//			SumI	+=	regI / sqrt(regR*regR - regI*regI*-1);	//real��
/*			if (!TF3I[n])
				SumR	+=	1;	//(TF3R[n] / TF3R[n]);
			nf (!TF3R[n])
				SumI	+=	1;	//(TF3I[n] / TF3I[n]);
			no*/
				tmp		=	isqrt(TF3R[n]*TF3R[n] + TF3I[n]*TF3I[n]),
				tmpR	=	TF3R[n]<<lSH;
				tmpI	=	TF3I[n]<<lSH;
//				SumR	+=	((TF3R[n]<<lSH) / tmp),		//2^lSH ����� ��еǴϱ�
//				SumI	+=	((TF3I[n]<<lSH) / tmp);		//�� ��ŭ ��� �÷���
				SumR	+=	(tmpR / tmp),		//2^lSH ����� ��еǴϱ�
				SumI	+=	(tmpI / tmp);		//�� ��ŭ ��� �÷���
mexPrintf(	"%dth/%d=%lli Epoch, Z/abs(Z)= (%lli+%llii)/%lli, Regulate= %lli+%llii, Sum= %lli+%llii\n",
			l, nEpoch, n, TF3R[n], TF3I[n], tmp, tmpR, tmpI, SumR, SumI);
//				EpSum	+=	( z / cabsf(z) );
//mexPrintf("Epoch=%d, z[%f+%fi]=z1[%f+%fi]*conj(z2[%f+%fi]), "
//			"Div(Z/abs(Z))=%f+%fi, EpSum = %f+%fi\n",
//			E, creal(z), cimag(z), creal(z1), cimag(z1), creal(z2), cimag(z2),
//			creal(D), cimag(D), creal(EpSum), cimag(EpSum));
//fprintf(rst, "Epoch=%d, z[%f+%fi]=z1[%f+%fi]*conj(z2[%f+%fi]), "
//			"Div(Z/abs(Z))=%f+%fi, EpSum = %f+%fi\n",
//			E, creal(z), cimag(z), creal(z1), cimag(z1), creal(z2), cimag(z2),
//			creal(D), cimag(D), creal(EpSum), cimag(EpSum));

/*mexPrintf(		"TFch1[%3d][%3d][%3d]= %9.6f %s%8.6fi : "
				"TFch2[%3d][%3d][%3d]= %9.6f %s%8.6fi\n",
				f+1,t+1,e+1, ch1r, ch1i>=0 ?"+" :"", ch1i,	//idxǥ��� 1����
				f+1,t+1,e+1, ch2r, ch2i>=0 ?"+" :"", ch2i);
fprintf(sti,	"TFch1[%3d][%3d][%3d]= %9.6f %s%8.6fi : "
				"TFch2[%3d][%3d][%3d]= %9.6f %s%8.6fi\n",
				f+1,t+1,e+1, ch1r, ch1i>=0 ?"+" :"", ch1i,
				f+1,t+1,e+1, ch2r, ch2i>=0 ?"+" :"", ch2i);*/
		}

//plv	=	abs( mean( EpSum ));		%���Ҽ� / ���밪(�Ǽ�)*/
//			plv[f + t*nFreq]	=	sqrt(					//real��
//					( SumR/nEpoch )*( SumR/nEpoch ) -
//					( SumI/nEpoch )*( SumI/nEpoch )*-1);
			if (!SumI)
//				plv[f + t*nFreq]	=	(float)(SumR / nEpoch);
				plv[m]	=	((float)(SumR / nEpoch)) / (1L<<lSH);
			nf (!SumR)
//				plv[f + t*nFreq]	=	(float)(SumI / nEpoch);
				plv[m]	=	((float)(SumI / nEpoch)) / (1L<<lSH);
			no
			{
				tmpR	=	SumR / nEpoch;
				tmpI	=	SumI / nEpoch;
mexPrintf(	"%dth/%d F*T, PLV(%d)=abs(mean(Sum))=abs(mean(%lli+%llii))=abs(%lli+%llii)\n",
			m, nFxT, m, SumR, SumI, tmpR, tmpI);

//				plv[f + t*nFreq]	=	(float)sqrt(tmpR*tmpR + tmpI*tmpI);
				plv[m]	=	((float)isqrt(tmpR*tmpR + tmpI*tmpI)) / (1L<<lSH);

mexPrintf(	"%dth/%d F*T, PLV(%d)=abs(mean(Sum))=abs(%lli+%llii)=%lli\n",
			m, nFxT, m, tmpR, tmpI, plv[m]);
			}
//			plv[f + t*nFreq]	=	cabsf( EpSum / nEpoch );	//real, float
//mexPrintf("PLV[%d, %d] = (%d x %d = %d) = %f\n", f, t, f, t, f+t*nFreq, plv[f + t*nFreq]);
//mexPrintf("mean(EpSum[%f+%fi], %d) = %f+%fi, abs(mean()) = %fvs PLV[%d,%d]=%f\n",
//			creal(EpSum), cimag(EpSum), nEpoch,
//			creal(EpSum/nEpoch), cimag(EpSum/nEpoch),
//			cabsf( EpSum / nEpoch ), f, t, plv[f + t*nFreq]);
//fprintf(rst,"mean(EpSum[%f+%fi], %d) = %f+%fi, abs(mean()) = %fvs PLV[%d,%d]=%f\n",
//			creal(EpSum), cimag(EpSum), nEpoch,
//			creal(EpSum/nEpoch), cimag(EpSum/nEpoch),
//			cabsf( EpSum / nEpoch ), f, t, plv[f + t*nFreq]);
	}

	free(TF3I);
	free(TF3R);

//	fclose(sti);	//-]

  /* Dispatch the entry-point. */
//	 c_tf2coh_min4_AmH_calc_mexFunct(c_tf2coh_min4_AmH_calcStackData, nlhs, plhs,
//	   nrhs, prhs);
//	 mxFree(c_tf2coh_min4_AmH_calcStackData);

//save to result file for comparing with value of edited code.

//	FILE	*rst		=	fopen("RESULT.dat", "wt");
//(tf2coh_min4_AmH_calcStackData *SD, const emlrtStack
//  *sp, const creal32_T TFch1[3006000], const creal32_T TFch2[3006000], real_T
//  nFreq, real_T nTime, real_T nEpoch, real_T bPerm, real32_T plv[9000])

//	[nFreq,nTime,Ch1,Ch2]	=	size(PLV);
//	nFreq			=	int32(nFreq);
//	nTime			=	int32(nTime);
/*mexPrintf(			"nFreq=%d, nTime=%d, nEpoch=%d\n", nFreq, nTime, nEpoch);
fprintf(rst,		"nFreq=%d, nTime=%d, nEpoch=%d\n", nFreq, nTime, nEpoch);

	double	P;
	for (f= 0; f< nFreq; f++)
		for (t= 0; t< nTime; t++)
		{
				P		=	plv[f + t*nFreq];

mexPrintf(			"PLV[%3d][%3d]= %9.6f\n",	f+1, t+1, P);
fprintf(rst,		"PLV[%3d][%3d]= %9.6f\n",	f+1, t+1, P);
		}
	fclose(rst);
*/
	//parameter ���� ����� ���� : ��� ���� ���� -> coder ��� marshallOut //-[
/*	int	iv3[2]	=	{ 0, 0 };
const	mxArray		*array0;
	int	iv4[2]	=	{ nFreq, nTime };

//	array0			=	emlrtCreateNumericArray(2, iv3, mxSINGLE_CLASS, mxREAL);
	array0			=	emlrtCreateNumericArray(2, iv3, mxDOUBLE_CLASS, mxREAL);
	mxSetData((mxArray *)array0, (void *)plv);		//filling array0
	emlrtSetDimensions((mxArray *)array0, iv4, 2);		//regulating dim size

	const mxArray *y	=	NULL;
	emlrtAssign(&y, array0);	// Marshall function outputs

	plhs[0]			=	y;*/	//-]
}

/* End of code generation (_coder_tf2coh_min4_AmH_calc_mex.c) */