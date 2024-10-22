/*  randomise.cc
    Tim Behrens & Steve Smith & Matthew Webster (FMRIB) & Tom Nichols (UMich)
    Copyright (C) 2004-2008 University of Oxford  */
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

#define _GNU_SOURCE 1
#define POSIX_SOURCE 1
#define CLUST_CON 26

// 26 for FSL 18 for SPM
#include "miscmaths/f2z.h"
#include "newimage/newimageall.h"
#include "libprob.h"
#include "ranopts.h"
#include <algorithm>

using namespace MISCMATHS;
using namespace NEWIMAGE;
using namespace Utilities;
using namespace RANDOMISE;

class VoxelwiseDesign
{
public:
  bool isSet;
  vector<Matrix> EV;
  vector<int> location;
  void setup(const vector<int>& voxelwise_ev_numbers,const vector<string>& voxelwise_ev_filenames,const volume<float>& mask, const int maximumLocation, const bool isVerbose);
  VoxelwiseDesign() { isSet=false; }
  Matrix adjustDesign(const Matrix& originalDesign,const int voxelNo);
private:
};

Matrix VoxelwiseDesign::adjustDesign(const Matrix& originalDesign, const int voxelNo)
{
  Matrix newDesign(originalDesign);
  for (unsigned int currentEV=0;currentEV<location.size();currentEV++)
    newDesign.Column(location[currentEV])=EV[currentEV].Column(voxelNo);
  return newDesign;
}

void VoxelwiseDesign::setup(const vector<int>& EVnumbers,const vector<string>& EVfilenames,const volume<float>& mask,const int maximumLocation,const bool isVerbose)
{
  isSet=false;
  if(EVnumbers.size() != EVfilenames.size())
    throw Exception("Number of input voxelwise_ev_filenames must match number of voxelwise_ev_numbers");
  location=EVnumbers;
  EV.resize(EVfilenames.size());
  volume4D<float> input;
  for(unsigned int i=0; i<EV.size(); i++)      
  {
    if(location[i]>maximumLocation)
      throw Exception("voxelwise_ev_numbers option specifies a number greater than number of design EVs)");
    if (isVerbose) cout << "Loading voxelwise ev: " << EVfilenames.at(i) << " for EV " << location.at(i) << endl;
    read_volume4D(input,EVfilenames.at(i));
    EV.at(i)=input.matrix(mask);
  }
  isSet=true;
}

VoxelwiseDesign voxelwiseInput;

class Permuter
{ 
public:
  bool isFlipping;
  bool isRandom;
  int nGroups;
  int nSubjects;
  double finalPermutation;
  vector<double>       uniquePermutations; //0 is unique for whole design, 1..nGroups is unique per block
  vector<ColumnVector> permutedLabels;
  vector<ColumnVector> originalLabels;
  vector<ColumnVector> originalLocations;
  vector<ColumnVector> previousPermutations;
  ColumnVector truePermutation;
  ColumnVector unpermutedVector;
  Permuter();
  ~Permuter();
  void writePermutationHistory(const string& filename);
  void createPermutationGroups(const Matrix& design, Matrix groups, const bool oneNonZeroContrast, const long requiredPermutations, const bool detectingNullElements, const bool outputDebug);
  void initialisePermutationGroups(const ColumnVector& labels, const long requiredPermutations);
  ColumnVector createDesignLabels(const Matrix& design);
  void createTruePermutation(const ColumnVector& labels, ColumnVector copyOldlabels, ColumnVector& permvec);
  ColumnVector nextPermutation(const long perm);
  ColumnVector nextPermutation(const long permutationNumber, const bool printStatus, const bool isStoring);
  bool isPreviousPermutation(const ColumnVector& newPermutation);
  ColumnVector permutationVector();
  double reportRequiredPermutations(const bool printToScreen);
  ColumnVector returnPreviousTruePermutation(const long permutationNumber);
private:
  double computeUniquePermutations(const ColumnVector& labels, const bool calculateFlips);
  void nextShuffle(ColumnVector& perm);
  void nextFlip(ColumnVector& mult);
};

class ParametricStatistic
{
public:
  Matrix originalStatistic,uncorrectedStatistic,maximumDistribution,sumStatMat,sumSampMat;
  bool isAveraging,storingUncorrected;
  void   store(const volume<int>& clusterLabels, const ColumnVector& clusterSizes, const volume<float>& mask, const int contrastNo, const unsigned long permNo);
  void   store(const Matrix& parametricMatrix, const unsigned long permNo);
  void   setup(const int nContrasts,const unsigned long nPerms, const int nVoxels, const bool wantAverage, const bool wantUncorrected);
  void   average(const string filename, const float percentileThreshold,const volume<float>& mask);
  ParametricStatistic() { isAveraging=false; }
};

void ParametricStatistic::setup(const int nContrasts,const unsigned long nPerms, const int nVoxels, const bool wantAverage,const bool wantUncorrected=false)
{
  isAveraging=wantAverage;
  storingUncorrected=wantUncorrected;
  maximumDistribution.ReSize(nContrasts,nPerms);
  maximumDistribution=0;
  if ( storingUncorrected ) {
    uncorrectedStatistic.ReSize(1,nVoxels);
    uncorrectedStatistic=0;
  }
  originalStatistic.ReSize(nContrasts,nVoxels);
  originalStatistic=0;
  if ( isAveraging ) {
    sumStatMat=originalStatistic;
    sumSampMat=originalStatistic;
  }
}

void ParametricStatistic::store(const volume<int>& clusterLabels, const ColumnVector& clusterSizes ,const volume<float>& mask, const int contrastNo, const unsigned long permNo)
{
  if ( clusterSizes.Nrows() > 0 ) 
    maximumDistribution(contrastNo,permNo)=clusterSizes.MaximumAbsoluteValue();
  if (permNo==1 || isAveraging) { 
    volume4D<float> parametricImage(mask.xsize(),mask.ysize(),mask.zsize(),1);
    parametricImage=0;
    for(int z=0; z<mask.zsize(); z++)
      for(int y=0; y<mask.ysize(); y++)
	for(int x=0; x<mask.xsize(); x++)
	  if( clusterLabels(x,y,z) ) 
	    parametricImage(x,y,z,0)=clusterSizes(clusterLabels(x,y,z));	  
    if (permNo==1) 
      originalStatistic.Row(contrastNo)=parametricImage.matrix(mask);
    if (isAveraging) {
      sumStatMat.Row(contrastNo)+=parametricImage.matrix(mask);
      sumSampMat.Row(contrastNo)+=SD(parametricImage.matrix(mask),parametricImage.matrix(mask));
    }
  }
}

void ParametricStatistic::store(const Matrix& parametricMatrix, const unsigned long permNo)
{
  maximumDistribution.Column(permNo)=max(parametricMatrix.t()).t();
  if (permNo==1) 
    originalStatistic=parametricMatrix;
  if (storingUncorrected) 
    uncorrectedStatistic += gt(originalStatistic,parametricMatrix);
  if (isAveraging) {
    sumStatMat+=parametricMatrix;
    sumSampMat+=SD(parametricMatrix,parametricMatrix);
  }
  
}

void ParametricStatistic::average(const string filename, const float percentileThreshold,const volume<float>& mask)
{
  if (isAveraging) {
    volume4D<float> temp;
    temp.setmatrix(sumStatMat,mask);
    save_volume4D(temp,filename+"sum");
    temp.setmatrix(sumSampMat,mask);
    save_volume4D(temp,filename+"samp");
    sumStatMat=SD(sumStatMat,sumSampMat);

    if (percentileThreshold>0) {
      temp.setmatrix(sumStatMat,mask);
      float min=temp.percentile(percentileThreshold,mask);
      //cerr << min << " " << percentile((Matrix)tstat_ceav.t(),percentileThreshold*100) << endl;     
      for(int i=1;i<=sumStatMat.Ncols();i++)
	if(sumStatMat(1,i)<min) sumStatMat(1,i)=min;
    }

    temp.setmatrix(sumStatMat,mask);
    save_volume4D(temp,filename+"post");
  }
}

Matrix tfce(const Matrix& tstat, const volume<float>& mask, const float delta, float height_power, float size_power, int connectivity){
  volume4D<float> spatialStatistic;
  spatialStatistic.setmatrix(tstat,mask);
  tfce(spatialStatistic[0],height_power,size_power,connectivity,0,delta);
  return(spatialStatistic.matrix(mask));
}

void clusterStatistic(ParametricStatistic& output, const Matrix& inputStatistic, const volume<float>& mask, const float threshold, const int permutationNo)
{
ColumnVector clusterSizes;
volume4D<float> spatialStatistic;  
   spatialStatistic.setmatrix(inputStatistic,mask);
   spatialStatistic.binarise(threshold);
   volume<int> clusterLabels=connected_components(spatialStatistic[0],clusterSizes,CLUST_CON);
   output.store(clusterLabels,clusterSizes,mask,1,permutationNo);
}

void clusterMassStatistic(ParametricStatistic& output, const Matrix& inputStatistic, const volume<float>& mask, const float threshold, const int permutationNo)
{
ColumnVector clusterSizes;
volume4D<float> spatialStatistic, originalSpatialStatistic;  
   spatialStatistic.setmatrix(inputStatistic,mask);
   originalSpatialStatistic=spatialStatistic;
   spatialStatistic.binarise(threshold);
   volume<int> clusterLabels=connected_components(spatialStatistic[0],clusterSizes,CLUST_CON);
   clusterSizes=0;	
   for(int z=0; z<mask.zsize(); z++)
     for(int y=0; y<mask.ysize(); y++)
       for(int x=0; x<mask.xsize(); x++)
	 if(clusterLabels(x,y,z)>0)
	   clusterSizes(clusterLabels(x,y,z))=clusterSizes(clusterLabels(x,y,z))+originalSpatialStatistic[0](x,y,z);
   output.store(clusterLabels,clusterSizes,mask,1,permutationNo);
}

Matrix tfceStatistic(ParametricStatistic& output, const Matrix& inputStatistic, const volume<float>& mask, float& tfceDelta, const float tfceHeight, const float tfceSize, const int tfceConnectivity, const int permutationNo, const bool isF, const int numContrasts, const vector<float>& dof)
{
   if (permutationNo==1) 
     tfceDelta=inputStatistic.Maximum()/100.0;  // i.e. 100 subdivisions of the max input stat height
   Matrix tstat_ce=tfce(inputStatistic,mask,tfceDelta,tfceHeight,tfceSize,tfceConnectivity);
   if ( isF ) { 
     ColumnVector zstat, dofVector(inputStatistic.AsColumn());
     dofVector=dof[0];
     F2z::ComputeFStats( tstat_ce.AsColumn(), numContrasts, dofVector, zstat);
     tstat_ce=zstat.AsRow();
   }
   output.store(tstat_ce, permutationNo);
   return (tstat_ce.Row(1));
}

void checkInput(const short st,const  Matrix& dm,const  Matrix& tc,const  Matrix& fc){
  if (dm.Nrows()!=st) throw Exception("number of rows in design matrix doesn't match number of \"time points\" in input data!"); 
  if (tc.Ncols()!=dm.Ncols()) throw Exception("number of columns in t-contrast matrix doesn't match number of columns in design matrix!");
  if (fc.Ncols() !=0 && fc.Ncols()!=tc.Nrows()) throw Exception("number of columns in f-contrast matrix doesn't match number of rows in t-contrast matrix!");
}

void Initialise(ranopts& opts, volume<float>& mask, Matrix& datam, Matrix& tc, Matrix& dm, Matrix& fc, Matrix& gp)
{
  if (opts.tfce2D.value()) {
    opts.tfce.set_value("true");
    opts.tfce_height.set_value("2");     
    opts.tfce_size.set_value("1");     
    opts.tfce_connectivity.set_value("26");  
  }
  if ( opts.randomSeed.set()) srand(opts.randomSeed.value());
  if ( opts.randomSeed.set() && opts.verbose.value() ) cout << "Seeding with " << opts.randomSeed.value() << endl;
  if (opts.verbose.value()) cout << "Loading Data: "; 
  short sx=0,sy=0,sz=0,st=0;
  {
      FSLIO *IP1;
      IP1 = NewFslOpen(opts.in_fileroot.value(), "r");
      if (IP1==0) throw Exception(("Failed to read volume "+opts.in_fileroot.value()).c_str()); 
      FslGetDim(IP1,&sx,&sy,&sz,&st);
      FslClose(IP1);
  }

  if(opts.one_samp.value())
  {
    dm.ReSize(st,1);
    dm=1;
    tc.ReSize(1,1);
    tc=1;
  }
  else if ( opts.dm_file.value()=="" || opts.tc_file.value()=="" ) throw Exception("Randomise requires a design matrix and contrast as input");
  if (opts.dm_file.value()!="") dm=read_vest(opts.dm_file.value());
  if (opts.tc_file.value()!="") tc=read_vest(opts.tc_file.value());
  if (opts.fc_file.value()!="") fc=read_vest(opts.fc_file.value());
  if (opts.gp_file.value()!="") gp=read_vest(opts.gp_file.value());
  else {
    gp.ReSize(dm.Nrows(),1);
    gp=1;
  }
  if (!opts.nMultiVariate.value()) checkInput(st,dm,tc,fc);  // should do a different check in the Multivariate case!

  if (opts.parallelData.value()) {
    int fragmentPermutations(300); 
    if (opts.tfce.value()) fragmentPermutations=240;
    if (st>100 || tc.Nrows() > 10 ) fragmentPermutations=200;
    if (opts.voxelwise_ev_numbers.set() && opts.voxelwise_ev_filenames.set()) fragmentPermutations=200;

    cout << opts.n_perm.value() << " " << tc.Nrows() << " " << opts.out_fileroot.value() << " " << fragmentPermutations << endl;
    exit(0);
  }

  if (opts.nMultiVariate.set()) {
    // Read in 4D data - see error message below for format details
    volume4D<float> input;
    read_volume4D(input,opts.in_fileroot.value());
    if ((sy!=opts.nMultiVariate.value()) || (sz!=1) || (st!=dm.Nrows())) { 
      throw Exception("Multi-Variate input data of wrong size!\nSize must be: N x k x 1 x M\n   where N=#vertices, k=#multi-variate dims, M=#subjects");
    }
    // make data matrix of concatenated components, with all of component 1, then all of component 2, etc.
    // this way the first sx values represent a whole mesh/volume of values for a component
    // and the output stats can just be taken as the first set of values (with corresponding row indices)
    datam.ReSize(st,sx*opts.nMultiVariate.value());
    for (int t=1; t<=st; t++) {
      for (int n=1; n<=opts.nMultiVariate.value(); n++) {
	for (int x=1; x<=sx; x++) {
	  datam(t,x+(n-1)*sx)=input(x-1,n-1,0,t-1);
	}
      }
    }
    // dummy mask (if needed) of size of output
    mask.reinitialize(sx,1,1);
    mask=1.0f;
  } else {
    FSLIO *IP1;
    IP1 = NewFslOpen(opts.in_fileroot.value(), "r");
    volume4D<float> data(sx,sy,sz,1);
    float* tbuffer;
    tbuffer = new float[sx*sy*sz];
    for (int t=0;t<st;t++) 
      {
	FslReadBuffer(IP1,tbuffer);
	data[0].reinitialize(sx,sy,sz,tbuffer,false);
	if (t==0)
	  {
	    if (opts.maskname.value()!="") 
	      {
		read_volume(mask,opts.maskname.value());
		if (!samesize(data[0],mask)) throw Exception("Mask dimensions do not match input data dimensions!");
	      }
	    else mask = data[0];
	    set_volume_properties(IP1,mask);
	    mask.binarise(0.0001);  
	  } 
	if (t!=0) datam&= data.matrix(mask);
	else datam=data.matrix(mask);
	if (opts.verbose.value()) cout << "*" << flush; 
      }
    delete [] tbuffer;
    FslClose(IP1);
    if (opts.demean_data.value()) datam=remmean(datam);
  }

  if (opts.verbose.value()) cout << endl;

  if (opts.voxelwise_ev_numbers.set() && opts.voxelwise_ev_filenames.set())
    voxelwiseInput.setup(opts.voxelwise_ev_numbers.value(),opts.voxelwise_ev_filenames.value(),mask,dm.Ncols(),opts.verbose.value());
  
  if (opts.verbose.value()) cout << "Data loaded" << endl;
}

Matrix PermutedDesign(const Matrix& originalDesign,const ColumnVector& permutation,const bool multiply){
  Matrix output=originalDesign;
  for(int row=1;row<=originalDesign.Nrows();row++)
  {
    if (multiply) output.Row(row)=originalDesign.Row(row)*permutation(row);
    else output.Row(row) << originalDesign.Row(int(permutation(row)));
  }
  return output;
}

Matrix calculateTstat(const Matrix& data, const Matrix& model, const Matrix& tc, Matrix& estimate, Matrix& residuals, Matrix& sigmaSquared, const float dof)
{
  Matrix pinvModel(pinv(model)); // inverted model used several times
  estimate=pinvModel*data;
  residuals=data-model*estimate;
  estimate=tc*estimate; //estimate now is cope
  sigmaSquared=sum(SP(residuals,residuals))/dof;
  residuals=diag(tc*pinvModel*pinvModel.t()*tc.t())*sigmaSquared; //residuals now is varcope
  return(SD(estimate,sqrt(residuals)));
}

Matrix calculateFStat(const Matrix& data, const Matrix& model, const Matrix& contrast, const float dof,const int rank)
{ 
  // model is N_subject by N_ev
  // data is N_subject by N_voxels
  Matrix pinvModel(pinv(model)); // inverted model used several times
  Matrix estimate = pinvModel*data;
  Matrix residuals= data-model*estimate;
  residuals = sum(SP(residuals,residuals))/dof; //residuals now hold sigmasquared
  estimate = pinv((contrast*pinvModel).t()).t()*contrast*estimate;
  estimate = sum(SP(estimate,estimate))/rank;
  return(SD(estimate,residuals));
}        

Matrix smoothTstat(const Matrix inputSigmaSquared,const volume<float>& mask,const volume<float>& smoothedMask, const float sigma_mm)
{
  volume4D<float> sigsqvol;
  sigsqvol.setmatrix(inputSigmaSquared,mask);
  sigsqvol[0]=smooth(sigsqvol[0],sigma_mm);
  sigsqvol[0]/=smoothedMask;
  Matrix newSigmaSquared=sigsqvol.matrix(mask);
  return(SD(newSigmaSquared,inputSigmaSquared));
}

void OutputStat(const ParametricStatistic input,const volume<float>& mask, const int nPerms,string statLabel,const string fileRoot,const bool outputText, const bool outputRaw=true)
{ 
volume4D<float> output(mask.xsize(),mask.ysize(),mask.zsize(),1);
long nVoxels(input.originalStatistic.Ncols());
Matrix currentStat(1,nVoxels);
 output.setmatrix(input.originalStatistic.Row(1),mask);
 if (outputRaw) save_volume4D(output,fileRoot+statLabel);
 RowVector distribution = input.maximumDistribution.Row(1);    
 if (outputText)
 {
   ofstream output_file((fileRoot+"_corrp"+statLabel+".txt").c_str());
   output_file << distribution.t();
   output_file.close();
 }
 SortAscending(distribution);
 currentStat=0;
 for(int i=1; i<=nVoxels; i++)
   for(int j=nPerms; j>=1; j--)
     if (input.originalStatistic(1,i)>distribution(j))
     {
       currentStat(1,i) = float(j)/nPerms;
       j=0;
     }
 output.setmatrix(currentStat,mask);
 save_volume4D(output,fileRoot+"_corrp"+statLabel);
 if (input.storingUncorrected) {
   output.setmatrix(input.uncorrectedStatistic.Row(1)/float(nPerms),mask);
   save_volume4D(output,fileRoot+"_p"+statLabel);
 }
}           

float MVGLM_fit(const Matrix& X, const Matrix& Y, const Matrix& contrast, vector<float>& dof)
{
  // adapted by Mark Jenkinson from code in first_utils (by Brian Patenaude)
  // Y is data : N_subject x 3
  // X is design : N_subject x N_ev
  // contrast is : N_con x N_ev
  // g = Y.Ncols = 3
  // p = X.Ncols = N_ev
  // N = Y.Nrows = N_subjects

  // Calculate estimated values
  Matrix Yhat=X*(X.t()*X).i()*X.t()*Y;
  // Calculate R0 (residual) covariance matrix
  Matrix R0=Y-Yhat;
  R0=R0.t()*R0;
  // Calculate R1, the sum-square /cross square product for hypothesis test
  Matrix Yhat1= X*contrast.t()*(contrast*X.t()*X*contrast.t()).i()*contrast*X.t()*Y;
  Matrix R1=Y-Yhat1;
  // Not efficient but easy to convert to other statistics
  R1=R1.t()*R1-R0;
	
  // Calculate Pillai F
  int g=Y.Ncols();
  float F=0, df2=0,df1=0;
  int p=X.Ncols();//number of dependant
  int N=Y.Nrows();//total sampel size
				
  float pillai=(R1*(R1+R0).i()).Trace();
				
  int s=1;
  if (p<(g-1)) {s=p;}
  else {s=g-1;}
  float t=(abs(p-g-1)-1)/2.0;
  float u=(N-g-p-1)/2.0;				
  F=((2*u+s+1)/(2*t+s+1))*(pillai/(s-pillai));
  df1=s*(2*t+s+1);
  df2=s*(2*u+s+1);
  if (dof.size()!=2) dof.resize(2);
  dof[0]=df1;  dof[1]=df2;
  //    cout<<"Pillai F "<<pillai<<" "<<F<<" "<<df1<<" "<<df2<<endl;
  return F;
}


Matrix calculateMultiVariateFStat(const Matrix& model, const Matrix& data, vector<float>& dof, int nMultiVariate)
{ 
  // model is N_subject by N_ev
  // data is N_subject by (N_vertex * 3)
  // dof[0] for numerator (F) and dof[1] for denominator  - but are these ever needed?
  int nvert=data.Ncols()/nMultiVariate;
  int nsubj=data.Nrows();
  int nev=model.Ncols();
  Matrix Fstat(1,nvert), datav(nsubj,3), contrast(nev,nev);
  contrast=IdentityMatrix(nev);  // is this what is needed after initial mangled of design?!?
  for (int n=1; n<=nvert; n++) {
    for (int r=1; r<=nsubj; r++) {
      datav(r,1)=data(r,n);
      datav(r,2)=data(r,n+nvert);
      datav(r,3)=data(r,n+2*nvert);
    }
    Fstat(1,n) = MVGLM_fit(model,datav,contrast,dof);
  }
  return Fstat;
}

Matrix evaluateStatistics(const Matrix& data,const Matrix& model,const Matrix& contrast, Matrix& cope, Matrix& varcope, Matrix& sigmaSquared,vector<float>& dof,const int rank,const int multiVariate, const bool doingF)
{
  if ( doingF ) {
    if ( multiVariate > 1 )
      return calculateMultiVariateFStat(model, data, dof, multiVariate);
    else
      return calculateFStat(data, model, contrast, dof[0], rank);
  } else 
    return calculateTstat(data, model, contrast, cope, varcope, sigmaSquared, dof[0]);
}

void calculatePermutationStatistics(ranopts& opts, const volume<float>& mask, Matrix& datam, Matrix& tc, Matrix& dm,int tstatnum, vector<float>& dof, Permuter& permuter, VoxelwiseDesign& voxelwiseDesign)
{
  int nVoxels=(int)no_mask_voxels(mask);
  int rankF=rank(tc.t());
  if ( opts.isDebugging.value() ) {
    cerr << "Input Design: " << endl << dm << endl;
    cerr << "Input Contrast: " << endl << tc << endl;
    cerr << "Contrast rank: " << rankF << endl;
    cerr << "Dof: " << dof[0] << " original dof: " << ols_dof(dm) << endl;
  }    
  volume4D<float> tstat4D(mask.xsize(),mask.ysize(),mask.zsize(),1);
  float tfce_delta(0), clusterThreshold(0), massThreshold(0);
  if (tstatnum>=0) clusterThreshold=opts.cluster_thresh.value();
  else clusterThreshold=opts.f_thresh.value();
  if (tstatnum>=0) massThreshold=opts.clustermass_thresh.value();
  else massThreshold=opts.fmass_thresh.value();
  bool isNormalising( opts.cluster_norm.value() && tstatnum >=0 ), lowram(false);

  string statLabel;
  if (tstatnum<0) 
    statLabel="_fstat"+num2str(-tstatnum);
  else 
    statLabel="_tstat"+num2str(tstatnum);
  // prepare smoothed mask for use (as a convolution renormaliser) in variance smoothing if required
  volume<float> smoothedMask;
  if(opts.var_sm_sig.value()>0) 
    smoothedMask=smooth(mask,opts.var_sm_sig.value());
  // containers for different inference distribution
  ParametricStatistic clusters, clusterMasses, clusterNormals, clusterEnhanced, clusterEnhancedNormals, voxels;
  Matrix dmperm, tstat(1,nVoxels), cope, varcope, sigmaSquared(1,nVoxels), previousTFCEStat;
  unsigned long nPerms=(unsigned long)permuter.reportRequiredPermutations(opts.verbose.value());

  if ( !((clusterThreshold>0) || (massThreshold>0) || opts.tfce.value() || opts.voxelwiseOutput.value()) )
  {
    cout << "Warning! No output options selected. Outputing raw tstat only" << endl;
    nPerms=1;
  }
  // resize the containers for the relevant inference distributions
  voxels.setup(1,nPerms,nVoxels,false,true);
  if ( clusterThreshold >0 )  
    clusters.setup(1,nPerms,nVoxels,isNormalising);
  if ( massThreshold>0 ) 
    clusterMasses.setup(1,nPerms,nVoxels,false);
  if ( clusters.isAveraging ) 
    clusterNormals.setup(1,nPerms,nVoxels,false);
  if ( opts.tfce.value() )    
    clusterEnhanced.setup(1,nPerms,nVoxels,isNormalising,true);
  if ( clusterEnhanced.isAveraging ) { 
    clusterEnhancedNormals.setup(1,nPerms,nVoxels,false);
    try { previousTFCEStat.ReSize(nPerms,clusterEnhanced.sumStatMat.Ncols());} //between 5e17 - 5e18 values for a 2gb machine
    catch (...) {cerr << "using lowram" << endl; lowram=true;}         
  }
  
  for(unsigned long perm=1; perm<=nPerms; perm++) {

    ColumnVector permvec = permuter.nextPermutation(perm,opts.verbose.value(), isNormalising || opts.outputText.value());   
    dmperm=PermutedDesign(dm,permvec,permuter.isFlipping);

    if (voxelwiseDesign.isSet)
      for(int voxel=1;voxel<=datam.Ncols();voxel++)
	{
	Matrix dmtemp(voxelwiseDesign.adjustDesign(dm,voxel)), sigmaTemp(1,1);
	dof[0]=ols_dof(dmtemp); 
	if (opts.demean_data.value()) dof[0]--;
	dmperm=PermutedDesign(dmtemp,permvec,permuter.isFlipping);
	tstat.Column(voxel)=evaluateStatistics(datam.Column(voxel), dmperm, tc, cope, varcope, sigmaTemp, dof, rankF, opts.nMultiVariate.value(), (tstatnum < 0) );
	sigmaSquared.Column(voxel)=sigmaTemp;
      }
    else 
      tstat=evaluateStatistics(datam, dmperm, tc, cope, varcope, sigmaSquared, dof, rankF, opts.nMultiVariate.value(), (tstatnum < 0) );
 
    if( opts.var_sm_sig.value()>0 && tstatnum > 0 ) 
      tstat=SD(tstat,sqrt(smoothTstat(sigmaSquared,mask,smoothedMask,opts.var_sm_sig.value())));
    if ( opts.isDebugging.value() ) 
      cerr << "statistic Maximum: " << tstat.Maximum() << endl;
    voxels.store(tstat,perm);
    if (opts.output_permstat.value()) {
      tstat4D.setmatrix(tstat,mask);
      save_volume4D(tstat4D,opts.out_fileroot.value()+"_rawstat" + statLabel + "_" + ((num2str(perm)).insert(0,"00000")).erase(0,num2str(perm).length()));
    }
    if (opts.tfce.value())
    {
      Matrix tfceOutput=tfceStatistic(clusterEnhanced,tstat,mask,tfce_delta,opts.tfce_height.value(),opts.tfce_size.value(),opts.tfce_connectivity.value(),perm,(tstatnum<0),tc.Nrows(),dof);
      if(!lowram && clusterEnhanced.isAveraging ) previousTFCEStat.Row(perm)=tfceOutput.Row(1);
    }
    if ( clusterThreshold > 0 ) 
      clusterStatistic(clusters,tstat,mask,clusterThreshold,perm);
    
    if ( massThreshold > 0 ) 
      clusterMassStatistic(clusterMasses,tstat,mask,massThreshold,perm);
  }
  //End of Permutations
    
  //Rerun perms for clusternorm
  if ( isNormalising )
  { 
    volume4D<float> temp4D;
    if ( clusters.isAveraging ) {
      clusters.average(opts.out_fileroot.value()+statLabel+"_clusternorm",0,mask);
      temp4D.setmatrix(clusters.sumStatMat,mask);
    }
    if (clusterEnhanced.isAveraging)
      clusterEnhanced.average(opts.out_fileroot.value()+statLabel+"_tfcenorm",0.02,mask);

    for(unsigned long perm=1; perm<=nPerms; perm++)
    {
      if (opts.verbose.value()) cout << "Starting second-pass " << perm << endl;
      if ( clusters.isAveraging || ( clusterEnhanced.isAveraging && lowram ) ) //Regenerate stats
      { 
	ColumnVector permvec=permuter.returnPreviousTruePermutation(perm);
	dmperm=PermutedDesign(dm,permvec,permuter.isFlipping);
	tstat=calculateTstat(datam,dmperm,tc,cope,varcope,sigmaSquared,dof[0]);    
      }
      if ( clusters.isAveraging )
      { 
	ColumnVector clustersizes;
	tstat4D.setmatrix(tstat,mask);
	tstat4D.binarise(clusterThreshold);
	volume<int> clusterLabels=connected_components(tstat4D[0],clustersizes,CLUST_CON);
	ColumnVector entries,cluster(clustersizes.Nrows());
	cluster=0;
	entries=cluster;
	for(int z=0; z<mask.zsize(); z++)
	  for(int y=0; y<mask.ysize(); y++)
	    for(int x=0; x<mask.xsize(); x++)
	      if (clusterLabels(x,y,z))
	      {
		cluster(clusterLabels(x,y,z))+=temp4D(x,y,z,0);
		entries(clusterLabels(x,y,z))++;
	      }
	clustersizes=SD(clustersizes,SD(cluster,entries));
	clusterNormals.store(clusterLabels,clustersizes,mask,1,perm);
      }
      if ( clusterEnhanced.isAveraging )
      {
	if (!lowram) tstat=previousTFCEStat.Row(perm);
	else tstat=tfce(tstat,mask,tfce_delta,opts.tfce_height.value(),opts.tfce_size.value(),opts.tfce_connectivity.value());
	tstat=SD(tstat,clusterEnhanced.sumStatMat); 
	clusterEnhancedNormals.store(tstat,perm);
      }
    }
  }
   
  //OUTPUT Routines 
  tstat4D.setmatrix(voxels.originalStatistic.Row(1),mask);
  save_volume4D(tstat4D,opts.out_fileroot.value()+statLabel);
  if ( opts.voxelwiseOutput.value() ) OutputStat(voxels,mask,nPerms,statLabel,opts.out_fileroot.value()+"_vox",opts.outputText.value(),false);
  if ( clusterThreshold > 0 ) OutputStat(clusters,mask,nPerms,statLabel,opts.out_fileroot.value()+"_clustere",opts.outputText.value(),opts.outputRaw.value());
  if ( massThreshold > 0 )    OutputStat(clusterMasses,mask,nPerms,statLabel,opts.out_fileroot.value()+"_clusterm",opts.outputText.value(),opts.outputRaw.value());
  if ( clusters.isAveraging ) OutputStat(clusterNormals,mask,nPerms,statLabel,opts.out_fileroot.value()+"_clustern",opts.outputText.value(),opts.outputRaw.value());  
  if ( opts.tfce.value() )    OutputStat(clusterEnhanced,mask,nPerms,statLabel,opts.out_fileroot.value()+"_tfce",opts.outputText.value(),opts.outputRaw.value());
  if ( clusterEnhanced.isAveraging ) OutputStat(clusterEnhancedNormals,mask,nPerms,statLabel,opts.out_fileroot.value()+"_tfcen",opts.outputText.value(),opts.outputRaw.value());
  if (opts.outputText.value()) 
    permuter.writePermutationHistory(opts.out_fileroot.value()+"_perm"+statLabel+".txt");  
}

bool convertContrast(const Matrix& inputModel,const Matrix& inputContrast,const Matrix& inputData,Matrix& outputModel,Matrix& outputContrast, Matrix& outputData, const int mode)
{
    int r(inputContrast.Nrows()),p(inputContrast.Ncols());
    Matrix tmp=(IdentityMatrix(p)-inputContrast.t()*pinv(inputContrast.t()));
    Matrix U,V;
    DiagonalMatrix D;
    SVD(tmp, D, U, V);
    Matrix c2=U.Columns(1,p-r);
    c2=c2.t();
    Matrix C = inputContrast & c2;
    Matrix W=inputModel*C.i();
    Matrix W1=W.Columns(1,r);
    Matrix W2=W.Columns(r+1,W.Ncols());

    bool confoundsExist( W2.Ncols() > 0 ); 
    if ( confoundsExist && mode < 2 ) 
      outputData=(IdentityMatrix(W2.Nrows())-W2*pinv(W2))*inputData;
    else 
      outputData=inputData;
    
    if ( mode == 0 ) { //Kennedy  Regress Y_a on X_a
      outputModel=W1;
      outputContrast=IdentityMatrix(r);
      if ( confoundsExist ) 
	outputModel=W1-W2*pinv(W2)*W1;
    }
    if ( mode == 1 || mode == 2 ) { //Regress Y_a (Freedman_Lane) or Y (No unconfounding) on X | Z )
      outputModel=W1;
      outputContrast=IdentityMatrix(r);
      if ( confoundsExist ) { 
	Matrix nuisanceContrast(r,W2.Ncols());
	nuisanceContrast=0;
	outputContrast = outputContrast | nuisanceContrast;
	outputModel = outputModel | W2;
      }             
    }
    return(confoundsExist);
}


void analyseContrast(const Matrix& inputContrast, const Matrix& dm, const Matrix& datam, const volume<float>& mask,const Matrix& gp,const int& contrastNo,ranopts& opts)
{
  //-ve num for f-stat contrast
  Matrix NewModel,NewCon,NewDataM;
  VoxelwiseDesign fullVoxelwiseDesign;
  Permuter permuter;
  bool hasConfounds(false);
  
  if (voxelwiseInput.isSet) {
    NewDataM=datam;
    vector<Matrix> effectiveVoxelwiseRegressors;
    effectiveVoxelwiseRegressors.resize(inputContrast.Nrows());
    for (unsigned int currentEV=0;currentEV<effectiveVoxelwiseRegressors.size();currentEV++) {
      effectiveVoxelwiseRegressors.at(currentEV)=datam;
      effectiveVoxelwiseRegressors.at(currentEV)=0;
    }
    for(int voxel=1;voxel<=datam.Ncols();voxel++)
    {
      Matrix tempDesign(voxelwiseInput.adjustDesign(dm,voxel)),tempData;
      hasConfounds=convertContrast(tempDesign,inputContrast,datam.Column(voxel),NewModel,NewCon,tempData,opts.confoundMethod.value());
      NewDataM.Column(voxel)=tempData;
      for (unsigned int currentEV=0;currentEV<effectiveVoxelwiseRegressors.size();currentEV++) 
	effectiveVoxelwiseRegressors.at(currentEV).Column(voxel)=NewModel.Column(currentEV+1);
    }
    fullVoxelwiseDesign.location.clear();
    fullVoxelwiseDesign.location.resize(inputContrast.Nrows());
    for (unsigned int currentEV=0;currentEV<effectiveVoxelwiseRegressors.size();currentEV++) 
      fullVoxelwiseDesign.location.at(currentEV)=currentEV+1;
    fullVoxelwiseDesign.EV.clear();
    fullVoxelwiseDesign.EV=effectiveVoxelwiseRegressors;
    fullVoxelwiseDesign.isSet=true;
  }
  else hasConfounds=convertContrast(dm,inputContrast,datam,NewModel,NewCon,NewDataM,opts.confoundMethod.value());

  if ( opts.isDebugging.value() ) {
    if ( hasConfounds ) 
      cerr << "Confounds detected." << endl;
    else 
      cerr << "No confounds detected." << endl;
  }

  bool oneRegressor( inputContrast.SumAbsoluteValue() == inputContrast.MaximumAbsoluteValue() );
  permuter.createPermutationGroups(remmean(dm)*inputContrast.t(),gp,(contrastNo>0 && oneRegressor),opts.n_perm.value(),opts.detectNullSubjects.value(),opts.isDebugging.value()); 
  if(permuter.isFlipping) cout << "One-sample design detected; sign-flipping instead of permuting." << endl;
  if(opts.verbose.value() || opts.how_many_perms.value()) 
  {
    if(permuter.isFlipping) cout << permuter.uniquePermutations[0] << " sign-flips required for exhaustive test";
    else cout << permuter.uniquePermutations[0] << " permutations required for exhaustive test";
    if (contrastNo>0)  cout << " of t-test " << contrastNo << endl;
    if (contrastNo==0) cout << " of all t-tests " << endl;
    if (contrastNo<0)  cout << " of f-test " << abs(contrastNo) << endl;
    if(opts.how_many_perms.value()) return;
  }  
  vector<float> dof(1,ols_dof(dm)-(int)opts.demean_data.value()); 
  calculatePermutationStatistics(opts,mask,NewDataM,NewCon,NewModel,contrastNo,dof,permuter,fullVoxelwiseDesign); 
}


void analyseFContrast(Matrix& fc,Matrix& tc,Matrix& model,Matrix& data,volume<float>& mask,Matrix& gp,ranopts& opts)
{   
   for( int fstat=1; fstat<=fc.Nrows() ; fstat++ ) 
   {
      Matrix fullFContrast(0,tc.Ncols());
      for (int tcon=1; tcon<=fc.Ncols() ; tcon++ )
	if (fc(fstat,tcon)==1) fullFContrast &= tc.Row(tcon);
      analyseContrast(fullFContrast,model,data,mask,gp,-fstat,opts);
   }
}

int main(int argc,char *argv[]) {
  Log& logger = LogSingleton::getInstance();
  ranopts& opts = ranopts::getInstance();
  opts.parse_command_line(argc,argv,logger);
  if (opts.parallelData.value()) opts.verbose.set_value("false");
  Matrix model, Tcontrasts, Fcontrasts, data, blockLabels;
  volume<float> mask;
  if ( opts.verbose.value() ) { 
    cout << "randomise options: ";
    for (int i=1;i<argc;i++) cout << argv[i] << " ";
    cout << endl;
  }
  try { 
    Initialise(opts,mask,data,Tcontrasts,model,Fcontrasts,blockLabels); 
    bool needsDemean=true;
    for (int i=1;i<=model.Ncols();i++) if ( fabs( (model.Column(i)).Sum() ) > 0.0001 ) needsDemean=false;
    if (needsDemean && !opts.demean_data.value()) cerr << "Warning: All design columns have zero mean - consider using the -D option to demean your data" << endl;
    if (!needsDemean && opts.demean_data.value()) cerr << "Warning: You have demeaned your data, but at least one design column has non-zero mean" << endl;
    if(opts.fc_file.value()!="") analyseFContrast(Fcontrasts,Tcontrasts,model,data,mask,blockLabels,opts); 
    for (int tstat=1; tstat<=Tcontrasts.Nrows() && !opts.doFOnly.value(); tstat++ )  analyseContrast(Tcontrasts.Row(tstat),model,data,mask,blockLabels,tstat,opts); 
  }
  catch(Exception& e) 
  { 
    cerr << "ERROR: Program failed" <<  e.what() << endl << endl << "Exiting" << endl; 
    return 1;
  }
  catch(...) 
  { 
    cerr << "ERROR: Program failed, unknown exception" << endl << endl << "Exiting" << endl; 
    return 1;
  }
  if ( opts.verbose.value() ) 
    cout << "Finished, exiting." << endl;
  return 0;
}

//Permuter Class
void Permuter::createPermutationGroups(const Matrix& design, Matrix groups,const bool oneNonZeroContrast,const long requiredPermutations, const bool detectingNullElements, const bool outputDebug)
{
  nGroups=int(groups.Maximum())+1;
  nSubjects=design.Nrows();
  ColumnVector labels = createDesignLabels(design);
  isFlipping = ( (labels.Maximum()==1) && oneNonZeroContrast );

  if (detectingNullElements)
    for(int row=1;row<=nSubjects;row++)
      if (abs(design.Row(row).Sum())<1e-10 && !isFlipping) //original just checked if Sum()==0
	groups(row,1)=0;

  originalLocations.resize(nGroups);
  permutedLabels.resize(nGroups);
  originalLabels.resize(nGroups);
  for(int group=0;group<=groups.Maximum();group++)
  {
     int active=0;
     for(int row=1;row<=nSubjects;row++)
       if(groups(row,1)==group) active++;
     originalLocations[group].ReSize(active);
     permutedLabels[group].ReSize(active);
     for(int row=nSubjects;row>=1;row--) //Now work backwards to fill in the row numbers
       if(groups(row,1)==group) originalLocations[group](active--)=row;
  }

  initialisePermutationGroups(labels,requiredPermutations);
  if (outputDebug) 
    cerr << "Subject | Design | group | label" << endl << ( truePermutation | design | groups | labels ) << endl;
}

ColumnVector Permuter::returnPreviousTruePermutation(const long permutationNumber)
{
  if (isFlipping) 
    return previousPermutations[permutationNumber-1];
  else {    
    ColumnVector permvec(unpermutedVector);
    for(long perm=1; perm<=permutationNumber; perm++) 
      createTruePermutation(previousPermutations[perm-1],previousPermutations[perm-1-int(perm!=1)],permvec);  
    return permvec;
  }
}

void Permuter::initialisePermutationGroups(const ColumnVector& designLabels,const long requiredPermutations)
{
  truePermutation.ReSize(nSubjects);
  for(int i=1;i<=nSubjects;i++) truePermutation(i)=i;
  if (isFlipping) truePermutation=1;
  unpermutedVector=truePermutation;
  uniquePermutations.resize(nGroups);
  uniquePermutations[0]=1;
  for(int group=0;group<nGroups;group++)
  { 
    for(int row=1;row<=permutedLabels[group].Nrows();row++) 
      permutedLabels[group](row)=designLabels((int)originalLocations[group](row));
    if (group>0) uniquePermutations[group]=computeUniquePermutations(permutedLabels[group],isFlipping);
    uniquePermutations[0]*=uniquePermutations[group];
    originalLabels[group]=permutedLabels[group];
  }
  isRandom=!(requiredPermutations==0 || requiredPermutations>=uniquePermutations[0]);
  if (isRandom) finalPermutation=requiredPermutations;
  else finalPermutation=uniquePermutations[0];
  previousPermutations.reserve((long)finalPermutation);
}

ColumnVector Permuter::permutationVector()
{
ColumnVector newvec(nSubjects); 
   for(int group=0;group<nGroups;group++)
     for(int row=1;row<=permutedLabels[group].Nrows();row++) 
       newvec((int)originalLocations[group](row))=permutedLabels[group](row);
   return newvec;
}

void Permuter::createTruePermutation(const ColumnVector& newLabels,ColumnVector copyOldLabels,ColumnVector& permvec)
{
  if (isFlipping) permvec=permutationVector();
  else
  {
    for(int k=1;k<=newLabels.Nrows();k++)	       
      if(newLabels(k)!=copyOldLabels(k))
        for(int l=1;l<=newLabels.Nrows();l++) 
	  if(newLabels(l)!=copyOldLabels(l) && copyOldLabels(l)==newLabels(k) )
 	   {
	     swap(permvec(l),permvec(k));
	     swap(copyOldLabels(l),copyOldLabels(k));
           }
  }
}

ColumnVector Permuter::nextPermutation(const long permutationNumber)
{
  for(int group=1;group<nGroups;group++)
  {
      if(isFlipping) nextFlip(permutedLabels[group]);
      else nextShuffle(permutedLabels[group]);
      if (!isRandom && permutedLabels[group]!=originalLabels[group] ) //Move to next group as either "reset" has occurred or we are in random mode
	break;
  }
  return(permutationVector());
}

ColumnVector Permuter::nextPermutation(const long permutationNumber, const bool printStatus, const bool isStoring)
{
  if (permutationNumber!=1 && printStatus) cout << "Starting permutation " << permutationNumber << endl;
  else if (printStatus) cout << "Starting permutation " << permutationNumber << " (Unpermuted data)" << endl;

  ColumnVector currentLabels=permutationVector();
  ColumnVector newPermutation;
  do
  {
    if (permutationNumber!=1) newPermutation=nextPermutation(permutationNumber);
  } while(isRandom && isPreviousPermutation(newPermutation));
  if(isStoring || isRandom) previousPermutations.push_back(permutationVector());
  createTruePermutation(permutationVector(),currentLabels,truePermutation);
  return(truePermutation);
}

bool Permuter::isPreviousPermutation(const ColumnVector& newPermutation){
  for(int i=previousPermutations.size()-1; i>=0; i--)
    if(newPermutation==previousPermutations[i]) return true;
  return false;
  }

void Permuter::nextShuffle(ColumnVector& perm){
   vector<int> temp;
   for (int i=1;i<=perm.Nrows();i++) temp.push_back((int)perm(i));
   if (isRandom) random_shuffle(temp.begin(),temp.end());
   else next_permutation(temp.begin(),temp.end());
   for (int i=1;i<=perm.Nrows();i++) perm(i)=temp[i-1];
}

void Permuter::nextFlip(ColumnVector& flip){
       
  if (isRandom)
  {
    for(int i=1;i<=flip.Nrows();i++)
    {
      float tmp=(float)rand()/RAND_MAX;
      if(tmp > 0.5) flip(i)=1;
      else  flip(i)=-1;
    }     
  }
  else for (int n=flip.Nrows();n>0;n--)
    if(flip(n)==1)
    {
      flip(n)=-1;
      if (n<flip.Nrows()) flip.Rows(n+1,flip.Nrows())=1;
      return;
    } 
}

double Permuter::computeUniquePermutations(const ColumnVector& labels,const bool calculateFlips){
  if (calculateFlips) return std::pow(2.0,labels.Nrows());
  ColumnVector label_counts((int)labels.MaximumAbsoluteValue());
  label_counts=0;
  for(int i=1; i<=labels.Nrows(); i++) label_counts(int(labels(i)))++;
  double yo = lgam(labels.Nrows()+1);
  for(int i=1; i<=labels.MaximumAbsoluteValue(); i++)
    yo -= lgam(label_counts(i)+1);
  return std::floor(exp(yo)+0.5);
}

ColumnVector Permuter::createDesignLabels(const Matrix& design){
  ColumnVector designLabels(design.Nrows());
  vector<RowVector> knownLabels;
  for(int i=1;i<=design.Nrows();i++){
    bool wasExistingLabel=false;
    for(unsigned int l=0;l<knownLabels.size();l++){
      if(design.Row(i)==knownLabels[l]){
	designLabels(i)=l+1;
	wasExistingLabel=true;
      }
    }
    if(!wasExistingLabel){
      knownLabels.push_back(design.Row(i));
      designLabels(i)=knownLabels.size();
    }
  }
  return(designLabels);
}

double Permuter::reportRequiredPermutations(const bool printToScreen)
{
  if (printToScreen)
  {
    if(isRandom) cout<<"Doing " << finalPermutation << " random permutations"<<endl;
    else cout<<"Doing all "<< finalPermutation <<" unique permutations"<<endl;
  }
  return(finalPermutation);
}

void Permuter::writePermutationHistory(const string& fileName)
{
  ofstream output_file(fileName.c_str());
  for(unsigned long perm=1; perm<=finalPermutation; perm++) {
    //output_file << previousPermutations[perm-1].t();
    output_file << returnPreviousTruePermutation(perm).t();    
  }
  output_file.close();
}

Permuter::Permuter()
{
}

Permuter::~Permuter()
{
}
