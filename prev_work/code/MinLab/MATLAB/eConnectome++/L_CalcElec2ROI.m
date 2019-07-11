function [ ROIdata ]	=	L_Elct2ROI( electrodesV, vertices, model, options )
	% compute map for sensor space
%	sensor.data(ix -StartTp +1)	=							...
%	sensordata(ix)	=	...
%		{ griddata(model.X, model.Y, electrodesV, model.XI, model.YI,'v4') };
	%% 20160315A. CAUTION: ix�� StartTp(~=1)�� ���� -> sensor �մ� ����ȭ
	% ����, ���� �����͸� ���� -> source.data �� ���ؼ��� ��������!!!

	% compute sources on cortex
	if options.autocorner		%-[
		% 20160320A. l_curve() performance is depended by figure env!
		% time delay without	figure open : about 5.65 sec
		% time delay WITH		figure open : about 0.13 sec
		% performance ratio is awesome 43.4615 times!
		tempfg		=	figure;						% IMPORTANT for speed!
		lamda		=	l_curve(model.U,model.s,electrodesV,'tikh');
		close(tempfg);
%			if single(options.lamda) ~= single(lamda)
%				fprintf('\nERROR : lamda(%f) vs org(%f)\n', lamda,options.lamda);
%			end
	else
		lamda		=	options.lamda;
	end		%-]

	%% compute sources on cortex
	cortexVI		=	[];	% -[
	if isequal(options.method,'mn')
		cortexVI	=	tikhonov(model.U,model.s,model.V,electrodesV,lamda);
	elseif isequal(options.method,'wmn')
		cortexVI	=	tikhonov(model.U,model.s,model.V,electrodesV,lamda);
		cortexVI	=	cortexVI ./ model.W';
	end
	if options.currymatrix == 1
		cortexVI(length(cortexVI)+1:options.cortexnumverts)	=	0;
	end	%-]
	%% ����������� source 20516 voxel �����ʹ� ��� ������ ����
	% ������ loop�� �� voxel ���� smooth ó������

	%% 20160318B. ������, ����� source (0.068073��) ����,
	%%						�ϱ��� smooth (0.266356��) �� �� ����!

	% get smooth values on finer colin cortex
	%% 20160318C. trying to ROI's voxel only rather than all voxel
	% ��, �ϱ��� loop�� �� voxel ���� �����ϴ� ���̹Ƿ�, ROI �� ���ؼ���
	% ����ϸ� �� �ӵ� ���� ����!
	% get smooth values on finer colin cortex FOR [compute ROI time series]
	nROI			=	length(vertices);			% ROI �������� Ȯ��
%	roidata			=	zeros(nROI, 1);
	roidata			=	zeros(nROI, 1);
	for	jx			=	1:nROI						% �� ROI �� ����
		ixRV		=	vertices{jx};

		ROIvts		=	zeros(length(ixRV), 1);
		for kx		=	1:length(ixRV)				% 1 ROI �����ϴ� �� voxel
			rx		=	ixRV(kx);
			values	=	cortexVI(model.neighbors.neighbors.idx{rx});%�迭����
			weight	=	model.neighbors.neighbors.weight{rx};

%			ROIvts(kx)	=	sum(weight .* values);	% sum() == scalar
			ROIvts(kx)	=	weight' * values;
		end
		%% 20160316A sum(weight .* values) ��Һ� �� & ��ü �� -> ��İ� ��ü
		% ���� ��� �������̰� ���� ����, ������� double �϶� �ٸ�!
		%	-> single �϶��� ����. ���κҸ�Ȯ
		roidata(jx)	=	mean(ROIvts);				% �� ROI ���� activity
	end
	ROIdata			=	{roidata};

	return

