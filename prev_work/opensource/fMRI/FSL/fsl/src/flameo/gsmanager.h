/*  gsmanager.h

    Mark Woolrich, Tim Behrens - FMRIB Image Analysis Group

    Copyright (C) 2002 University of Oxford  */

/*  COPYRIGHT  */

#if !defined(gsmanager_h)
#define gsmanager_h

#include <iostream>
#include <fstream>
#include <string>
#include <vector>

#include "gsoptions.h"
#include "newimage/newimageall.h"
#include "design.h"

using namespace NEWIMAGE;
using namespace MISCMATHS;

namespace Gs {
    
  // Give this class a file containing
  class Gsmanager
    {
    public:

      // constructor
      Gsmanager() : 
	opts(GsOptions::getInstance()),
	nmaskvoxels(0)
	{
	}

      // load data from file in from file and set up starting values
      void setup();

      // initialise
      void initialise();

      void run();

      // saves results in logging directory
      void save();

      // Destructor
      virtual ~Gsmanager() {}
 
    private:

      const Gsmanager& operator=(Gsmanager& par);     
      Gsmanager(Gsmanager& des);      

      void multitfit(const Matrix& x, ColumnVector& m, SymmetricMatrix& covar, float& v, bool fixmean=false) const;

      float log_likelihood(float beta, const ColumnVector& gam, const ColumnVector& y, const Matrix& z, const ColumnVector& S);
      float log_likelihood_outlier(float beta, float beta_outlier, const ColumnVector& gam, const ColumnVector& y, const Matrix& z, const ColumnVector& S, float global_prob_outlier);

      float marg_posterior_energy(float x, const ColumnVector& y, const Matrix& z, const ColumnVector& S);
      float marg_posterior_energy_outlier(float logbeta, float logbeta_outlier, const ColumnVector& y, const Matrix& z, const ColumnVector& S, const ColumnVector& prob_outlier);

      float solveforbeta(const ColumnVector& y, const Matrix& z, const ColumnVector& S);

      bool pass_through_to_mcmc(float zlowerthresh, float zupperthresh, int px, int py, int pz);

      // functions to calc contrasts
      void ols_contrasts(const ColumnVector& gammean, const SymmetricMatrix& gamS, int px, int py, int pz);
      void fe_contrasts(const ColumnVector& gammean, const SymmetricMatrix& gamS, int px, int py, int pz);
      void flame1_contrasts(const ColumnVector& gammean, const SymmetricMatrix& gamS, int px, int py, int pz);
      void flame1_contrasts_with_outliers(const ColumnVector& mn, const SymmetricMatrix& covariance, int px, int py, int pz);
      void flame2_contrasts(const Matrix& gamsamples, int px, int py, int pz);

      void t_ols_contrast(const ColumnVector& gammean, const SymmetricMatrix& gamS, const RowVector& tcontrast, float& cope, float& varcope, float& t, float& dof, float& z, int px, int py, int pz);	
      void f_ols_contrast(const ColumnVector& gammean, const SymmetricMatrix& gamS, const Matrix& fcontrast, float& f, float& dof1, float& dof2, float& z, int px, int py, int pz);
	
	
      void t_mcmc_contrast(const Matrix& gamsamples, const RowVector& tcontrast, float& cope, float& varcope, float& t, float& dof, float& z, int px, int py, int pz);
      void f_mcmc_contrast(const Matrix& gamsamples, const Matrix& fcontrast, float& f, float& dof1, float& dof2, float& z, int px, int py, int pz);


      // voxelwise functions to perform the different inference approaches
      void fixed_effects_onvoxel(const ColumnVector& Y, const Matrix& z, const ColumnVector& S, ColumnVector& gam, SymmetricMatrix& gamcovariance);
      void flame_stage1_onvoxel(const vector<ColumnVector>& Yg, const ColumnVector& Y, const vector<Matrix>& zg, const Matrix& z, const vector<ColumnVector>& Sg, const ColumnVector& S, ColumnVector& beta, ColumnVector& gam, SymmetricMatrix& gamcovariance, float& logpost, int& nparams, int px, int py, int pz);
      void flame_stage1_onvoxel_inferoutliers(const vector<ColumnVector>& Yg, const ColumnVector& Y, const vector<Matrix>& zg, const Matrix& z, const vector<ColumnVector>& Sg, const ColumnVector& S, ColumnVector& beta, ColumnVector& gam, SymmetricMatrix& gamcovariance, ColumnVector& global_prob_outlier, vector<ColumnVector>& prob_outlier_g,  ColumnVector& prob_outlier, ColumnVector& beta_outlier, float& logpost, int& nparams, bool& no_outliers, int px, int py, int pz);
      void flame_stage1_inferoutliers();
      void init_flame_stage1_inferoutliers();

      // functions to perform the different inference approaches
      void fixed_effects(); 
      void ols(); 
      void flame_stage1();
      void flame_stage2();
      void do_kmeans(const Matrix& data,vector<int>& z,const int k,Matrix& means);
      void randomise(vector< pair<float,int> >& r);
      vector< pair<float,int> > randomise(const int n);

      void regularise_flame2_contrasts();
     
      volume<float> mcmc_mask;
     
      // intermediates
      Design design;

      vector<volume<float> > beta_b;
      vector<volume<float> > beta_c;
      vector<volume<float> > beta_mean;
      vector<volume<float> > beta_outlier_mean;
      vector<volume<float> > global_prob_outlier_mean;
      vector<volume4D<float> > prob_outlier_mean;

      volume4D<float> cov_pes;

      // outputs

      vector<volume<float> > pes;
      vector<volume<float> > ts;
      vector<volume<float> > tdofs;
      vector<volume<float> > zts;
      vector<volume<float> > zflame1upperts;
      vector<volume<float> > zflame1lowerts;
      vector<volume<float> > tcopes;
      vector<volume<float> > tvarcopes;      
      vector<volume<float> > fs;
      vector<volume<float> > fdof1s;
      vector<volume<float> > fdof2s;
      vector<volume<float> > zfs;
      vector<volume<float> > zflame1upperfs;
      vector<volume<float> > zflame1lowerfs;

      // intermediates
      int ngs;
      int nevs;
      int ntpts;
      int xsize;
      int ysize;
      int zsize;

      GsOptions& opts;

      int nmaskvoxels;

      bool dofpassedin;
    };

  bool compare(const pair<float,int> &r1,const pair<float,int> &r2);

}   
#endif







