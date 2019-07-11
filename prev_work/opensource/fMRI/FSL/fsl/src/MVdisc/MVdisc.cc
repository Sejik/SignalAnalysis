/*
 Brian Patenaude, 
 FMRIB Image Analysis Group
 */
#include <iostream>
#include "MVdisc.h"
#include "fslvtkio/fslvtkio.h"

#include <time.h>
#include <stdlib.h>
#include <string>
#include <fstream>
#include <stdio.h>
#include <algorithm>
#include "meshclass/meshclass.h"
#include "newimage/newimageall.h"
#include "first_lib/first_newmat_vec.h"

using namespace std;
using namespace NEWIMAGE;
using namespace mesh;
using namespace fslvtkio;
using namespace FIRST_LIB;
namespace mvdisc {
	MVdisc::MVdisc(){

	}
	MVdisc::~MVdisc(){

	}
	

	void MVdisc::quickSVD(const Matrix & data,  DiagonalMatrix &D,Matrix &U, Matrix &V ) const 
	{
		//this is appropriate for the case where number of subjects is much less than the number of dimnesions	
		SVD(data.t()*data, D,U,V);
		
		for (int i=0; i<D.Nrows();i++){
			D.element(i)=sqrt(D.element(i));
		}
		
		U=data*V*( D.i() );
		
	}
	
	void MVdisc::quickSVD(const Matrix & data,  DiagonalMatrix &D,Matrix &U ) const
	{
		//this is appropriate for the case where number of subjects is much less than the number of dimnesions	
		Matrix V;
		SVD(data.t()*data, D,U,V);
		
		for (int i=0; i<D.Nrows();i++){
			D.element(i)=sqrt(D.element(i));
		}
		
		U=data*V*( D.i() );
		V.Release();
	}
	
	
	ReturnMatrix MVdisc::calculateClassMeans(const Matrix & Data, const ColumnVector & target, vector<unsigned int> & nk) const
	{
		
		//return number of subjects per class
		unsigned int K=1;	//count the number of classes
		for (int i=0;i< target.Nrows();i++)
			if (target.element(i)>=K)
				K++;
		
		unsigned int N=Data.Ncols();	//store total numbver of subjects
		if (N!=static_cast<unsigned int>(target.Nrows()))
			cerr<<"Number of Subjects in Design does not math that in the data."<<endl;

		unsigned int p=Data.Nrows(); //number of dimensions
		
		//stores number of subjects for each class
		nk.clear();
		for (unsigned int cl=0;cl<K;cl++)
			nk.push_back(0);
				
		//declare matrix of means
		Matrix muM(p,K);
		muM=0.0;//zero matrix
		
		//sums subjects witin classes, and count number of subjects
		for (unsigned int cl=0;cl<K;cl++)
			for (unsigned int i=0;i<N;i++)
				if (target.element(i)==cl)
				{//if subjects belongs to class cl 
					muM.Column(cl+1)+=Data.Column(i+1);
					nk.at(cl)++;
				}
			
			//normalize by number of subjects
		for (unsigned int cl=0;cl<K;cl++)
			muM.Column(cl+1)/=nk.at(cl);

	
		muM.Release();
		return muM;
		
	}
	
	ReturnMatrix MVdisc::sortAndDemeanByClass(const Matrix & Data, const ColumnVector & target, const Matrix & muM, const vector<unsigned int> & nk, ColumnVector & targSorted) const
	{
		//return number of subjects per class
		
		short K=static_cast<short>(nk.size());	//count the number of classes
		int N=Data.Ncols();	//store total numbver of subjects
		int p=Data.Nrows(); //number of dimensions

		//check for consistency
		if (N!=target.Nrows())
			throw mvdiscException("Number of Subjects in Design does not match that in the data.");
	
		
		//declare matrix of means
		targSorted.ReSize(target.Nrows());
		Matrix DataSorted(p,N);//sorted and demeaned data
			
			//sort data by class and demean	
			int sortCount=0;
			for (int cl=0;cl<K;cl++) //for each class
				for (int i=0;i<N;i++)	//search through each suject					
					if (target.element(i)==cl) //pick out that class
					{//if subjects belongs to class cl 
						DataSorted.Column(sortCount+1)=Data.Column(i+1)-muM.Column(cl+1);
						targSorted.element(sortCount)=cl;
						sortCount++;
					}
			DataSorted.Release();					
			return DataSorted;
	}
	
	void MVdisc::estimateCommonCov(const Matrix & DeMean, const vector< unsigned int > & nK, Matrix & U, vector<float> & vD) const
	{
		//K is number of classes
		unsigned int K=nK.size();
		int p=DeMean.Nrows();
		int N=DeMean.Ncols();	//store total numbver of subjects
		
		//check for consistency
		//if (N!=target.Nrows())
		//	throw mvdiscException("Number of Subjects in Design does not math that in the data.");
		
		DiagonalMatrix D;
		//Check if number of subjects is greater than number of dimensions
		if (N > p)
		{
			//dealing with a full-rank matrix
			Matrix COV(p,p);
			COV=0;
		
			int cumsum=0;
			for (unsigned int i=0 ; i<K;i++)
			{
				COV+=DeMean.Columns(cumsum+1,cumsum+nK.at(i)) * ( DeMean.Columns(cumsum+1,cumsum+nK.at(i)).t());
				cumsum+=nK.at(i);		
			}
			COV/=N-K;
			
			SVD(COV,D,U);
			
			for (int i =0; i<D.Nrows();i++){
				D.element(i)=sqrt( D.element(i));
			}
				COV.Release();
		}else{
			quickSVD(DeMean,D,U);
			D/=sqrt(N-K);
		}
		
		vD.clear();
		for (int i=0; i<D.Nrows();i++)	
			vD.push_back(D.element(i));
		
	}
	
	void MVdisc::estimateClassCovs(const Matrix & DeMean, const ColumnVector & target, const vector< int > & nK, vector< Matrix > & vU, vector< DiagonalMatrix > & vD) const 
	{
		//K is number of classes
		vD.clear();
		vU.clear();
		
		
		int N=DeMean.Ncols();	//store total numbver of subjects
	//	if (N!=target.Nrows())
	//		cerr<<"Number of Subjects in Design does not math that in the data."<<endl;
	
		unsigned int K=nK.size();
		//int p=DeMean.Nrows();
		
		//Check if number of subjects is greater than number of dimensions
		int cumsum=0;
		for (unsigned int i=0 ; i<K;i++){
			//Matrix COV(p,p);
			Matrix U;
			DiagonalMatrix D;
			if (N > nK.at(i)){
				//dealing with a full-rank matrix
							//	cout<<"well cond"<<endl;

				//cout<<((DeMean.Columns(cumsum+1,cumsum+nK.at(i)) * DeMean.Columns(cumsum+1,cumsum+nK.at(i)).t()).AsScalar()/(N-1))<<endl;
				SVD((DeMean.Columns(cumsum+1,cumsum+nK.at(i)) * DeMean.Columns(cumsum+1,cumsum+nK.at(i)).t())/(N-1),D,U);
				for (int i =0; i<D.Nrows();i++){
					cout<<"D2 "<<D.element(i)<<endl;
					D.element(i)=sqrt( D.element(i));
				}
				
			}else{
				//cout<<"ill cond"<<endl;
				quickSVD(DeMean.Columns(cumsum+1,cumsum+nK.at(i))/(N-1),D,U);
				
			}
			
			vU.push_back(U);
			vD.push_back(D);
			
			cumsum+=nK.at(i);	
			
			//D.Release();
			//U.Release();
			
		}
		
		
		
	}
	
	template<class T> 
	vector<T> MVdisc::threshInvert(const vector<T> & D, const T & p) const 
	 {
		vector<T> Di;
		
		T ssq=0;
		for (typename vector<T>::const_iterator i=D.begin(); i!=D.end() ;i++)
		{
			ssq+=*i;
			Di.push_back(0);
		}
			
		T thresh=sqrt(ssq*p);//fraction of total variance
		
		typename vector<T>::iterator j=Di.begin();
		for (typename vector<T>::const_iterator i=D.begin();i!=D.end();i++,j++)
			if ( (*i) > thresh )
				(*j) = 1/(*i);

		return Di;
	 }
	 
	 
	//returns a vector of classifications
	vector<unsigned int> MVdisc::applyLDA(const vector<ColumnVector> & Data, const float & eigThresh) const 
	{
		if ( (LDAmu.Ncols()==0) || (LDAmu.Nrows()==0) || (LDAcov_Vecs.Nrows()==0) || (LDAcov_Vecs.Ncols()==0) || (LDAcov_Eigs.size()==0)  || (LDAnsubs.size()==0) )
			throw mvdiscException("The LDA parameters have not been set or are ill-defined");
	
		vector<unsigned int> v_classified;
			
				unsigned int Dclass=0;
				float decisionOld=0;
			
				//perform the discrimiant
				DiagonalMatrix Di;
				Di=first_newmat_vector::vectorToDiagonalMatrix<float>( threshInvert<float>(LDAcov_Eigs,eigThresh) );
				//invert with threhsold
				
				for (vector<ColumnVector>::const_iterator i=Data.begin();i!=Data.end();i++)
				{
			
				for (unsigned int cl=0;cl<LDAnsubs.size();cl++)//calculate for each class
				{
					float centDist=(Di * LDAcov_Vecs.t() * (LDAmu.Column(cl+1) - (*i))).SumSquare();
					float descPi=log(static_cast<float>(LDAnsubs.at(cl))/LDAnsubs.size());
					float decision=-0.5*(centDist) + descPi;
					
					if (cl==0)
					{
						Dclass=0;
						decisionOld=decision;
					}else if (decision>decisionOld)
					{
						Dclass=cl;
						decisionOld=decision;
					}
				}	
									v_classified.push_back(Dclass);

				}
				return v_classified;
			
	}
	
		//returns a vector of classifications
	short MVdisc::applyLDA(ColumnVector & Data, const float & eigThresh) const 
	{
		if ( (LDAmu.Ncols()==0) || (LDAmu.Nrows()==0) || (LDAcov_Vecs.Nrows()==0) || (LDAcov_Vecs.Ncols()==0) || (LDAcov_Eigs.size()==0)  || (LDAnsubs.size()==0) )
			throw mvdiscException("The LDA parameters have not been set or are ill-defined");
				
				short Dclass=0;
				float decisionOld=0;
			
				//perform the discrimiant
				DiagonalMatrix Di;
				Di=first_newmat_vector::vectorToDiagonalMatrix<float>( threshInvert<float>(LDAcov_Eigs,eigThresh) );
				//invert with threhsold
				
			
				for (short cl=0;cl<static_cast<short>(LDAnsubs.size());cl++)//calculate for each class
				{
					float centDist=(Di * LDAcov_Vecs.t() * (LDAmu.Column(cl+1) - Data)).SumSquare();
					float descPi=log(static_cast<float>(LDAnsubs.at(cl))/LDAnsubs.size());
					float decision=-0.5*(centDist) + descPi;
					
					if (cl==0)
					{
						Dclass=0;
						decisionOld=decision;
					}else if (decision>decisionOld)
					{
						Dclass=cl;
						decisionOld=decision;
					}
				}	
							
				
				return Dclass;
			
	}

	

void MVdisc::estimateLDAParams(const Matrix & Data, const ColumnVector & target)
{
	//asisgns first and second required LDA parameters
	LDAmu=calculateClassMeans(Data, target, LDAnsubs);
	
	//assigend demenad matrix (with sorting) and sorted target
	
	//this is currently limited to 2 classes??? 
	Matrix demeaned; //demeaned data
	ColumnVector targSorted;
	demeaned=sortAndDemeanByClass(Data, target, LDAmu, LDAnsubs, targSorted);
	
	//estiamte covariance matrix and setting thrid LDA parameters (uses SVD if number of subjects is less than number of dimensions)
	estimateCommonCov(demeaned, LDAnsubs, LDAcov_Vecs, LDAcov_Eigs);
				
	demeaned.Release();
}

void MVdisc::estimateAndAppendLDAParams(const Matrix & Data, const ColumnVector & target)
{

	cout<<"mean hmm2 "<<LDAmu.Nrows()<<" "<<LDAmu.Ncols()<<endl;
	//asisgns first and second required LDA parameters
	//LDAnsubs.clear();
	Matrix LDAmu_temp= calculateClassMeans(Data, target, LDAnsubs);
	//assigend demenad matrix (with sorting) and sorted target
	
	//this is currently limited to 2 classes??? 
	Matrix demeaned; //demeaned data
	ColumnVector targSorted;
		cout<<"meandone noew sort"<<" "<<endl;

	demeaned=sortAndDemeanByClass(Data, target, LDAmu_temp, LDAnsubs, targSorted);
	
	//estiamte covariance matrix and setting thrid LDA parameters (uses SVD if number of subjects is less than number of dimensions)
	Matrix LDAcov_Vecs_temp;
	vector<float> LDAcov_Eigs_temp;
		cout<<"estimate cov"<<" "<<endl;

	estimateCommonCov(demeaned, LDAnsubs, LDAcov_Vecs_temp, LDAcov_Eigs_temp);
	
	//appebd vecs
	LDAcov_Vecs = LDAcov_Vecs & LDAcov_Vecs_temp;
	//append eigs
	for (vector<float>::iterator i= LDAcov_Eigs_temp.begin();i!= LDAcov_Eigs_temp.end();i++)
		 LDAcov_Eigs.push_back(*i);
	
	LDAmu=LDAmu & LDAmu_temp;
				
	demeaned.Release();
}

	
void MVdisc::saveLDAParams(const string & outname)  const 
{
	cout<<"saving stuff "<<outname<<endl;
	//this is currently limited to 2 classes 
	fslvtkIO * discOut = new fslvtkIO();
	discOut->setDataType(static_cast<fslvtkIO::DataType>(0));
				//store mean 
				cout<<"points "<<LDAmu.Nrows()<<" "<<LDAmu.Ncols()<<endl;
				discOut->setPoints(LDAmu.Column(1));
				discOut->addFieldData(first_newmat_vector::wrapMatrix(LDAmu.Column(2)),"mean2","float");
				
				discOut->addFieldData(LDAcov_Vecs,"Covariance_EigVecs","float");
				discOut->addFieldData<float>(LDAcov_Eigs,"Covariance_EigVals","float");
				discOut->addFieldData<unsigned int>(LDAnsubs,"number_of_subjects","float");
				
				discOut->save(outname);
					cout<<"done saving stuff"<<endl;

				delete discOut;
}

void MVdisc::saveLDAParams(const string & outname, const Matrix & polygons)  const 
{
	cout<<"saving stuff "<<outname<<endl;
	//this is currently limited to 2 classes 
	fslvtkIO * discOut = new fslvtkIO();
	discOut->setDataType(static_cast<fslvtkIO::DataType>(0));
				//store mean 
				cout<<"points "<<LDAmu.Nrows()<<" "<<LDAmu.Ncols()<<endl;
				discOut->setPoints(LDAmu.Column(1));
				discOut->setPolygons(polygons);
				discOut->addFieldData(first_newmat_vector::wrapMatrix(LDAmu.Column(2)),"mean2","float");
				
				discOut->addFieldData(LDAcov_Vecs,"Covariance_EigVecs","float");
				discOut->addFieldData<float>(LDAcov_Eigs,"Covariance_EigVals","float");
				discOut->addFieldData<unsigned int>(LDAnsubs,"number_of_subjects","float");
				
				discOut->save(outname);
					cout<<"done saving stuff"<<endl;

				delete discOut;
}

float MVdisc::run_LOO_LDA(const NEWMAT::Matrix & Data, const ColumnVector & target)
{
	unsigned int N=Data.Ncols();
	float accuracy=0;
	for (unsigned int i=1;i<=N;i++)//main loop across subjects
	{
		Matrix DataLOO;
		ColumnVector TargetLOO;
			if (i==1)
			{
				DataLOO=Data.SubMatrix(1,Data.Nrows(),i+1,Data.Ncols());
				TargetLOO=target.SubMatrix(i+1,Data.Ncols(),1,1);
			}else if (i==N)
			{
				DataLOO=Data.SubMatrix(1,Data.Nrows(),1,i-1);
				TargetLOO=target.SubMatrix(1,i-1,1,1);
			}else
			{
				DataLOO=Data.SubMatrix(1,Data.Nrows(),1,i-1) | Data.SubMatrix(1,Data.Nrows(),i+1,Data.Ncols());
				TargetLOO= target.SubMatrix(1,i-1,1,1) & target.SubMatrix(i+1,Data.Ncols(),1,1);
			}
		
		estimateLDAParams(DataLOO,TargetLOO);
		ColumnVector testSub=Data.Column(i);
		short cl=applyLDA(testSub,0.00);
		if (cl==target.element(i-1))
			accuracy++;
	}
	return accuracy/N;
}



	}
