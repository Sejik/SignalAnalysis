%각 데이터에 대한 coh를 구한다.
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

			%편의를 위해 파일명을 구성해 둠
			WORKNAME = [ char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) ];

%			cd 'x:\SKK_theta_anterior_only\skk_phase';			%phase데이터가 저장된 랩_백업_서버 상의 path
			%phase파일에서 PLV, PLS만 로딩
			eval(['load(''' fullPATH '/skk_phase30/' 'Phase_' WORKNAME '.mat'',''PLV'',''PLS'',''channame'',''selchanname'',''-mat'');']);

			fprintf('get the StrikeZone for %s\n', WORKNAME);
			[coh,f,t] = strikezone_tigoum(PLV, PLS);			%strike zone 계산!

%			cd 'x:\SKK_theta_anterior_only\skk_coh';			%coh데이터를 저장할 랩_백업_서버 상의 path
			%전체 데이터 말고, coh, f, t 만 저장
			save([fullPATH '/skk_coh/' 'Coh_' WORKNAME '.mat'], 'channame', 'selchanname', 'coh', 'f', 't', '-v7.3');
        end
    end
end
