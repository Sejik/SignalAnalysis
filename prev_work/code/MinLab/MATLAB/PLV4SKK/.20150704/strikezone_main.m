%�� �����Ϳ� ���� coh�� ���Ѵ�.
% please load eEEG for each experiment and condition:
clear;clc;


%% Header %%
fullPATH	=	'x:/PLV_theta';
%phasePATH	=	'x:\SKK_theta_anterior_only\skk_phase';
%coh__PATH	=	'x:\SKK_theta_anterior_only\skk_coh';
dataname	=	{'Fav_USA', 'Neutral_Mexico', 'Unfav_Paki'};
trialname	=	{'dislike', 'like'};
subname		=	{'su02', 'su04', 'su07', 'su08', 'su09', 'su10', 'su12'};
%subname		=	{'su02', 'su04', 'su08', 'su10', 'su12'};
%fullPATH	=	'.';
%dataname	=	{'Fav_USA', 'Neutral_Mexico'};
%trialname	=	{'dislike', 'like'};
%subname		=	{'su04'};
data		=	[length(dataname)*length(trialname):3];  %[datanumb * trialnumb] * [f, t_start, t_fin]

%% phase ->[strike_zone]-> coh %%
for datanumb = 1:length(dataname)
    for trialnumb = 1:length(trialname)
        for subnumb = 1:length(subname)

			%���Ǹ� ���� ���ϸ��� ������ ��
			WORKNAME = [ char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) ];

%			cd 'x:\SKK_theta_anterior_only\skk_phase';			%phase�����Ͱ� ����� ��_���_���� ���� path
			%phase���Ͽ��� PLV, PLS�� �ε�
			eval(['load(''' fullPATH '/skk_phase30/' 'Phase_' WORKNAME '.mat'',''PLV'',''PLS'',''channame'',''selchanname'',''-mat'');']);

			fprintf('get the StrikeZone for %s\n', WORKNAME);
			[coh,f,t] = strikezone_tigoum(PLV, PLS);			%strike zone ���!

%			cd 'x:\SKK_theta_anterior_only\skk_coh';			%coh�����͸� ������ ��_���_���� ���� path
			%��ü ������ ����, coh, f, t �� ����
			save([fullPATH '/skk_coh/' 'Coh_' WORKNAME '.mat'], 'channame', 'selchanname', 'coh', 'f', 't', '-v7.3');
        end
    end
end
