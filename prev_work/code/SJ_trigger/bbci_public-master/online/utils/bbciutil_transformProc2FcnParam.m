function S= bbciutil_transformProc2FcnParam(S)
%TRANSFORMPROC2FCNPARAM - Transform 'proc' field to fcn/param fields
%
%This function just transforms the way a sequence of processing steps
%is given. This is best exmplained by an example:
% S.proc=  {{'proc_baseline', [-200 0]}, ...
%           {'proc_jumpingMeans', 5, 10}};
% T.fcn= {'proc_baseline', 'proc_jumpingMeans'}
% T.param= {{[-200 0]}, {5, 10}};
%The 'proc' representation is more intuitive for definition, but the
%fcn/param representation is better for performance. There the representation
%is transform initially in bbci_apply.
%
%Synopsis:
%  T= bbciutil_transformProc2FcnParam(S)
%
%Arguments:
%  S - Structure which has the proc
%
%Output:
%  T - Updated structure

% 02-2011 Benjamin Blankertz


if ~isfield(S, 'proc'),
  for k= 1:length(S),
    if (~isfield(S,'param') || isempty(S(k).param)) && ...
          isfield(S(k), 'fcn') && ~isempty(S(k).fcn),
      S(k).param= repmat({{}}, [1 length(S(k).fcn)]);
    end
  end
  return;
end

for k= 1:length(S),
  if isfield(S(k),'fcn') && ~isempty(S(k).fcn),
%    warning('struct has already nonempty field fcn');
    continue;
  end
  nProcs= length(S(k).proc);
  S(k).fcn= cell(1, nProcs);
  S(k).param= cell(1, nProcs);
  for p= 1:nProcs,
    [S(k).fcn{p}, S(k).param{p}]= misc_getFuncParam(S(k).proc{p});
  end
end
S= rmfield(S, 'proc');
