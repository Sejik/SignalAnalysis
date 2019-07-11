function mnt= mnt_adaptMontage(mnt, varargin)
%MNT_ADAPTMONTAGE - Adapts an electrode montage to another electrode set
%
%Synposis:
% mnt= mnt_adaptMontage(MNT, CLAB);
% mnt= mnt_adaptMontage(MNT, DAT);
%
%Input:
% MNT:   display montage, see setElectrodeMontage, setDisplayMontage
% CLAB:  channels, format as accepted by util_chanind
% DAT:   a data struct which has a field clab with format as above
%
%Output:
% MNT:   updated display montage
%
%Example:% 
% file= 'Gabriel_00_09_05/selfpaced2sGabriel';
% [cnt,mrk,mnt]= loadProcessedEEG(file);
% epo= makeEpochs(cnt, mrk, [-1500 500]);
% epo= proc_baseline(epo, [-1500 -1300]);
% ep= proc_selectChannels(epo, {'C3-4', 'FC3-4'});
% mt= mnt_adaptMontage(mnt, ep);
% %% now mt fits to ep, just as mnt to epo

chans= util_chanind(mnt.clab, varargin{:});

if isfield(mnt, 'x'),
  mnt.x = mnt.x(chans);
  mnt.y = mnt.y(chans);
end
if isfield(mnt, 'box'),
  if size(mnt.box,2)>length(mnt.clab),
    mnt.box = mnt.box(:,[chans end]);
    mnt.box_sz = mnt.box_sz(:,[chans end]);
  else
    mnt.box = mnt.box(:,chans);
    mnt.box_sz = mnt.box_sz(:,chans);
  end
end
mnt.clab= mnt.clab(chans);

if isfield(mnt, 'pos_3d'),
  mnt.pos_3d = mnt.pos_3d(:,chans);
end
