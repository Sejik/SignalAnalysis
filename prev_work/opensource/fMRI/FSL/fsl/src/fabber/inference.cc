/*  inference.cc - General inference technique base class

    Adrian Groves, FMRIB Image Analysis Group

    Copyright (C) 2007-2008 University of Oxford  */

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

#include "inference.h"
#include "newimage/newimageall.h"
 
using namespace NEWIMAGE;
using namespace std;
using namespace MISCMATHS;

void InferenceTechnique::Setup(ArgsType& args)
{
  Tracer_Plus tr("InferenceTechnique::Setup");

  // Pick models
  model = FwdModel::NewFromName(args.Read("model"), args);
  assert( model->NumParams() > 0 );
  LOG_ERR("    Forward Model version:\n      " 
	  << model->ModelVersion() << endl);

  noise = NoiseModel::NewFromName(args.Read("noise"), args);
//  noise->LoadPrior(args.ReadWithDefault("noise-prior","hardcoded"));
//  noise->Dump("  ");

  saveModelFit = args.ReadBool("save-model-fit");
  saveResiduals = args.ReadBool("save-residuals");
}



void InferenceTechnique::SaveResults(const DataSet& data) const
{
  Tracer_Plus tr("InferenceTechnique::SaveResults");
    LOG << "    Preparing to save results..." << endl;

  
    // Save the resultMVNs as two NIFTI files
    // Note: I should probably use a single NIFTI file with
    // NIFTI_INTENT_NORMAL -- but I can't find the detailed 
    // documentation!  (Ordering for a multivariate norm).

    const volume<float>& mask  = data.GetMask();
    int nVoxels = resultMVNs.size();

    cout << "Saving!\n";
    MVNDist::Save(resultMVNs, outputDir + "/finalMVN", mask);

    if (resultMVNsWithoutPrior.size() > 0)
      {
	assert(resultMVNsWithoutPrior.size() == (unsigned)nVoxels);
	MVNDist::Save(resultMVNsWithoutPrior, outputDir + "/finalMVNwithoutPrior", mask);
      }

    /* Some validation code -- checked, Save then Load 
       produced identical results (to single precision)
       cout << "Creating!\n";    
       vector<MVNDist*> test(resultMVNs.size(), NULL);
       cout << "Loading!\n";    
       MVNDist::Load(test, outputDir + "/finalMVN", mask);

       assert(test[0] != NULL);

       cout << "Verifying MVNDists are identical!!!";    
       // won't be identical because they're written as floats.
       for (unsigned i = 1; i <= test.size(); i++)
       {
       cout << i << endl;
       test.at(i-1); resultMVNs.at(i-1);
       cout << 'a'<< endl;
       assert(resultMVNs[i-1] != NULL);
       assert(test[i-1] != NULL);
       cout << resultMVNs[i-1]->means.t() << test[i-1]->means.t();
       //        assert(resultMVNs[i-1]->means == test[i-1]->means);
       cout << 'b' << endl;
       cout << resultMVNs[i-1]->GetCovariance();
       cout << test[i-1]->GetCovariance();
       //        assert(resultMVNs[i-1]->GetCovariance() == test[i-1]->GetCovariance());
       cout << 'c' << endl;
       }
    */

    // Write the parameter names into paramnames.txt
    
    LOG << "    Writing paramnames.txt..." << endl;
    ofstream paramFile((outputDir + "/paramnames.txt").c_str());
    vector<string> paramNames;
    model->NameParams(paramNames);
    for (unsigned i = 0; i < paramNames.size(); i++)
    {
        LOG << "      " << paramNames[i] << endl;
        paramFile << paramNames[i] << endl;
    }
    paramFile.close();
    
    LOG << "    Same information using DumpParameters:" << endl;
    ColumnVector indices(model->NumParams());
    for (int i = 1; i <= indices.Nrows(); i++)
        indices(i) = i;
    model->DumpParameters(indices, "      ");

    // Create individual files for each parameter's mean and Z-stat

    for (unsigned i = 1; i <= paramNames.size(); i++)
    {
        Matrix paramMean, paramZstat;
    	paramMean.ReSize(1, nVoxels);
	paramZstat.ReSize(1, nVoxels);

        for (int vox = 1; vox <= nVoxels; vox++)
        {
	    paramMean(1,vox) = resultMVNs[vox-1]->means(i);
            paramZstat(1,vox) =
              paramMean(1,vox) / 
              sqrt(resultMVNs[vox-1]->GetCovariance()(i,i));
        }
    	LOG << "    Writing means..." << endl;

    	// Save paramMeans
	volume4D<float> output(mask.xsize(),mask.ysize(),mask.zsize(),1);
	output.setmatrix(paramMean,mask);
	output.set_intent(NIFTI_INTENT_NONE,0,0,0);
	output.setDisplayMaximumMinimum(output.max(),output.min());
	save_volume4D(output,outputDir + "/mean_" + paramNames.at(i-1));

	output.setmatrix(paramZstat,mask);
        output.set_intent(NIFTI_INTENT_ZSCORE,0,0,0);
	output.setDisplayMaximumMinimum(output.max(),output.min());
	save_volume4D(output,outputDir + "/zstat_" + paramNames.at(i-1));
    }        

    // Save the Free Energy estimates
    if (!resultFs.empty())
      {
	assert((int)resultFs.size() == nVoxels);
	Matrix freeEnergy;
	freeEnergy.ReSize(1, nVoxels);
	for (int vox = 1; vox <= nVoxels; vox++)
	  {
	    freeEnergy(1,vox) = resultFs.at(vox-1);
	  }
	
	volume4D<float> output(mask.xsize(),mask.ysize(),mask.zsize(),1);
	output.setmatrix(freeEnergy,mask);
	output.set_intent(NIFTI_INTENT_NONE,0,0,0);
	output.setDisplayMaximumMinimum(output.max(),output.min());
	save_volume4D(output,outputDir + "/freeEnergy");
      }
    else
      {
	LOG_ERR("Free energy wasn't recorded, so no freeEnergy.nii.gz created.\n");
      }
    
    if (saveModelFit || saveResiduals)
      {
        LOG << "    Writing model fit/residuals..." << endl;
        // Produce the model fit and residual volumeserieses
	
        Matrix modelFit, residuals;
        modelFit.ReSize(model->NumOutputs(), nVoxels);
	ColumnVector tmp;
        for (int vox = 1; vox <= nVoxels; vox++)
        {
            model->Evaluate(resultMVNs.at(vox-1)->means.Rows(1,model->NumParams()), tmp);
            modelFit.Column(vox) = tmp;
        }

	volume4D<float> output(mask.xsize(),mask.ysize(),mask.zsize(),model->NumOutputs());
	
        if (saveResiduals)
        {
	  residuals = data.GetVoxelData() - modelFit;
	  output.setmatrix(residuals,mask);
	  output.set_intent(NIFTI_INTENT_NONE,0,0,0);
	  output.setDisplayMaximumMinimum(output.max(),output.min());
	  save_volume4D(output,outputDir + "/residuals");
        }
        if (saveModelFit)
        {
 	  output.setmatrix(residuals,mask);
	  output.set_intent(NIFTI_INTENT_NONE,0,0,0);
	  output.setDisplayMaximumMinimum(output.max(),output.min());
	  save_volume4D(output,outputDir + "/modelfit");
        }

    }

    LOG << "    Done writing results." << endl;
}


InferenceTechnique::~InferenceTechnique() 
{ 
  delete model;
  delete noise;
  while (!resultMVNs.empty())
    {
      delete resultMVNs.back();
      resultMVNs.pop_back();
    }
  while (!resultMVNsWithoutPrior.empty())
    {
      delete resultMVNsWithoutPrior.back();
      resultMVNsWithoutPrior.pop_back();
    }
}

#include "inference_vb.h"
#include "inference_spatialvb.h"
#include "inference_nlls.h"

// Whenever you add a new class to inference.h, update this too.
InferenceTechnique* InferenceTechnique::NewFromName(const string& method)
{
  Tracer_Plus tr("PickInferenceTechnique");

  if (method == "vb")
    {
      return new VariationalBayesInferenceTechnique;
    }
  else if (method == "spatialvb")
    {
      return new SpatialVariationalBayes;
    }
  else if (method == "nlls")
    {
      return new NLLSInferenceTechnique;
    }
  else if (method == "")
    {
      throw Invalid_option("Must include the --method=vb or --method=spatialvb option");
    }
  else 
    {
      throw Invalid_option("Unrecognized --method: " + method);
    }
}
