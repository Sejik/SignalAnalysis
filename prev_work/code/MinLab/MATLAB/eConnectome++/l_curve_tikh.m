			lamda		=	l_curve2(model.U,model.s,electrodesV, 'tikh');
			cortexVI	=	tikhonov(U, s, V, electrodesV, lamda);

function [reg_corner,RHO,ETA,REGPARAM] = l_curve(U,sm,b,method,L,V)
%L_CURVE Plot the L-curve and find its "corner".
%
% [reg_corner,RHO,ETA,REGPARAM] =
%                  l_curve(U,s,b,method)
%                  l_curve(U,sm,b,method)  ,  sm = [sigma,mu]
%                  l_curve(U,s,b,method,L,V)
%
% Plots the L-shaped curve of ETA, the solution norm || x || or
% semi-norm || L x ||, as a function of RHO, the residual norm
% || A x - b ||, for the following methods:
%    method = 'Tikh'  : Tikhonov regularization   (solid line )
%    method = 'tsvd'  : truncated SVD or GSVD     (o markers  )
%    method = 'dsvd'  : damped SVD or GSVD        (dotted line)
%    method = 'mtsvd' : modified TSVD             (x markers  )
% The corresponding reg. parameters are returned in REGPARAM.  If no
% method is specified then 'Tikh' is default.  For other methods use plot_lc.
%
% Note that 'Tikh', 'tsvd' and 'dsvd' require either U and s (standard-
% form regularization) computed by the function csvd, or U and sm (general-
% form regularization) computed by the function cgsvd, while 'mtvsd'
% requires U and s as well as L and V computed by the function csvd.
%
% If any output arguments are specified, then the corner of the L-curve
% is identified and the corresponding reg. parameter reg_corner is
% returned.  Use routine l_corner if an upper bound on ETA is required.

% Reference: P. C. Hansen & D. P. O'Leary, "The use of the L-curve in
% the regularization of discrete ill-posed problems",  SIAM J. Sci.
% Comput. 14 (1993), pp. 1487-1503.

% Per Christian Hansen, DTU Compute, October 27, 2010.

% Set defaults.
if (nargin==3), method='Tikh'; end  % Tikhonov reg. is default.
npoints = 200;  % Number of points on the L-curve for Tikh and dsvd.
smin_ratio = 16*eps;  % Smallest regularization parameter.

% Initialization.
[m,n] = size(U); [p,ps] = size(sm);
if (nargout > 0), locate = 1; else locate = 0; end
beta = U'*b; beta2 = norm(b)^2 - norm(beta)^2;
if (ps==1)
  s = sm; beta = beta(1:p);
else
  s = sm(p:-1:1,1)./sm(p:-1:1,2); beta = beta(p:-1:1);
end
xi = beta(1:p)./s;
xi( isinf(xi) ) = 0;

if (strncmp(method,'Tikh',4) | strncmp(method,'tikh',4))
	ETA			=	zeros(npoints,1); RHO = ETA; REGPARAM = ETA; s2 = s.^2;
	REGPARAM(npoints)	=	max([s(p),s(1)*smin_ratio]);
	ratio		=	(s(1)/REGPARAM(npoints))^(1/(npoints-1));
%{
	for i=npoints-1:-1:1, REGPARAM(i) = ratio*REGPARAM(i+1); end
	for i=1:npoints
		f = s2./(s2 + REGPARAM(i)^2);
		ETA(i) = norm(f.*xi);
		RHO(i) = norm((1-f).*beta(1:p));
	end
%}
	%% 20160628A. 원본 코드(위) 보다 수정 코드(아래) 가 3배 가량 더 빠름
	REGPARAM	=	REGPARAM(end) .* ( ratio .^ [npoints-1:-1:0] );
	xi			=	repmat(xi, 1, length(REGPARAM));
	beta		=	repmat(beta, 1, length(REGPARAM));
	s2			=	repmat(s2, 1, length(REGPARAM));	% expand col->row
	reg_param2	=	repmat(REGPARAM.^2, size(s2,1),1);	% expand row->col
	f			=	s2 ./ (s2 + reg_param2);
	fxi			=	f .* xi;
	fbeta		=	(1-f) .* beta(1:p, :);
	ETA			=	sqrt(sum(abs(fxi  ).^2,1))';	%# The two-norm of each col
	RHO			=	sqrt(sum(abs(fbeta).^2,1))';	%# The two-norm of each col
%pNorm = sum(abs(M).^p,1).^(1/p); %# The p-norm of each column (define p first)
%infNorm = max(M,[],1);           %# The infinity norm (max value) of each column

	if (m > n & beta2 > 0), RHO = sqrt(RHO.^2 + beta2); end
	marker = '-'; txt = 'Tikh.';
%{
elseif (strncmp(method,'tsvd',4) | strncmp(method,'tgsv',4))	% -[

  ETA = zeros(p,1); RHO = ETA;
  ETA(1) = abs(xi(1))^2;
  for k=2:p, ETA(k) = ETA(k-1) + abs(xi(k))^2; end
  ETA = sqrt(ETA);
  if (m > n)
    if (beta2 > 0), RHO(p) = beta2; else RHO(p) = eps^2; end
  else
    RHO(p) = eps^2;
  end
  for k=p-1:-1:1, RHO(k) = RHO(k+1) + abs(beta(k+1))^2; end
  RHO = sqrt(RHO);
  REGPARAM = (1:p)'; marker = 'o';
  if (ps==1)
    U = U(:,1:p); txt = 'TSVD';
  else
    U = U(:,1:p); txt = 'TGSVD';
  end

elseif (strncmp(method,'dsvd',4) | strncmp(method,'dgsv',4))

  ETA = zeros(npoints,1); RHO = ETA; REGPARAM = ETA;
  REGPARAM(npoints) = max([s(p),s(1)*smin_ratio]);
  ratio = (s(1)/REGPARAM(npoints))^(1/(npoints-1));
  for i=npoints-1:-1:1, REGPARAM(i) = ratio*REGPARAM(i+1); end
  for i=1:npoints
    f = s./(s + REGPARAM(i));
    ETA(i) = norm(f.*xi);
    RHO(i) = norm((1-f).*beta(1:p));
  end
  if (m > n & beta2 > 0), RHO = sqrt(RHO.^2 + beta2); end
  marker = ':';
  if (ps==1), txt = 'DSVD'; else txt = 'DGSVD'; end

elseif (strncmp(method,'mtsv',4))

  if (nargin~=6)
    error('The matrices L and V must also be specified')
  end
  [p,n] = size(L); RHO = zeros(p,1); ETA = RHO;
  [Q,R] = qr(L*V(:,n:-1:n-p),0);
  for i=1:p
    k = n-p+i;
    Lxk = L*V(:,1:k)*xi(1:k);
    zk = R(1:n-k,1:n-k)\(Q(:,1:n-k)'*Lxk); zk = zk(n-k:-1:1);
    ETA(i) = norm(Q(:,n-k+1:p)'*Lxk);
    if (i < p)
      RHO(i) = norm(beta(k+1:n) + s(k+1:n).*zk);
    else
      RHO(i) = eps;
    end
  end
  if (m > n & beta2 > 0), RHO = sqrt(RHO.^2 + beta2); end
  REGPARAM = (n-p+1:n)'; txt = 'MTSVD';
  U = U(:,REGPARAM); sm = sm(REGPARAM);
  marker = 'x'; ps = 2;  % General form regularization.		% -]
%}
else
  error('Illegal method')
end

% Locate the "corner" of the L-curve, if required.
if ~locate, return; end

function [reg_corner,RHO,ETA,REGPARAM] = l_curve(U,sm,b,method,L,V)
[reg_corner,rho_c,eta_c] = l_corner2(RHO,ETA,REGPARAM,		U,sm,b,method);
function [reg_c,rho_c,eta_c] = l_corner(RHO,ETA,REGPARAM,U,s,b,method,M)
%L_CORNER Locate the "corner" of the L-curve.
%
% [reg_c,rho_c,eta_c] =
%        l_corner(RHO,ETA,REGPARAM)
%        l_corner(RHO,ETA,REGPARAM,U,s,b,method,M)
%        l_corner(RHO,ETA,REGPARAM,U,sm,b,method,M) ,  sm = [sigma,mu]
%
% Locates the "corner" of the L-curve in log-log scale.
%
% It is assumed that corresponding values of || A x - b ||, || L x ||,
% and the regularization parameter are stored in the arrays RHO, ETA,
% and REGPARAM, respectively (such as the output from routine l_curve).
%
% If nargin = 3, then no particular method is assumed, and if
% nargin = 2 then it is issumed that REGPARAM = 1:length(RHO).
%
% If nargin >= 6, then the following methods are allowed:
%    method = 'Tikh'  : Tikhonov regularization
%    method = 'tsvd'  : truncated SVD or GSVD
%    method = 'dsvd'  : damped SVD or GSVD
%    method = 'mtsvd' : modified TSVD,
% and if no method is specified, 'Tikh' is default.  If the Spline Toolbox
% is not available, then only 'Tikh' and 'dsvd' can be used.
%
% An eighth argument M specifies an upper bound for ETA, below which
% the corner should be found.

% Per Christian Hansen, DTU Compute, January 31, 2015.

% Ensure that RHO and ETA are column vectors.
RHO = RHO(:); ETA = ETA(:);

% Set default regularization method.
%%if (nargin <= 3)
%%  method = 'none';
%%  if (nargin==2), REGPARAM = (1:length(RHO))'; end
%%else
%%  if (nargin==6), method = 'Tikh'; end
%%end

% Set this logical variable to 1 (true) if the corner algorithm
% should always be used, even if the Spline Toolbox is available.
alwayscorner = 0;

% Set threshold for skipping very small singular values in the
% analysis of a discrete L-curve.
s_thr = eps;  % Neglect singular values less than s_thr.

% Set default parameters for treatment of discrete L-curve.
deg   = 2;  % Degree of local smooting polynomial.
q     = 2;  % Half-width of local smoothing interval.
order = 4;  % Order of fitting 2-D spline curve.

% Initialization.
if (length(RHO) < order)
  error('Too few data points for L-curve analysis')
end
if (nargin > 3)
  [p,ps] = size(s); [m,n] = size(U);
  beta = U'*b; b0 = b - U*beta;
  if (ps==2)
    s = s(p:-1:1,1)./s(p:-1:1,2);
    beta = beta(p:-1:1);
  end
  xi = beta./s;
  if (m>n)  % Take of the least-squares residual.
      beta = [beta;norm(b0)];
  end
end

% Restrict the analysis of the L-curve according to M (if specified).
if (nargin==8)
  index = find(ETA < M);
  RHO = RHO(index); ETA = ETA(index); REGPARAM = REGPARAM(index);
end

if (strncmp(method,'Tikh',4) || strncmp(method,'tikh',4))

  % The L-curve is differentiable; computation of curvature in
  % log-log scale is easy.

  % Compute g = - curvature of L-curve.
  g = lcfun2(REGPARAM,s,beta,xi);

  % Locate the corner.  If the curvature is negative everywhere,
  % then define the leftmost point of the L-curve as the corner.
  [~,gi] = min(g);
  reg_c = fminbnd('lcfun2',...
    REGPARAM(min(gi+1,length(g))),REGPARAM(max(gi-1,1)),...
    optimset('Display','off'),s,beta,xi); % Minimizer.
  kappa_max = - lcfun2(reg_c,s,beta,xi); % Maximum curvature.

  if (kappa_max < 0)
    lr = length(RHO);
    reg_c = REGPARAM(lr); rho_c = RHO(lr); eta_c = ETA(lr);
  else
    f = (s.^2)./(s.^2 + reg_c^2);
    eta_c = norm(f.*xi);
    rho_c = norm((1-f).*beta(1:length(f)));
    if (m>n), rho_c = sqrt(rho_c^2 + norm(b0)^2); end
  end
%{
elseif (strncmp(method,'tsvd',4) || strncmp(method,'tgsv',4) || ...		%-[
        strncmp(method,'mtsv',4) || strncmp(method,'none',4))

  % Use the adaptive pruning algorithm to find the corner, if the
  % Spline Toolbox is not available.
  if ~exist('splines','dir') || alwayscorner
    %error('The Spline Toolbox in not available so l_corner cannot be used')
    reg_c = corner(RHO,ETA);
    rho_c = RHO(reg_c);
    eta_c = ETA(reg_c);
    return
  end

  % Otherwise use local smoothing followed by fitting a 2-D spline curve
  % to the smoothed discrete L-curve. Restrict the analysis of the L-curve
  % according to s_thr.
  if (nargin > 3)
    if (nargin==8)       % In case the bound M is in action.
      s = s(index,:);
    end
    index = find(s > s_thr);
    RHO = RHO(index); ETA = ETA(index); REGPARAM = REGPARAM(index);
  end

  % Convert to logarithms.
  lr = length(RHO);
  lrho = log(RHO); leta = log(ETA); slrho = lrho; sleta = leta;

  % For all interior points k = q+1:length(RHO)-q-1 on the discrete
  % L-curve, perform local smoothing with a polynomial of degree deg
  % to the points k-q:k+q.
  v = (-q:q)'; A = zeros(2*q+1,deg+1); A(:,1) = ones(length(v),1);
  for j = 2:deg+1, A(:,j) = A(:,j-1).*v; end
  for k = q+1:lr-q-1
    cr = A\lrho(k+v); slrho(k) = cr(1);
    ce = A\leta(k+v); sleta(k) = ce(1);
  end

  % Fit a 2-D spline curve to the smoothed discrete L-curve.
  sp = spmak((1:lr+order),[slrho';sleta']);
  pp = ppbrk(sp2pp(sp),[4,lr+1]);

  % Extract abscissa and ordinate splines and differentiate them.
  % Compute as many function values as default in spleval.
  P     = spleval(pp);  dpp   = fnder(pp);
  D     = spleval(dpp); ddpp  = fnder(pp,2);
  DD    = spleval(ddpp);
  ppx   = P(1,:);       ppy   = P(2,:);
  dppx  = D(1,:);       dppy  = D(2,:);
  ddppx = DD(1,:);      ddppy = DD(2,:);

  % Compute the corner of the discretized .spline curve via max. curvature.
  % No need to refine this corner, since the final regularization
  % parameter is discrete anyway.
  % Define curvature = 0 where both dppx and dppy are zero.
  k1    = dppx.*ddppy - ddppx.*dppy;
  k2    = (dppx.^2 + dppy.^2).^(1.5);
  I_nz  = find(k2 ~= 0);
  kappa = zeros(1,length(dppx));
  kappa(I_nz) = -k1(I_nz)./k2(I_nz);
  [kmax,ikmax] = max(kappa);
  x_corner = ppx(ikmax); y_corner = ppy(ikmax);

  % Locate the point on the discrete L-curve which is closest to the
  % corner of the spline curve.  Prefer a point below and to the
  % left of the corner.  If the curvature is negative everywhere,
  % then define the leftmost point of the L-curve as the corner.
  if (kmax < 0)
    reg_c = REGPARAM(lr); rho_c = RHO(lr); eta_c = ETA(lr);
  else
    index = find(lrho < x_corner & leta < y_corner);
    if ~isempty(index)
      [~,rpi] = min((lrho(index)-x_corner).^2 + (leta(index)-y_corner).^2);
      rpi = index(rpi);
    else
      [~,rpi] = min((lrho-x_corner).^2 + (leta-y_corner).^2);
    end
    reg_c = REGPARAM(rpi); rho_c = RHO(rpi); eta_c = ETA(rpi);
  end

elseif (strncmp(method,'dsvd',4) || strncmp(method,'dgsv',4))

  % The L-curve is differentiable; computation of curvature in
  % log-log scale is easy.

  % Compute g = - curvature of L-curve.
  g = lcfun2(REGPARAM,s,beta,xi,1);

  % Locate the corner.  If the curvature is negative everywhere,
  % then define the leftmost point of the L-curve as the corner.
  [~,gi] = min(g);
  reg_c = fminbnd('lcfun2',...
    REGPARAM(min(gi+1,length(g))),REGPARAM(max(gi-1,1)),...
    optimset('Display','off'),s,beta,xi,1); % Minimizer.
  kappa_max = - lcfun2(reg_c,s,beta,xi,1); % Maximum curvature.

  if (kappa_max < 0)
    lr = length(RHO);
    reg_c = REGPARAM(lr); rho_c = RHO(lr); eta_c = ETA(lr);
  else
    f = s./(s + reg_c);
    eta_c = norm(f.*xi);
    rho_c = norm((1-f).*beta(1:length(f)));
    if (m>n), rho_c = sqrt(rho_c^2 + norm(b0)^2); end
  end	%-]
%}
else
  error('Illegal method')
end



function [x_lambda,RHO,ETA] = tikhonov(U,s,V,b,lambda,x_0)
%TIKHONOV Tikhonov regularization.
%
% [x_lambda,RHO,ETA] = tikhonov(U,s,V,b,lambda,x_0)
% [x_lambda,RHO,ETA] = tikhonov(U,sm,X,b,lambda,x_0) ,  sm = [sigma,mu]
%
% Computes the Tikhonov regularized solution x_lambda, given the SVD or
% GSVD as computed via csvd or cgsvd, respectively.  If the SVD is used,
% i.e. if U, s, and V are specified, then standard-form regularization
% is applied:
%    min { || A x - b ||^2 + lambda^2 || x - x_0 ||^2 } .
% If, on the other hand, the GSVD is used, i.e. if U, sm, and X are
% specified, then general-form regularization is applied:
%    min { || A x - b ||^2 + lambda^2 || L (x - x_0) ||^2 } .
%
% If an initial estimate x_0 is not specified, then x_0 = 0 is used.
%
% Note that x_0 cannot be used if A is underdetermined and L ~= I.
%
% If lambda is a vector, then x_lambda is a matrix such that
%    x_lambda = [ x_lambda(1), x_lambda(2), ... ] .
%
% The solution norm (standard-form case) or seminorm (general-form
% case) and the residual norm are returned in ETA and RHO.

% Per Christian Hansen, DTU Compute, April 14, 2003.

% Reference: A. N. Tikhonov & V. Y. Arsenin, "Solutions of Ill-Posed
% Problems", Wiley, 1977.

% Initialization.
if (min(lambda)<0)
  error('Illegal regularization parameter lambda')
end
m = size(U,1);
n = size(V,1);
[p,ps] = size(s);
beta = U(:,1:p)'*b;
zeta = s(:,1).*beta;
ll = length(lambda); x_lambda = zeros(n,ll);
RHO = zeros(ll,1); ETA = zeros(ll,1);

% Treat each lambda separately.
if (ps==1)

  % The standard-form case.
  if (nargin==6), omega = V'*x_0; end
  for i=1:ll
    if (nargin==5)
      x_lambda(:,i) = V(:,1:p)*(zeta./(s.^2 + lambda(i)^2));
      RHO(i) = lambda(i)^2*norm(beta./(s.^2 + lambda(i)^2));
    else
      x_lambda(:,i) = V(:,1:p)*...
        ((zeta + lambda(i)^2*omega)./(s.^2 + lambda(i)^2));
      RHO(i) = lambda(i)^2*norm((beta - s.*omega)./(s.^2 + lambda(i)^2));
    end
    ETA(i) = norm(x_lambda(:,i));
  end
  if (nargout > 1 & size(U,1) > p)
    RHO = sqrt(RHO.^2 + norm(b - U(:,1:n)*[beta;U(:,p+1:n)'*b])^2);
  end

elseif (m>=n)

  % The overdetermined or square general-form case.
  gamma2 = (s(:,1)./s(:,2)).^2;
  if (nargin==6), omega = V\x_0; omega = omega(1:p); end
  if (p==n)
    x0 = zeros(n,1);
  else
    x0 = V(:,p+1:n)*U(:,p+1:n)'*b;
  end
  for i=1:ll
    if (nargin==5)
      xi = zeta./(s(:,1).^2 + lambda(i)^2*s(:,2).^2);
      x_lambda(:,i) = V(:,1:p)*xi + x0;
      RHO(i) = lambda(i)^2*norm(beta./(gamma2 + lambda(i)^2));
    else
      xi = (zeta + lambda(i)^2*(s(:,2).^2).*omega)./...
           (s(:,1).^2 + lambda(i)^2*s(:,2).^2);
      x_lambda(:,i) = V(:,1:p)*xi + x0;
      RHO(i) = lambda(i)^2*norm((beta - s(:,1).*omega)./...
               (gamma2 + lambda(i)^2));
    end
    ETA(i) = norm(s(:,2).*xi);
  end
  if (nargout > 1 & size(U,1) > p)
    RHO = sqrt(RHO.^2 + norm(b - U(:,1:n)*[beta;U(:,p+1:n)'*b])^2);
  end

else

  % The underdetermined general-form case.
  gamma2 = (s(:,1)./s(:,2)).^2;
  if (nargin==6), error('x_0 not allowed'), end
  if (p==m)
    x0 = zeros(n,1);
  else
    x0 = V(:,p+1:m)*U(:,p+1:m)'*b;
  end
  for i=1:ll
    xi = zeta./(s(:,1).^2 + lambda(i)^2*s(:,2).^2);
    x_lambda(:,i) = V(:,1:p)*xi + x0;
    RHO(i) = lambda(i)^2*norm(beta./(gamma2 + lambda(i)^2));
    ETA(i) = norm(s(:,2).*xi);
  end

end
