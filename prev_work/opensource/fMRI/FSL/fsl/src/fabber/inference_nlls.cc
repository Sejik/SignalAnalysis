/* inference_nlls.h - Non-Linear Least Squares class declarations

   Adrian Groves Michael Chappell, FMRIB Image Analysis Group

   Copyright (C) 2007 University of Oxford */

#include "inference_nlls.h"

void NLLSInferenceTechnique::Setup(ArgsType& args)
{
  Tracer_Plus tr("NLLSInferenceTechnique::Setup");
  model = FwdModel::NewFromName(args.Read("model"), args);
  assert( model->NumParams() > 0 );
  LOG_ERR("    Forward Model version:\n      " 
	  << model->ModelVersion() << endl);

  //determine whether NLLS is being run in isolation or as a pre-step for VB (alters what we do if result is ill conditioned)
  vbinit = args.ReadBool("vb-init");

  // option to load a 'posterior' which will allow the setting of intial parameter estmates for NLLS
  MVNDist* loadPosterior = new MVNDist( model->NumParams() );
  MVNDist* junk = new MVNDist( model->NumParams() );
  string filePosterior = args.ReadWithDefault("fwd-inital-posterior","modeldefault");
  model->HardcodedInitialDists(*junk, *loadPosterior);
  if (filePosterior != "modeldefault") loadPosterior->Load(filePosterior);

  //assert(initialFwdPosterior == NULL);
  initialFwdPosterior = loadPosterior;
  loadPosterior = NULL;

  lm = args.ReadBool("lm"); //determine whether we use L (default) or LM converengce

}

void NLLSInferenceTechnique::DoCalculations(const DataSet& allData)
{
  Tracer_Plus tr("NLLSInferenceTechnique::DoCalculations");
  //get data for this voxel
  const Matrix& data = allData.GetVoxelData();
  int Nvoxels = data.Ncols();
  int Nsamples = data.Nrows();
  if (data.Nrows() != model->NumOutputs())
    throw Invalid_option("Data length (" 
      + stringify(data.Nrows())
      + ") does not match model's output length ("
      + stringify(model->NumOutputs())
      + ")!");

  for (int voxel = 1; voxel <= Nvoxels; voxel++)
    {
      ColumnVector y=data.Column(voxel);
      
      LOG_ERR("  Voxel " << voxel << " of " << Nvoxels << endl);

      MVNDist fwdPosterior;
      LinearizedFwdModel linear(model);

      int Nparams = initialFwdPosterior->GetSize();
      fwdPosterior.SetSize(Nparams);
      IdentityMatrix I(Nparams);

      NLLSCF costfn(y, model);
      NonlinParam nlinpar(Nparams,NL_LM);

      if (!lm)
	{ nlinpar.SetGaussNewtonType(LM_L); }

      // set ics from 'posterior'
      ColumnVector nlinics = initialFwdPosterior->means;
      nlinpar.SetStartingEstimate(nlinics);
      nlinpar.LogPar( true);nlinpar.LogCF(true);
      
 
      try {
	NonlinOut status = nonlin(nlinpar,costfn);


	/*cout << "The solution is: " << nlinpar.Par() << endl;
	cout << "and this is the process " << endl;
	for (int i=0; i<nlinpar.CFHistory().size(); i++) {
	  cout << " cf: " << (nlinpar.CFHistory())[i] <<endl;
	}
	for (int i=0; i<nlinpar.ParHistory().size(); i++) {
	  cout << (nlinpar.ParHistory())[i] << ": :";
	  }*/

	fwdPosterior.means = nlinpar.Par();

	// recenter linearized model on new parameters
	linear.ReCentre( fwdPosterior.means );
	const Matrix& J = linear.Jacobian();
	// Calculate the NLLS covariance
	/* this is inv(J'*J)*mse?*/
	double sqerr = costfn.cf( fwdPosterior.means );
	double mse = sqerr/(Nsamples - Nparams);
	
	/*	Matrix Q = J;
	UpperTriangularMatrix R;
	QRZ(Q,R);
	Matrix Rinv = R.i();
	SymmetricMatrix nllscov;
	nllscov = Rinv.t()*Rinv*mse;
	
	fwdPosterior.SetCovariance( nllscov );*/

	
	SymmetricMatrix nllsprec;
      	nllsprec << J.t()*J/mse;
	
	// look for zero diagonal elements (implies parameter is not observable) 
	//and set precision small, but non-zero - so that covariance can be calculated
	for (int i=1; i<=nllsprec.Nrows(); i++)
	  {
	    if (nllsprec(i,i) < 1e-6)
	      {
		nllsprec(i,i) = 1e-6;
	      }
	  }
	fwdPosterior.SetPrecisions( nllsprec );
	fwdPosterior.GetCovariance();

      }

catch (Exception)
	{
	  LOG_ERR("   NEWMAT Exception in this voxel:\n"
		  << Exception::what() << endl);
	  
	  //if (haltOnBadVoxel) throw;
    
	  LOG_ERR("   Estimates in this voxel may be unreliable" <<endl
		  << "(precision matrix will be set manually)" <<endl
		  << "   Going on to the next voxel" << endl);

	    // output the results where we are
	    fwdPosterior.means = nlinpar.Par();

	    // recenter linearized model on new parameters
	    linear.ReCentre( fwdPosterior.means );
	    
	    // precision matrix is probably singular so set manually
	    fwdPosterior.SetPrecisions(  I*1e-12 );
	 
	}

      resultMVNs.push_back(new MVNDist(fwdPosterior));
      assert(resultMVNs.size() == voxel);
    }
}

NLLSInferenceTechnique::~NLLSInferenceTechnique()
{

}

double NLLSCF::cf(const ColumnVector& p) const
{
  Tracer_Plus tr("NLLSCF::cf");
  ColumnVector yhat;
  model->Evaluate(p,yhat);

  double cfv = ( (y-yhat).t() * (y-yhat) ).AsScalar();

  /*double cfv = 0.0;
  for (int i=1; i<=y.Nrows(); i++) { //sum of squares cost function
    double err = y(i) - yhat(i);
    cfv += err*err;
    }*/
  return(cfv);
}

ReturnMatrix NLLSCF::grad(const ColumnVector& p) const
{
  Tracer_Plus tr("NLLSCF::grad");
  ColumnVector gradv(p.Nrows());
  gradv=0.0;

  // need to recenter the linearised model to the current parameter values
  linear.ReCentre( p );
  const Matrix& J = linear.Jacobian();
  //const ColumnVector gm = linear.Offset(); //this is g(w) i.e. model evaluated at current parameters?
  ColumnVector yhat;
  model->Evaluate(p,yhat);

  gradv = -2*J.t()*(y-yhat);

  gradv.Release();
  return(gradv);
  }

boost::shared_ptr<BFMatrix> NLLSCF::hess(const ColumnVector& p, boost::shared_ptr<BFMatrix> iptr) const
{
  Tracer_Plus tr("NLLSCF::hess");
  boost::shared_ptr<BFMatrix> hessm;

  if (iptr && iptr->Nrows()==p.Nrows() && iptr->Ncols()==p.Nrows())
    { hessm = iptr; }
  else
    {
      hessm = boost::shared_ptr<BFMatrix>(new FullBFMatrix(p.Nrows(),p.Nrows()));
    }
  
  // need to recenter the linearised model to the current parameter values
  linear.ReCentre( p );
  const Matrix& J = linear.Jacobian();
  Matrix hesstemp = 2*J.t()*J; //Make the G-N approximation to the hessian

  //(*hessm) = J.t()*J;

  for (int i=1; i<=p.Nrows(); i++) { for (int j=1; j<=p.Nrows(); j++) hessm->Set(i,j,hesstemp(i,j));}

  return(hessm);
  }
  
