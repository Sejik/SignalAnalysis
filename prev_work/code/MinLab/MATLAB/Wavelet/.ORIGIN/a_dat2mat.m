%% dat2mat.m %%
% Analyzer���� export�� dat���ϵ��� matlab���� ����ϴ� mat���Ϸ� ��ȯ�ϴ� �ڵ�

%% �ڵ� �����ϱ� �� �޸𸮸� ���� ��Ʈ���� �����ִ� �˾�â���� �ݴ� ����
clear;
close all

%% Header %%
% ���� �ϳ��� ���̴� ��� �ڵ忡 �����ϰ� ����/���̱� �س��� ���� ���մϴ�.
%
% channame: 1�� ���� 32�� ���� ���� ��ȣ�� �°� ä���̸� ����. �м��� ���������� �ʿ������� ������ ����ϴ� �����Ͱ�
% ��� ä�ο��� �Դ��� Ȯ���ϰų� ���÷����� �� ���� �˴ϴ�.
%
% dataname, trialname: ���� �з����ӿ� ���� �˸°� ���������� �ٲ��ָ� �˴ϴ�.
%
% subname: ������ ����Ʈ. Outlier�� ���� ��� �� ����Ʈ������ ���ָ� �˴ϴ�.

channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={'like', 'dislike'};
trialname={'Fav_USA', 'Neutral_Mexico', 'Unfav_paki'};
subname={'su02', 'su04'};

%% All Epochs %%
% Average ���� ���� ��ü Epoch�� ���� Analyzer ������(.dat ����)�� ��Ʈ������ ���� ���� .mat ���Ϸ�
% ��ȯ�ϴ� �κ�.

% �Ʒ��� for������ ������, ���� ���ǵ ���� �ݺ������� �ڵ带 ���ư��� �ϴ� loop�� �Դϴ�.
for subnumb= 1:length(subname)
    for datanumb= 1:length(dataname)
        for trialnumb=1:length(trialname)
            %%% �Ʒ��� 'eval' �Լ��� �ſ� �߿��մϴ�. %%%
            % �����ڳ� ���� ���� ���� �ٲٸ鼭 ��� ���� �ڵ带 �����ϰ� ���� �� ����ϴ� �Լ��Դϴ�.
            % for�� �ȿ��� ������ ����� variable �� ����� ��쿡�� �Ϲ����� �ڵ�, ���� ���
            %
            % ex1) A=1+1;
            % ex2) A=max(B);
            %
            % ���� ���� �׳� for�� �ȿ� �־ ����ϼŵ� ������, for���� �� �� ���� �ٸ� ���� �ҷ����̰ų� �ٸ�
            % ���� ����� ��쿡�� �ڵ忡 �޶����� �κе��� �������ּž� �մϴ�.
            %
            % ���� ��, comment �ٷ� �Ʒ� �ڵ忡 �ִ� eval �Լ��� ��ȣ �ȿ� �� �ִ� �ڵ�� �����δ�
            % DataBuf = importdata(''exp_su00XX_BaselineCorrection_trialname�ϳ�_dataname�ϳ�.dat'');
            % �Դϴ�. '.dat'������ matlab���� �Ϲ����� 'load'�Լ��δ� �ҷ��� �� ���� ������
            % 'importdata' ��� �Լ��� �� �� �Դϴ�.
            % �츮�� �׻� ���� dat������ �ҷ����̴� ���� �ƴ϶� ������ ������ �� ���� ����(trialname, dataname)��
            % �ٸ� dat������ �ҷ����̴� ���̱� ������, for���� ���鼭 �ٸ� subname, trialname,
            % dataname ���� �ҷ� ���̵��� eval �Լ��� �����س��� ���Դϴ�.
            % �ڵ带 ������ �ϴµ� ������ �߿��� �Լ��̰� ���� ���� �ڵ忡�� ���� ���̴� �Լ� �̹Ƿ�, ��� ����Ǵ�
            % ������ Ȯ���ϰ� �˾Ƶδ� ���� ���� �� �����ϴ�. �ڼ��� ������ help �� google ���� �̿��غ��ø�
            % ���� �� �����ϴ�.
            
            % dat������ import�ؼ� DataBuf�� ����.
            cd a;
            eval(['DataBuf = importdata(''skk_' char(subname{subnumb}) '_BaselineCorrection_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '.dat'');']);
            cd ..;
            % DataBuf�� data��� �κ��� B�� �ٽ� ����.
            B=DataBuf.data;
            
            % Wavelet�� ����� �� ������ Ÿ���� �׻� (timepoint x epochs x channels) ��
            % ���°� �Ǿ�� �մϴ�. ���� B�� ����Ǿ� �ִ� ������ Ÿ���� (��ü ������ x channels) �̳�
            % (channels x ��ü ������) �� �����Դϴ�. �̸� �츮�� ����ϴ� ���·� �߶��ֱ� ���� �Ʒ��� reshape ���
            % �Լ��� ����մϴ�. ���� ���� B�� ���°� (��ü ������ x channels) ��� �ٷ� reshape��
            % ���ָ� ������, (channels x ��ü ������) �� ���¶�� ��ġ�� �������Ѿ� �ϹǷ� �Ʒ� �ڵ带
            % �߰��Ͻø� �˴ϴ�. �м��Ͻ� �� �׻� Ȯ���ϼž��� �κ��Դϴ�.
            s =size(B);
            if s(1) == 32
                B=shiftdim(B, 1);
            end;
            
            eEEG=reshape(B, 1000, [], 32); % eEEG(timepoint x epochs x channels). 
            clear B DataBuf s;
            % �����Ͱ� �ڼ��̴� ���� �����ϰ� �޸� �뷮�� ���� ���ؼ�, �̹� ����� ���� variable���� clear
            % �� �����ִ� ���� �����ϴ�. 
            
            eEEG(:,:,17)=NaN;    % EOG�� �м��� ������� �ʱ� ������ Not a Number�� ����.
            eEEG(:,:,22)=NaN;    % NULL�� ��������.
            
            % ������ ó���� eEEG�� mat���Ϸ� ����.
            eval(['FILENAME=''skk_' char(subname{subnumb}) '_BaselineCorrection_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) ''';']);
            cd save;
            save(FILENAME, 'eEEG');
            clear eEEG
            cd ..;
        end
    end
end

%% Average
% �� �������� ��ü Epoch���� Average�� Analyzer ������(.dat ����), �� ERP �����͸� ��Ʈ������ ���� ���� .mat ���Ϸ�
% ��ȯ�ϴ� �κ�.

for subnumb= 1:length(subname)
    for datanumb= 1:length(dataname)
        for trialnumb=1:length(trialname)
        
            eval(['DataBuf = importdata(''skk_' char(subname{subnumb}) '_Average_BaselineCorrection_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '.dat'');']);
            ERP_bl=DataBuf.data;
            clear DataBuf
            
            % Average �� �������̹Ƿ� epoch �κ��� ����, ���⼭ import�� �����ʹ� 2�����Դϴ�. ������ ���������� (channels x timepoint) �� ���¶�� ��ġ�� �������Ѿ� �ϹǷ� �Ʒ� �ڵ带
            % �߰��Ͻø� �˴ϴ�. �м��Ͻ� �� �׻� Ȯ���ϼž��� �κ��Դϴ�.
            
            
            s =size(ERP_bl);
            if s(1) == 32
                B=shiftdim(ERP_bl, 1));
            end;
                                    
            ERP_bl(:,17)=NaN;    % EOG�� �м��� ������� �ʱ� ������ Not a Number�� ����.
            ERP_bl(:,22)=NaN;    % NULL�� ��������.
            
            % ERP_bl �� mat���Ϸ� ����.
            eval(['FILENAME=''skk_' char(subname{subnumb}) '_Average_BaselineCorrection_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) ''';']);
            cd save;
            save(FILENAME, 'ERP_bl');
            clear ERP_bl s;
            cd ..;
        end
    end
end