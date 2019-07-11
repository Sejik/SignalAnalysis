function [plv,pls]=tf2coh_Min2(ch, TF, K, iter)
%%%%%%%%%%%%%%%%%%%%%%%%
%  [PLV,PLS]=tf2coh(TFc1,TFc2,K,ITER)
% Usage:
%	>> [PLV,PLS]=tf2coh([ch1, ch2], TF, K,ITER)
%	>> tf2coh(double(1x2) ch, complex(single(9x1000x372x30)) TF,
%					double(1x1) K, double(1x1) iter)
%
% Inputs:
%	ch : [ch1, ch2];
%   TFc1: time freqency complex map at channel 1 (freq x time points x epochs)
%   TFc2: time freqency complex map at channel 2 (freq x time points x epochs)
%   K : numer of average for surrogation [default:200]
%   ITER: number of surrogation [default:200]
% Outputs:
%   PLV: phase locking value
%	   [freq x time]
%   PLS: phase locking statistics
% 2007/10/04
% by Hae-Jeong Park, Yonsei Univ. MoNET
% email: hjpark0@gmail.com
%%%%%%%%%%%%%%%%%%%%%%%%

if nargin< 3, K		= 200; end;
if nargin< 4, iter	= 200; end;

%[ch1, ch2]			=	ch;		%correct? checking!
ch1		=	ch(1);
ch2		=	ch(2);
[flen,tlen,numepoch]=	size(TF(:,:,:,ch1));

%	fprintf('+Unit : COH of CHAN:%d~%d (%d of FREQ)\n',		ch1, ch2, flen);
	%위 '+Unit :'은 spmd의한 출력 들여쓰기에 맞춰 상위 fprint와 ':'의 일치 위함.
	%fprintf는 coder()에서 지원 안함.

% tf=zeros(flen,tlen);
% for e=1:numepoch,
%	 tf01=TFc1(:,:,e);
%	 tf02=TFc2(:,:,e);
%	 tf_=tf01.*conj(tf02);
%	 tf=tf+tf_./abs(tf_);
% end;
% tf=tf/numepoch;
% plv=abs(tf);
TFc		=	TF(:,:,:,ch1).* conj(TF(:,:,:,ch2));	%epoch까지 포함 한방에 연산!
TF_		=	TFc./  abs(TFc);	%epoch까지 포함 각 요소별 연산: -1, 0, +1 중 하나
%tf		=	mean(TF_, 3);		%epoch에 대해 평균값
%plv		=	abs(tf);		%plv 값 산출
plv		=	abs( mean(TF_, 3) );%epoch에 대한 평균값을 구한후 절대값 산출

if nargout< 2,
	pls	=	[];
	return;
end;

%ep		=	[	...
%   123,   99,  174,  333,  294,  244,  281,   32,  361,   40,   22,  261,  303,  175,   34,  152,  343,   92,	...
%   301,  170,  325,  304,   91,  146,  119,  190,  319,  112,  127,  241,  165,  306,   35,    6,  265,  336,	...
%   121,  271,  228,  160,  236,   55,  148,    3,  358,   96,  166,  320,  136,  269,   68,   16,  140,  135,	...
%    69,  310,  115,  369,   11,  101,   54,  105,  335,  296,  176,  218,  360,   30,  321,  357,  133,  291,	...
%   186,  149,  224,   45,  184,  365,  216,   77,  280,  338,  211,  235,   60,  217,  219,  113,  214,  254,	...
%   171,  249,  147,  292,  150,  163,   74,   78,   72,   62,   70,  229,  129,  266,  232,  242,  107,  134,	...
%   345,   51,   33,    7,   86,  331,  182,  237,  212,  351,  196,  221,  103,   38,  238,  278,  267,  100,	...
%   157,  340,   58,   76,  205,  143,   81,  172,  259,  187,  366,  159,  337,  372,  202,   89,   42,  162,	...
%   322,   28,  258,  326,  128,  145,  164,  230,  328,  151,  349,   17,  346,  239,  223,  131,  332,  317,	...
%   220,  194,   41,  227,  120,   47,  195,  111,  180,  316,  250,  367,   98,  213,  300,   80,  284,   14,	...
%   193,  247,  255,  156,  339,   46,  295,  155,  273,   56,  283,  299,   63,  240,  197,  198,  144,  312,	...
%   253,  305,  327,  104,   93,  204,  117,  354,  252,    8,  181,   67,  347,   84,  139,  208,  362,   90,	...
%    97,  169,  290,  248,  138,   83,   59,  210,  231,  106,  233,  286,   79,  287,  142,  209,  256,  188,	...
%   330,    5,  201,  371,   48,  179,  314,  177,  272,  108,   53,   29,   21,  329,  311,  353,  356,  364,	...
%    25,  257,   52,  268,  302,  185,  109,   37,  355,  279,   64,  352,   31,   49,  234,  298,  275,  270,	...
%   309,  246,  178,  344,   27,  282,  183,  110,   61,   88,   50,   87,   26,   43,  124,  192,  274,   94,	...
%   189,  161,   19,  102,  200,   44,  264,  130,   15,  315,  243,  324,  289,  203,   73,    1,  125,  308,	...
%   199,  307,  173,   36,  318,  116,   82,  323,   71,  215,   23,  141,  370,  288,  126,  137,  207,  363,	...
%   262,  293,   65,  277,  158,  153,  276,  285,  225,    2,  132,  263,  114,    4,   18,   85,  342,  222,	...
%   245,   75,  191,   24,   95,  206,  167,  348,  154,   39,  341,  168,   13,    9,   66,   20,   57,  122,	...
%   251,   10,   12,  313,  297,  226,  368,  350,  334,  260,  118,  359	];

%ep_K			=	zeros(numepoch, K);				%ep에 대해 K배
%TFc3			=	repmat(TF(:,:,:,ch1), K);
%TFc4			=	repmat(TF(:,:,:,ch2), K);
%TFc3			=	zeros(flen, tlen, numepoch, K);	%K포함 4D 구성
%TFc4			=	zeros(flen, tlen, numepoch, K);	%K포함 4D 구성

%사전준비: 아래 for i=... 루프 내에서 작업하면 매번 반복해서 시간 더 많이 소요함.
%for j=1:K, TFc3(:,:,:,j) = TF(:,:,:,ch1); end;		%K배 복제
cnt				=	zeros(flen, tlen, 'single');	%plvs >= plv 인 time 갯수

for i=1:iter,
   %fprintf('iteration:%d ...\n',i);
	plvs		=	zeros(flen, tlen, 'single');
	for k=1:K,
		ep		=	randperm(numepoch);

% 		tf=zeros(flen,tlen);
%		 for e=1:numepoch,
%			tf01=TFc1(:,:,e);
%			tf02=TFc2(:,:,ep(e));
%			%tf02=TFc2(:,:,e);
%			tf_=tf01.*conj(tf02);
%			tf=tf+tf_./abs(tf_);
%		end;
%		tf=tf/numepoch;
%		plvs=plvs+abs(tf);
		TFc4	=	TF(:,:,ep,ch2);		%ep값을 index로 하여 TF배열 재구성
		TFc		=	TF(:,:,:,ch1).* conj(TFc4);	%epoch까지 포함해서 한방에 연산!
		TF_		=	TFc./  abs(TFc);	%epoch까지 포함 각 요소별 연산: -1, 0, +1
		tf		=	mean(TF_, 3);		%epoch에 대해 평균값
		plvs	=	plvs + abs(tf);		%plv 값 집합 구성

	end;
	plvs		=	plvs/K;

%%	for j=1:K, ep_K(:,j) = randperm(numepoch); end;
%	for j=1:K, ep_K(:,j) = ep; end;
%   %----------
%%	TFc4		=	TFc4(:,:,ep_K);		%맞나? ep_K==2D, thus equal to TFc4(:,:,ep,K)
%	for j=1:K, TFc4(:,:,:,j) = TF(:,:,ep,ch2); end;	%K배 복제 + 재배열
%   %----------
%	TFc			=	TFc3.* conj(TFc4);	%epoch까지 포함해서 한방에 연산!
%	TF_			=	TFc./  abs(TFc);	%epoch까지 포함해서 각 요소별로 연산: -1, 0, +1 중 하나
%	tf			=	mean(TF_, 3);		%epoch에 대해 평균값
%	plvs		=	abs(mean(tf, 4));	%K level: plv 값 집합 구성

	%주파수별로 구분해서 plvs>=plv 인 경우를 계수해야 함.
	for j=1:flen,
		id			=	find(plvs(j, :) >= plv(j, :));	%특정주파수단위 시간범위
		cnt(j, id)	=	cnt(j, id)+1;					%특정주파수별 계수
	end;
end;

pls				=	cnt/iter;			%계수값에 대한 평균값 취함.
%for f=1:flen,							%주파수별 통계적으로 유의한지 분석
%	if pls(f,:) >= 0.05,				%유의한 차이점 없으면 값 clear
%		plv(f,:)=	zeros(1, tlen, 'single');	%값 clear
%		pls(f,:)=	zeros(1, tlen, 'single');	%값 clear
%	end;
%end;

