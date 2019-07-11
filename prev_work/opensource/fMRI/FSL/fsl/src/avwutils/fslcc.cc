//     fslcc.cc cross-correlate two time series
//     Steve Smith and Matthew Webster, FMRIB Image Analysis Group
//     Copyright (C) 2001-2009 University of Oxford  
//     COPYRIGHT  

#include "newimage/newimageall.h"
#include "newimage/fmribmain.h"
#include <iomanip>

using namespace NEWIMAGE;

int print_usage(const string& progname) 
{
  cout << "Usage: fslcc [-noabs] <first_input> <second_input> [cc_thresh]" << endl;
  cout << "-noabs: Don't return absolute values (keep sign)." << endl;
  return(1);
}

template <class T>
int fmrib_main(int argc, char *argv[])
{
  volume4D<T> input_volume1, input_volume2;
  int currentArguement(1);
  bool noabs(string(argv[currentArguement])=="-noabs");
  if (noabs)
    currentArguement++;
  string input_name1(argv[currentArguement++]);
  string input_name2(argv[currentArguement++]);
  read_volume4D(input_volume1,input_name1);
  read_volume4D(input_volume2,input_name2);
  double thresh(0.1);
  if (argc > currentArguement)  thresh=atof(argv[currentArguement]);
  if (input_volume1.maxx() != input_volume2.maxx() ||  input_volume1.maxy() != input_volume2.maxy()  ||  input_volume1.maxz() != input_volume2.maxz())
  {
    cerr << "Error: Mismatch in image dimensions" << endl; 
    return 1;
  }

  for(int t1=0;t1<=input_volume1.maxt();t1++)
  {
    double ss1=sqrt(input_volume1[t1].sumsquares());  
    for(int t2=0;t2<=input_volume2.maxt();t2++)
    {
       double ss2=sqrt(input_volume2[t2].sumsquares());  
       double score=0;
       for(int k=0;k<=input_volume1.maxz();k++)
         for(int j=0;j<=input_volume1.maxy();j++)
           for(int i=0;i<=input_volume1.maxx();i++)
	     score+=input_volume1(i,j,k,t1)*input_volume2(i,j,k,t2); 
       if (!noabs)
	 score=fabs(score);
       score/=(ss1*ss2);
       if (score>thresh)
         cout << setw(3) << t1+1 << " " << setw(3) << t2+1 << " " <<  setiosflags (ios::fixed) << setprecision(2) << score << endl;
    }
  }

  return 0;
}


int main(int argc,char *argv[])
{
  string progname(argv[0]);
  if (argc < 3 || ( string(argv[1])=="-noabs" && argc<4 ) || argc > 5) 
    return print_usage(progname);
     
  string inputName(argv[1]);
  if ( inputName=="-noabs" )
    inputName=string(argv[2]);
  return call_fmrib_main(dtype(inputName),argc,argv); 
}
