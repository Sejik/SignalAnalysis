//     fslmerge.cc concatenate AVW files into a single output
//     Steve Smith, David Flitney, Stuart Clare and Matthew Webster, FMRIB Image Analysis Group
//     Copyright (C) 2000-2005 University of Oxford  
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

#include "newimage/newimageall.h"
#include "newimage/fmribmain.h"

using namespace NEWIMAGE;

void print_usage(const string& progname) 
{
  cout << endl;
  cout << "Usage: fslmerge <-x/y/z/t/a> <output> <file1 file2 .......>" << endl;
  cout << "     -t : concatenate images in time" << endl;
  cout << "     -x : concatenate images in the x direction"  << endl;
  cout << "     -y : concatenate images in the y direction"  << endl;
  cout << "     -z : concatenate images in the z direction" << endl;
  cout << "     -a : auto-choose: single slices -> volume, volumes -> 4D (time series)"  << endl;
}

template <class T>
int fmrib_main(int argc, char *argv[])
{
  volume4D<T> input_volume;
  volumeinfo vinfo;
  int i,j,k,t,vol,direction,dimerror=0,xdimtot=0,ydimtot=0,zdimtot=0,tdimtot=0,xoffset=0,yoffset=0,zoffset=0,toffset=0;
 
  if (!strcmp(argv[1], "-t"))       direction=0;
  else if (!strcmp(argv[1], "-x"))  direction=1;
  else if (!strcmp(argv[1], "-y"))  direction=2;
  else if (!strcmp(argv[1], "-z"))  direction=3; 
  else if (!strcmp(argv[1], "-a"))  direction=4;
  else 
  {
    print_usage(string(argv[0]));
    return(1);
  }
  read_volume4D_hdr_only(input_volume,string(argv[3]),vinfo);
  xdimtot=input_volume.xsize(); 
  ydimtot=input_volume.ysize(); 
  zdimtot=input_volume.zsize();
  tdimtot=input_volume.tsize();
  if(direction==4)
  {
    if( (zdimtot<2) && (tdimtot<2) ) direction=3;
     else direction=0;
  }
  input_volume.destroy();    //Remove when new newimage comes out

  for(vol = 4; vol < argc; vol++)
  {        
    read_volume4D_hdr_only(input_volume,string(argv[vol]));
    if (direction==0) tdimtot+=input_volume.tsize(); 
  //    cerr << tdimtot << endl; //This will give errors in tdimtot if input_volume.destroy not present
    if (direction==1) xdimtot+=input_volume.xsize(); 
    if (direction==2) ydimtot+=input_volume.ysize();
    if (direction==3) zdimtot+=input_volume.zsize();
    input_volume.destroy();     //Remove when new newimage comes out
  }
  volume4D<T> output_volume(xdimtot,ydimtot,zdimtot,tdimtot);
  read_volume4D(input_volume,string(argv[3]));  
  output_volume.copyproperties(input_volume);

  for(vol = 3; vol < argc; vol++)
  {   
    if (vol>3) read_volume4D(input_volume,string(argv[vol]));  
    if (direction == 0 && (input_volume.xsize() != xdimtot || input_volume.ysize() != ydimtot || input_volume.zsize() != zdimtot)) dimerror=1;
    if (direction == 1 && (input_volume.ysize() != ydimtot || input_volume.zsize() != zdimtot || input_volume.tsize() != tdimtot)) dimerror=1;
    if (direction == 2 && (input_volume.xsize() != xdimtot || input_volume.zsize() != zdimtot || input_volume.tsize() != tdimtot)) dimerror=1; 
    if (direction == 3 && (input_volume.xsize() != xdimtot || input_volume.ysize() != ydimtot || input_volume.tsize() != tdimtot)) dimerror=1;
    if (dimerror)
    {
      cerr << "Error in size-match along non-concatenated dimension" << endl; 
      return 1;
    }

             
    for(t=0;t<input_volume.tsize();t++)           
      for(k=0;k<input_volume.zsize();k++)
        for(j=0;j<input_volume.ysize();j++)	    
          for(i=0;i<input_volume.xsize();i++)
            output_volume.value(i+xoffset,j+yoffset,k+zoffset,t+toffset)=input_volume.value(i,j,k,t);
    if (direction==0)  toffset+=input_volume.tsize();  
    if (direction==1)  xoffset+=input_volume.xsize();  
    if (direction==2)  yoffset+=input_volume.ysize(); 
    if (direction==3)  zoffset+=input_volume.zsize(); 
    input_volume.destroy();   //Remove when new newimage comes out      
  }

  save_volume4D(output_volume,string(argv[2]),vinfo);
  return 0;
}


int main(int argc,char *argv[])
{
  if (argc < 4) 
  { 
    print_usage(string(argv[0]));
    return 1; 
  }
  return call_fmrib_main(dtype(string(argv[3])),argc,argv); 
}


