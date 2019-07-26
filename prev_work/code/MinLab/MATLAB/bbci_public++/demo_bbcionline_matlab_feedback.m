% BBCI DEMO - Testing Matlab feedback using random signals.
%% edited by tigoum, from 20160131
%
%  The demo shows, how a Matlab-based feedback can be tested in simulated
%  online mode. As a source of signals, a random signal generator is used
%  (acquire fcn 'bbci_acquire_randomSignals').
%  For this demo, the data processing does not matter. Here, we define
%  a very simple processing chain with a random clasifiers.

nChan		=	30;
%clab			=	{'C3','Cz','C4', 'CP3','CPz','CP4'};
if nChan + 2 == 32					% 30 + EOG + NULL
	clab	={	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
elseif nChan + 1 == 64				% 63 + EOG
	clab	={	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',	'FCz',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',  'PO10',...
				'AF7',	'AF3',	'AF4',	'AF8',	'F5',	'F1',	'F2',	'F6', ...
				'FT9',	'FT7',	'FC3',	'FC4',	'FT8',	'FT10',	'C5',	'C1', ...
				'C2',	'C6',	'TP7',	'CP3',	'CPz',	'CP4',	'TP8',	'P5', ...
				'P1',	'P2',	'P6',	'PO7',	'PO3',	'POz',	'PO4',	'PO8' };
end
% ----------
C				=	struct('b', 0);
C.w				=	randn(length(clab), 1);

% Setting parameter for bbci
bbci						=	struct;

% setup the calibration
%{
Online Use of the BBCI Toolbox from a User's Perspective

For the 'user' of the BBCI online system, essentially two operations are required: calibration of the system and online application of the system. These operations are performed by the functions bbci_calibration and bbci_apply respectively. After calibration, the calibrated system can be saved via bbci_save (advisable, but not required). Here is a simple (but complete) example, how the system can be calibrated and started in online operation:
%}
%{
% Define in 'bbci' the type of calibration and calibration specific parameters:-[
bbci= struct('calibrate');
bbci.calibrate.fcn= @bbci_calibrate_csp;
bbci.calibrate.settings.classes= {'left', 'right'};

% Run calibration:
[bbci, data]= bbci_calibrate(bbci);

% Optionally specify in 'bbci' application specific parameters:
bbci.feedback.receiver= 'matlab';
bbci.feedback.fcn= @bbci_feedback_cursor;
bbci.feedback.opt= struct('trials_per_run', 80);

% Saving the classifier is not necessary for operation, but advisable.
% Optinally feature vectors and figures of the calibration can be saved.
bbci_save(bbci, data);

% Start online operation of the BBCI system:
%%[bbci, data]= bbci_apply(bbci);
% This simple scripts makes some assumptions on the data, e.g., that the markers for the two conditions left and right are 1 and 2.	%-]
%}
% Specify how signals are acquired:
if 0
bbci.source.acquire_fcn		=	@bbci_acquire_randomSignals;
bbci.source.acquire_param	=	{'clab',clab, 'realtime',2};
else
%{
params			=	struct;
params.host		=	'163.152.26.95';	% BrainVision Recoder's IP
state			=	bbci_acquire_bv('init', params);	% �ʱ�ȭ
[data]			=	bbci_acquire_bv(state);				% data capture
%whos data
%}
bbci_acquire_bv('close')
bbci.source.acquire_fcn		=	@bbci_acquire_bv;		% capture from BV recoder
bbci.source.acquire_param	=	{struct('fs',500, 'host','163.152.26.95')};
end

% Modify aspects of data processing:
bbci.feature.proc			=	{@proc_variance, @proc_logarithm};
bbci.feature.ival			=	[-4000 0];				% full time [-6000 3000]
														% ������ [-2000 7000]
														% ���������� ���������� 0
bbci.classifier.C			=	C;
bbci.quit_condition.marker	=	255;					% �ߴܿ� ��Ŀ !!!

% Specify the feedback application and its parameters:
bbci.feedback.receiver		=	'matlab';
bbci.feedback.fcn			=	@bbci_feedback_cursor;
bbci.feedback.opt			=	...
	struct('trigger_classes_list', {{'left','right'}},	...
		'countdown', 3000,								...
		'trials_per_run', 6,							...
		'geometry', [0 0 640 480]);	% response�� display�ϴ� ȭ��: �ݵ�� ����!
%bbci.feedback.fcn			=	@bbci_feedback_robotics;	% robot���� ���� �߹�
%bbci.feedback.opt			=	struct( ... );

% Specify how feedback log stored:
bbci.feedback.log.output	=	'file';
bbci.feedback.log.folder	=	BTB.TmpDir;

% ?how is this supposed to stop?
try
%data			=	bbci_apply_uni(bbci);
data			=	bbci_apply(bbci);
% Of course, bbci_apply would do the very same.
catch	Exception
%	Exception.identifier: ''
	if strcmp(Exception.message, 'bbci_acquire_bv: close the connection first!')
					bbci_acquire_bv('close');				% ���� ����
%data			=	bbci_apply_uni(bbci);					% �� ����
data			=	bbci_apply(bbci);

	else
		fprintf('Warning : %s\n', Exception.message);
	end
%	Exception.cause: {0x1 cell}
%	Exception.stack: [3x1 struct]
end

pause(1); close;

% Replay in fast forward:
fprintf('Now doing a replay of that feedback from the logfile.\n'); pause(2);
bbci_fbutil_replay(data.feedback.log.filename);
%bbci_fbutil_replay(data.feedback.log.filename, 'realtime',0);
