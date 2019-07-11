/* mvntool.cc - Tool for adding parameters to an MVN

   Michael Chappell, FMRIB Analysis Group

   Copyright (C) 2007 University of Oxford  */

#include <iostream>
#include <exception>
#include <stdexcept>
#include <map>
#include <string>
#include "inference.h"
#include "dist_mvn.h"
#include "easyoptions.h"
#include "newimage/newimageall.h"

using namespace Utilities;
using namespace std;
using namespace MISCMATHS;
using namespace NEWIMAGE;

/* Function declarations */
void Usage(const string& errorString = "");

int main(int argc, char** argv)
{
	try
	  {
	    cout << "FABBER: MVNtool" << endl;

	    EasyOptions args(argc, argv);

	    if (args.ReadBool("help"))
	      {
		Usage();
		return 0;
	      }

	    EasyLog::StartLogUsingStream(cout);

	    /* parse command line arguments*/
	    string infile;
	    string outfile;
	    infile = args.Read("input");
	    string maskfile;
	    maskfile = args.Read("mask");
	    int param;
	    param = convertTo<int>(args.Read("param"));

	    bool ins; bool write;

	    double val;	double var;
	    bool bval;bool bvar;
	    /* Choose what we want to do to/with the parameter - default is to read */
	    ins = args.ReadBool("new"); //insert a new parameter
	    write = args.ReadBool("write"); //overwrite an existing parameter
	    if (ins | write) {
	      if (ins & write) { throw Invalid_option("Cannot insert and write at same time - choose either --new or --write"); }
		outfile = args.ReadWithDefault("output",infile);

		val = convertTo<double>(args.ReadWithDefault("val","-1e-6"));
		var = convertTo<double>(args.ReadWithDefault("var","-1e-6"));
	      }
	    else {
	      outfile = args.Read("output");

	      bval = args.ReadBool("val");
	      bvar = args.ReadBool("var");
	      if (bval & bvar) { throw Invalid_option("Cannot output value and variance at same time - choose either --val or --val"); }
	      if (!bval & !bvar) { throw Invalid_option("Please select whether you want to extract the value (--val) or the variance (--var)"); }
	    }

	    /* Read in MVN file */
	    volume<float> mask;
            read_volume(mask,maskfile);
	    mask.binarise(1e-16,mask.max()+1,exclusive);

	    cout << "Read file" << endl;
	    vector<MVNDist*> vmvnin;
	    MVNDist::Load(vmvnin,infile,mask);

	    
	    if (ins | write) {
		/* section to deal with writing to or inserting into an MVN*/
		SymmetricMatrix mvncov;
		vector<MVNDist*> vmvnout(vmvnin);

		int oldsize;
		MVNDist mvnin;
		mvnin = *vmvnin[1];
		oldsize = mvnin.GetSize();

		if (ins)
		  { 
		    cout << "Inserting new parameter" << endl;
		    if (param > oldsize+1) throw Invalid_option("Cannot insert parameter here, not enough parameters in existing MVN");
		  }
		else
		  { if (param > oldsize) throw Invalid_option("Cannot edit this parameter, not enough parameters in existing MVN");}
		
		MVNDist mvnnew(1);
		mvnnew.means = 0;
		SymmetricMatrix covnew(1);
		covnew(1,1) = 0;
		mvnnew.SetCovariance(covnew);
		MVNDist mvnout;
		
		/* Loop over each enrty in mvnin */
		for (unsigned v=0;v < vmvnin.size(); v++)
		  {
		    mvnin = *vmvnin[v];
		    
		    if (ins)
		      { /* insert new parameter */
			//cout << "Add new parameter" << endl;
			
			if (param-1 >= 1)
			  {
			    MVNDist mvn1(param -1);
			    mvn1.CopyFromSubmatrix(mvnin,1,param -1,0);
			    mvnout=MVNDist(mvn1,mvnnew);
			  }
			else
			  {
			    mvnout = mvnnew;
			  }
			
			if (oldsize >= param)
			  {
			    MVNDist mvn2(oldsize+1-param);
			    mvn2.CopyFromSubmatrix(mvnin,param,oldsize,0);
			    mvnout=MVNDist(mvnout,mvn2);
			  }
   
			mvncov = mvnout.GetCovariance();
		      }
		    else
		      { 
			mvnout = mvnin;
			mvncov = mvnin.GetCovariance();
		      }
		    
		    /* Set parameters mean value and variance*/
		    //cout << "Set parameter mean and variance" << endl;
		    mvnout.means(param) = val;
		    mvncov(param,param) = var;
		    mvnout.SetCovariance(mvncov);
		    
		    vmvnout[v] = new MVNDist(mvnout);
		  }

		/* Save MVN to output */
		cout << "Save file" << endl;
		MVNDist::Save(vmvnout,outfile,mask);
	      }

	    else {
	      /* Section to deal with reading a parameter out to an image */
	      int nVoxels = vmvnin.size();
	      Matrix image;
	      image.ReSize(1,nVoxels);

	      if (bval) {
		cout << "Extracting value for parameter:" << param << endl;
		for (int vox = 1; vox <= nVoxels; vox++)
		  {
		    image(1,vox) = vmvnin[vox-1]->means(param);
		  }
	      }
	      else if (bvar) {
		cout << "Extracting variance for parameter:" << param << endl;
		for (int vox = 1; vox <= nVoxels; vox++)
		  {
		    image(1,vox) = vmvnin[vox-1]->GetCovariance()(param,param);
		  }
	      }

	      cout << "Writing output file" << endl;

              volume4D<float> output(mask.xsize(),mask.ysize(),mask.zsize(),1);
	      copybasicproperties(mask,output);
	      output.setmatrix(image,mask);
	      output.setDisplayMaximumMinimum(output.max(),output.min());
	      output.set_intent(NIFTI_INTENT_NONE,0,0,0);
	      save_volume4D(output,outfile);
	    }
	      
	    cout << "Done." << endl;
	    
	    return 0;
	  }
	catch (const Invalid_option& e)
	  {
	    cout << Exception::what() << endl;
	    Usage();
	  }
	catch (Exception)
	  {
	    cout << Exception::what() << endl;
	  }
	catch (...)
	  {
	    cout << "There was an error!" << endl;
	  }

	return 1;
}

void Usage(const string& errorString)
{
  cout << "\nUsage: mvntool <arguments>\n"
       << "Arguments are mandatory unless they appear in [brackets].\n\n";

  cout << " --help : Prints this information." << endl
       << " --input=<MVNfile> : Name of input MVN file." << endl
       << " --param=<n> : Number of parameter to read/replace/insert." << endl << endl
       << " Extract behaviour (default):" << endl
       << " --output=<NIFIfile> : Name of file for output" << endl
       << "   [--val] : Write parameter value to file." << endl
       << "   [--var] : Write parameter variance to file." << endl << endl
       << " Writing behaviour:" << endl
       << "   [--write] : Overwrite an existing parameter" << endl
       << "   [--new] : Insert a new parameter." << endl
       << "[--output]=<MVNfile> : Name of file for output, overwrites input if not set" << endl
       << " --val=<mean_value> : Mean value for parameter to be written." << endl
       << " --var=<variance> : Variance of parameter to be written." << endl
       << endl;
}
