function EEG = pop_matreader( name, pathstr )
% pop_matreader - read MAT file and return EEG structure
%
% Usage:         
%%			0. ~isempty(name) & ~isempty(pathstr) : by tigoum
%%				NOT popup window!, & direct read mat file on pathstr
%
%            1. type 
%               >> EEG = pop_matreader
%               or call EEG = pop_matreader to convert MAT file to EEG structure. 
%               Output: EEG - is the structure enclosing EEG data.
%               (1) For EEG recorded with standard labels, the recognizable MAT file format 
%               includes at least 8 fields: 
%               - EEG.name is the name for the EEG data.
%               - EEG.type is 'EEG'
%               - EEG.nbchan is the number of channels
%               - EEG.points is the number of sampling points
%               - EEG.srate is the sampling rate
%               - EEG.labeltype is 'standard'
%               - EEG.labels is a cell array of channel labels
%               - EEG.data is a 2D array ([m, n]) for EEG time series, 
%                 where m=nbchan and n=points.
%               (2) For EEG recorded with customized locations, the recognizable MAT file format 
%               includes at least 10 fields: 
%               - EEG.name is the name for the EEG data.
%               - EEG.type is 'EEG'
%               - EEG.nbchan is the number of channels
%               - EEG.points is the number of sampling points
%               - EEG.srate is the sampling rate
%               - EEG.labeltype is 'customized'
%               - EEG.labels is a cell array of channel labels
%               - EEG.data is a 2D array ([m, n]) for EEG time series, 
%                 where m=nbchan and n=points.
%               - EEG.locations has nbchan structures (the customized locations)
%                  - EEG.locations(i).X is the X element of the i-th location.
%                  - EEG.locations(i).Y is the Y element of the i-th location.
%                  - EEG.locations(i).Z is the Z element of the i-th location.
%               - EEG.marks is a 2D array ([m, n]) for landmark locations, where
%                  - EEG.marks(1,:) is the Nz location
%                  - EEG.marks(2,:) is the T9/LPA location
%                  - EEG.marks(3,:) is the T10/RPA location
%               (3) For ERP data, the EEG structure includes an extra field:
%               - EEG.event stores the information for events.  
%
%               Please see the eConnectome Manual 
%               (via 'Menu bar -> Help -> Manual' in the main econnectome GUI)
%               for details about the recognizable MAT file format for EEG.
%
%            2. call EEG = pop_matreader from the eegfc GUI ('Menu bar -> File -> Import -> MAT File'). 
%               The imported EEG will be made the current EEG and mastered by the 
%               document manager of the eegfc GUI. 
%
% Program Author: Yakang Dai, University of Minnesota, USA
%
% User feedback welcome: e-mail: econnect@umn.edu
%

% License
% ==============================================================
% This program is part of the eConnectome.
% 
% Copyright (C) 2010 Regents of the University of Minnesota. All rights reserved.
% Correspondence: binhe@umn.edu
% Web: econnectome.umn.edu
%
% This program is free software for academic research: you can redistribute it and/or modify
% it for non-commercial uses, under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program. If not, see http://www.gnu.org/copyleft/gpl.html.
%
% This program is for research purposes only. This program
% CAN NOT be used for commercial purposes. This program 
% SHOULD NOT be used for medical purposes. The authors 
% WILL NOT be responsible for using the program in medical
% conditions.
% ==========================================

% Revision Logs
% ==========================================
%
% Yakang Dai, 20-Apr-2010 18:26:30
% Add ERP analysis function
%
% Yakang Dai, 01-Mar-2010 15:20:30
% Release Version 1.0 beta 
%
% ==========================================

if nargin < 2 | isempty(name) | isempty(pathstr)	% appended by tigoum
[name pathstr]=uigetfile('*.mat', 'Select EEG File');
if name==0
	EEG = [];
	return;
end
end

addpath(pathstr);
Fullfilename=fullfile(pathstr,name);

eeg		=	load(Fullfilename);
field	=	fieldnames(eeg)';
if isempty(eeg)
    EEG = [];
    errordlg( ['Load ' Fullfilename ' error!'] );
    return;

elseif isfield(eeg, 'eEEG') & length(size(eeg.eEEG)) == 3	% minlab 3D raw data
	%% Connectome type EEG Structure ����
%	eeg.{
%		eCHN: {1x32 cell}
%		eEEG: [3500x32x60 double]
%		eFS: 500
%		eMRK: [1x60 double]
%	}
	EEG				=	struct;

	EEG.name		=	name;						% the name for the EEG data
%	EEG.data		=	permute(eeg.eEEG, [2 3 1]);	% chan x trial x data(dp)
%	EEG.data		=	shiftdim(eeg.eEEG, 1);		% chan x trial x data(dp)
	%20160324B. CAUTION! permute(or shift) dimension order significant %carefully
	EEG.data		=	permute(eeg.eEEG, [2 1 3]);	% chan x data(dp) x trial
	EEG.org_permute	=	true;						% using shiftdim()
	EEG.org_dims	=	size(eeg.eEEG);				% ���� ����: dp x ch x trial
%	EEG.data		=	reshape(EEG.data, EEG.org_dims(2), []);	% ch x (tr x dp)
	EEG.data		=	reshape(EEG.data, EEG.org_dims(2), []);	% ch x (dp x tr)
		% a 2D array ([m,n]) for EEG time series where m = nbchan and n = points
	EEG.type		=	'EEG';	% the type of data, 'EEG'(����X), 'ECOG' or 'MEG'
	EEG.unit		=	'uv';						% data�� ����
	EEG.nbchan		=	EEG.org_dims(2);			% the number of channels
	EEG.points		=	size(EEG.data, 2);			% # of sampling points
	EEG.srate		=	eeg.eFS;					% sampling rate
	EEG.labeltype	=	'standard';					% channel location
													% 10-10, 10-20: 'standard'
													% �̿��� ��� 'custom' ǥ��
	EEG.labels		=	eeg.eCHN';					% a cell array of chan labels
				% channel name(������ ����ϴ� �� ���� �η��� �ƴ� �� ���� �Է�)
	EEG.marker		=	eeg.eMRK';					% append by tigoum

	% ���� struct ȭ ��Ų �����͸� �����̾��� ��ó�� ����
	eeg				=	struct('EEG', EEG);
	clear EEG

elseif isfield(eeg, 'eEEG') & length(size(eeg.eEEG)) == 2	% minlab 2D raw data
	%% Connectome type EEG Structure ����
%	eeg.{
%		eCHN: {1x32 cell}
%		eEEG: [3500x32 double]
%		eFS: 500
%		eMRK: [1x1 double]
%	}
	EEG				=	struct;

	EEG.name		=	name;						% the name for the EEG data
	EEG.data		=	permute(eeg.eEEG, [2 1]);	% chan x data(dp)
	EEG.org_permute	=	true;						% using shiftdim()
	EEG.type		=	'EEG';	% the type of data, 'EEG'(����X), 'ECOG' or 'MEG'
	EEG.unit		=	'uv';						% data�� ����
	EEG.nbchan		=	size(EEG.data, 1);			% the number of channels
	EEG.points		=	size(EEG.data, 2);			% # of sampling points
	EEG.srate		=	eeg.eFS;					% sampling rate
	EEG.labeltype	=	'standard';					% channel location
													% 10-10, 10-20: 'standard'
													% �̿��� ��� 'custom' ǥ��
	EEG.labels		=	eeg.eCHN';					% a cell array of chan labels
				% channel name(������ ����ϴ� �� ���� �η��� �ƴ� �� ���� �Է�)
	EEG.marker		=	eeg.eMRK';					% append by tigoum

	% ���� struct ȭ ��Ų �����͸� �����̾��� ��ó�� ����
	eeg				=	struct('EEG', EEG);
	clear EEG

elseif isfield(eeg, 'gEEG')						% minlab average data format !!!
	%% Connectome type EEG Structure ����
%	eeg.{
%		eCHN: {1x32 cell}
%		eEEG: [3500x32 double]
%		eFS: 500
%	}
	EEG				=	struct;

	EEG.name		=	name;						% the name for the EEG data
%	EEG.org_dims	=	size(eeg.gEEG);				% ���� ����: dp x ch
	EEG.data		=	permute(eeg.gEEG, [2 1]);	% chan x data(dp)
%	EEG.data		=	reshape(EEG.data, EEG.org_dims(2), []);	% ch x (tr x dp)
		% a 2D array ([m,n]) for EEG time series where m = nbchan and n = points
	EEG.type		=	'EEG';	% the type of data, 'EEG'(����X), 'ECOG' or 'MEG'
	EEG.unit		=	'uv';						% data�� ����
	EEG.nbchan		=	EEG.org_dims(2);			% the number of channels
	EEG.points		=	size(EEG.data, 2);			% # of sampling points
	EEG.srate		=	eeg.eFS;					% sampling rate
	EEG.labeltype	=	'standard';					% channel location
													% 10-10, 10-20: 'standard'
													% �̿��� ��� 'custom' ǥ��
	EEG.labels		=	eeg.eCHN';					% a cell array of chan labels
				% channel name(������ ����ϴ� �� ���� �η��� �ƴ� �� ���� �Է�)
%	EEG.marker		=	eeg.eMRK';					% append by tigoum

	% ���� struct ȭ ��Ų �����͸� �����̾��� ��ó�� ����
	eeg				=	struct('EEG', EEG);
	clear EEG

elseif any( cellfun(@(x)( ~isempty(x) ),	...	% minlab erp/evk data format !!!
			regexp( field', 'ERP_[A-Za-z0-9_]{2,}', 'match' )	) )	% 2 more
%	eeg.{
%		ERP_F__L: [1000x30 double]
%		EVK_F__L: [280x1000x30 double]
%		TOA_F__L: [280x1000x30 double]
%		TOT_F__L: [280x1000x30 double]
%	}
	% rename the variable
%	ERP				=	whos('-regexp', 'eeg.ERP_[A-Za-z0-9_]{4}');
%	EVK				=	whos('-regexp', 'eeg.EVK_[A-Za-z0-9_]{4}');
%	TOA				=	whos('-regexp', 'eeg.TOA_[A-Za-z0-9_]{4}');
%	TOT				=	whos('-regexp', 'eeg.TOT_[A-Za-z0-9_]{4}');
	ERP=char(field( cellfun(@(x) ~isempty(x), regexp(field,'ERP_.*','match')) ));
	EVK=char(field( cellfun(@(x) ~isempty(x), regexp(field,'EVK_.*','match')) ));
	TOA=char(field( cellfun(@(x) ~isempty(x), regexp(field,'TOA_.*','match')) ));
	TOT=char(field( cellfun(@(x) ~isempty(x), regexp(field,'TOT_.*','match')) ));

	szArr = {size(eeg.(ERP)), size(eeg.(EVK)), size(eeg.(TOA)), size(eeg.(TOT))};

	% --------------------------------------------------
	% ������ ������ �̹Ƿ�, GUI�� �����Ͽ� ����ڷκ��� ���ù���.
	% ����, �̾����� ���� mat data�� loading������ ������ ���û��׵��� �ٷ�
	% ����ǵ��� �����׸��� ����ؼ� ������ ��.
	persistent glVar;								% ���� ���� ���
	persistent glDim;								% ���� ���� ���
	persistent glIntv;								% ���� ���� ���
	persistent gleFS;								% ���� ���� ���

	if isempty(glVar),[glVar,glDim,glIntv,gleFS]=deal(1,[],[],1);end %����1�� %-[

	G.hF	=	figure(	'units','pixels',									...
						'position',[300 300 300 300],						...
						'menubar','none',									...
						'name','Select for multi variables',				...
						'numbertitle','off',								...
						'resize','off');

	G.txVar	=	uicontrol('Style','text', 'String','Variables',	...	% text ���
						'Unit','pix',										...
						'Position',[10 260 80 25],							...
						'Fontsize',10,										...
						'HorizontalAlignment','center');
	set(G.txVar,'backgroundcolor',get(G.hF,'color'))
	G.var	=	uicontrol('style','pop',						...	% sel var
						'unit','pix',										...
						'position',[100 270 190 20],						...
						'fontsize',10,										...
						'fontweight','bold',								...
						'HorizontalAlignment', 'center',					...
						'string',{ERP;EVK;TOA;TOT},							...
						'value',glVar,										...
						'callback',{@var_call, G.hF});

	G.txDim	=	uicontrol('Style','text', 'String','Dimension',	...	% text
						'Unit','pix',										...
						'Position',[10 230 80 25],							...
						'Fontsize',10,										...
						'HorizontalAlignment','center');
	set(G.txDim,'backgroundcolor',get(G.hF,'color'))
	G.dim	=	uicontrol('style','pop',						...	% sel dim
						'unit','pix',										...
						'position',[100 240 190 20],						...
						'fontsize',10,										...
						'fontweight','bold',								...
						'callback',{@dim_call, G.hF});
%						var_call();					% G.dim�� string, value ����

	G.txInt	=	uicontrol('Style','text', 'String','Index',		...	% text
						'Unit','pix',										...
						'Position',[10 60 80 160],							...
						'Fontsize',10,										...
						'HorizontalAlignment','center');
	set(G.txInt,'backgroundcolor',get(G.hF,'color'))
	G.intv	=	uicontrol('style','list',						...	% ���� ����
						'unit','pix',										...
						'position',[100 70 190 155],						...
						'fontsize',10,										...
						'fontweight','bold');
%						dim_call();					% G.intv�� string, value ����

	G.txeFS	=	uicontrol('Style','text', 'String','Sample Rate',	...	% text
						'Unit','pix',										...
						'Position',[10 30 80 25],							...
						'Fontsize',10,										...
						'HorizontalAlignment','center');
	set(G.txeFS,'backgroundcolor',get(G.hF,'color'))
	G.eFS	=	uicontrol('style','pop',						...	% ���� ����
						'unit','pix',										...
						'position',[100 40 190 20],							...
						'fontsize',10,										...
						'fontweight','bold',								...
						'string',{'500';'1000'},							...
						'value',gleFS);

	G.pb	=	uicontrol('style','push',						...	% select ok
						'unit','pix',										...
						'position',[10 10 280 20],							...
						'fontsize',12,										...
						'fontweight','bold',								...
						'string','SELECT',									...
						'callback','uiresume(gcbf)');	% @pb_call);

	[G.szArr, G.glVar, G.glDim, G.glIntv] = deal(szArr, glVar, glDim, glIntv);
	guidata(G.hF, G)								% ����
%	movegui('center')								% �� ��� ��ġ
						var_call(0,0, G.hF);		% ���μ� �˾Ƽ� dim_call ȣ��
%						dim_call(G.hF);				% G.intv�� string, value ����
	uiwait(G.hF);									% polling

	% ���� ��� Ȯ������.
try,glVar	=	get(G.var, {'string','value'});		% ������ ����
catch	exception									% destroy dialog box
%	Error using handle.handle/get
%	Invalid or deleted object.
    EEG = [];
%	errordlg('The input is not a valid EEG MAT File');
    return;
end
	VAR		=	char(glVar{1}(glVar{2}));
	glVar	=	glVar{2};

	glDim	=	get(G.dim, {'string','value'});		% ���� ����
%	glDim	=	str2double(glDim{1}(glDim{2}));
	glDim	=	glDim{2};

	glIntv	=	get(G.intv,{'string','value'});		% ������ ���� ����
%	glIntv	=	str2double(glIntv{1}(glIntv{2}));
	glIntv	=	glIntv{2};

	gleFS	=	get(G.eFS,{'string','value'});		% ������ ���� ����
	eeg.eFS	=	str2double(gleFS{1}(gleFS{2}));
	gleFS	=	gleFS{2};

	close(G.hF);									% remove popup menu	%-]

	% --------------------------------------------------
	% ���õ� ������ ���� ��ó�� �����Ѵ�.
	% VAR, glDim, glIntv �� �ַ� ����Ͽ�, 3D -> 2D �� �����ϸ� ��.
	DATA			=	eeg.(VAR);
	if glVar > 1									% 3D ������ ���
		% ch x dp ���� �Ű�Ἥ ������ ��.
		DATA		=	shiftdim(DATA, glDim-1);	% �ش� ������ 1�� ��ġ��
		DATA		=	mean(DATA(glIntv,:,:), 1);	% 1�� ������ ��ճ�
		DATA		=	shiftdim(DATA, ndims(DATA)-(glDim-1)); % ��ġ ����

		switch glDim
		case 1, DATA=	permute(DATA, [ 1 3 2 ]);	% fq x ch x dp -> ch x dp
		case 2, DATA=	permute(DATA, [ 3 2 1 ]);	% ch x dp x fq -> ch x fq
		case 3, %DATA=	permute(DATA, [ 1 2 3 ]);	% fq x dp x ch -> fq x dp
		end

		DATA		=	squeeze(DATA);				% ũ�� 1 �� ���� ����
	else											% 2D ����, ��ó�� �� ����
		DATA		=	permute(DATA, [ 2 1 ]);		% chan x data(dp)
	end

	% --------------------------------------------------
	EEG				=	struct;

	[~,NAME,~]		=	fileparts(name);
	EEG.name		=	[NAME '.' VAR];				% the name for the EEG data
%	EEG.data		=	permute(DATA, [2 1]);		% chan x data(dp)
	EEG.data		=	DATA;						% chan x data(dp)
	EEG.type		=	'EEG';	% the type of data, 'EEG'(����X), 'ECOG' or 'MEG'
	EEG.unit		=	'uv';						% data�� ����
	EEG.nbchan		=	size(EEG.data, 1);			% the number of channels
	EEG.points		=	size(EEG.data, 2);			% # of sampling points
	EEG.srate		=	eeg.eFS;					% sampling rate
	EEG.labeltype	=	'standard';					% channel location
													% 10-10, 10-20: 'standard'
													% �̿��� ��� 'custom' ǥ��
	if		EEG.nbchan == 30		% -[
		Chan		=	{		...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
						'CP5',	'CP1',	'CP2',	'CP6',			'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
	elseif	EEG.nbchan == 31
		Chan		=	{		...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',			'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
	elseif	EEG.nbchan == 32
		Chan		=	{		...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
	elseif	EEG.nbchan == 63
		Chan		=	{		...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
						'CP5',	'CP1',	'CP2',	'CP6',	'FCz',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',  'PO10',...
				'AF7',	'AF3',	'AF4',	'AF8',	'F5',	'F1',	'F2',	'F6', ...
				'FT9',	'FT7',	'FC3',	'FC4',	'FT8',	'FT10',	'C5',	'C1', ...
				'C2',	'C6',	'TP7',	'CP3',	'CPz',	'CP4',	'TP8',	'P5', ...
				'P1',	'P2',	'P6',	'PO7',	'PO3',	'POz',	'PO4',	'PO8' };
	elseif	EEG.nbchan == 64
		Chan		=	{		...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',	'FCz',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',  'PO10',...
				'AF7',	'AF3',	'AF4',	'AF8',	'F5',	'F1',	'F2',	'F6', ...
				'FT9',	'FT7',	'FC3',	'FC4',	'FT8',	'FT10',	'C5',	'C1', ...
				'C2',	'C6',	'TP7',	'CP3',	'CPz',	'CP4',	'TP8',	'P5', ...
				'P1',	'P2',	'P6',	'PO7',	'PO3',	'POz',	'PO4',	'PO8' };
	end		%-]
	EEG.labels		=	Chan';						% a cell array of chan labels
				% channel name(������ ����ϴ� �� ���� �η��� �ƴ� �� ���� �Է�)

	% ���� struct ȭ ��Ų �����͸� �����̾��� ��ó�� ����
	eeg				=	struct('EEG', EEG);
	clear EEG
end
	function []	=	var_call(src, evt, hF)			% built-in callback
		G		=	guidata(hF);					% GUI �ڵ�
		var		=	get(G.var, {'string','value'});	% ������ ����

		lDim	=	G.szArr{var{2}};				% ������ �ش��ϴ� index
		if length(lDim) > 2							% 3���� �̻� ũ���� ����
		sDim	=	arrayfun(@(x) {num2str(x)}, lDim);
		dim		=	get(G.dim, {'string','value'});	% ���� ����
%		Dim		=	str2double(dim{1}(dim{2}));		% �� ���� == dim �ִ�ũ��
		if 0<src,Dim=dim{2}; else,Dim=G.glDim; end	% �� Ȯ��: �ʱ�ȭ ȣ�� ����
		if isempty(Dim) | length(lDim)<Dim, Dim=1; end %��ﰪ �ʰ���
					set(G.dim, 'string',sDim);		% ���� ���
					set(G.dim, 'value', Dim);		% ���� ����
		else
					set(G.dim, 'string',{});		% 2������ ��������!
					set(G.dim, 'value', []);		% ���� ����
		end
%		guidata(hF, G);								% ����
		dim_call(src, evt, hF);						% ������ ����
	end	% func
	function []	=	dim_call(src, evt, hF)			% built-in callback
		G		=	guidata(hF);					% GUI �ڵ�
		dim		=	get(G.dim, {'string','value'});	% ���� ����
		if ~isempty(dim{1}) & ~isempty(dim{2})		% �� ���� == 3���� �̻�
		Dim		=	str2double(dim{1}(dim{2}));		% �� ���� == dim �ִ�ũ��

		sIntv	=	arrayfun(@(x) {num2str(x)}, [1:Dim]);
		intv	=	get(G.intv,{'string','value'});	% ������ ���� ����
%		Intv	=	str2double(intv{1}(intv{2}));
		if 0<src,Intv=str2double(intv{1}(intv{2})); else,Intv=G.glIntv; end
		if isempty(Intv), Intv = 1; end				% �ʱⰪ ����
		if any(Dim<Intv), Intv(~ismember(Intv,[1:Dim]))=[]; end %�ʰ�
					set(G.intv, 'max',length(sIntv), 'min',1);
					set(G.intv, 'string',sIntv);	% ���� ���
					set(G.intv, 'value', Intv);		% ���� ����
		else
					set(G.intv, 'string',{});		% 2������ ����!
					set(G.intv, 'value', []);		% ���� ����
		end	% if ~isempty
%		guidata(hF, G);								% ����
	end	% func

names = fieldnames(eeg);
numfield = length(names);
if numfield ~= 1 
    EEG = [];
    errordlg('The input is not a valid EEG MAT File');
    return;
end

field = char(names);

reqfields = {'nbchan','points','srate','labeltype','labels','data'};
fields = isfield(eeg.(field),reqfields);
if ~all(fields)
    idx = find(fields==0);
    missed = strcat(reqfields(idx));
    errordlg(['Miss fields:' missed]);
end
    
EEG = eeg.(field);
if ~isfield(EEG,'name') | isempty(EEG.name)
%    [pathstr, name, ext, versn] = fileparts(Fullfilename);
    [pathstr, name, ext] = fileparts(Fullfilename);
    EEG.name = name;
end

if ~isfield(EEG,'type') | isempty(EEG.type)
    EEG.type = 'EEG';
end

if isempty(EEG.nbchan)
    errordlg('Number of channles is empty!');
    return;
end

if isempty(EEG.points)
    errordlg('Number of points is empty!');
    return;
end

if isempty(EEG.srate)
    warndlg('Sampling rate is empty!');
    EEG.srate = 250;
end

if isempty(EEG.labeltype)
    errordlg('There is no label type!');
    return;
end

if isempty(EEG.labels)
    errordlg('There is no label!');
    return;
end

if isempty(EEG.data)
    errordlg('There is no data!');
    return;
end

if EEG.nbchan ~= length(EEG.labels) 
   errordlg('Number of labels is not right!'); 
   return;
end

sz = size(EEG.data);
if EEG.nbchan ~= sz(1) && EEG.nbchan ~= sz(2)
    errordlg('Data size is not roght!'); 
    return;
end

if EEG.nbchan == sz(2)
    EEG.data = EEG.data';
    sz(2) = sz(1);
end

if EEG.points ~= sz(2)
    errordlg('Data size is not right!'); 
    return;
end

if ~isfield(EEG,'start') | isempty(EEG.start)
    EEG.start = 1;
end

if ~isfield(EEG,'end') | isempty(EEG.end)
    EEG.end = EEG.points;
end

if ~isfield(EEG,'dispchans') | isempty(EEG.dispchans)
    EEG.dispchans = EEG.nbchan;
end

if ~isfield(EEG,'vidx')
    EEG.vidx = 1:EEG.nbchan;
end

if ~isfield(EEG,'bad')
    EEG.bad = [];
end

if ~isfield(EEG, 'unit')
    EEG.unit = 'uV';
end

if strcmp(EEG.labeltype, 'standard')% Generate standard label locations if the given labels are standard.
    if ~isfield(EEG,'locations')
        EEG.locations = stdLocations(EEG.labels);
        vidx = ~cellfun(@isempty, {EEG.locations(:).X});
        EEG.vidx = find(vidx==1);
    end
else % Read customized label locations if the given labels are not standard.
    if isfield(EEG,'locations') && length(EEG.locations) > 0
        if isfield(EEG.locations,'x')
            EEG.vidx = 1:EEG.nbchan; % has locations.
        else
            if isfield(EEG, 'marks') && length(EEG.marks) == 3
                if EEG.nbchan ~= length(EEG.locations)
                    errordlg('The number of locations is not right!');
                    return;
                end

                reqfields = {'X','Y','Z'};
                fields = isfield(EEG.locations,reqfields);
                if ~all(fields)
                    idx = find(fields==0);
                    missed = strcat(reqfields(idx));
                    errordlg(['Miss dimensions:' missed]);
                end
                cstmlocations(:,1) = cell2mat({EEG.locations(:).X});
                cstmlocations(:,2) = cell2mat({EEG.locations(:).Y});
                cstmlocations(:,3) = cell2mat({EEG.locations(:).Z});
                markedlocs = EEG.marks;

                EEG.locations = coRegistration(cstmlocations, markedlocs);
            else
                errordlg('Miss Marks for Location Co-registration.'); % customized labeltype with locations need marks for co-registration.
                return;
            end
        end
    else
        errordlg('Miss Customized-Channel-Locations information.'); % customized labeltype without locations not suported.
        return;
    end
end

vdata = EEG.data(EEG.vidx,:);
if ~isfield(EEG,'min') | isempty(EEG.min)
    EEG.min = min(min(vdata));
end

if ~isfield(EEG,'max') | isempty(EEG.max)
    EEG.max = max(max(vdata));
end

% ERP analysis
if isfield(EEG, 'event') && length(EEG.event) > 0    
    analysisevent = questdlg('Perform ERP analysis?','','Yes','Cancel','Cancel');
    if strcmp(analysisevent, 'Yes')
        EEG = erpanalysis(EEG);
    end
end

end	% function
