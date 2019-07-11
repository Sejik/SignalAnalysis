function [plv,pls]=tf2coh_min(TFc1,TFc2,K,iter)
%%%%%%%%%%%%%%%%%%%%%%%%
%  [PLV,PLS]=tf2coh(TFc1,TFc2,K,ITER)
% Usage:
%  >> [PLV,PLS]=tf2coh(TFc1,TFc2,K,ITER)
%
% Inputs:
%   TFc1: time freqency complex map at channel 1 (freq x time points x epochs)
%   TFc2: time freqency complex map at channel 2 (freq x time points x epochs)
%   K : numer of average for surrogation [default:200]
%   ITER: number of surrogation [default:200]
% Outputs:
%   PLV: phase locking value
%       [freq x time]
%   PLS: phase locking statistics
% 2007/10/04 
% by Hae-Jeong Park, Yonsei Univ. MoNET
% email: hjpark0@gmail.com
%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<3, K=200; end;
if nargin<4, iter=200; end;

[flen,tlen,numepoch]=size(TFc1);

tf=zeros(flen,tlen);
for e=1:numepoch,
    tf01=TFc1(:,:,e);
    tf02=TFc2(:,:,e);
    tf_=tf01.*conj(tf02);
    tf=tf+tf_./abs(tf_);
end;
tf=tf/numepoch;
plv=abs(tf);

if nargout<2,
    pls=[];
    return;
end;
    
cnt=zeros(flen,tlen);
for i=1:iter,
   %fprintf('iteration:%d ...\n',i);
    plvs=zeros(flen,tlen);
    for k=1:K,        
        ep=randperm(numepoch);
        tf=zeros(flen,tlen);
        for e=1:numepoch,
            tf01=TFc1(:,:,e);
            tf02=TFc2(:,:,ep(e));
            %tf02=TFc2(:,:,e);
            tf_=tf01.*conj(tf02);
            tf=tf+tf_./abs(tf_);
        end;
        tf=tf/numepoch;
        plvs=plvs+abs(tf);
    end;
    plvs=plvs/K;
    
    id=find(plvs>=plv);    
    cnt(id)=cnt(id)+1;    
end;
pls=cnt/iter;

