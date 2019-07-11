function [ALFFBrain, Header] = alff(AllVolume,ASamplePeriod, HighCutoff, LowCutoff, AMaskFilename, AResultFilename, TemporalMask, ScrubbingMethod, Header, CUTNUMBER)
% Use ALFF method to compute the brain and return a ALFF brain map which reflects the "energy" of the voxels' BOLD signal
% Ref: Zang, Y.F., He, Y., Zhu, C.Z., Cao, Q.J., Sui, M.Q., Liang, M., Tian, L.X., Jiang, T.Z., Wang, Y.F., 2007. Altered baseline brain activity in children with ADHD revealed by resting-state functional MRI. Brain Dev 29, 83-91.
% FORMAT    [ALFFBrain, Header] = y_alff(AllVolume,ASamplePeriod, HighCutoff, LowCutoff, AMaskFilename, AResultFilename, TemporalMask, ScrubbingMethod, Header, CUTNUMBER)
% Input:
% 	AllVolume		-	4D data matrix (DimX*DimY*DimZ*DimTimePoints) or the directory of 3D image data file or the filename of one 4D data file
% 	ASamplePeriod		TR, or like the variable name
% 	LowCutoff			the low edge of the pass band
% 	HighCutoff			the High edge of the pass band
% 	AMaskFilename		the mask file name, I only compute the point within the mask
%	AResultFilename		the output filename
%   TemporalMask    -   Temporal mask for scrubbing (DimTimePoints*1)
%                   -   Empty (blank: '' or []) means do not need scrube. Then ScrubbingMethod can leave blank
%   ScrubbingMethod -   The methods for scrubbing.
%                       -1. 'cut': discarding the timepoints with TemporalMask == 0
%                       -2. 'nearest': interpolate the timepoints with TemporalMask == 0 by Nearest neighbor interpolation 
%                       -3. 'linear': interpolate the timepoints with TemporalMask == 0 by Linear interpolation
%                       -4. 'spline': interpolate the timepoints with TemporalMask == 0 by Cubic spline interpolation
%                       -5. 'pchip': interpolate the timepoints with TemporalMask == 0 by Piecewise cubic Hermite interpolation
%   Header          -   If AllVolume is given as a 4D Brain matrix, then Header should be designated.
%   CUTNUMBER           Cut the data into pieces if small RAM memory e.g. 4GB is available on PC. It can be set to 1 on server with big memory (e.g., 50GB).
%                       default: 10
% Output:
%	ALFFBrain       -   The ALFF results
%   Header          -   The NIfTI Header
%	AResultFilename	the filename of ALFF result
%-----------------------------------------------------------
%   Algorithm originally Written by Xiao-Wei Song (Dawnwei.Song@gmail.com).
%   Algorithm Re-Written by YAN Chao-Gan (ycg.yan@gmail.com) on 120328.
%   Note: the ALFF generated by the new version is sqrt(2/N) times of the
%   original version. (new version used: 2*abs(fft(x))/N; original version
%   used:  sqrt(2*abs(fft(x))^2/N)) 
%	http://restfmri.net 

if ~exist('CUTNUMBER','var')
    CUTNUMBER = 10;
end

theElapsedTime =cputime;

fprintf('\nComputing ALFF...');

if ~isnumeric(AllVolume)
    [AllVolume,VoxelSize,theImgFileList, Header] =rest_to4d(AllVolume);
end

[nDim1 nDim2 nDim3 nDimTimePoints]=size(AllVolume);
BrainSize = [nDim1 nDim2 nDim3];
VoxelSize = sqrt(sum(Header.mat(1:3,1:3).^2));

fprintf('\n\t Load mask "%s".', AMaskFilename);
MaskData = rest_loadmask(nDim1, nDim2, nDim3, AMaskFilename);
MaskData = logical(MaskData);

% Convert into 2D
AllVolume=reshape(AllVolume,[],nDimTimePoints)';

MaskDataOneDim=reshape(MaskData,1,[]);
AllVolume=AllVolume(:,find(MaskDataOneDim));

% Scrubbing
if exist('TemporalMask','var') && ~isempty(TemporalMask)
    if ~all(TemporalMask)
        fprintf('\n\t Scrubbing...');
        AllVolume = AllVolume(find(TemporalMask),:); %'cut'
        if ~strcmpi(ScrubbingMethod,'cut')
            xi=1:length(TemporalMask);
            x=xi(find(TemporalMask));
            AllVolume = interp1(x,AllVolume,xi,ScrubbingMethod);
        end
        nDimTimePoints = size(AllVolume,1);
    end
end


% Get the frequency index
sampleFreq 	 = 1/ASamplePeriod;
sampleLength = nDimTimePoints;
paddedLength = rest_nextpow2_one35(sampleLength); %2^nextpow2(sampleLength);
if (LowCutoff >= sampleFreq/2) % All high included
    idx_LowCutoff = paddedLength/2 + 1;
else % high cut off, such as freq > 0.01 Hz
    idx_LowCutoff = ceil(LowCutoff * paddedLength * ASamplePeriod + 1);
    % Change from round to ceil: idx_LowCutoff = round(LowCutoff *paddedLength *ASamplePeriod + 1);
end
if (HighCutoff>=sampleFreq/2)||(HighCutoff==0) % All low pass
    idx_HighCutoff = paddedLength/2 + 1;
else % Low pass, such as freq < 0.08 Hz
    idx_HighCutoff = fix(HighCutoff *paddedLength *ASamplePeriod + 1);
    % Change from round to fix: idx_HighCutoff	=round(HighCutoff *paddedLength *ASamplePeriod + 1);
end


% Detrend before fft as did in the previous alff.m
%AllVolume=detrend(AllVolume);
% Cut to be friendly with the RAM Memory
SegmentLength = ceil(size(AllVolume,2) / CUTNUMBER);
for iCut=1:CUTNUMBER
    if iCut~=CUTNUMBER
        Segment = (iCut-1)*SegmentLength+1 : iCut*SegmentLength;
    else
        Segment = (iCut-1)*SegmentLength+1 : size(AllVolume,2);
    end
    AllVolume(:,Segment) = detrend(AllVolume(:,Segment));
end


% Zero Padding
AllVolume = [AllVolume;zeros(paddedLength -sampleLength,size(AllVolume,2))]; %padded with zero

fprintf('\n\t Performing FFT ...');
%AllVolume = 2*abs(fft(AllVolume))/sampleLength;
% Cut to be friendly with the RAM Memory
SegmentLength = ceil(size(AllVolume,2) / CUTNUMBER);
for iCut=1:CUTNUMBER
    if iCut~=CUTNUMBER
        Segment = (iCut-1)*SegmentLength+1 : iCut*SegmentLength;
    else
        Segment = (iCut-1)*SegmentLength+1 : size(AllVolume,2);
    end
    AllVolume(:,Segment) = 2*abs(fft(AllVolume(:,Segment)))/sampleLength;
    fprintf('.');
end


ALFF_2D = mean(AllVolume(idx_LowCutoff:idx_HighCutoff,:));

% Get the 3D brain back
ALFFBrain = zeros(size(MaskDataOneDim));
ALFFBrain(1,find(MaskDataOneDim)) = ALFF_2D;
ALFFBrain = reshape(ALFFBrain,nDim1, nDim2, nDim3);


Header.pinfo = [1;0;0];
Header.dt    =[16,0];

%Save ALFF image to disk
fprintf('\n\t Saving ALFF map.\tWait...');
rest_writefile(single(ALFFBrain), ...
    AResultFilename, ...
    BrainSize,VoxelSize,Header, 'single');

theElapsedTime = cputime - theElapsedTime;
fprintf('\n\t ALFF compution over, elapsed time: %g seconds.\n', theElapsedTime);

