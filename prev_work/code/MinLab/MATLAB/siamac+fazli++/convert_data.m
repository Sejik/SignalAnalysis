subdir_list= textread(['session_list'], '%s');
data_path = '/home/data/SSVEP_BKM/Raw/';
save_path = '/home/data/SSVEP_BKM/Mat/';
grd= sprintf(['EOGv,_,scale,_,legend,_,EOGh\n' ...
              'F7,F3,_,Fz,_,F4,F8\n' ...
              'FC5,_,FC1,_,FC2,_,FC6\n' ...
              'T7,_,C3,Cz,C4,_,T8\n' ...
              'CP5,_,CP1,_,CP2,_,CP6\n' ...
              'P7,_,P3,Pz,P4,_,P8\n' ...
              '_,PO3,O1,Oz,O2,PO4,_']);

for vp= 1:length(subdir_list),

subdir= subdir_list{vp};
sbj= subdir(find(subdir=='_',1,'last')+1:end);

fprintf('** processing %s.\n', subdir);

file = subdir;
    hdr= eegfile_readBVheader([data_path file]);
try,
    hdr.impedances;
    remove_chan=find(hdr.impedances>40);
catch
    fprintf('impedances not recorded...\n');
    %continue;
end
Wps= [42 49]/hdr.fs*2;
[n, Ws]= cheb2ord(Wps(1), Wps(2), 3, 40);
[filt.b, filt.a]= cheby2(n, 50, Ws);

[cnt, mrk_orig]= eegfile_readBV([data_path file ], ... 
                                'fs',100, ...
                                'filt',filt);

try
    cnt=proc_removeChannels(cnt,remove_chan);
catch
    cnt=proc_removeChannels(cnt,'NULL');
    fprintf('no impedance info... \n')
end


classDef= {111,112,113,114,115,116; '1','2','3','4','5','6'};
mrk= mrk_defineClasses(mrk_orig, classDef);

mnt= getElectrodePositions(cnt.clab);
mnt= mnt_setGrid(mnt, grd);
var_list= {'fs_orig',hdr.fs, 'mrk_orig',mrk_orig, 'hdr',hdr};


save_name=[save_path subdir '.mat'];

eegfile_saveMatlab(save_name, cnt, mrk, mnt, ...
                'channelwise',1, ...
                'format','int16', ...
                'resolution', NaN, ...
                'vars',var_list);
end
