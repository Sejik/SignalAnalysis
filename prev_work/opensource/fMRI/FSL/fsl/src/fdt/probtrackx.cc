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
#include "utils/log.h"
#include "meshclass/meshclass.h"
#include "probtrackx.h"


using namespace std;
using namespace NEWIMAGE;
using namespace TRACT;
using namespace Utilities;
using namespace PARTICLE;
using namespace mesh;
//using namespace NEWMAT;
//////////////////////////
/////////////////////////



int main ( int argc, char **argv ){
  probtrackxOptions& opts =probtrackxOptions::getInstance();
  Log& logger = LogSingleton::getInstance();
  opts.parse_command_line(argc,argv,logger);
  srand(opts.rseed.value());
  
  
  if(opts.verbose.value()>0){
    opts.status();
  }
  if(opts.mode.value()=="simple"){
    track();
    return 0;
  }

  string tmpin=opts.seedfile.value();
  if(fsl_imageexists(opts.seedfile.value())){ 
    if(fsl_imageexists(opts.mask2.value())){ twomasks();}
    else{ seedmask(); }
  }
  else if(opts.network.value()){ nmasks(); }
  else if(opts.meshfile.value()!=""){meshmask();}
  else {cout << "exit without doing anything"<<endl;return 0;};

  //else if(fopen(tmpin.c_str(),"r")!=NULL ){ track();}

  // else if(opts.mode.value()=="seeds_to_targets")
  //     seeds_to_targets();
  //   else if(opts.mode.value()=="seedmask")
  //     alltracts();
  //   else if(opts.mode.value()=="twomasks_symm")
  //     twomasks_symm();
  //   else if(opts.mode.value()=="waypoints")
  //     waypoints();
  //   else if(opts.mode.value()=="matrix1")
  //     matrix1();
  //   else if(opts.mode.value()=="matrix2"){
  //     if(opts.meshfile.value()=="")
  //       matrix2();
  //     else
  //       mesh_matrix2();
  //   }
  //   else if(opts.mode.value()=="maskmatrix")
  //     maskmatrix();
  //   else if(opts.mode.value()=="meshlengths")
  //     mesh_lengths();
  //else{
  //   cout <<"Invalid setting for option  mode -- try setting mode=help"<<endl;
  //}
  
  return 0;
}















