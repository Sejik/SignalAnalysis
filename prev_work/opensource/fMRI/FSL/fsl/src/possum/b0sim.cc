/*  b0sim.cc

    Mark Jenkinson, FMRIB Image Analysis Group

    Copyright (C) 2003 University of Oxford  */

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

// Simulator for static B0 - made specifically for HBM2004

#define _GNU_SOURCE 1
#define POSIX_SOURCE 1

#include "newimage/newimageall.h"
#include "miscmaths/miscmaths.h"
#include "utils/options.h"

using namespace MISCMATHS;
using namespace NEWIMAGE;
using namespace Utilities;

// The two strings below specify the title and example usage that is
//  printed out as the help or usage message

string title="b0sim (Version 1.0)\nCopyright(c) 2003, University of Oxford (Mark Jenkinson)";
string examples="b0sim [options] -i <input model> -b <b0 input> -o <output>";


Option<bool> verbose(string("-v,--verbose"), false, 
		     string("switch on diagnostic messages"), 
		     false, no_argument);
Option<bool> help(string("-h,--help"), false,
		  string("display this message"),
		  false, no_argument);
Option<bool> debug(string("-d,--debug"), false,
		  string("turn debugging outputs (files) on"),
		  false, no_argument);
Option<bool> zerogradients(string("--zerogradients"), false,
		  string("use mean b0 in each voxel but have zero b0 gradients"),
		  false, no_argument);
Option<string> inname(string("-i,--in"), string(""),
		  string("input filename for object model"),
		  true, requires_argument);
Option<string> b0name(string("-b,--b0"), string(""),
		  string("filename for object b0 (in Tesla)"),
		  false, requires_argument);
Option<string> outname(string("-o,--out"), string(""),
		  string("filename for output image (complex)"),
		  true, requires_argument);
int nonoptarg;

////////////////////////////////////////////////////////////////////////////

// Local functions

int calc_gradients(const volume<double>& im, volume<double>& gx, 
		   volume<double>& gy, volume<double>& gz)
{
  // Input image, im, must be in uT : output gradients in uT/mm
  // NB: sets all gradients at the edge of the volume to zero for
  //     simplicity, as normally just need to know inside the brain
  //     which doesn't extend this far!
  gx = im*0;
  gy = gx;
  gz = gx;
  for (int z=1; z<im.zsize()-1; z++) {
    for (int y=1; y<im.ysize()-1; y++) {
      for (int x=1; x<im.xsize()-1; x++) {
	gx(x,y,z) = 1*(im(x+1,y+1,z+1) + im(x+1,y-1,z+1) + im(x+1,y-1,z-1)
		       + im(x+1,y+1,z-1) - im(x-1,y+1,z+1)
		       - im(x-1,y-1,z+1) - im(x-1,y-1,z-1) - im(x-1,y+1,z-1))
	  + 6*(im(x+1,y,z+1) + im(x+1,y,z-1) + im(x+1,y+1,z) + im(x+1,y-1,z)
	       - im(x-1,y,z+1) - im(x-1,y,z-1) - im(x-1,y+1,z) - im(x-1,y-1,z))
	  + 36*(im(x+1,y,z) - im(x-1,y,z));
	gy(x,y,z) = 1*(im(x+1,y+1,z+1) + im(x-1,y+1,z+1) + im(x-1,y+1,z-1)
		       + im(x+1,y+1,z-1) - im(x+1,y-1,z+1)
		       - im(x-1,y-1,z+1) - im(x-1,y-1,z-1) - im(x+1,y-1,z-1))
	  + 6*(im(x,y+1,z+1) + im(x,y+1,z-1) + im(x+1,y+1,z) + im(x-1,y+1,z)
	       - im(x,y-1,z+1) - im(x,y-1,z-1) - im(x+1,y-1,z) - im(x-1,y-1,z))
	  + 36*(im(x,y+1,z) - im(x,y-1,z));
	gz(x,y,z) = 1*(im(x+1,y+1,z+1) + im(x-1,y+1,z+1) + im(x-1,y-1,z+1)
		       + im(x+1,y-1,z+1) - im(x+1,y+1,z-1)
		       - im(x-1,y+1,z-1) - im(x-1,y-1,z-1) - im(x+1,y-1,z-1))
	  + 6*(im(x,y+1,z+1) + im(x,y-1,z+1) + im(x+1,y,z+1) + im(x-1,y,z+1)
	       - im(x,y+1,z-1) - im(x,y-1,z-1) - im(x+1,y,z-1) - im(x-1,y,z-1))
	  + 36*(im(x,y,z+1) - im(x,y,z-1));
      }
    }
  }
  // compensate for weightings and that grad = dI / dx, and dx = 2 here
  double scalefac = 1.0/(2*(4*1 + 4*6 + 1*36));
  gx *= scalefac/im.xdim();  // in uT/mm
  gy *= scalefac/im.ydim();
  gz *= scalefac/im.zdim();
  return 0;
}


int do_work(int argc, char* argv[]) 
{
  // Simulates an EPI image based on rho from brainweb_t2 and b0
  // inhomogeneity from input file
  
  if (debug.value()) cout << "Debugging on" << endl;
  
  string fname=fslbasename(outname.value());

  // random scanner and physics parameters
  double gmax = 35;  // max grad strength of 10 mT/m = uT/mm
  double gammabar = 42.6;  // MHz/T = kHz/mT
  // NB: gammabar * field in mT/m = kHz/m = Hz/mm
  double te = 40*1e-3;  // in sec
  
  // read input object model
  volume<double> rho, b0, gx, gy, gz;
  read_volume(rho,inname.value());
  int inx=rho.xsize();
  int iny=rho.ysize();
  int inz=rho.zsize();
  double lx=rho.xdim(), ly=rho.ydim(), lz=rho.zdim(); // input voxel dims in mm
  double x0=MISCMATHS::round(inx/2)*lx; // centre of input image in mm
  double y0=MISCMATHS::round(iny/2)*ly;
  double z0=MISCMATHS::round(inz/2)*lz;
  volume<double> xpos(inx,iny,1), ypos(inx,iny,1);  // both in mm
  xpos = rho*0.0;
  ypos = xpos;
  for (int x=0; x<inx; x++) {
    for (int y=0; y<iny; y++) {
      xpos(x,y,0)=(x+1)*lx - x0;  // for consistency with matlab
      ypos(x,y,0)=(y+1)*ly - y0;
    }
  }
  // read in b0 inhomogeneity
  if (b0name.set()) {
    read_volume(b0,b0name.value());
    b0=b0*1e6;  // must be in uT (so that gammabar*b0 is in Hz)
  } else {
    b0=rho*0;
  }
  if (verbose.value()) cout << "Calculating b0 gradients" << endl;
  if (zerogradients.value()) {
    gx=b0*0.0f;
    gy=b0*0.0f;
    gz=b0*0.0f;
  } else {
    calc_gradients(b0,gx,gy,gz);
    if (debug.value()) save_volume(gx,fname+"debug_gx");
    if (debug.value()) save_volume(gy,fname+"debug_gy");
    if (debug.value()) save_volume(gz,fname+"debug_gz");
  }

  // EPI params
  //int nx=64, ny=64, nz=25;
  int nx=64, ny=64, nz=1;
  double dx=4.0, dy=4.0, dz=6.0; // output voxel dims in mm
  
  // set up k-space
  double dkx=1/(nx*dx); // in mm^-1
  double dky=1/(ny*dy);
  
  ColumnVector kx1(nx), ky1(nx);
  for (int m=1, n=(-nx/2); n<=(nx-1)/2; m++, n++) {
    kx1(m)=n;
  }
  for (int m=1, n=(-ny/2); n<=(ny-1)/2; m++, n++) {
    ky1(m)=n;
  }
  ColumnVector kx(nx*ny), ky(nx*ny);
  for (int n=1; n<=ny/2; n++) {
    for (int m=1; m<=nx; m++) {
      kx((2*n-2)*nx + m)=kx1(m);
      kx((2*n-1)*nx + m)=kx1(nx + 1 - m);
      ky((2*n-2)*nx + m)=ky1(2*n-1);
      ky((2*n-1)*nx + m)=ky1(2*n);
    }
  }
  kx=kx*dkx;
  ky=ky*dky;
  
  // set up timing
  double dt = dkx/(gammabar*gmax); // in sec
  double t0 = te - ((ny/2)*(nx-1) + nx/2)*dt;
  ColumnVector t(nx*ny);
  for (int n=0; n<(nx*ny); n++) { t(n+1)=t0 + dt*n; }

  if (debug.value()) write_ascii_matrix(t,fname+"debug_t");
  if (debug.value()) write_ascii_matrix(kx,fname+"debug_kx");
  if (debug.value()) write_ascii_matrix(ky,fname+"debug_ky");
  
  // setup final image
  volume<float> dummy(nx,ny,nz);
  dummy.setdims(dx,dy,dz);
  dummy = 0;
  complexvolume finalimage(dummy,dummy);

  // calculate signal s(t)
  
  Matrix sig(2,nx*ny);
  double twopi = 2.0*M_PI;
  for (int oz=0; oz<nz; oz++) { // slice number of output
    sig = 0;
    int zstart, zend;
    // the mess below just tries to set middle of output = middle of input
    zstart = MISCMATHS::round(dz/lz)*MISCMATHS::round(oz - MISCMATHS::round(nz/2)) + MISCMATHS::round(inz/2) - MISCMATHS::round((dz-lz)/(2*lz));
    zend = zstart + MISCMATHS::round(dz/lz) - 1;
    if (zstart<0) zstart=0;
    if (zend>=inz) zend=inz-1;
    if ( (zstart>=inz) || (zend<0) ) {
      zstart=1; zend=0;  // do not want the following loop to run!
    } else if (verbose.value()) { 
      cout << "Output slice " << oz << " ;  input slice range : ";
    }
    for (int z=zstart; z<=zend; z++) {  // slice number of input
      if (verbose.value()) { 
	if (z==zend) cout << z << endl; 
	else { cout <<  z << " , "; cout.flush(); }
      }
      double zpos=lz*(z+1)-z0;   // NB z+1 for MATLAB equivalence
      for (int m=1; m<=nx*ny; m++) { // time point index
	double gbart = gammabar*t(m);
	for (int y=0; y<iny; y++) {
	  for (int x=0; x<inx; x++) {
	    if (rho(x,y,z)>0) {
	      double kxx=kx(m) + gbart*gx(x,y,z);
	      double kyy=ky(m) + gbart*gy(x,y,z);
	      double kzz=gbart*gz(x,y,z);
	      double phi = twopi*(gbart*b0(x,y,z) + kx(m)*xpos(x,y,0) + 
				  ky(m)*ypos(x,y,0));   
	      double term = rho(x,y,z)*MISCMATHS::Sinc(lx*kxx)*
		MISCMATHS::Sinc(ly*kyy)*MISCMATHS::Sinc(lz*kzz);
	      sig(1,m) += cos(phi)*term;
	      sig(2,m) += sin(phi)*term;
	    }
	  }
	}
      }
    }
    sig *= (lx*ly*lz);
    
    if (debug.value()) write_ascii_matrix(sig,fname+"debug_signal");
    
    // reconstruct slice
    volume<float> dummy(nx,ny,1);
    dummy = 0.0;
    complexvolume kslice(dummy,dummy);
    for (int n=1; n<=(ny/2); n++) {
      int tidx = (n-1)*2*nx + 1;
      for (int m=1; m<=nx; m++) {
	kslice.re(m-1,2*n-2,0) = (double) sig(1,tidx + m - 1);
	kslice.im(m-1,2*n-2,0) = (double) sig(2,tidx + m - 1);
	kslice.re(m-1,2*n-1,0) = (double) sig(1,tidx+2*nx-m);
	kslice.im(m-1,2*n-1,0) = (double) sig(2,tidx+2*nx-m);
      }
    }
  
    if (debug.value()) save_complexvolume(kslice,fname+"debug_kspace");
    fft2(kslice);
    fftshift(kslice);
    // copy transformed slice into final image
    for (int oy=0; oy<ny; oy++) {
      for (int ox=0; ox<nx; ox++) {
	finalimage.re(ox,oy,oz)=kslice.re(ox,oy,0);
	finalimage.im(ox,oy,oz)=kslice.im(ox,oy,0);
      }
    }
  }

  if (debug.value()) print_volume_info(finalimage.re(),"finalimage.re()");
  if (debug.value()) print_volume_info(finalimage.im(),"finalimage.im()");
  save_complexvolume(finalimage,fname);
  
  return 0;
}



////////////////////////////////////////////////////////////////////////////

int main(int argc,char *argv[])
{

  Tracer tr("main");
  OptionParser options(title, examples);

  try {
    // must include all wanted options here (the order determines how
    //  the help message is printed)
    options.add(inname);
    options.add(b0name);
    options.add(outname);
    options.add(zerogradients);
    options.add(verbose);
    options.add(help);
    options.add(debug);
    
    nonoptarg = options.parse_command_line(argc, argv);

    // line below stops the program if the help was requested or 
    //  a compulsory option was not set
    if ( (help.value()) || (!options.check_compulsory_arguments(true)) )
      {
	options.usage();
	exit(EXIT_FAILURE);
      }
    
  }  catch(X_OptionError& e) {
    options.usage();
    cerr << endl << e.what() << endl;
    exit(EXIT_FAILURE);
  } catch(std::exception &e) {
    cerr << e.what() << endl;
  } 

  // Call the local functions

  return do_work(argc,argv);
}

















