// Definitions of class used to decode and
// read files written by fnirt, and potentially
// by other pieces of software as long as they
// are valid displacement-field files.
//
// fnirt_file_reader.cpp
// 
// Jesper Andersson, FMRIB Image Analysis Group
//
// Copyright (C) 2007 University of Oxford 
//

#include <string>
#include <vector>
#include <boost/shared_ptr.hpp>
#include "newmat.h"

#ifndef EXPOSE_TREACHEROUS
#define EXPOSE_TREACHEROUS           // To allow us to use .sampling_mat()
#endif

#include "newimage/newimageall.h"
#include "warpfns.h"
#include "basisfield/basisfield.h"
#include "basisfield/splinefield.h"
#include "basisfield/dctfield.h"
#include "fnirt_file_reader.h"

using namespace std;
using namespace NEWMAT;
using namespace BASISFIELD;
using namespace boost;

namespace NEWIMAGE {

/////////////////////////////////////////////////////////////////////
//
// Copy constructor
//
/////////////////////////////////////////////////////////////////////

FnirtFileReader::FnirtFileReader(const FnirtFileReader& src) 
: _fname(src._fname), _type(src._type), _aff(src._aff), _coef_rep(3)
{
  for (unsigned int i=0; i<src._coef_rep.size(); i++) {
    if (_type == FnirtSplineDispType) {
      if (src._coef_rep[i]) {
        const splinefield& tmpref = dynamic_cast<const splinefield&>(*(src._coef_rep[i]));
        _coef_rep[i] = shared_ptr<basisfield>(new splinefield(tmpref));
      }
    }
    if (_type == FnirtDCTDispType) {
      if (src._coef_rep[i]) {
        const dctfield& tmpref = dynamic_cast<const dctfield&>(*(src._coef_rep[i]));
        _coef_rep[i] = shared_ptr<basisfield>(new dctfield(tmpref));
      }
    }
  }
  if (src._vol_rep) _vol_rep = shared_ptr<volume4D<float> >(new volume4D<float>(*(src._vol_rep)));
}

/////////////////////////////////////////////////////////////////////
//
// Return matrix-size of field
//
/////////////////////////////////////////////////////////////////////

vector<unsigned int> FnirtFileReader::FieldSize() const
{
  vector<unsigned int>  ret(3,0);

  switch (_type) {
  case FnirtFieldDispType: case UnknownDispType:
    ret[0] = static_cast<unsigned int>(_vol_rep->xsize()); 
    ret[1] = static_cast<unsigned int>(_vol_rep->ysize()); 
    ret[2] = static_cast<unsigned int>(_vol_rep->zsize()); 
    break;
 case FnirtSplineDispType: case FnirtDCTDispType:
   ret[0] = _coef_rep[0]->FieldSz_x(); ret[1] = _coef_rep[0]->FieldSz_y(); ret[2] = _coef_rep[0]->FieldSz_z(); 
   break;
  default:
    throw FnirtFileReaderException("FieldSize: Invalid _type");
  }
  return(ret);
}

/////////////////////////////////////////////////////////////////////
//
// Return voxel-size of field
//
/////////////////////////////////////////////////////////////////////

vector<double> FnirtFileReader::VoxelSize() const
{
  vector<double>  ret(3,0);

  switch (_type) {
  case FnirtFieldDispType: case UnknownDispType:
    ret[0] = _vol_rep->xdim(); ret[1] = _vol_rep->ydim(); ret[2] = _vol_rep->zdim();
    break;
 case FnirtSplineDispType: case FnirtDCTDispType:
   ret[0] = _coef_rep[0]->Vxs_x(); ret[1] = _coef_rep[0]->Vxs_y(); ret[2] = _coef_rep[0]->Vxs_z(); 
   break;
  default:
    throw FnirtFileReaderException("VoxelSize: Invalid _type");
  }
  return(ret);
}

/////////////////////////////////////////////////////////////////////
//
// Return knot-spacing provided field is splinefield
//
/////////////////////////////////////////////////////////////////////

vector<unsigned int> FnirtFileReader::KnotSpacing() const
{
  if (_type == FnirtSplineDispType) {
    vector<unsigned int>  ret(3,0);
    const splinefield&    tmp = dynamic_cast<const splinefield&>(*(_coef_rep[0]));
    ret[0] = tmp.Ksp_x(); ret[1] = tmp.Ksp_y(); ret[2] = tmp.Ksp_z(); 
    return(ret);
  }
  else {
    throw FnirtFileReaderException("KnotSpacing: Field not a splinefield");
  }
}

/////////////////////////////////////////////////////////////////////
//
// Return spline order provided field is splinefield
//
/////////////////////////////////////////////////////////////////////

unsigned int FnirtFileReader::SplineOrder() const
{
  if (_type == FnirtSplineDispType) {
    const splinefield&    tmp = dynamic_cast<const splinefield&>(*(_coef_rep[0]));
    return(tmp.Order());
  }
  else {
    throw FnirtFileReaderException("KnotSpacing: Field not a splinefield");
  }
}

/////////////////////////////////////////////////////////////////////
//
// Return DCT-order provided field is dctfield
//
/////////////////////////////////////////////////////////////////////

vector<unsigned int> FnirtFileReader::DCTOrder() const
{
  vector<unsigned int>  ret(3,0);

  switch (_type) {
  case FnirtFieldDispType: case UnknownDispType: case FnirtSplineDispType:
    throw FnirtFileReaderException("DCTOrder: Field not a dctfield");
    break;
  case FnirtDCTDispType:
   ret[0] = _coef_rep[0]->CoefSz_x(); ret[1] = _coef_rep[0]->CoefSz_y(); ret[2] = _coef_rep[0]->CoefSz_z(); 
   break;
  default:
    throw FnirtFileReaderException("DCTOrder: Invalid _type");
  }
  return(ret);
}

/////////////////////////////////////////////////////////////////////
//
// Return field as a NEWMAT matrix/vector. Optionally with the affine 
// part of the transform included in the field.
//
/////////////////////////////////////////////////////////////////////

ReturnMatrix FnirtFileReader::FieldAsNewmatMatrix(int indx, bool inc_aff) const
{
  if (indx > 2) throw FnirtFileReaderException("FieldAsNewmatMatrix: indx out of range");

  if (indx == -1) {  // Means we want full 4D shabang
    volume4D<float>  volfield = FieldAsNewimageVolume4D(inc_aff);
    Matrix omat(volfield.nvoxels(),3);
    for (unsigned int i=0; i<3; i++) omat.Column(i+1) = volfield[i].vec();
    omat.Release();
    return(omat);
  }
  else {
    volume<float> volfield = FieldAsNewimageVolume(indx,inc_aff);
    ColumnVector omat = volfield.vec();
    omat.Release();
    return(omat);
  }
}

/////////////////////////////////////////////////////////////////////
//
// Return one of the three "fields" as NEWIMAGE volume. 
// Optionally with the affine part of the transform included in the field.
//
/////////////////////////////////////////////////////////////////////

volume<float> FnirtFileReader::FieldAsNewimageVolume(unsigned int indx, bool inc_aff) const
{
  if (indx > 2) throw FnirtFileReaderException("FieldAsNewimageVolume: indx out of range");
  volume<float> vol(FieldSize()[0],FieldSize()[1],FieldSize()[2]);
  switch (_type) {
  case FnirtFieldDispType: case UnknownDispType:
    return((*_vol_rep)[indx]); 
    break;
  case FnirtSplineDispType: case FnirtDCTDispType:
    vol.setdims(VoxelSize()[0],VoxelSize()[1],VoxelSize()[2]);
    _coef_rep[indx]->AsVolume(vol);
    if (inc_aff) add_affine_part(_aff,indx,vol);
    return(vol);
    break;
  default:
    throw FnirtFileReaderException("FieldAsNewimageVolume: Invalid _type");
  }
} 

/////////////////////////////////////////////////////////////////////
//
// Return field as 4D volume. Optionally with the affine 
// part of the transform included in the field.
//
/////////////////////////////////////////////////////////////////////

volume4D<float> FnirtFileReader::FieldAsNewimageVolume4D(bool inc_aff) const
{
  volume4D<float> vol(FieldSize()[0],FieldSize()[1],FieldSize()[2],3);
  switch (_type) {
  case FnirtFieldDispType: case UnknownDispType:
    return(*_vol_rep); 
    break;
  case FnirtSplineDispType: case FnirtDCTDispType:
    vol.setdims(VoxelSize()[0],VoxelSize()[1],VoxelSize()[2],1.0);
    for (unsigned int i=0; i<3; i++) {
      _coef_rep[i]->AsVolume(vol[i]);
      if (inc_aff) add_affine_part(_aff,i,vol[i]);
    }
    return(vol);
    break;
  default:
    throw FnirtFileReaderException("FieldAsNewimageVolume4D: Invalid _type");
  }
} 

/////////////////////////////////////////////////////////////////////
//
// Return the Jacobian determinant of the field as a NEWIMAGE volume.
//
/////////////////////////////////////////////////////////////////////

volume<float> FnirtFileReader::Jacobian(bool inc_aff) const
{
  if (_type==FnirtFieldDispType || _type==UnknownDispType) {
    throw FnirtFileReaderException("Jacobian: Not yet implemented for non-basis representations");
  }
  else if (_type==FnirtSplineDispType || _type==FnirtDCTDispType) {
    volume<float>  jac(FieldSize()[0],FieldSize()[1],FieldSize()[2]);
    jac.setdims(VoxelSize()[0],VoxelSize()[1],VoxelSize()[2]);
    deffield2jacobian(*(_coef_rep[0]),*(_coef_rep[1]),*(_coef_rep[2]),jac);
    return(jac);
  }
  else throw FnirtFileReaderException("Jacobian: Invalid _type");  
}
/////////////////////////////////////////////////////////////////////
//
// Return field as an instance of splinefield class.
//
/////////////////////////////////////////////////////////////////////

splinefield FnirtFileReader::FieldAsSplinefield(unsigned int indx, vector<unsigned int> ksp, unsigned int order) const
{
  if (!ksp.size() && _type != FnirtSplineDispType) {
    throw FnirtFileReaderException("FieldAsSplineField: Must specify ksp if spline is not native type");
  }
  if (indx > 2) throw FnirtFileReaderException("FieldAsSplineField: indx out of range");
  if (_type == FnirtSplineDispType) {
    if ((!ksp.size() || ksp==KnotSpacing()) && (!order || order==SplineOrder())) {
      const splinefield& tmpref = dynamic_cast<const splinefield&>(*(_coef_rep[indx]));
      return(tmpref);
    }
    else {
      if (!order || order==SplineOrder()) {  // If we are keeping the order
        order = SplineOrder();
        shared_ptr<basisfield>  tmpptr = _coef_rep[indx]->ZoomField(FieldSize(),VoxelSize(),ksp);
        const splinefield&      tmpref = dynamic_cast<const splinefield&>(*tmpptr);
        return(tmpref);
      }
      else { // New order and (possibly) ksp
        volume<float>       vol(FieldAsNewimageVolume(indx));
        splinefield         rval(FieldSize(),VoxelSize(),ksp,order);
        rval.Set(vol);
        return(rval);
      }
    }
  }
  else {
    if (!order) order = 3;   // Cubic splines default
    volume<float>       vol(FieldAsNewimageVolume(indx));
    splinefield         rval(FieldSize(),VoxelSize(),ksp,order);
    rval.Set(vol);
    return(rval);
  }
}

/////////////////////////////////////////////////////////////////////
//
// Return field as an instance of dctfield class.
//
/////////////////////////////////////////////////////////////////////

dctfield FnirtFileReader::FieldAsDctfield(unsigned int indx, vector<unsigned int> order) const
{
  if (!order.size() && _type != FnirtDCTDispType) {
    throw FnirtFileReaderException("FieldAsDctfield: Must specify order if DCT is not native type");
  }
  if (indx > 2) throw FnirtFileReaderException("FieldAsSplineField: indx out of range");
  shared_ptr<volume<float> >   volp;
  shared_ptr<dctfield>         rvalp;
  if (_type == FnirtDCTDispType) {
    if (!order.size() || order==DCTOrder()) {
      const dctfield& tmpref = dynamic_cast<const dctfield&>(*(_coef_rep[indx]));
      return(tmpref);
    }
    else {
      shared_ptr<basisfield>  tmpptr = _coef_rep[indx]->ZoomField(FieldSize(),VoxelSize(),order);
      const dctfield& tmpref = dynamic_cast<const dctfield&>(*tmpptr);
      return(tmpref);
    }
  }
  else {
    volume<float>       vol(FieldAsNewimageVolume(indx));
    dctfield            rval(FieldSize(),VoxelSize(),order);
    rval.Set(vol);
    return(rval);
  }
}

/////////////////////////////////////////////////////////////////////
//
// This is a globally declared "helper" routine.
//
/////////////////////////////////////////////////////////////////////

void deffield2jacobian(const BASISFIELD::basisfield&   dx,
                       const BASISFIELD::basisfield&   dy,
                       const BASISFIELD::basisfield&   dz,
                       volume<float>&                  jac)
{
  const boost::shared_ptr<ColumnVector>  dxdx = dx.Get(BASISFIELD::FieldIndex(1));  
  const boost::shared_ptr<ColumnVector>  dxdy = dx.Get(BASISFIELD::FieldIndex(2));  
  const boost::shared_ptr<ColumnVector>  dxdz = dx.Get(BASISFIELD::FieldIndex(3));  
  const boost::shared_ptr<ColumnVector>  dydx = dy.Get(BASISFIELD::FieldIndex(1));  
  const boost::shared_ptr<ColumnVector>  dydy = dy.Get(BASISFIELD::FieldIndex(2));  
  const boost::shared_ptr<ColumnVector>  dydz = dy.Get(BASISFIELD::FieldIndex(3));  
  const boost::shared_ptr<ColumnVector>  dzdx = dz.Get(BASISFIELD::FieldIndex(1));  
  const boost::shared_ptr<ColumnVector>  dzdy = dz.Get(BASISFIELD::FieldIndex(2));  
  const boost::shared_ptr<ColumnVector>  dzdz = dz.Get(BASISFIELD::FieldIndex(3));

  for (unsigned int indx=0, k=0; k<dx.FieldSz_z(); k++) {
    for (unsigned int j=0; j<dx.FieldSz_y(); j++) {
      for (unsigned int i=0; i<dx.FieldSz_x(); i++) {
	jac(i,j,k) = (1.0+(1.0/dx.Vxs_x())*dxdx->element(indx)) * (1.0+(1.0/dy.Vxs_y())*dydy->element(indx)) * (1.0+(1.0/dz.Vxs_z())*dzdz->element(indx));
        jac(i,j,k) += (1.0/dx.Vxs_y())*dxdy->element(indx) * (1.0/dy.Vxs_z())*dydz->element(indx) * (1.0/dz.Vxs_x())*dzdx->element(indx);
	jac(i,j,k) += (1.0/dx.Vxs_z())*dxdz->element(indx) * (1.0/dy.Vxs_x())*dydx->element(indx) * (1.0/dz.Vxs_y())*dzdy->element(indx);
        jac(i,j,k) -= (1.0/dz.Vxs_x())*dzdx->element(indx) * (1.0+(1.0/dy.Vxs_y())*dydy->element(indx)) * (1.0/dx.Vxs_z())*dxdz->element(indx);
        jac(i,j,k) -= (1.0/dz.Vxs_y())*dzdy->element(indx) * (1.0/dy.Vxs_z())*dydz->element(indx) * (1.0+(1.0/dx.Vxs_x())*dxdx->element(indx));
        jac(i,j,k) -= (1.0+(1.0/dz.Vxs_z())*dzdz->element(indx)) * (1.0/dy.Vxs_x())*dydx->element(indx) * (1.0/dx.Vxs_y())*dxdy->element(indx);
	indx++;
      }
    }
  }
}

/////////////////////////////////////////////////////////////////////
//
// Here starts private helper routines
//
/////////////////////////////////////////////////////////////////////

void FnirtFileReader::common_read(const string& fname, AbsOrRelWarps wt, bool verbose)
{
  // Read volume indicated by fname
  volume4D<float>   vol;
  read_volume4D(vol,fname);
  if (vol.tsize() != 3) throw FnirtFileReaderException("FnirtFileReader: Displacement fields must contain 3 volumes");  

  Matrix qform;
  
  // Take appropriate action depending on intent code of volume
  switch (vol.intent_code()) {
  case FSL_CUBIC_SPLINE_COEFFICIENTS:
  case FSL_QUADRATIC_SPLINE_COEFFICIENTS: 
  case FSL_DCT_COEFFICIENTS:                                 // Coefficients generated by FSL application (e.g. fnirt)
    read_orig_volume4D(vol,fname);                           // Re-read coefficients "raw"
    _aff = vol.sform_mat();                                  // Affine part of transform
    _aor = RelativeWarps;                                    // Relative warps
    _coef_rep = read_coef_file(vol,verbose);
    if (vol.intent_code() == FSL_CUBIC_SPLINE_COEFFICIENTS || 
        vol.intent_code() == FSL_QUADRATIC_SPLINE_COEFFICIENTS) _type = FnirtSplineDispType;
    else if (vol.intent_code() == FSL_DCT_COEFFICIENTS) _type = FnirtDCTDispType;
    break;
  case FSL_FNIRT_DISPLACEMENT_FIELD:                                    // Field generated by fnirt
    _type = FnirtFieldDispType;
    _aor = RelativeWarps;                                               // Relative warps
    _vol_rep = shared_ptr<volume4D<float> >(new volume4D<float>(vol));  // Represent as volume
    _aff = IdentityMatrix(4);                                           // Affine part already included
    break;
  default:                                                              // Field generated by "unknown" application
    _type = UnknownDispType;
    _aor =wt;                                                           // Trust the user
    _vol_rep = shared_ptr<volume4D<float> >(new volume4D<float>(vol));  // Represent as volume
    _aff = IdentityMatrix(4);                                           // Affine part already included
    // Convert into realtive warps (if neccessary)
    if (wt==AbsoluteWarps) convertwarp_abs2rel(*_vol_rep);
    else if (wt==UnknownWarps) {
      if (verbose) cout << "Automatically determining absolute/relative warp convention" << endl;
      float stddev0 = (*_vol_rep)[0].stddev()+(*_vol_rep)[1].stddev()+(*_vol_rep)[2].stddev();
      convertwarp_abs2rel(*_vol_rep);
      float stddev1 = (*_vol_rep)[0].stddev()+(*_vol_rep)[1].stddev()+(*_vol_rep)[2].stddev();
      // assume that relative warp always has less stddev
      if (stddev0>stddev1) {
        // the initial one (greater stddev) was absolute
        if (verbose) cout << "Assuming warps was absolute" << endl;
      } 
      else {
        // the initial one was relative
        if (verbose) cout << "Assuming warps was relative" << endl;
        convertwarp_rel2abs(*_vol_rep);  // Restore to relative, which is what we want
      }
    }
    break;
  }
}

vector<shared_ptr<basisfield> > FnirtFileReader::read_coef_file(const volume4D<float>&   vcoef,
                                                                bool                     verbose) const
{
  // Collect info that we need to create the fields
  Matrix        qform = vcoef.qform_mat();
  if (verbose) cout << "qform = " << qform << endl;
  vector<unsigned int>   sz(3,0);
  vector<double>         vxs(3,0.0);
  for (int i=0; i<3; i++) {
    sz[i] = static_cast<unsigned int>(qform(i+1,4));
    vxs[i] = static_cast<double>(vcoef.intent_param(i+1));  
  }
  if (verbose) cout << "Matrix size: " << sz[0] << "  " << sz[1] << "  " << sz[2] << endl;
  if (verbose) cout << "Voxel size: " << vxs[0] << "  " << vxs[1] << "  " << vxs[2] << endl;

  vector<shared_ptr<basisfield> >   fields(3);

  if (vcoef.intent_code() == FSL_CUBIC_SPLINE_COEFFICIENTS ||
      vcoef.intent_code() == FSL_QUADRATIC_SPLINE_COEFFICIENTS) {        // Interpret as spline coefficients
    if (verbose) cout << "Interpreting file as spline coefficients" << endl;
    vector<unsigned int>   ksp(3,0);
    unsigned int           order = 3;
    if (vcoef.intent_code() == FSL_QUADRATIC_SPLINE_COEFFICIENTS) order = 2;
    ksp[0] = static_cast<unsigned int>(vcoef.xdim() + 0.5);
    ksp[1] = static_cast<unsigned int>(vcoef.ydim() + 0.5);
    ksp[2] = static_cast<unsigned int>(vcoef.zdim() + 0.5);
    if (verbose) cout << "Knot-spacing: " << ksp[0] << "  " << ksp[1] << "  " << ksp[2] << endl;
    if (verbose) cout << "Size of coefficient matrix: " << vcoef.xsize() << "  " << vcoef.ysize() << "  " << vcoef.zsize() << endl;
    for (int i=0; i<3; i++) {
      fields[i] = shared_ptr<splinefield>(new splinefield(sz,vxs,ksp,order));
    }
    // Sanity check
    if (fields[0]->CoefSz_x() != static_cast<unsigned int>(vcoef.xsize()) ||
        fields[0]->CoefSz_y() != static_cast<unsigned int>(vcoef.ysize()) ||
        fields[0]->CoefSz_z() != static_cast<unsigned int>(vcoef.zsize())) {
      throw FnirtFileReaderException("read_coef_file: Coefficient file not self consistent");
    }
  }
  else if (vcoef.intent_code() == FSL_DCT_COEFFICIENTS) {   // Interpret as DCT coefficients
    if (verbose) cout << "Interpreting file as DCT coefficients" << endl;
    std::vector<unsigned int>   order(3);
    order[0] = static_cast<unsigned int>(vcoef.xsize());
    order[1] = static_cast<unsigned int>(vcoef.ysize());
    order[2] = static_cast<unsigned int>(vcoef.zsize());
    if (verbose) cout << "Size of coefficient matrix: " << vcoef.xsize() << "  " << vcoef.ysize() << "  " << vcoef.zsize() << endl;
    for (int i=0; i<3; i++) {
      fields[i] = shared_ptr<dctfield>(new dctfield(sz,vxs,order));
    }
  }

  // Set the coefficients from the file
  for (int i=0; i<3; i++) {
    fields[i]->SetCoef(vcoef[i].vec());
  }

  // Return vector of fields
  
  return(fields);
}

void FnirtFileReader::add_affine_part(Matrix aff, unsigned int indx, volume<float>& warps) const
{
  if (indx > 2) throw FnirtFileReaderException("add_affine_part: indx out of range");
  if ((aff-IdentityMatrix(4)).MaximumAbsoluteValue() > 1e-6) {
    Matrix        M = (aff.i() - IdentityMatrix(4)) * warps.sampling_mat();
    ColumnVector  mr(4);
    for (unsigned int i=1; i<=4; i++) mr(i) = M(indx+1,i);
    ColumnVector  xv(4);
    int zs = warps.zsize(), ys = warps.ysize(), xs = warps.xsize();
    xv(4) = 1.0;
    for (int z=0; z<zs; z++) {
      xv(3) = double(z);
      for (int y=0; y<ys; y++) {
        xv(2) = double(y);
        for (int x=0; x<xs; x++) {
          xv(1) = double(x); 
          warps(x,y,z) += DotProduct(mr,xv);
	}
      }
    }
  }
}

} // End namespace NEWIMAGE
