function [ ]	=	gabor_main(Wpx, Hpx, inch, theta, d, CPD)

clc;
clear;

%%-------------------------------------------------------------------------------
% 시야각 6도에 대응하는 스크린 크기 비례하는 이미지 크기 계산
%% 1. 전체 화면 정보부터 산출
Wpx		=	1920;			% 가로 픽셀 수 -> 모니터에 따라 상수값으로 결정
Hpx		=	1080;			% 세로 픽셀 수 -> 모니터에 따라 상수값으로 결정
inch	=	27;				% 스크린(모니터) 대각 길이: 현재 방음실 모니터 기준
inch2mm	=	inch * 0.0254;	% M 로 변환한 값
% sqrt( Wpx^2 + Hpx^2 ) = sqrt( Lpx^2 ) 로부터,
% Wpx와 Hpx는 일정한 비율관계(ex, 3:4, 16:9, HDTV급은 모두 16:9)
%	따라서, Wpx = 16u 라고 하면, Hpx = 9u, 단 u 는 최대공약수인 스크린 단위 길이
% 위 식에 대입하면, sqrt( (16u)^2 + (9u)^2 ) = Lpx = sqrt( 337 u^2) = u*sqrt(337)
U		=	inch2mm / sqrt(337);	% 따라서, u = L / sqrt(337) (단위: M 미터)
									% 이것은 16:9 비율에서의 기본 길이임

% 한편, 1 pixel 길이는 위 u 및, 스크린의 해상도에 의해 결정되므로,
%	화면길이 / 해상도 = 16U / Wpx
Ux		=	16 * U / Wpx;			% 단위는 M 미터
Uy		=	9  * U / Hpx;			% 사실은 Ux == Uy 일 것.

%% 2. 화면에 올려질 이미지의 크기 산출
% 이미지의 가로를 a, 세로를 b 라고 하면,
% sqrt( W^2 + B^2 ) = sqrt( z^2 ), 이때 정사각형이므로 W == B
% sqrt( 2W^2 ) = z
% 따라서, W = z / sqrt(2) (단, 단위는 M 미터)
theta	=	6.00;					% 시야각 -> 상수값으로 결정 가능
d		=	1.00;					% 눈~스크린 거리 -> 상수값으로 결정 필요
z		=	2 * d * tand(theta/2);	% 이미지의 대각 직경; 정사각형
W		=	z / sqrt(2);			% 이미지의 가로 세로 길이. 단위는 M 미터
Wpx		=	W / Ux;					% Uy 로 나누어도 마찬가지. 단위는 픽셀 수

% 이어서는 CPD 계산 : CPD는 상수로 정해지며, 구해야 할 것은 cycle 관련 데이터
%w		=	W;						% gabor patch의 이미지 길이(실제길이) == W
CPD		=	0.5;					% w 내 sine cycle 갯수 : 인간 시야각 한계
n		=	CPD*theta;				% CPD에 해당하는 단위 cycle의 갯수
N		=	W / n;					% 1 cycle 의 길이 M 미터
Npx		=	N / Ux;					% 1 cycle 의 pixel 수

fprintf('Image Size : mm(%f x %f; \\ %f), px(%d x %d)\n',			...
						W*1000,W*1000,sqrt(2*W^2)*1000, int32(Wpx), int32(Wpx));
fprintf('Pixel/Cycle: mm(%f x %f; \\ %f), px(%5.2f x %5.2f)\n',	...
						N*1000,N*1000, sqrt(2*N^2)*1000, Npx,Npx);

%%-------------------------------------------------------------------------------
% Sigma		: size : 직경
% lambda	: freq : 반복 빈도 or 라인 굵기
% theta		: angle: 각도

PATH		=	'./Main_EXP_Visual';				%path
%Size		=	5.0	: 10	: 45.0;				%5등분
%Freq		=	5.0	: 2.5	: 15.0;				%5등분
%Alpha		=	1e-3: 0.2	: 1.0;				%5등분
%Alpha		=	[ 0.4e-2 0.7e-2 1e-2 1e-1 1 ];	%5등분
Tilt		=	[0/360 45/360 90/360 135/360];	%4등분
%gabor_filter(25, 25, 0.001, 45/360, PATH);
%{
gabor_patch(256, 25, 0.007, 45, PATH); fprintf('pause\n'); pause
gabor_patch(50, 25, 0.007, 45, PATH); fprintf('pause\n'); pause
gabor_patch(25, 25, 0.005, 45, PATH); fprintf('pause\n'); pause
gabor_patch(50, 25, 0.005, 45, PATH); fprintf('pause\n'); pause
gabor_patch(25, 25, 0.003, 45, PATH); fprintf('pause\n'); pause
gabor_patch(50, 25, 0.003, 45, PATH); fprintf('pause\n'); pause
%}


%%-------------------------------------------------------------------------------
%S1~6 * T1~4 = 24 종류의 stimuli 를 제작한다.
%단, contrast가 각 indivisual 마다 차이날 수 있으므로, 이를 감안해야 함.
%S3 과 S4의 중간값이 contrast의 기준임.
%따라서, 기준 constrast를 C0 라고 둘 때,
%	S4 = C0 + delta/2
%	S3 = C0 - delta/2
%로 가정할 수 있지만, 더 정확하게 구성하려면 log-기반 sigmoid 함수를 적용해야 함.
%결론적으로,
%	Sn = C0 + sigmoid(n)-0.5, 단, 0<C0<1, Sig(6)==2*(Sig(C0)-0), 3<C0<4 임
% 블럭주석의 경우 주석지시자 옆에 다른 문자가 더 달려 있으면 인식 안됨!
fprintf('\nGenerating Gabor combination for [Contrast * Tilt = 6 * 4 = 24]\n');
S			=	Wpx; %256.0;							%중간 등급: 256win의 10%
F			=	Npx; %25.0;							%중간 등급: 256win의 10%
%sigmoid 함수 : http://roboticist.tistory.com/494
% 1 ./ (1+exp(-ax)) * 0.020	: 단, 0.020은 max contrast, a는 기울기, x는 delta
%							: 현재: a=1/2(미정: ASAP 기울도록), x= -2.5:1.0:2.5
%	=	0.0045    0.0064    0.0088    0.0112    0.0136    0.0155
a			=	1/2;
x			=	-2.5:1.0:2.5;
Alpha		=	1 ./ (1+exp(-a * x)) * 0.0057;	%6등분
Tilt		=	[0 45 90 135];	%4등분
for c		=	1:length(Alpha)
	C		=	Alpha(c);

for a		=	1:length(Tilt)
	T		=	Tilt(a);

	jpg		=	gabor_patch(S, F, C, T, PATH, Wpx);	%이미지 해상도 fitting 필요

	fprintf(['Save GABOR including spec[S:%05.2f, F:%05.2f, '				...
			'C:%06.4f, T:%05.1f] image to %s\n'],	S, F, C, T, jpg);
end
end
%{
%%-------------------------------------------------------------------------------
%experiment용 stimuli를 제작한다 : 0.0:0.0005:0.05 * 4 = 400
S			=	25.0*1;							%중간 등급: 256win의 10%
F			=	25.0;							%중간 등급: 256win의 10%
Alpha		=	[0.009-0.001*5:0.001:0.009 0.010 0.011:0.001:0.011+0.001*5];
				%12등분: 중앙값: 0.010 = total 13개
T			=	1.0;							%정방향
fprintf('\nGenerating Gabor image for [Contrast step %d]\n', length(Alpha));
for c		=	1:length(Alpha)
	C		=	Alpha(c);
	jpg		=	gabor_patch(S, F, C, T, PATH);
%	jpg		=	gabor_filter(S, F, C, T, PATH);

	fprintf(['Save GABOR including spec[S:%04.2f, F:%04.2f, C:%05.3f, '		...
			'T:%04.2f] image to %s\n'],	S, F, C, T, jpg);
end
%}
%{
%%-------------------------------------------------------------------------------
%pre-pre-experiment(랩연구원 차원 기초 실험)용 stimuli를 제작한다.
S			=	25.0*1;							%중간 등급: 256win의 10%
F			=	25.0;							%중간 등급: 256win의 10%
Alpha		=	[0.009-0.001*5:0.001:0.009 0.010 0.011:0.001:0.011+0.001*5];
				%12등분: 중앙값: 0.010 = total 13개
T			=	1.0;							%정방향
fprintf('\nGenerating Gabor image for [Contrast step %d]\n', length(Alpha));
for c		=	1:length(Alpha)
	C		=	Alpha(c);
	jpg		=	gabor_patch(S, F, C, T, PATH);
%	jpg		=	gabor_filter(S, F, C, T, PATH);

	fprintf(['Save GABOR including spec[S:%04.2f, F:%04.2f, C:%05.3f, '		...
			'T:%04.2f] image to %s\n'],	S, F, C, T, jpg);
end
%}
%{
% 블럭주석의 경우 주석지시자 옆에 다른 문자가 더 달려 있으면 인식 안됨! %-[
fprintf('Generating Gabor image for [Size]\n');
S			=	25.0;							%중간 등급
F			=	10.0;							%중간 등급
C			=	1.0;							%가장 뚜렷하게
T			=	1.0;							%정방향
for s		=	1:length(Size)
	S		=	Size(s);
	jpg		=	gabor_filter(S, F, C, T, PATH);

	fprintf(['Save GABOR including spec[S:%04.2f, F:%04.2f, C:%05.3f, '		...
			'T:%04.2f] image to %s\n'],	S, F, C, T, jpg);
end

fprintf('\nGenerating Gabor image for [Freq]\n');
S			=	25.0;							%중간 등급
for f		=	1:length(Freq)
	F		=	Freq(f);
	jpg		=	gabor_filter(S, F, C, T, PATH);

	fprintf(['Save GABOR including spec[S:%04.2f, F:%04.2f, C:%05.3f, '		...
			'T:%04.2f] image to %s\n'],	S, F, C, T, jpg);
end

fprintf('\nGenerating Gabor image for [Tilt]\n');
C			=	1.0;							%가장 뚜렷하게
for a		=	1:length(Tilt)
	T		=	Tilt(a);
	jpg		=	gabor_filter(S, F, C, T, PATH);

	fprintf(['Save GABOR including spec[S:%04.2f, F:%04.2f, C:%05.3f, '		...
			'T:%04.2f] image to %s\n'],	S, F, C, T, jpg);
end

%%-------------------------------------------------------------------------------
% 크기, 간격, 농도의 조합으로 구성된 visual stimuli 작성
fprintf('\nGenerating Gabor image for [Size x Freq x Contrast x Tilt]\n');
for s		=	1:length(Size),	
	S		=	Size(s);

for f		=	1:length(Freq)
	F		=	Freq(f);

for c		=	1:length(Alpha)
	C		=	Alpha(c);
%	jpg		=	gabor_filter(S, F, C, T, PATH);

for a		=	1:length(Tilt)
	T		=	Tilt(a);
	jpg		=	gabor_filter(S, F, C, T, PATH);

	fprintf(['Save GABOR including spec[S:%04.2f, F:%04.2f, C:%05.3f, '		...
			'T:%04.2f] image to %s\n'],	S, F, C, T, jpg);
end
end
end
end	%-]
%}

%%-------------------------------------------------------------------------------
%{
function [ filename ]	=	gabor_filter( Size, Freq, Contrast, Tilt, Path ) %-[
	Width		=	256;
	Height		=	256;

	%%---------------------------------------------------------------------------
	%gabor 생성
	[x y F]		=	gabor_base(	'theta',	2*pi*Tilt,						...
								'width',	Width,	'height',	Height,		...
								'Sigma',	Size,							...
								'lambda',	Freq,							...
								'px',		0.5,	'py',		0.5			...
							);

	%%---------------------------------------------------------------------------
%	delete(gca); clf;
%	set(gca, 'Position', [0 0 1 1], 'OuterPosition', [0 0 1 1]);
%	set(gca, 'Position', [0 0 1 1]);			%그림 주변 공간(축 표기용) 제거
%	set(gca, 'xtick', [],	'ytick', []);
	set(gca, 'Position', [0 0 1 1],		'box', 'off',	'visible', 'off');
	axis off;									%좌표 생략
	axis tight;									%좌표 공간 최소화

%	set(gcf, 'Position', [1 1 256 256], 'OuterPosition', [1 1 256 256]);
	set(gcf, 'Position', [1 1 Width Height]);	%window 크기
%	set(gcf, 'PaperPosition', [1 1 256 256], 'PaperSize', [256 256]);
%	set(gcf, 'renderer', 'painters');			%이미지에 대한 포맷팅
%%	set(gcf, 'InvertHardcopy', 'off');			%파일 저장시 배경색 반전 끄기
%	set(gcf, 'Color', 'black');					%배경색: 위에서 배경제거 성공
%	whitebg([1 1 1]);							%배경색
	set(gcf, 'Color', [0.5, 0.5, 0.5]);			%배경색: R, G, B 비율
	hold on;

	%%---------------------------------------------------------------------------
%	h_back		=	pcolor(ones(size(F)));
%	hold on;
%	set(h_back, 'facecolor', [0.0 0.0 0.0]);	%배경색
%	set(h_gabor, 'edgecolor', 'none');			%배경색

	%surface 생성
%	set(h_gabor, 'Position',	[0 0 256 256]);				%window 크기
%	F( find( F < 1e-5 ) ) = 1;					%임계값 이하는 0으로 clear
	S			=	F * Contrast;				%새로운 surface
	h_gabor		=	pcolor(x, y, S);			%surface 작성
	%20150921A. 지난 주까지 Contrast제어가 정확히 되었으나, 갑자기 안됨.
	%	이유는 명확치 않으나, 아마도 pcolor 상의 pseudocolor map 특성과 관련된 듯
	hold on;

	%axis image;
%	shading('interp');							%쉐이딩 방식

	%%---------------------------------------------------------------------------
	%색상 제어
%	alpha(h_gabor, Contrast);					%진하기
	%colormap copper;
%	colormap gray;
	Gray		=	colormap(gray);				%앞서 정의한 gray의 colormap 획득
%	Gray		=	colormap;					%앞서 정의한 gray의 colormap 획득
%	Level		=	size(Gray, 1);				% m by 3 형 colormap 구조임
%	Cont		=	contrast(Gray, 256) * Contrast;		%최대 심도 * 비율적 감소
	Cont		=	contrast(Gray, 256);		%최대 심도
%	Cont		*=	Contrast;					%비율적 감소 -> but black 방향
%	Cont		=	(Cont-0.5)*Contrast+0.5;	%0.5(중앙:gray)기준 양쪽 감소
	colormap(Cont);

	%%---------------------------------------------------------------------------
	% 이미지를 파일로 저장

	%파일이름 구성 후 파일로 저장
%	filename	=	[	char(Path) '_Gabor' '_S' int2str(Size)				...
%						'_F' int2str(Freq) '_T' int2str(Tilt)				...
%						'_C' int2str(Contrast)	'.jpg'	];
	filename	=	sprintf('%s_Gabor_S%05.2f_F%05.2f_C%06.4f_T%04.2f.jpg',	...
							Path, Size, Freq, Contrast, Tilt);

	%파일로 저장
%	saveas(h_gabor, 'test.jpg');					%jpg : 비공간을 흰색으로 채움
	saveas(gcf, filename, 'jpg');

	%파일을 다시 읽어서 좌우 공백 제거
	img			=	imread(filename);
	new			=	imcrop(img, [151,1, 899, 899]);	%151까지 흰색이 있음

	%이미지 크기를 visual stimuli 시야각 계산에 맞춰 산출한, 281.0263 * %281.0263
	%으로 재조정
	stimuli		=	imresize(new, [ 259 259 ]);

	imwrite(stimuli, filename, 'jpg');	%-]
%}
%%-------------------------------------------------------------------------------
function [ filename ]	=	gabor_patch(Size, Freq, Contrast, Tilt, Path, Wpx)%-[
	imSize		=	256;				% image size: n X n
	lamda		=	Freq;	%10;		% wavelength (number of pixels per cycle)
	theta		=	Tilt;	%15;		% grating orientation
	sigma		=	Size;	%10;		% gaussian standard deviation in pixels
	phase		=	.25;				% phase (0 -> 1)
	trim		=	.005;				% trim off gaussian values smaller than this

	X			=	1:imSize;			% X is a vector from 1 to imageSize
	X0			=	(X / imSize) - .5;	% rescale X -> -.5 to .5
%	figure;								% make new figure window
%	plot(X0);							% plot ramp
	[Xm Ym]		=	meshgrid(X0, X0);

	freq		=	imSize / lamda;			% compute frequency from wavelength
	phaseRad	=	(phase * 2* pi);		% convert to radians: 0 -> 2*pi

	thetaRad	=	(theta / 360) * 2*pi;	% convert theta (orientation) to radians
	Xt			=	Xm * cos(thetaRad);		% compute proportion of Xm for given orientation
	Yt			=	Ym * sin(thetaRad);		% compute proportion of Ym for given orientation
	XYt			=	[ Xt + Yt ];			% sum X and Y components
	XYf			=	XYt * freq * 2*pi;		% convert to radians and scale by frequency

	grating		=	sin( XYf + phaseRad );	% make 2D sinewave

	sz			=	sigma / imSize;			% gaussian width as fraction of imageSize
	gauss		=	exp( -(((Xm.^2)+(Ym.^2)) ./ (2* sz^2)) );	% formula for 2D gaussian
	gauss(gauss < trim)	=	0;				% trim around edges (for 8-bit colour displays)
	gabor		=	grating .* gauss;		% use .* dot-product

	%%---------------------------------------------------------------------------
	set(gca,	'Position', [0 0 1 1],		...
				'box', 'off',				...
				'visible', 'off',			...
				'xtick', [],	'ytick', []);
	% display nicely without borders
	set(gcf, 'Position', [1 1 imSize imSize]);	%window 크기
	%저장된 파일의 좌우로 백색 공백이 안생기게 하려면 위 설정이 필수,
	%단, 이미지가 좌우로 좀 늘어짐. -> 해결방법은?
%	set(gcf, 'renderer', 'painters');			%이미지에 대한 포맷팅
%	set(gcf, 'menu','none', 'Toolbar','none', 'Color',[.5 .5 .5]);	% without background
	set(gcf, 'Color',[.5 .5 .5]);	% without background

%	axis off;									%좌표 생략
%	axis tight;									%좌표 공간 최소화
	axis image; axis off; axis tight;			% 좌표공간 해제
	hold on;

	imagesc( gabor, [-1 1] );					% display
	hold on;
%	shading('interp');							%쉐이딩 방식

	Gray		=	colormap(gray);				%앞서 정의한 gray의 colormap 획득
%	Gray		=	colormap;					%앞서 정의한 gray의 colormap 획득
%	Level		=	size(Gray, 1);				% m by 3 형 colormap 구조임
%%	Cont		=	contrast(Gray, 256) * Contrast;		%최대 심도 * 비율적 감소
	Cont		=	contrast(Gray, 256);		%최대 심도
%	Cont		*=	Contrast;					%비율적 감소 -> but black 방향
	Cont		=	(Cont-0.5)*Contrast+0.5*1.01;%0.5(중앙:gray)기준 양쪽 감소
												%가운데 값이 128되어야 하는데,
												%왠일인지 127되서, 1% bl을 올림
%	Cont		=	Cont .* Contrast;
%	Cont		=	( Cont + 1 ) / 2;			%re-center on 0.5, gamma correct

	colormap(Cont);

	%%---------------------------------------------------------------------------
	% 이미지를 파일로 저장
%	set(gcf, 'renderer', 'painters');			%이미지에 대한 포맷팅
	filename	=	sprintf('%s_Gabor_S%05.2f_F%05.2f_C%06.4f_T%05.1f.jpg',	...
							Path, Size, Freq, Contrast, Tilt);

	%파일로 저장
%	print -djpeg99 'test.jpg'
%	saveas(h_gabor, 'test.jpg');					%jpg : 비공간을 흰색으로 채움
	saveas(gcf, filename, 'jpg');

	%파일을 다시 읽어서 좌우 공백 제거
	img			=	imread(filename);
	new			=	imcrop(img, [151,1, 899, 899]);	%151까지 흰색이 있음

	%이미지 크기를 visual stimuli 시야각 계산에 맞춰 산출한, Wpx로 재조정
%	stimuli		=	imresize(new, [ 259 259 ]);
	stimuli		=	imresize(new, [ Wpx Wpx ]);

	imwrite(stimuli, filename, 'jpg');	%-]
