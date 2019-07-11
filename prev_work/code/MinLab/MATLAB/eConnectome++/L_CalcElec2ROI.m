function [ ROIdata ]	=	L_Elct2ROI( electrodesV, vertices, model, options )
	% compute map for sensor space
%	sensor.data(ix -StartTp +1)	=							...
%	sensordata(ix)	=	...
%		{ griddata(model.X, model.Y, electrodesV, model.XI, model.YI,'v4') };
	%% 20160315A. CAUTION: ix가 StartTp(~=1)서 시작 -> sensor 앞단 공백화
	% 따라서, 실제 데이터만 저장 -> source.data 에 대해서도 마찬가지!!!

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
	%% 현재시점에서 source 20516 voxel 데이터는 모두 구해진 상태
	% 이하의 loop는 각 voxel 별로 smooth 처리수행

	%% 20160318B. 조사결과, 상기의 source (0.068073초) 보다,
	%%						하기의 smooth (0.266356초) 가 더 느림!

	% get smooth values on finer colin cortex
	%% 20160318C. trying to ROI's voxel only rather than all voxel
	% 즉, 하기의 loop는 각 voxel 별로 연산하는 것이므로, ROI 에 대해서만
	% 계산하면 더 속도 개선 가능!
	% get smooth values on finer colin cortex FOR [compute ROI time series]
	nROI			=	length(vertices);			% ROI 갯수정보 확보
%	roidata			=	zeros(nROI, 1);
	roidata			=	zeros(nROI, 1);
	for	jx			=	1:nROI						% 각 ROI 별 수행
		ixRV		=	vertices{jx};

		ROIvts		=	zeros(length(ixRV), 1);
		for kx		=	1:length(ixRV)				% 1 ROI 구성하는 각 voxel
			rx		=	ixRV(kx);
			values	=	cortexVI(model.neighbors.neighbors.idx{rx});%배열리턴
			weight	=	model.neighbors.neighbors.weight{rx};

%			ROIvts(kx)	=	sum(weight .* values);	% sum() == scalar
			ROIvts(kx)	=	weight' * values;
		end
		%% 20160316A sum(weight .* values) 요소별 곱 & 전체 합 -> 행렬곱 대체
		% 조사 결과 성능차이가 거의 없고, 결과값이 double 일때 다름!
		%	-> single 일때는 같음. 원인불명확
		roidata(jx)	=	mean(ROIvts);				% 각 ROI 수준 activity
	end
	ROIdata			=	{roidata};

	return

