%%Contents
%
%Present a drifting gabor patch with cogent
%first check if a data file of the same name already exists
%seed random number generator
%load movie matrix
%computed constants
%start cogent
%make fixation sprites
%create each movie frame in a separate sprite
%block loop
%Present a drifting gabor patch with cogent
%
%%drift speed discrimination task, or adaptation task Elliot Freeman 0207

p.dataFile				=	'speedDiscrimData';	% name of file to save data into
p.condition				=	1;					% use this to identify the type of block
p.gam					=	2.2;				% p.gamma value from calibration procedure
p.contrast				=	.5;					% p.contrast of gabor patch
p.windowmode			=	0;					% 0: small window; 1: full screen
p.horizontalResolution	=	1024;				% horizontal screen resolution in pixels: select from [640 800 1024 1152 1280 1600]
p.imageFile				=	'gaborMovie';		% filename of image matrix
p.RGB					=	[1 1 1];			% maximum luminance of horizontalResolution guns (before scaling by overall p.contrast)
p.contrast				=	1;					% overall p.contrast of images
p.refreshRate			=	75;					% refresh rate of screen in hertz
p.trialDuration			=	100;				% duration of each stimulus presentation (ms)
p.ISI					=	500;				% inter stimulus interval (ms)
p.fixPos				=	[0 0];				% X and Y position of stimulus
p.stimPos				=	[0 100];			% X and Y position of stimulus
p.fixSize				=	5;					% size of fixation point
p.nTrial				=	10;					% number of trials
p.escapeKey				=	52;					% code for escape key
p.responseKeys			=	[97 98];			% codes for left and right-arrow keys
p.baseLineStimulus		=	5;					% speed of non-target stimulus (how many times movie is played per second)
p.minMaxLevels			=	[5 20];				% minimum and maximum increment to use in target
p.nLevels				=	5;					% number of levels of stimulus increments
p.nBlocks				=	1;					% number of blocks
p.magnification			=	2;					% scale to magnify stimulus

%%first check if a data file of the same name already exists
%first add .mat suffix to datafile name if missing

dataFile = p.dataFile;
%[PATHSTR,NAME,EXT,VERSN] = fileparts(dataFile);
[PATHSTR,NAME,EXT] = fileparts(dataFile);
if isempty(EXT)
	dataFile = [dataFile '.mat'];
end
if exist(dataFile, 'file')						% choice of saving a new file, overwriting or aborting
	button = questdlg('Data file already exists. What to do?', '', 'Append', 'Overwrite', 'Save New', 'Append');
	switch button
	case 'Overwrite'
		drawnow;								% this makes dialogue box go away
	case 'Save New'
		[filename, pathname] = uiputfile('*.mat', 'Save data as');  % select new datafile
		p.dataFile = fullfile(pathname, filename);
		drawnow;
	case 'Append'
		load dataFile;
		drawnow;
	otherwise break;
	end
end
%Error: A BREAK statement appeared outside of a loop. Use RETURN instead.

%%seed random number generator

rand('state',sum(100*clock));

%%load movie matrix

load(p.imageFile, 'im');						% load movie matrix
[sX sY nFrames] = size(im);						% get dimensions and number of frames

%%computed constants

bg = .5 .^ (1/p.gam);							% calculate p.gamma corrected mid-gray background value
stimValues = linspace( p.minMaxLevels(1), p.minMaxLevels(2), p.nLevels);   % how much each level modulates baseline stimulus value

%%start cogent

resVal = [640 800 1024 1152 1280 1600];			% possible screen resolutions
resCode = find(p.horizontalResolution == resVal);	% select one
config_display(p.windowmode,resCode,[bg bg bg], [1 1 1]); % configure graphics window
config_keyboard;								% set up keyboard
start_cogent;									% start cogent

%%make fixation sprites

fixSprite = 1000;
cgMakeSprite(fixSprite, p.fixSize, p.fixSize, bg, bg, bg);		% make a new sprite
cgSetSprite(fixSprite);
cgEllipse(p.fixPos(1), p.fixPos(2), p.fixSize, p.fixSize, [1 1 1], 'f');
fixSprite = 1000;
cgMakeSprite(fixSprite+1, p.fixSize, p.fixSize, bg, bg, bg);	% make a new sprite
cgSetSprite(fixSprite+1);
cgEllipse(p.fixPos(1), p.fixPos(2), p.fixSize, p.fixSize, [0 0 0], 'f');
cgSetSprite(0);

%%create each movie frame in a separate sprite

for iFrame = 1:nFrames							% loop through frames
	imF = im(:,:,iFrame);						% extract frame from movie matrix

	% To load the images into sprites, Cogent needs a three column matrix:
	% each column contains the luminance values for Red Green and Blue
	% respectively. To make this matrix,
	% (1) transpose each image frame (explanation below) and
	% (2) scale each column by the appropriate values of RGB to manipulate
	% the colour of the resulting image

	imR = imF' * p.RGB(1);						% vector for red guns
	imG = imF' * p.RGB(2);						% vector for green guns
	imB = imF' * p.RGB(3);						% vector for blue guns

	% (3) now squash each R G or B image into a single column vector
	% (4) and horizontally concatenate into three column matrix
	imRGB = [imR(:) imG(:) imB(:)];				% now compile in to three-column matrix

	% finally apply overall contrast scaling, recenter values on 0.5, gamma correct
	imRGB0 = imRGB .* p.contrast;				% apply contrast modulation to whole matrix
	imRGB1 = ( imRGB0 +1 ) /2;					% convert values of -1->1 to 0->1 (gray is now .5)
	imRGB_gamma = imRGB1 .^ ( 1/ p.gam );		% apply p.gamma correction to image

	% make a new sprite and put image into it
	cgMakeSprite(iFrame, sX, sY, bg, bg, bg);	% make a new sprite
	cgloadarray(iFrame, sX,sY,imRGB_gamma);		% load image frame into sprite
end

%%block loop

% initialize variables
abortFlag = 0;									% reset flag for aborting experiment
trialData = [];									% clear record of trial data

for iblock = 1: p.nBlocks

	%% wait for any key (escape to quit)
	cgflip(bg, bg, bg);							% blank screen
	cgtext(sprintf('Block %d', iblock), 0,100);
	cgflip(bg, bg, bg);							% blank screen
	[ keyout, t, n ] = waitkeydown(inf);		% wait forever for a key to be preset
	if keyout == p.escapeKey || abortFlag		% if the key was 'escape' or the abortFlag was set
		break									% jump to end of experiment where data can be saved
	end

	%% random sequence of stimulus modulations
	stimLevels0 = repmat(1:p.nLevels, 1, ceil(p.nTrial / p.nLevels)); % every level gets repeated the same number of times
	randomIndices = randperm(length(stimLevels0));	%  randomly permuted vector of indices
	stimLevels = stimLevels0(randomIndices);	% use random vector to reorder levels

	%% trial sequence
	for iTrial = 1: p.nTrial
		targetInterval = round(rand(1)) + 1;	% which interval has the target? random binary choice: 1 or 2 (first or second)

		%% put up fixation
		cgflip(bg, bg, bg);
		cgDrawSprite(fixSprite, p.fixPos(1), p.fixPos(2));	% put spot in fixation position
		cgDrawSprite(fixSprite, p.stimPos(1), p.stimPos(2));% also a placeholder for the stimulus location
		cgflip(bg, bg, bg);

		wait(500);								% delay before trial

		% two interval forced-choice procedure: target and non-target
		% intervals in unpredictable order; subject has to choose which
		% contained the target.
		for iInterval = 1:2						% interval loop
			if iInterval == targetInterval		% in the target interval...
				thisStimValue = stimValues(stimLevels(iInterval));	% pick current target value
			else								% in the non-target interval...
				thisStimValue = p.baseLineStimulus;		% set to baseline value
			end

			%% work out how fast to play movie
			framesPerSecond = (thisStimValue) * nFrames;	% how many frames shown per second
			frameIncrement = framesPerSecond / p.refreshRate;% how much to increment frame count every screen refresh

			%% display movie
			wait(p.ISI);
			iFrame = 0;
			t0 = time;
			while time < (t0 + p.trialDuration)
				iFrame = iFrame + frameIncrement;
				mFrame = mod(iFrame-1, nFrames)+1;
				cgDrawSprite(mFrame, p.stimPos(1), p.stimPos(2), sX * p.magnification, sY * p.magnification);
				cgDrawSprite(fixSprite, p.fixPos(1), p.fixPos(2));
				cgflip(bg, bg, bg);
			end

			cgDrawSprite(fixSprite, p.fixPos(1), p.fixPos(2));	% white fixation spot between intervals
			cgflip(bg, bg, bg);
		end

		%% collect responses
		cgDrawSprite(fixSprite+1, p.fixPos(1), p.fixPos(2));	% black fixation dot to prompt response
		cgflip(bg, bg, bg);
		clearkeys;								% clear keyboard buffer of any previous entries
		[ keyout, rt, n ] = waitkeydown(inf, [p.responseKeys p.escapeKey]);	% wait forever for one of the response keys to be preset
		if any(keyout == p.escapeKey)			% abort sequence
			abortFlag = 1;						% when we exit trial loop, block loop is still active. Pass back abortFlag to quit block loop
			break;								% exit trial loop
		end
		whichKey = find(keyout(1) == p.responseKeys);	% check whether the first keypress was the left or right-arrow key
		correct = (whichKey == targetInterval);			% check if subject correctly chose target interval (1=correct)
		trialData(iTrial,:) = [thisStimValue targetInterval whichKey correct rt]; % compile results for this trial
		disp(trialData(iTrial,:));						% display result on console
	end % trial loop

	%% compile results into structure and save
	[z,tm]=dos('time /T');	[z,d]=dos('date /T');

	data.time = [d tm];							% timestamp
	data.trialData = trialData;					% record of trial stimulus and response
	data.condition = p.condition				% condition code
	results(end + 1).data = data;				% append data structure to results structure
	results(end + 1).params = p;				% append parameters to results structure too
	save(p.dataFile, 'results');				% save results to disk

end % block loop
stop_cogent

%%Published with MATLAB¢ç 7.1
