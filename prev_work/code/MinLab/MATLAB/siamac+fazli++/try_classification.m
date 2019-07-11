subdir_list= textread(['session_list'], '%s');
data_path = '/home/data/SSVEP_BKM/Mat/';

for sbj=1:length(subdir_list)

%load data of one subject:
[cnt,mrk,mnt] = eegfile_loadMatlab([data_path subdir_list{sbj}]); 

cnt.clab

epo=cntToEpo(cnt,mrk,[0 5000]);
spec=proc_spectrum(epo,[4 31],kaiser(cnt.fs,2));

loss_LDA(sbj)=xvalidation(spec,'LDA');
loss_RLDA(sbj)=xvalidation(spec,'RLDAshrink');

end
%LDA - accuracy   0.414        0.488         0.529
%RLDA - accuracy  0.49         0.502         0.636
