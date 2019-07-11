%% Header %%
dataname={'Fav_USA', 'Neutral_Mexico', 'Unfav_Paki'};
trialname={'dislike', 'like'};
subname={'su02', 'su04', 'su07', 'su08', 'su09', 'su10', 'su12', 'su14', 'su16', 'su18', 'su19', 'su20', 'su21', 'su22', 'su25', 'su26', 'su27', 'su28', 'su29'};


chs=[1:16];

for datanumb= 1:length(dataname)
    for trialnumb=1:length(trialname)
        for subnumb= 1:length(subname)
            cd skk_tf;
            eval(['load(''TF_' char(dataname{datanumb})  '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '.mat'');']);
            
            TF_origin1=TF_origin;
            ERP1=ERP;
            TFi1=TFi;
            TFe_bl1=TFe_bl;

            clear  TF_origin  ERP  TFi  TFe_bl

            eval(['load TF_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '_2.mat']);

            TF_origin2=TF_origin;
            ERP2=ERP;
            TFi2=TFi;
            TFe_bl2=TFe_bl;

            clear  TF_origin  ERP  TFi  TFe_bl
            cd ..;
            
            ERP = [ERP1, ERP2];
            
            TFe_bl = TFe_bl1;
            TFi = TFi1;
            TF_origin = TF_origin1;
            
            for k=1:16;
                TFe_bl(:,:,16+k)=TFe_bl2(:,:,k);
                TFi(:,:,16+k)=TFi2(:,:,k);
                TF_origin(:,:,:,16+k)=TF_origin2(:,:,:,k);
            end
            cd skk_combine;
            FILENAME = ['TF_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb})]; 
            save(FILENAME, 'TF_origin', 'ERP', 'TFi', 'TFe_bl');
            cd ..;
            clearvars -except dataname datanumb trialname trialnumb subname subnumb chs
            clc
            
         end
    end
end