//     fslchfiletype.cc  Conversion program for different volume types
//     Matthew Webster, FMRIB Image Analysis Group
//     Copyright (C) 2008 University of Oxford  
//     COPYRIGHT  

#include "newimage/newimageall.h"
#include "newimage/fmribmain.h"

using namespace NEWIMAGE;

int printUsage(const string& progname) 
{
  cout << "Usage: " << progname << " <filetype> <filename> [filename2]" << endl << endl;
  cout << "  Changes the file type of the image file, or copies to new file" << endl;
  cout << "  Valid values of filetype are ANALYZE, NIFTI, NIFTI_PAIR," << endl;
  cout << "                               ANALYZE_GZ, NIFTI_GZ, NIFTI_PAIR_GZ" << endl;
  return 1;
}

template <class T>
int fmrib_main(int argc, char *argv[])
{
  volume4D<T> input;
  volumeinfo vinfo;
  read_volume4D(input,string(argv[0]),vinfo);
  save_volume4D_dtype(input,string(argv[1]),dtype(string(argv[0])),vinfo,true);
  return 0;
}

int main(int argc,char *argv[])
{
  if (argc < 3 || argc > 4)
    return printUsage(string(argv[0]));

  string inputFile(argv[2]);
  string outputFile(argv[2]);
  if (argc==4) outputFile=string(argv[3]);

  int outputType(-1);
  if (string(argv[1])=="ANALYZE") outputType=FSL_TYPE_ANALYZE;
  else if (string(argv[1])=="NIFTI") outputType=FSL_TYPE_NIFTI;
  else if (string(argv[1])=="NIFTI_PAIR") outputType=FSL_TYPE_NIFTI_PAIR;
  else if (string(argv[1])=="ANALYZE_GZ") outputType=FSL_TYPE_ANALYZE_GZ;
  else if (string(argv[1])=="NIFTI_GZ") outputType=FSL_TYPE_NIFTI_GZ;
  else if (string(argv[1])=="NIFTI_PAIR_GZ") outputType=FSL_TYPE_NIFTI_PAIR_GZ;
  else return printUsage(string(argv[0]));

  FslSetOverrideOutputType(outputType);

  if (dtype(inputFile)==DT_COMPLEX) 
  {
    volume4D<float> real, imaginary;
    volumeinfo vinfo;
    read_complexvolume4D(real, imaginary, inputFile, vinfo);
    save_complexvolume4D(real, imaginary, outputFile, vinfo);
  }
  else  
  {
    argv[0]= const_cast <char*>(inputFile.c_str());
    argv[1]= const_cast <char*>(outputFile.c_str());
    call_fmrib_main(dtype(inputFile),argc,argv);
  }
  return 0;
}

