function mnt= mnt_restrictMontage(mnt, varargin)
%MNT_RESTRICTMONTAGE - Restrict an electrode montage to a subset of channels.
%
%Synposis:
% mnt= mnt_restrictMontage(MNT, CHANS);
% mnt= mnt_restrictMontage(MNT, DAT);
%
%Input:
% MNT:   display montage, see setElectrodeMontage, setDisplayMontage
% CHANS: channels, format as accepted by util_chanind
% DAT:   structure which has a field 'clab', such as cnt, epo, ...
%
%Output:
% MNT:   updated display montage
%
%Example:
% [cnt, mrk, mnt]= loadProcessedEEG('Gabriel_00_09_05/selfpaced2sGabriel');
% cnt_lap= proc_laplace(cnt);
% mnt= mnt_restrictMontage(mnt, cnt_lap);
% plotScalpPattern(mnt, cnt_lap.x(10000,:));

if nargin==2 && isstruct(varargin{1}),
  if isfield(varargin{1}, 'clab'),
    chans= util_chanind(mnt.clab, varargin{1}.clab);
  else
    error('field .clab expected when 2nd argument is a struct');
  end
else
  chans= util_chanind(mnt.clab, varargin{:});
end
off= setdiff(1:length(mnt.clab), chans,'legacy');

mnt.x(off)= [];
mnt.y(off)= [];
mnt.clab(off)= [];

% Nirs specific
if isfield(mnt,'dist')
  mnt.dist(off)=[];
end
if isfield(mnt,'sd')
  mnt.sd(off,:) = [];
end

% box
if isfield(mnt, 'box'),
  mnt.box(:,off)= [];
  mnt.box_sz(:,off)= [];
end

if isfield(mnt, 'pos_3d'),
  mnt.pos_3d(:,off)= [];
end
