load '/home/minlab/Projects/SKK/SKK_3/GRD/Com_F__L.mat'

mLib_TIMEplotTopo_AmH({ERP_F__L ERP_U__D}, [-500:2:1500-1], '/home2/minlab/Tools/MATLAB/EEG_30chan.ced', {'F__L' 'U__D'}, [90], [-300 800], '', [ -2 2 ])

mLib_TIMEplotTopo_AmH(ERP_F__L, [-500:2:1500-1], '/home2/minlab/Tools/MATLAB/EEG_30chan.ced', {'F__L'}, [90], [-300 800], 'Cz', [ -2 2 ])

mLib_TFplotTopo_AmH(TFe_bl, [1/4:1/4:70], [-500:2:1500-1], [5 6 7], [-200 100 300], '/home/minlab/Tools/MATLAB/EEG_30chan.ced', 'FAHD', [5 30], [-300 800], 'Cz')

load('/home/minlab/Projects/SKK/SKK_3/TF/SKK_su01_FAHD.mat')

mLib_TFplotTopo_AmH(TFe_bl, [1/4:1/4:70], [-500:2:1500-1], [5 NaN 6 7], [-200 NaN 100 300], '/home/minlab/Tools/MATLAB/EEG_30chan.ced', 'FAHD', [5 30], [-300 800], 'Cz', [-1.5 1.5], 0.9)

mLib_TFplotTopo_AmH(TFe_bl, [1/4:1/4:70], [-500:2:1500-1], [5 NaN 6 7], [-200 250 100 300], '/home/minlab/Tools/MATLAB/EEG_30chan.ced', 'FAHD', [5 30], [-300 800], 'Cz')

mLib_TFplotTopo_AmH(TFe_bl, [1/4:1/4:70], [-500:2:1500-1], [5 NaN 6.5 7], [-200 250 inf 300], '/home/minlab/Tools/MATLAB/EEG_30chan.ced', 'FAHD', [5 30], [-300 800], 'Cz')

mLib_TFplotTopo_AmH(TFe_bl, [1/4:1/4:70], [-500:2:1500-1], [5 NaN 6.75 7], [-200 250 inf 300], '/home/minlab/Tools/MATLAB/EEG_30chan.ced', 'FAHD', [5 30], [-300 800], 'Cz')

mLib_TFplotTopo_AmH(TFe_bl, [1/4:1/4:70], [-500:2:1500-1], [5 NaN inf 7], [-200 250 272 300], '/home/minlab/Tools/MATLAB/EEG_30chan.ced', 'FAHD', [5 30], [-300 800], 'Cz')

mLib_TFplotTopo_AmH(TFe_bl, [1/4:1/4:70], [-500:2:1500-1], [5 NaN inf 7], [-200 250 inf 300], '/home/minlab/Tools/MATLAB/EEG_30chan.ced', 'FAHD', [5 30], [-300 800], 'Cz')

