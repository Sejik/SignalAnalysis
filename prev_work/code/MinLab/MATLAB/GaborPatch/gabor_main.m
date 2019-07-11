function [ ]	=	gabor_main(Wpx, Hpx, inch, theta, d, CPD)

clc;
clear;

%%-------------------------------------------------------------------------------
% �þ߰� 6���� �����ϴ� ��ũ�� ũ�� ����ϴ� �̹��� ũ�� ���
%% 1. ��ü ȭ�� �������� ����
Wpx		=	1920;			% ���� �ȼ� �� -> ����Ϳ� ���� ��������� ����
Hpx		=	1080;			% ���� �ȼ� �� -> ����Ϳ� ���� ��������� ����
inch	=	27;				% ��ũ��(�����) �밢 ����: ���� ������ ����� ����
inch2mm	=	inch * 0.0254;	% M �� ��ȯ�� ��
% sqrt( Wpx^2 + Hpx^2 ) = sqrt( Lpx^2 ) �κ���,
% Wpx�� Hpx�� ������ ��������(ex, 3:4, 16:9, HDTV���� ��� 16:9)
%	����, Wpx = 16u ��� �ϸ�, Hpx = 9u, �� u �� �ִ������� ��ũ�� ���� ����
% �� �Ŀ� �����ϸ�, sqrt( (16u)^2 + (9u)^2 ) = Lpx = sqrt( 337 u^2) = u*sqrt(337)
U		=	inch2mm / sqrt(337);	% ����, u = L / sqrt(337) (����: M ����)
									% �̰��� 16:9 ���������� �⺻ ������

% ����, 1 pixel ���̴� �� u ��, ��ũ���� �ػ󵵿� ���� �����ǹǷ�,
%	ȭ����� / �ػ� = 16U / Wpx
Ux		=	16 * U / Wpx;			% ������ M ����
Uy		=	9  * U / Hpx;			% ����� Ux == Uy �� ��.

%% 2. ȭ�鿡 �÷��� �̹����� ũ�� ����
% �̹����� ���θ� a, ���θ� b ��� �ϸ�,
% sqrt( W^2 + B^2 ) = sqrt( z^2 ), �̶� ���簢���̹Ƿ� W == B
% sqrt( 2W^2 ) = z
% ����, W = z / sqrt(2) (��, ������ M ����)
theta	=	6.00;					% �þ߰� -> ��������� ���� ����
d		=	1.00;					% ��~��ũ�� �Ÿ� -> ��������� ���� �ʿ�
z		=	2 * d * tand(theta/2);	% �̹����� �밢 ����; ���簢��
W		=	z / sqrt(2);			% �̹����� ���� ���� ����. ������ M ����
Wpx		=	W / Ux;					% Uy �� ����� ��������. ������ �ȼ� ��

% �̾�� CPD ��� : CPD�� ����� ��������, ���ؾ� �� ���� cycle ���� ������
%w		=	W;						% gabor patch�� �̹��� ����(��������) == W
CPD		=	0.5;					% w �� sine cycle ���� : �ΰ� �þ߰� �Ѱ�
n		=	CPD*theta;				% CPD�� �ش��ϴ� ���� cycle�� ����
N		=	W / n;					% 1 cycle �� ���� M ����
Npx		=	N / Ux;					% 1 cycle �� pixel ��

fprintf('Image Size : mm(%f x %f; \\ %f), px(%d x %d)\n',			...
						W*1000,W*1000,sqrt(2*W^2)*1000, int32(Wpx), int32(Wpx));
fprintf('Pixel/Cycle: mm(%f x %f; \\ %f), px(%5.2f x %5.2f)\n',	...
						N*1000,N*1000, sqrt(2*N^2)*1000, Npx,Npx);

%%-------------------------------------------------------------------------------
% Sigma		: size : ����
% lambda	: freq : �ݺ� �� or ���� ����
% theta		: angle: ����

PATH		=	'./Main_EXP_Visual';				%path
%Size		=	5.0	: 10	: 45.0;				%5���
%Freq		=	5.0	: 2.5	: 15.0;				%5���
%Alpha		=	1e-3: 0.2	: 1.0;				%5���
%Alpha		=	[ 0.4e-2 0.7e-2 1e-2 1e-1 1 ];	%5���
Tilt		=	[0/360 45/360 90/360 135/360];	%4���
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
%S1~6 * T1~4 = 24 ������ stimuli �� �����Ѵ�.
%��, contrast�� �� indivisual ���� ���̳� �� �����Ƿ�, �̸� �����ؾ� ��.
%S3 �� S4�� �߰����� contrast�� ������.
%����, ���� constrast�� C0 ��� �� ��,
%	S4 = C0 + delta/2
%	S3 = C0 - delta/2
%�� ������ �� ������, �� ��Ȯ�ϰ� �����Ϸ��� log-��� sigmoid �Լ��� �����ؾ� ��.
%���������,
%	Sn = C0 + sigmoid(n)-0.5, ��, 0<C0<1, Sig(6)==2*(Sig(C0)-0), 3<C0<4 ��
% ���ּ��� ��� �ּ������� ���� �ٸ� ���ڰ� �� �޷� ������ �ν� �ȵ�!
fprintf('\nGenerating Gabor combination for [Contrast * Tilt = 6 * 4 = 24]\n');
S			=	Wpx; %256.0;							%�߰� ���: 256win�� 10%
F			=	Npx; %25.0;							%�߰� ���: 256win�� 10%
%sigmoid �Լ� : http://roboticist.tistory.com/494
% 1 ./ (1+exp(-ax)) * 0.020	: ��, 0.020�� max contrast, a�� ����, x�� delta
%							: ����: a=1/2(����: ASAP ��ﵵ��), x= -2.5:1.0:2.5
%	=	0.0045    0.0064    0.0088    0.0112    0.0136    0.0155
a			=	1/2;
x			=	-2.5:1.0:2.5;
Alpha		=	1 ./ (1+exp(-a * x)) * 0.0057;	%6���
Tilt		=	[0 45 90 135];	%4���
for c		=	1:length(Alpha)
	C		=	Alpha(c);

for a		=	1:length(Tilt)
	T		=	Tilt(a);

	jpg		=	gabor_patch(S, F, C, T, PATH, Wpx);	%�̹��� �ػ� fitting �ʿ�

	fprintf(['Save GABOR including spec[S:%05.2f, F:%05.2f, '				...
			'C:%06.4f, T:%05.1f] image to %s\n'],	S, F, C, T, jpg);
end
end
%{
%%-------------------------------------------------------------------------------
%experiment�� stimuli�� �����Ѵ� : 0.0:0.0005:0.05 * 4 = 400
S			=	25.0*1;							%�߰� ���: 256win�� 10%
F			=	25.0;							%�߰� ���: 256win�� 10%
Alpha		=	[0.009-0.001*5:0.001:0.009 0.010 0.011:0.001:0.011+0.001*5];
				%12���: �߾Ӱ�: 0.010 = total 13��
T			=	1.0;							%������
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
%pre-pre-experiment(�������� ���� ���� ����)�� stimuli�� �����Ѵ�.
S			=	25.0*1;							%�߰� ���: 256win�� 10%
F			=	25.0;							%�߰� ���: 256win�� 10%
Alpha		=	[0.009-0.001*5:0.001:0.009 0.010 0.011:0.001:0.011+0.001*5];
				%12���: �߾Ӱ�: 0.010 = total 13��
T			=	1.0;							%������
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
% ���ּ��� ��� �ּ������� ���� �ٸ� ���ڰ� �� �޷� ������ �ν� �ȵ�! %-[
fprintf('Generating Gabor image for [Size]\n');
S			=	25.0;							%�߰� ���
F			=	10.0;							%�߰� ���
C			=	1.0;							%���� �ѷ��ϰ�
T			=	1.0;							%������
for s		=	1:length(Size)
	S		=	Size(s);
	jpg		=	gabor_filter(S, F, C, T, PATH);

	fprintf(['Save GABOR including spec[S:%04.2f, F:%04.2f, C:%05.3f, '		...
			'T:%04.2f] image to %s\n'],	S, F, C, T, jpg);
end

fprintf('\nGenerating Gabor image for [Freq]\n');
S			=	25.0;							%�߰� ���
for f		=	1:length(Freq)
	F		=	Freq(f);
	jpg		=	gabor_filter(S, F, C, T, PATH);

	fprintf(['Save GABOR including spec[S:%04.2f, F:%04.2f, C:%05.3f, '		...
			'T:%04.2f] image to %s\n'],	S, F, C, T, jpg);
end

fprintf('\nGenerating Gabor image for [Tilt]\n');
C			=	1.0;							%���� �ѷ��ϰ�
for a		=	1:length(Tilt)
	T		=	Tilt(a);
	jpg		=	gabor_filter(S, F, C, T, PATH);

	fprintf(['Save GABOR including spec[S:%04.2f, F:%04.2f, C:%05.3f, '		...
			'T:%04.2f] image to %s\n'],	S, F, C, T, jpg);
end

%%-------------------------------------------------------------------------------
% ũ��, ����, ���� �������� ������ visual stimuli �ۼ�
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
	%gabor ����
	[x y F]		=	gabor_base(	'theta',	2*pi*Tilt,						...
								'width',	Width,	'height',	Height,		...
								'Sigma',	Size,							...
								'lambda',	Freq,							...
								'px',		0.5,	'py',		0.5			...
							);

	%%---------------------------------------------------------------------------
%	delete(gca); clf;
%	set(gca, 'Position', [0 0 1 1], 'OuterPosition', [0 0 1 1]);
%	set(gca, 'Position', [0 0 1 1]);			%�׸� �ֺ� ����(�� ǥ���) ����
%	set(gca, 'xtick', [],	'ytick', []);
	set(gca, 'Position', [0 0 1 1],		'box', 'off',	'visible', 'off');
	axis off;									%��ǥ ����
	axis tight;									%��ǥ ���� �ּ�ȭ

%	set(gcf, 'Position', [1 1 256 256], 'OuterPosition', [1 1 256 256]);
	set(gcf, 'Position', [1 1 Width Height]);	%window ũ��
%	set(gcf, 'PaperPosition', [1 1 256 256], 'PaperSize', [256 256]);
%	set(gcf, 'renderer', 'painters');			%�̹����� ���� ������
%%	set(gcf, 'InvertHardcopy', 'off');			%���� ����� ���� ���� ����
%	set(gcf, 'Color', 'black');					%����: ������ ������� ����
%	whitebg([1 1 1]);							%����
	set(gcf, 'Color', [0.5, 0.5, 0.5]);			%����: R, G, B ����
	hold on;

	%%---------------------------------------------------------------------------
%	h_back		=	pcolor(ones(size(F)));
%	hold on;
%	set(h_back, 'facecolor', [0.0 0.0 0.0]);	%����
%	set(h_gabor, 'edgecolor', 'none');			%����

	%surface ����
%	set(h_gabor, 'Position',	[0 0 256 256]);				%window ũ��
%	F( find( F < 1e-5 ) ) = 1;					%�Ӱ谪 ���ϴ� 0���� clear
	S			=	F * Contrast;				%���ο� surface
	h_gabor		=	pcolor(x, y, S);			%surface �ۼ�
	%20150921A. ���� �ֱ��� Contrast��� ��Ȯ�� �Ǿ�����, ���ڱ� �ȵ�.
	%	������ ��Ȯġ ������, �Ƹ��� pcolor ���� pseudocolor map Ư���� ���õ� ��
	hold on;

	%axis image;
%	shading('interp');							%���̵� ���

	%%---------------------------------------------------------------------------
	%���� ����
%	alpha(h_gabor, Contrast);					%���ϱ�
	%colormap copper;
%	colormap gray;
	Gray		=	colormap(gray);				%�ռ� ������ gray�� colormap ȹ��
%	Gray		=	colormap;					%�ռ� ������ gray�� colormap ȹ��
%	Level		=	size(Gray, 1);				% m by 3 �� colormap ������
%	Cont		=	contrast(Gray, 256) * Contrast;		%�ִ� �ɵ� * ������ ����
	Cont		=	contrast(Gray, 256);		%�ִ� �ɵ�
%	Cont		*=	Contrast;					%������ ���� -> but black ����
%	Cont		=	(Cont-0.5)*Contrast+0.5;	%0.5(�߾�:gray)���� ���� ����
	colormap(Cont);

	%%---------------------------------------------------------------------------
	% �̹����� ���Ϸ� ����

	%�����̸� ���� �� ���Ϸ� ����
%	filename	=	[	char(Path) '_Gabor' '_S' int2str(Size)				...
%						'_F' int2str(Freq) '_T' int2str(Tilt)				...
%						'_C' int2str(Contrast)	'.jpg'	];
	filename	=	sprintf('%s_Gabor_S%05.2f_F%05.2f_C%06.4f_T%04.2f.jpg',	...
							Path, Size, Freq, Contrast, Tilt);

	%���Ϸ� ����
%	saveas(h_gabor, 'test.jpg');					%jpg : ������� ������� ä��
	saveas(gcf, filename, 'jpg');

	%������ �ٽ� �о �¿� ���� ����
	img			=	imread(filename);
	new			=	imcrop(img, [151,1, 899, 899]);	%151���� ����� ����

	%�̹��� ũ�⸦ visual stimuli �þ߰� ��꿡 ���� ������, 281.0263 * %281.0263
	%���� ������
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
	set(gcf, 'Position', [1 1 imSize imSize]);	%window ũ��
	%����� ������ �¿�� ��� ������ �Ȼ���� �Ϸ��� �� ������ �ʼ�,
	%��, �̹����� �¿�� �� �þ���. -> �ذ�����?
%	set(gcf, 'renderer', 'painters');			%�̹����� ���� ������
%	set(gcf, 'menu','none', 'Toolbar','none', 'Color',[.5 .5 .5]);	% without background
	set(gcf, 'Color',[.5 .5 .5]);	% without background

%	axis off;									%��ǥ ����
%	axis tight;									%��ǥ ���� �ּ�ȭ
	axis image; axis off; axis tight;			% ��ǥ���� ����
	hold on;

	imagesc( gabor, [-1 1] );					% display
	hold on;
%	shading('interp');							%���̵� ���

	Gray		=	colormap(gray);				%�ռ� ������ gray�� colormap ȹ��
%	Gray		=	colormap;					%�ռ� ������ gray�� colormap ȹ��
%	Level		=	size(Gray, 1);				% m by 3 �� colormap ������
%%	Cont		=	contrast(Gray, 256) * Contrast;		%�ִ� �ɵ� * ������ ����
	Cont		=	contrast(Gray, 256);		%�ִ� �ɵ�
%	Cont		*=	Contrast;					%������ ���� -> but black ����
	Cont		=	(Cont-0.5)*Contrast+0.5*1.01;%0.5(�߾�:gray)���� ���� ����
												%��� ���� 128�Ǿ�� �ϴµ�,
												%�������� 127�Ǽ�, 1% bl�� �ø�
%	Cont		=	Cont .* Contrast;
%	Cont		=	( Cont + 1 ) / 2;			%re-center on 0.5, gamma correct

	colormap(Cont);

	%%---------------------------------------------------------------------------
	% �̹����� ���Ϸ� ����
%	set(gcf, 'renderer', 'painters');			%�̹����� ���� ������
	filename	=	sprintf('%s_Gabor_S%05.2f_F%05.2f_C%06.4f_T%05.1f.jpg',	...
							Path, Size, Freq, Contrast, Tilt);

	%���Ϸ� ����
%	print -djpeg99 'test.jpg'
%	saveas(h_gabor, 'test.jpg');					%jpg : ������� ������� ä��
	saveas(gcf, filename, 'jpg');

	%������ �ٽ� �о �¿� ���� ����
	img			=	imread(filename);
	new			=	imcrop(img, [151,1, 899, 899]);	%151���� ����� ����

	%�̹��� ũ�⸦ visual stimuli �þ߰� ��꿡 ���� ������, Wpx�� ������
%	stimuli		=	imresize(new, [ 259 259 ]);
	stimuli		=	imresize(new, [ Wpx Wpx ]);

	imwrite(stimuli, filename, 'jpg');	%-]
