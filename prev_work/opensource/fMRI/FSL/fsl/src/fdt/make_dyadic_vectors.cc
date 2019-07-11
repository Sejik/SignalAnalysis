/*  Copyright (C) 2004 University of Oxford  */

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

#include <iostream>
#include <fstream>
#include "newimage/newimageall.h"
#include <vector>
using namespace std;
using namespace NEWIMAGE;

int main ( int argc, char **argv ){
  if(argc<4){
    cerr<<"usage: make_dyadic_vectors <theta_vol> <phi_vol> [mask] <output>"<<endl;
    cerr<<"[mask] is optional"<<endl;
    exit(1);
  }

  volume4D<float> ths,phs;
  volumeinfo tempinfo;
  read_volume4D(ths,argv[1],tempinfo);
  read_volume4D(phs,argv[2]);
  volume<float> mask;
  string oname;
  if(argc==5){
    oname=argv[4];
    read_volume(mask,argv[3]);
  }
  else{
    mask=ths[0]*0+1;
    oname=argv[3];
  }
  volume4D<float> dyadic_vecs(ths.xsize(),ths.ysize(),ths.zsize(),3);
  dyadic_vecs=0;
  copybasicproperties(ths[0],dyadic_vecs[0]);
  SymmetricMatrix dyad(3);dyad=0;
  ColumnVector dir(3);
  
  DiagonalMatrix dyad_D; //eigenvalues
  Matrix dyad_V; //eigenvectors

  for(int k=ths.minz();k<=ths.maxz();k++){
    for(int j=ths.miny();j<=ths.maxy();j++){
      for(int i=ths.minx();i<=ths.maxx();i++){
	if(mask(i,j,k)>0){
	  dyad=0;
	  for(int s=ths.mint();s<=ths.maxt();s++){		   
	  
	    float th=ths(i,j,k,s);
	    float ph=phs(i,j,k,s);
	    dir(1)=sin(th)*cos(ph);
	    dir(2)=sin(th)*sin(ph);
	    dir(3)=cos(th);
	    dyad << dyad+dir*dir.t();
	  }
	  
	  EigenValues(dyad,dyad_D,dyad_V);
	  int maxeig;
	  if(dyad_D(1)>dyad_D(2)){
	    if(dyad_D(1)>dyad_D(3)) maxeig=1;
	    else maxeig=3;
	  }
	  else{
	    if(dyad_D(2)>dyad_D(3)) maxeig=2;
	    else maxeig=3;
	  }
	  dyadic_vecs(i,j,k,0)=dyad_V(1,maxeig);
	  dyadic_vecs(i,j,k,1)=dyad_V(2,maxeig);
	  dyadic_vecs(i,j,k,2)=dyad_V(3,maxeig);
	}
	else{
	  dyadic_vecs(i,j,k,0)=0;
	  dyadic_vecs(i,j,k,1)=0;
	  dyadic_vecs(i,j,k,2)=0;
	}
      }
    }
  }
  
  save_volume4D(dyadic_vecs,oname,tempinfo);
}









