function ERP=epoch2erp_min(eEEG,thr,prestimsampleidx)
% Usage:
%  >> [ERP,USE,X]=epoch2erp(eEEG,fsamp,thr,prestim);
% Inputs:
%   eEEG        = epoched EEG data (time points x epochs x channels)
%   fsamp       = data sampling rate (Hz)
%   thr         = threshold uV to reject
%   prestimsampleidx     = prestim index for baseline correction, [1:500] for example
%
% Outputs:
%    ERP        = event related potential
%    EPOCHUSE        = epochs used for the analysis. if USE(epoch,channel)==0,
%               it was rejected else it was included in the ERP averaging
%    X          = filtered EEG with frequency band (1.5~20 Hz)
%                 Rejected epochs will be filled with zeros
% Author: Hae-Jeong Park, 2007, Yonsei Univ., MoNET

% Copyright (C) 11-13-2007, Hae-Jeong Park, parkhj@yuhs.ac
if nargin<2, thr=70; end; %70uV
if nargin<3, prestimsampleidx=[]; end;
corr_baseline=1;

if length(prestimsampleidx)==2, prestimsampleidx=prestimsampleidx(1):prestimsampleidx(2); end;

nume=size(eEEG,2);
dim=length(size(eEEG));
if dim==2, chn=1; 
else chn=size(eEEG,3); 
end;

X=zeros(size(eEEG));

for c=1:chn,
    idx=[]; ridx=[];
    fprintf('ch:%d of %d...\n',c,chn);
    for e=1:nume,
        x=eEEG(:,e,c);
        id=find(x>thr | x<-thr);
            if ~isempty(id),
                ridx=[ridx e];
                continue;
            end;
        end;            
        X(:,e,c)=x;
        idx=[idx e];
    end;
    erp=mean(X(:,idx,c),2);   
       
        if corr_baseline,
            erp_bl=erp-mean(erp(prestimsampleidx));    
        end;
        ERP(:,c)=erp_bl;


