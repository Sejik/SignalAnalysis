/*  inference_vb.cc - VB inference technique class declarations

    Adrian Groves and Michael Chappell, FMRIB Image Analysis Group

    Copyright (C) 2007 University of Oxford  */

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

#include "inference_vb.h"
#include "convergence.h"

void VariationalBayesInferenceTechnique::Setup(ArgsType& args) 
{ 
  Tracer_Plus tr("VariationalBayesInferenceTechnique::Setup");

  // Call ancestor, which does most of the real work
  InferenceTechnique::Setup(args);

  // Load up initial prior and initial posterior
  MVNDist* loadPrior = new MVNDist( model->NumParams() );
  MVNDist* loadPosterior = new MVNDist( model->NumParams() );
  NoiseParams* loadNoisePrior = noise->NewParams();
  NoiseParams* loadNoisePosterior = noise->NewParams();
  
  string filePrior = args.ReadWithDefault("fwd-initial-prior", "modeldefault");
  string filePosterior = args.ReadWithDefault("fwd-initial-posterior", "modeldefault");
  if (filePrior == "modeldefault" || filePosterior == "modeldefault")
      model->HardcodedInitialDists(*loadPrior, *loadPosterior);
  if (filePrior != "modeldefault") loadPrior->Load(filePrior);
  if (filePosterior != "modeldefault") loadPosterior->Load(filePosterior);
 
  if ( (loadPosterior->GetSize() != model->NumParams()) 
    || (loadPrior->GetSize() != model->NumParams()) )
      throw Invalid_option("Size mismatch: model wants " 
      	+ stringify(model->NumParams())
	+ ", initial prior (" + filePrior + ") is " 
	+ stringify(loadPrior->GetSize()) 
	+ ", initial posterior (" + filePosterior + ") is "
        + stringify(loadPosterior->GetSize())
	+ "\n");

  filePrior = args.ReadWithDefault("noise-initial-prior", "modeldefault");
  filePosterior = args.ReadWithDefault("noise-initial-posterior", "modeldefault");
  if (filePrior == "modeldefault" || filePosterior == "modeldefault")
      noise->HardcodedInitialDists(*loadNoisePrior, *loadNoisePosterior);
  if (filePrior != "modeldefault") 
      loadNoisePrior->InputFromMVN( MVNDist(filePrior) );
  if (filePosterior != "modeldefault") 
      loadNoisePosterior->InputFromMVN( MVNDist(filePosterior) );

  // Make these distributions constant:
  assert(initialFwdPrior == NULL);
  assert(initialFwdPosterior == NULL);    
  assert(initialNoisePrior == NULL);
  assert(initialNoisePosterior == NULL);    
  initialFwdPrior = loadPrior;
  initialFwdPosterior = loadPosterior;
  initialNoisePrior = loadNoisePrior;
  initialNoisePosterior = loadNoisePosterior;
  loadPrior = loadPosterior = NULL;
  loadNoisePrior = loadNoisePosterior = NULL; // now, only accessible as consts.

  // Resume from a previous run? 
  continueFromFile = args.ReadWithDefault("continue-from-mvn", "");
  if (continueFromFile != "")
  {
    // Won't need these any more.  They don't hurt, but why leave them around?
    // They can only cause trouble (if used by mistake).
    delete initialFwdPosterior; initialFwdPosterior = NULL;
    
    if ( !args.ReadBool("continue-fwd-only") )
    {
        delete initialNoisePosterior; 
        initialNoisePosterior = NULL;
    }
  }

  // Fix the linearization centres?
  lockedLinearFile = args.ReadWithDefault("locked-linear-from-mvn","");

  // Maximum iterations allowed:
  string maxIterations = args.ReadWithDefault("max-iterations","10");
  if (maxIterations.find_first_not_of("0123456789") != string::npos)
    throw Invalid_option("--convergence=its=?? parameter must be a positive number");    
  int its = atol(maxIterations.c_str());
  if (its<=0)
    throw Invalid_option("--convergence=its=?? paramter must be positive");
  
  // Figure out convergence-testing method:
  string convergence = args.ReadWithDefault("convergence", "maxits");
  if (convergence == "maxits")
    conv = new CountingConvergenceDetector(its);
  else if (convergence == "pointzeroone")
    conv = new FchangeConvergenceDetector(its, 0.01);
  else if (convergence == "freduce")
    conv = new FreduceConvergenceDetector(its, 0.01);
  else if (convergence == "trialmode")
    conv = new TrialModeConvergenceDetector(its, 10, 0.01);
  else
    throw Invalid_option("Unrecognized convergence detector: '" 
                           + convergence + "'");

  // Figure out if F needs to be calculated every iteration
  printF = args.ReadBool("print-free-energy");
  needF = conv->UseF() || printF;

  haltOnBadVoxel = !args.ReadBool("allow-bad-voxels");
  if (haltOnBadVoxel)
    LOG << "Note: numerical errors in voxels will cause the program to halt.\n"
        << "Use --allow-bad-voxels (with caution!) to keep on calculating.\n";
  else
    LOG << "Using --allow-bad-voxels: numerical errors in a voxel will\n"
	<< "simply stop the calculation of that voxel.\n"
	<< "Check log for 'Going on to the next voxel' messages.\n"
	<< "Note that you should get very few (if any) exceptions like this;"
	<< "they are probably due to bugs or a numerically unstable model.";
  
}

void VariationalBayesInferenceTechnique::DoCalculations(const DataSet& allData) 
{
  Tracer_Plus tr("VariationalBayesInferenceTechnique::DoCalculations");
  
  const Matrix& data = allData.GetVoxelData();
  // Rows are volumes
  // Columns are (time) series
  // num Rows is size of (time) series
  // num Cols is size of volumes       
  int Nvoxels = data.Ncols();
  if (data.Nrows() != model->NumOutputs())
    throw Invalid_option("Data length (" 
      + stringify(data.Nrows())
      + ") does not match model's output length ("
      + stringify(model->NumOutputs())
      + ")!");

  assert(resultMVNs.empty()); // Only call DoCalculations once
  resultMVNs.resize(Nvoxels, NULL);

  assert(resultFs.empty());
  resultFs.resize(Nvoxels, 9999);  // 9999 is a garbage default value

  // If we're continuing from previous saved results, load them here:
  bool continuingFromFile = (continueFromFile != "");
  vector<MVNDist*> continueFromDists;
  if (continuingFromFile)
  {
    MVNDist::Load(continueFromDists, continueFromFile, allData.GetMask());
  } 

  if (lockedLinearFile != "")
    throw Invalid_option("The option --locked-linear-from-mvn doesn't work with --method=vb yet, but should be pretty easy to implement.\n");
    

  const int nFwdParams = initialFwdPrior->GetSize();
  const int nNoiseParams = initialNoisePrior->OutputAsMVN().GetSize(); 

  // Reverse order (to test that everything is being properly reset):
  //for (int voxel = Nvoxels; voxel >=1; voxel--) 
  
  for (int voxel = 1; voxel <= Nvoxels; voxel++)
    {
      ColumnVector y = data.Column(voxel);
      model->pass_in_data( y );
      NoiseParams* noiseVox = NULL;
      
      // if (continuingFromFile)
      if (initialNoisePosterior == NULL) // continuing noise params from file 
      {
        assert(continuingFromFile);
        assert(continueFromDists.at(voxel-1)->GetSize() == nFwdParams+nNoiseParams);
        noiseVox = noise->NewParams();
        noiseVox->InputFromMVN( continueFromDists.at(voxel-1)
            ->GetSubmatrix(nFwdParams+1, nFwdParams+nNoiseParams) );
      }  
      else
      {
        noiseVox = initialNoisePosterior->Clone();
	/* if (continuingFromFile)
	   assert(continueFromDists.at(voxel-1)->GetSize() == nFwdParams);*/
      }
      const NoiseParams* noiseVoxPrior = initialNoisePrior;
      NoiseParams* const noiseVoxSave = noiseVox->Clone();
      
      LOG_ERR("  Voxel " << voxel << " of " << Nvoxels << endl); 
      //  << " sumsquares = " << (y.t() * y).AsScalar() << endl;
      double F = 1234.5678;

      MVNDist fwdPrior( *initialFwdPrior );
      MVNDist fwdPosterior;
      if (continuingFromFile)
      {
        assert(initialFwdPosterior == NULL);
        fwdPosterior = continueFromDists.at(voxel-1)->GetSubmatrix(1, nFwdParams);
      }
      else
      { 
        assert(initialFwdPosterior != NULL);
        fwdPosterior = *initialFwdPosterior;
      }
      MVNDist fwdPosteriorSave(fwdPosterior);

      
      LinearizedFwdModel linear( model );
      
      // Setup for ARD (fwdmodel will decide if there is anything to be done)
      double Fard = 0;
      model->SetupARD( fwdPosterior, fwdPrior, Fard );
      

      try
	{
	  linear.ReCentre( fwdPosterior.means );
	  conv->Reset();

	  noise->Precalculate( *noiseVox, *noiseVoxPrior, y );

	  int iteration = 0; //count the iterations
	  do 
	    {
	      if (needF) { 
		F = noise->CalcFreeEnergy( *noiseVox, 
					   *noiseVoxPrior, fwdPosterior, fwdPrior, linear, y);
		F = F + Fard; }
	      if (printF) 
		LOG << "      Fbefore == " << F << endl;

 
              // Save old values if called for
	      if ( conv->NeedSave() )
              {
		*noiseVoxSave = *noiseVox;  // copy values, not pointers!
                fwdPosteriorSave = fwdPosterior;
              }

	      // Do ARD updates (model will decide if there is anything to do here)
	      if (iteration > 0) { model->UpdateARD( fwdPosterior, fwdPrior, Fard ); }

	      // Theta update
	      noise->UpdateTheta( *noiseVox, fwdPosterior, fwdPrior, linear, y );


      
	      if (needF) {
		F = noise->CalcFreeEnergy( *noiseVox, 
					   *noiseVoxPrior, fwdPosterior, fwdPrior, linear, y);
		F = F + Fard; }
	      if (printF) 
		LOG << "      Ftheta == " << F << endl;
	      
	      
	      // Alpha & Phi updates
	      noise->UpdateNoise( *noiseVox, *noiseVoxPrior, fwdPosterior, linear, y );

	      if (needF) {
		F = noise->CalcFreeEnergy( *noiseVox, 
					   *noiseVoxPrior, fwdPosterior, fwdPrior, linear, y);
		F = F + Fard; }
	      if (printF) 
	      LOG << "      Fphi == " << F << endl;

	      // Test of NoiseModel cloning:
	      // NoiseModel* tmp = noise; noise = tmp->Clone(); delete tmp;

	      // Linearization update
	      // Update the linear model before doing Free eneergy calculation (and ready for next round of theta and phi updates)
	      linear.ReCentre( fwdPosterior.means );
	      
	      
	      if (needF) {
		F = noise->CalcFreeEnergy( *noiseVox, 
					   *noiseVoxPrior, fwdPosterior, fwdPrior, linear, y);
		F = F + Fard; }
	      if (printF) 
		LOG << "      Fnoise == " << F << endl;

	      iteration++;
	    }           
	  while ( !conv->Test( F ) );

	  // Revert to old values at last stage if required
	  if ( conv-> NeedRevert() )
          {
	    *noiseVox = *noiseVoxSave;  // copy values, not pointers!
            fwdPosterior = fwdPosteriorSave;
	  }
	  conv->DumpTo(LOG, "    ");
	} 
      catch (const overflow_error& e)
	{
	  LOG_ERR("    Went infinite!  Reason:" << endl
		  << "      " << e.what() << endl);
	  //todo: write garbage or best guess to memory/file
	  if (haltOnBadVoxel) throw;
	  LOG_ERR("    Going on to the next voxel." << endl);
	}
      catch (Exception)
	{
	  LOG_ERR("    NEWMAT Exception in this voxel:\n"
		  << Exception::what() << endl);
	  if (haltOnBadVoxel) throw;
	  LOG_ERR("    Going on to the next voxel." << endl);  
	}
      catch (...)
	{
	  LOG_ERR("    Other exception caught in main calculation loop!!\n");
	    //<< "    Use --halt-on-bad-voxel for more details." << endl;
	  if (haltOnBadVoxel) throw;
	  LOG_ERR("    Going on to the next voxel" << endl);
	}
      
      try {

	LOG << "    Final parameter estimates are:" << endl;
	linear.DumpParameters(fwdPosterior.means, "      ");
	
	assert(resultMVNs.at(voxel-1) == NULL);
	resultMVNs.at(voxel-1) = new MVNDist(
	  fwdPosterior, noiseVox->OutputAsMVN() );
	if (needF)
	  resultFs.at(voxel-1) = F;

      } catch (...) {
	// Even that can fail, due to results being singular
	LOG << "    Can't give any sensible answer for this voxel; outputting zero +- identity\n";
	MVNDist* tmp = new MVNDist();
	tmp->SetSize(fwdPosterior.means.Nrows()
		    + noiseVox->OutputAsMVN().means.Nrows());
	tmp->SetCovariance(IdentityMatrix(tmp->means.Nrows()));
	resultMVNs.at(voxel-1) = tmp;

	if (needF)
	  resultFs.at(voxel-1) = F;
      }
      
      delete noiseVox; noiseVox = NULL;
      delete noiseVoxSave;
    }

    while (continueFromDists.size()>0)
    {
      delete continueFromDists.back();
      continueFromDists.pop_back();
    }
}

VariationalBayesInferenceTechnique::~VariationalBayesInferenceTechnique() 
{ 
  delete conv;
  delete initialFwdPrior;
  delete initialFwdPosterior;
}




