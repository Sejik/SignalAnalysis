
clear;
channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={'Fav_USA', 'Neutral_Mexico', 'Unfav_Paki'};
trialname={'dislike', 'like'};
subname={'su02', 'su04', 'su07', 'su08', 'su09', 'su10', 'su12', 'su14', 'su16', 'su18', 'su19', 'su20', 'su21', 'su22', 'su25', 'su26', 'su27', 'su28', 'su29'};

%% Subjects_All Epochs_bl
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
            eval(['DataBuf = importdata(''EXP_NEW_' char(subname{subnumb}) '_BaselineCorrection_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '.dat'');']);
            % DataBuf�� data��� �κ��� B�� �ٽ� ����.
            B=DataBuf.data;
            
            % Wavelet�� ����� �� ������ Ÿ���� �׻� (timepoint x epochs x channels) ��
            % ���°� �Ǿ�� �մϴ�. ���� B�� ����Ǿ� �ִ� ������ Ÿ���� (��ü ������ x channels) �̳�
            % (channels x ��ü ������) �� �����Դϴ�. �̸� �츮�� ����ϴ� ���·� �߶��ֱ� ���� �Ʒ��� reshape ���
            % �Լ��� ����մϴ�. ���� ���� B�� ���°� (��ü ������ x channels) ��� �ٷ� reshape��
            % ���ָ� ������, (channels x ��ü ������) �� ���¶�� ��ġ�� �������Ѿ� �ϹǷ� �Ʒ� �ڵ带
            % �߰��Ͻø� �˴ϴ�. �м��Ͻ� �� �׻� Ȯ���ϼž��� �κ��Դϴ�.
            
            % B=shiftdim(B, 1);
            
            eEEG=reshape(B, 1050, [], 32); % eEEG(timepoint x epochs x channels). 
            clear B DataBuf
            % �����Ͱ� �ڼ��̴� ���� �����ϰ� �޸� �뷮�� ���� ���ؼ�, �̹� ����� ���� variable���� clear
            % �� �����ִ� ���� �����ϴ�. 
            
            eEEG(:,:,17)=NaN;    % EOG�� �м��� ������� �ʱ� ������ Not a Number�� ����.
            eEEG(:,:,22)=NaN;    % NULL�� ��������.
            
            % ������ ó���� eEEG�� mat���Ϸ� ����.
            eval(['FILENAME=''exp_new_' char(subname{subnumb}) '_BaselineCorrection_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) ''';']);
            save(FILENAME, 'eEEG');
            clear eEEG
        end
    end
end

