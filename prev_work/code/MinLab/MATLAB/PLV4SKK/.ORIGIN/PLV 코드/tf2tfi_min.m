function [TFi,TFP,TFA]=tf2tfi_min(TF,EPOCHUSE)
if nargin<2, EPOCHUSE=[]; end;

TFP=TF.*conj(TF); %power, ³ªÁß¿¡ total activity, 
TFA=atan2(imag(TF),real(TF));%anglue 
%%
TFi=squeeze(sum(TFP,3));
% TFi=squeeze(mean(TFP,3));
%%
if isempty(EPOCHUSE),
    nch=size(TF,4);
    nuse=size(TF,3)*ones(1,nch);
else
    nuse=sum(EPOCHUSE);
end;

%% 1 when line 7 (not line 8) activated
for i=1:size(TFi,3),
    TFi(:,:,i)=TFi(:,:,i)/nuse(i);
end;
%%