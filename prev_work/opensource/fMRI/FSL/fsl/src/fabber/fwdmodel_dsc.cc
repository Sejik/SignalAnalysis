/*  fwdmodel_dsc.cc - Implements a convolution absed model for DSC analysis

    Michael Chappell, FMRIB Image Analysis Group

    Copyright (C) 2008 University of Oxford  */

/*  Part of FSL - FMRIB's Software Library
    http://www.fmrib.ox.ac.uk/fsl
    fsl@fmrib.ox.ac.uk
    
    Developed at FMRIB (Oxford Centre for Functional Magnetic Resonance
    Imaging of the Brain), Department of Clinical Neurology, Oxford
    University, Oxford, UK
    
    
    LICENCE
    
    FMRIB Software Library, Release 4.0 (c) 2007, The University of
    Oxford (the "Software")
    
    The Software remains the property of the University of Oxford ("the
    University").
    
    The Software is distributed "AS IS" under this Licence solely for
    non-commercial use in the hope that it will be useful, but in order
    that the University as a charitable foundation protects its assets for
    the benefit of its educational and research purposes, the University
    makes clear that no condition is made or to be implied, nor is any
    warranty given or to be implied, as to the accuracy of the Software,
    or that it will be suitable for any particular purpose or for use
    under any specific conditions. Furthermore, the University disclaims
    all responsibility for the use which is made of the Software. It
    further disclaims any liability for the outcomes arising from using
    the Software.
    
    The Licensee agrees to indemnify the University and hold the
    University harmless from and against any and all claims, damages and
    liabilities asserted by third parties (including claims for
    negligence) which arise directly or indirectly from the use of the
    Software or the sale of any products based on the Software.
    
    No part of the Software may be reproduced, modified, transmitted or
    transferred in any form or by any means, electronic or mechanical,
    without the express permission of the University. The permission of
    the University is not required if the said reproduction, modification,
    transmission or transference is done without financial return, the
    conditions of this Licence are imposed upon the receiver of the
    product, and all original and amended source code is included in any
    transmitted product. You may be held legally responsible for any
    copyright infringement that is caused or encouraged by your failure to
    abide by these terms and conditions.
    
    You are not permitted under this Licence to use this Software
    commercially. Use for which any financial return is received shall be
    defined as commercial use, and includes (1) integration of all or part
    of the source code or the Software into a product for sale or license
    by or on behalf of Licensee to third parties or (2) use of the
    Software or any derivative of it for research with the final aim of
    developing software products for sale or license to a third party or
    (3) use of the Software or any derivative of it for research with the
    final aim of developing non-software products for sale or license to a
    third party, or (4) use of the Software to provide any service to an
    external organisation for which payment is received. If you are
    interested in using the Software commercially, please contact Isis
    Innovation Limited ("Isis"), the technology transfer company of the
    University, to negotiate a licence. Contact details are:
    innovation@isis.ox.ac.uk quoting reference DE/1112. */

#include "fwdmodel_dsc.h"

#include <iostream>
#include <newmatio.h>
#include <stdexcept>
#include "newimage/newimageall.h"
using namespace NEWIMAGE;
#include "easylog.h"
#include "miscmaths/miscprob.h"

string DSCFwdModel::ModelVersion() const
{
  return "$Id: fwdmodel_dsc.cc,v 1.4 2008/07/28 15:02:58 chappell Exp $";
}

void DSCFwdModel::HardcodedInitialDists(MVNDist& prior, 
    MVNDist& posterior) const
{
    Tracer_Plus tr("DSCFwdModel::HardcodedInitialDists");
    assert(prior.means.Nrows() == NumParams());

     SymmetricMatrix precisions = IdentityMatrix(NumParams()) * 1e-12;

    // Set priors
    // CBF
     prior.means(cbf_index()) = 0;
     precisions(cbf_index(),cbf_index()) = 1e-12;

     if (infermtt) {
       // Transit mean parameter
       prior.means(gmu_index()) = 2.3; //10;
       precisions(gmu_index(),gmu_index()) = 0.1; //0.01;
     }

     if (inferlambda) {
       // Transit labmda parameter
       prior.means(lambda_index()) = 2.3; //10;
       precisions(lambda_index(),lambda_index()) = 0.1; //0.01;
     }

     if (inferdelay) {
       // delay parameter
       prior.means(delta_index()) = 0;
       precisions(delta_index(),delta_index()) = 0.04;
     }

     // signal magnitude parameter
     prior.means(sig0_index()) = 100;
     precisions(sig0_index(),sig0_index()) = 1e-6;
    
   
    // Set precsions on priors
    prior.SetPrecisions(precisions);
    
    // Set initial posterior
    posterior = prior;

    // For parameters with uniformative prior chosoe more sensible inital posterior
    // Tissue perfusion
    posterior.means(cbf_index()) = 0.001;
    precisions(cbf_index(),cbf_index()) = 1;

    posterior.SetPrecisions(precisions);
    
}    
    
    

void DSCFwdModel::Evaluate(const ColumnVector& params, ColumnVector& result) const
{
  Tracer_Plus tr("DSCFwdModel::Evaluate");

    // ensure that values are reasonable
    // negative check
   ColumnVector paramcpy = params;
    for (int i=1;i<=NumParams();i++) {
      if (params(i)<0) { paramcpy(i) = 0; }
      }
  
   // parameters that are inferred - extract and give sensible names
   float cbf;
   float gmu; //mean of the transit time distribution
   float lambda; // log lambda (fromt ransit distirbution)
   float delta;
   float sig0; //'inital' value of the signal

   // extract values from params
   cbf = paramcpy(cbf_index());

   if (infermtt) {
     gmu = params(gmu_index()); //this is the log of the mtt so we can have -ve values
   }
   else {gmu = 0;}
   if (inferlambda) {
     lambda = params(lambda_index()); //this is the log of lambda so we can have -ve values
   }
   else {
     lambda = 0;
   }

   if (inferdelay) {
   delta = params(delta_index()); // NOTE: delta is allowed to be negative
   }
   else {
     delta = 0;
   }
   sig0 = paramcpy(sig0_index());

 
     
   // sensible limits on delta (beyond which it gets silly trying to estimate it)
   if (delta > ntpts/2*delt) {delta = ntpts/2*delt;}
   if (delta < -ntpts/2*delt) {delta = -ntpts/2*delt;}   


   //cout << "aif: " << aif.t() << endl;

 

   // deal with delay parameter - this shifts the aif
   float nshift = floor(delta/hdelt); // number of time points of shift associated with delta
   float minorshift = delta - nshift*hdelt; // shift within the sampled time points (this is always a 'forward' shift)
      
   ColumnVector aifnew(nhtpts);
   int index;
   for (int i=1; i<=nhtpts; i++) {
     index = i-nshift;
     if (index==1) { aifnew(i) = aif(1)*minorshift/hdelt; } //linear interpolation with zero as 'previous' time point
     else if (index < 1) { aifnew(i) = 0; }
     else if (index>nhtpts) { aifnew(i) = aif(nhtpts); }
     else {
       //linear interpolation
       aifnew(i) = aif(index) + (aif(index-1)-aif(index))*minorshift/hdelt;
     }
   }
   
     
   ColumnVector residue;
   residue.ReSize(nhtpts);
   
   // Evaluate the residue function
   if (gmu > 10) gmu = 10;

   if (lambda > 10) lambda=10;
   // gmu and lambda are actually the log versions
   gmu = exp(gmu);
   lambda = exp(lambda);
   //if (gmu<=0.1) gmu = 0.1;
   //if (lambda<=0.1) lambda = 0.1;
   /*float alph = exp(lambda);
   float bet = gmu/exp(lambda);
   //cout << "transitm: " << gmu << " transitv: " << exp(lambda) << "alph: " << alph << " bet: " << bet << endl
   for (int i=1; i<=ntpts; i++) {
     residue(i) = gdtrc(1/bet,alph,tsamp(i));
     }*/
   float gvar = gmu*gmu/lambda;   
   residue = 1 - gammacdf(htsamp.t(),gmu,gvar).t();

   //cout << cbf << "  " << gmu << "  " << gvar << "  " << delta << "  " << sig0 << endl;
   /*float alpha = gmu*gmu/gvar;
   float beta = gmu/alpha;
   for (int i=1; i <=residue.Nrows(); i++) {
     residue(i) = evalresidue(tsamp(i),alpha,beta);
     }*/

   // Do the convolution
   // form the convolution matrix (there is probably a better way!)
   
   //aifnew = aif;
   
   //cout << "--------------------" << endl;
   //cout << "cbf: " << cbf << " gmu: " << gmu << " log(lambda): " << lambda << " delta: " << delta << " sig0: " << sig0 << endl;

   //cout << "residue: " << residue.t() << endl;
   //cout << "aifnew: " << aifnew.t() << endl;

   LowerTriangularMatrix A(nhtpts); A=0.0;

   if (convmtx=="simple")
     {
       // Simple convolution matrix
       for (int i=1; i<=nhtpts; i++) {
	 for (int j=1; j <= i; j++) {
	   A(i,j) = aifnew(i-j+1); //note we are using the local aifnew here! (i.e. it has been suitably time shifted)
	 }
       }
     }
   //cout << "new run" << endl;
   //cout << A << endl;

   else if (convmtx=="voltera")
     {
       ColumnVector aifextend(nhtpts+2);
       ColumnVector zero(1);
       zero=0;
       aifextend = zero & aifnew & zero;
       int x, y, z;
       //voltera convolution matrix (as defined by Sourbron 2007) - assume zeros outside aif range
       for (int i=1; i<=nhtpts; i++) {
	 for (int j=1; j <= i; j++) {
	   //cout << i << "  " << j << endl;
	   x = i+1;y=j+1; z = i-j+1;
	   if (j==1) { A(i,j) =(2*aifextend(x) + aifextend(x-1))/6; }
	   else if (j==i) { A(i,j) = (2*aifextend(2) + aifextend(3))/6; }
	   else { 
	     A(i,j) =  (4*aifextend(z) + aifextend(z-1) + aifextend(z+1))/6; 
	     //cout << x << "  " << y << "  " << z << "  " << ( 4*aifextend(z) + aifextend(z-1) + aifextend(z+1) )/6 << "  " << 1/6*(4*aifextend(z) + aifextend(z-1) + aifextend(z+1)) << endl;
	     // cout << aifextend(z) << "  " << aifextend(z-1) << "  " << aifextend(z+1) << endl;
	   }
	   //cout << i << "  " << j << "  " << aifextend(z) << "  " << A(i,j) << endl<<endl;
	 }
       }
     }

   //cout << A << endl;

   // do the multiplication
   ColumnVector C; 
   C = cbf*hdelt*A*residue;
   //convert to the DSC signal

   //cout  << "C: " << C.t() << endl;

   //cout << "sig0: " << sig0 << " r2: " << r2 << " te: " << te << endl;
   
   //cout<< htsamp.t() << endl;

   ColumnVector C_low(ntpts);
   for (int i=1; i<=ntpts; i++) {
     C_low(i) = C((i-1)*upsample+1);
     //C_low(i) = interp1(htsamp,C,tsamp(i));
     } 

   result.ReSize(ntpts);
   for (int i=1; i<=ntpts; i++) {
     result(i) = sig0*exp(-C_low(i)*te);
   }

   // downsample back to normal time points
   //cout << estsig.t() << endl;
   //result.ReSize(ntpts);
   //result=estsig;
   /*for (int i=1; i<=ntpts; i++) {
     result(i) = interp1(htsamp,estsig,tsamp(i));
     }
   if ((result-estsig).SumAbsoluteValue()>0.1){
     cout << result.t() << endl;
     cout << estsig.t() << endl;
     }*/

   //cout << result.t()<< endl;
}

DSCFwdModel::DSCFwdModel(ArgsType& args)
{
  Tracer_Plus tr("DSCFwdModel::DSCFwdModel");
    string scanParams = args.ReadWithDefault("scan-params","cmdline");
    
    if (scanParams == "cmdline")
    {
      // specify command line parameters here
      te = convertTo<double>(args.Read("te"));
      
      delt = convertTo<double>(args.Read("delt"));

      // specify options of the model
      infermtt = args.ReadBool("infermtt");
      inferlambda = args.ReadBool("inferlambda");
      inferdelay = args.ReadBool("inferdelay");

      convmtx = args.ReadWithDefault("convmtx","simple");
      
      // Read in the arterial signal
      ColumnVector artsig;
      string artfile = args.Read("aif");
      artsig = read_ascii_matrix( artfile );

      // establish number of time points from the arterial signal
      ntpts = artsig.Nrows();

      // Create vector of sampled times
      tsamp.ReSize(ntpts);
      for (int i=1; i<=ntpts; i++) {
	tsamp(i) = (i-1)*delt;
      }

          
       // calculate the arterial input function (from upsampled artsig)
      ColumnVector aif_low(ntpts);
      aif_low = -1/te*log(artsig/artsig(1)); //using first value from aif input as time zero value
      
      // upsample the signal
      upsample=1;
      nhtpts=(ntpts-1)*upsample+1;
      htsamp.ReSize(nhtpts); 
      aif.ReSize(nhtpts);
      htsamp(1) = tsamp(1); aif(1) = aif_low(1);
      hdelt = delt/upsample;
      int j=0; int ii=0;
      for (int i=2; i<=nhtpts-1; i++) {
	htsamp(i) = htsamp(i-1)+hdelt;
	j = floor((i-1)/upsample)+1;
	ii= i - upsample*(j-1)-1;
	aif(i) = aif_low(j) + ii/upsample*(aif_low(j+1) - aif_low(j));
      }
      htsamp(nhtpts)=tsamp(ntpts);
      aif(nhtpts) = aif_low(ntpts);
     

      // add information about the parameters to the log
      /* do logging here*/
   
    }

    else
        throw invalid_argument("Only --scan-params=cmdline is accepted at the moment");    
    
 
}

void DSCFwdModel::ModelUsage()
{ 
  cout << "Model usagae for DSC model...";
}

void DSCFwdModel::DumpParameters(const ColumnVector& vec,
                                    const string& indent) const
{
    
}

void DSCFwdModel::NameParams(vector<string>& names) const
{
  names.clear();
  
  names.push_back("cbf");
  if (infermtt) names.push_back("transitm");
  if (inferlambda) names.push_back("lambda");
  
  if (inferdelay)
  names.push_back("delay");

  names.push_back("sig0");
  
}

void DSCFwdModel::pass_in_data( const ColumnVector& data )
{
  s =data;
  return;
}

