#include "streamlines.h"



namespace TRACT{

  ColumnVector mean_sph_pol(ColumnVector& A, ColumnVector& B){
    // A and B contain th, ph f. 
    float th,ph;
    ColumnVector rA(3), rB(3);

    rA << (sin(A(1))*cos(A(2))) << (sin(A(1))*sin(A(2))) << (cos(A(1)));
    rB << (sin(B(1))*cos(B(2))) << (sin(B(1))*sin(B(2))) << (cos(B(1)));
    
    if(sum(SP(rA,rB)).AsScalar()>0)
      cart2sph((rA+rB)/2,th,ph);
    else
      cart2sph((rA-rB)/2,th,ph);
    
    A(1)=th; A(2)=ph;
    return A;
  }
  
  void read_masks(vector<string>& masks, const string& filename){
    ifstream fs(filename.c_str());
    string tmp;
    if(fs){
      fs>>tmp;
      do{
	masks.push_back(tmp);
	fs>>tmp;
      }while(!fs.eof());
    }
    else{
      cerr<<filename<<" does not exist"<<endl;
      exit(0);
    }
  }
  
  
  Streamliner::Streamliner():opts(probtrackxOptions::getInstance()),logger(LogSingleton::getInstance()),
			     vols(opts.usef.value()){
    
    read_volume(m_mask,opts.maskfile.value());
    m_part.initialise(0,0,0,0,0,0,opts.steplength.value(),m_mask.xdim(),m_mask.ydim(),m_mask.zdim(),false);
    if(opts.skipmask.value()!="") read_volume(m_skipmask,opts.skipmask.value());
    m_lcrat=5;
    if(opts.loopcheck.value()){
      m_loopcheck.reinitialize(int(ceil(m_mask.xsize()/m_lcrat)+1),int(ceil(m_mask.ysize()/m_lcrat)+1),int(ceil(m_mask.zsize()/m_lcrat)+1),3);
      m_loopcheck=0;
    }
    if(opts.rubbishfile.value()!=""){
      read_volume(m_rubbish,opts.rubbishfile.value());
    }
    if(opts.stopfile.value()!=""){
      read_volume(m_stop,opts.stopfile.value());
    }
    if(opts.prefdirfile.value()!=""){
      read_volume4D(m_prefdir,opts.prefdirfile.value());
    }
 
    vector<string> masknames;
    if(opts.waypoints.value()!=""){
      if(fsl_imageexists(opts.waypoints.value())){
	masknames.push_back( opts.waypoints.value() );
      }
      else{
	read_masks(masknames,opts.waypoints.value());
      }

      for( unsigned int m = 0; m < masknames.size(); m++ ){
	volume<float>* tmpptr =new volume<float>;
	if(opts.verbose.value()>0)
	  cout<<masknames[m]<<endl;
	read_volume(*tmpptr,masknames[m]);
	m_waymasks.push_back(tmpptr);
	m_passed_flags.push_back(false);
	m_own_waymasks.push_back(true);
      }
    } 
    if(opts.seeds_to_dti.value()!=""){
      m_Seeds_to_DTI = read_ascii_matrix(opts.seeds_to_dti.value());
    }
    else{
      m_Seeds_to_DTI=IdentityMatrix(4);
    }
    vols.initialise(opts.basename.value());
    m_path.reserve(opts.nparticles.value());
    m_x_s_init=0;
    m_y_s_init=0;
    m_z_s_init=0;

    // create rotdir for cases where seeding from a freesurfer mesh
    Matrix F(3,3),u(3,3),v(3,3);
    DiagonalMatrix d(3);
    F << -m_Seeds_to_DTI(1,1) << m_Seeds_to_DTI(1,3) << -m_Seeds_to_DTI(1,2)
      << -m_Seeds_to_DTI(2,1) << m_Seeds_to_DTI(2,3) << -m_Seeds_to_DTI(2,2)
      << -m_Seeds_to_DTI(3,1) << m_Seeds_to_DTI(3,3) << -m_Seeds_to_DTI(3,2);
    
    SVD(F*F.t(),d,u,v);
    m_rotdir.ReSize(3,3);
    m_rotdir = (u*sqrt(d)*v.t()).i()*F;

  }
  
  
  bool Streamliner::streamline(const float& x_init,const float& y_init,const float& z_init, const ColumnVector& dim_seeds,const int& fibst,const ColumnVector& dir){ 
    
    //fibst tells tractvolsx which fibre to start with if there are more than one..
    //x_init etc. are in seed space...
    vols.reset(fibst);
    m_x_s_init=x_init; //seed x position in voxels
    m_y_s_init=y_init; // and y
    m_z_s_init=z_init; // and z
    ColumnVector xyz_seeds(3);
    xyz_seeds<<x_init<<y_init<<z_init;
    ColumnVector xyz_dti;
    ColumnVector th_ph_f;
    float xst,yst,zst,x,y,z,tmp2;


    xyz_dti=vox_to_vox(xyz_seeds,dim_seeds,vols.dimensions(),m_Seeds_to_DTI);    

    xst=xyz_dti(1);yst=xyz_dti(2);zst=xyz_dti(3);
    m_path.clear();
    x=xst;y=yst;z=zst;
    m_part.change_xyz(x,y,z);

    if(opts.meshfile.value()!=""){
      // rotate dir using seeds_to_dti*mm_to_vox
      ColumnVector rotdir(3);
      rotdir = m_rotdir*dir;
      m_part.set_dir(rotdir(1),rotdir(2),rotdir(3));//Set the start dir so that we track inwards from cortex
    }
    
    int partlength=0;
    bool rubbish_passed=false;
    bool stop_flag=false;
    //bool has_goneout=false;
      //NB - this only goes in one direction!!
    for(unsigned int pf=0;pf<m_passed_flags.size();pf++) {
      m_passed_flags[pf]=false;  /// only keep it if this streamline went through all the masks
    }

    Matrix DTI_to_Seeds(4,4);
    DTI_to_Seeds = m_Seeds_to_DTI.i();
    for( int it = 1 ; it <= opts.nsteps.value()/2; it++){
      if( (m_mask( round(m_part.x()), round(m_part.y()), round(m_part.z())) > 0) ){
	///////////////////////////////////
	//loopchecking
	///////////////////////////////////
	if(opts.loopcheck.value()){
	  float oldrx=m_loopcheck((int)round(m_part.x()/m_lcrat),(int)round(m_part.y()/m_lcrat),(int)round(m_part.z()/m_lcrat),0);
	  float oldry=m_loopcheck((int)round(m_part.x()/m_lcrat),(int)round(m_part.y()/m_lcrat),(int)round(m_part.z()/m_lcrat),1);
	  float oldrz=m_loopcheck((int)round(m_part.x()/m_lcrat),(int)round(m_part.y()/m_lcrat),(int)round(m_part.z()/m_lcrat),2);
	  if(m_part.rx()*oldrx+m_part.ry()*oldry+m_part.rz()*oldrz<0)
	    {
	      break;
	    }
	    
	  m_loopcheck((int)round(m_part.x()/m_lcrat),(int)round(m_part.y()/m_lcrat),(int)round(m_part.z()/m_lcrat),0)=m_part.rx();
	  m_loopcheck((int)round(m_part.x()/m_lcrat),(int)round(m_part.y()/m_lcrat),(int)round(m_part.z()/m_lcrat),1)=m_part.ry();
	  m_loopcheck((int)round(m_part.x()/m_lcrat),(int)round(m_part.y()/m_lcrat),(int)round(m_part.z()/m_lcrat),2)=m_part.rz();  
	    
	}
	
	if(opts.verbose.value()>1)
	  logger<<m_part;
	
	x=m_part.x();y=m_part.y();z=m_part.z();
	xyz_dti <<x<<y<<z;
	xyz_seeds=vox_to_vox(xyz_dti,vols.dimensions(),dim_seeds,DTI_to_Seeds);
	int x_s =(int)round((float)xyz_seeds(1));
	int y_s =(int)round((float)xyz_seeds(2));
	int z_s =(int)round((float)xyz_seeds(3));
	
	float pref_x=0,pref_y=0,pref_z=0;
	if(opts.prefdirfile.value()!=""){
	  pref_x = m_prefdir((int)xyz_seeds(1),(int)xyz_seeds(2),(int)xyz_seeds(3),0);
	  pref_y = m_prefdir((int)xyz_seeds(1),(int)xyz_seeds(2),(int)xyz_seeds(3),1);
	  pref_z = m_prefdir((int)xyz_seeds(1),(int)xyz_seeds(2),(int)xyz_seeds(3),2); 
	}
	//update every passed_flag
	for( unsigned int wm=0;wm<m_waymasks.size();wm++ ){
	  if( (*m_waymasks[wm])(x_s,y_s,z_s)!=0 ) {
	    m_passed_flags[wm]=true;
	  }
	}
	m_path.push_back(xyz_seeds);
	//	  m_path(it,1)=x_s; 
	//	  m_path(it,2)=y_s;
	//	  m_path(it,3)=z_s;
	partlength++;
	

	if(opts.rubbishfile.value()!=""){
	  if(m_rubbish(x_s,y_s,z_s)!=0){
	    rubbish_passed=true;
	    break;
	  }
	}
	if(opts.stopfile.value()!=""){
	  if(m_stop(x_s,y_s,z_s)!=0){
	    stop_flag=true;
	  }
	  //else
	  if(stop_flag)break;
	}	  
	  
	if(opts.skipmask.value() == ""){
	  th_ph_f=vols.sample(m_part.x(),m_part.y(),m_part.z(),m_part.rx(),m_part.ry(),m_part.rz(),pref_x,pref_y,pref_z);
	}
	else{
	  if(m_skipmask(x_s,y_s,z_s)==0)
	    th_ph_f=vols.sample(m_part.x(),m_part.y(),m_part.z(),m_part.rx(),m_part.ry(),m_part.rz(),pref_x,pref_y,pref_z);
	}
	  
	  
	tmp2=rand(); tmp2/=RAND_MAX;
	if(th_ph_f(3)>tmp2){
	  if(!m_part.check_dir(th_ph_f(1),th_ph_f(2),opts.c_thr.value())){
	    break;
	  }
	    
	  if((th_ph_f(1)!=0&&th_ph_f(2)!=0)){
	    if( (m_mask( round(m_part.x()), round(m_part.y()), round(m_part.z())) != 0) ){
	      if(!opts.modeuler.value())
		m_part.jump(th_ph_f(1),th_ph_f(2));
	      else
		{
		  ColumnVector test_th_ph_f;
		  
		  m_part.testjump(th_ph_f(1),th_ph_f(2));
		  test_th_ph_f=vols.sample(m_part.testx(),m_part.testy(),m_part.testz(),m_part.rx(),m_part.ry(),m_part.rz(),pref_x,pref_y,pref_z);
		  test_th_ph_f=mean_sph_pol(th_ph_f,test_th_ph_f);
		  m_part.jump(test_th_ph_f(1),test_th_ph_f(2));
		  
		}
	    }
	    
	    
	  }
	}
	  
	  
      }
	
    } // Close Step Number Loop
    if(opts.loopcheck.value()){
      m_loopcheck=0;
    }
    
    bool accept_path=true;
    if(m_passed_flags.size()!=0){
      for(unsigned int i=0; i<m_passed_flags.size();i++)
	if(!m_passed_flags[i])
	  accept_path=false;
    }   
    if(rubbish_passed)
      accept_path=false;

    return accept_path;
  }
  
  
  void Counter::initialise(){
    if(opts.simpleout.value()||opts.matrix1out.value()){
      initialise_path_dist();
    }
    if(opts.s2tout.value()){
      initialise_seedcounts();
    }
    if(opts.matrix1out.value()){
      initialise_matrix1();
    }
    if(opts.matrix2out.value()){
      initialise_matrix2();
    }
    if(opts.maskmatrixout.value()){
      initialise_maskmatrix();
    }
  }
  
  void Counter::initialise_seedcounts(){
    
    volume<float> tmp;
    volume<int> tmpint;
    read_masks(m_targetmasknames,opts.targetfile.value());
    m_targflags.resize(m_targetmasknames.size(),0);
    //m_particle_numbers.resize(m_targetmasknames.size());
    //tmpvec.reserve(opts.nparticles.value());
    cout<<"Number of masks "<<m_targetmasknames.size()<<endl;
    //are they initialised to zero?
    for(unsigned int m=0;m<m_targetmasknames.size();m++){
      read_volume(tmp,m_targetmasknames[m]);
      m_targetmasks.push_back(tmp);
      copyconvert(tmp,tmpint);
      tmpint=0;
      m_seedcounts.push_back(tmpint);
      //m_particle_numbers.push_back(tmpvec);
    }

    // where we save the seed counts in text files
    if(opts.seedcountastext.value()){
      
      int numseeds=0;
      if(opts.meshfile.value()==""){
	for(int Wz=m_seeds.minz();Wz<=m_seeds.maxz();Wz++)
	  for(int Wy=m_seeds.miny();Wy<=m_seeds.maxy();Wy++)
	    for(int Wx=m_seeds.minx();Wx<=m_seeds.maxx();Wx++)
	      if(m_seeds.value(Wx,Wy,Wz)!=0)
		numseeds++;
      }
      else{
	ifstream fs(opts.seedfile.value().c_str());
	if(fs){
	  char buffer[1024];
	  fs.getline(buffer,1024);
	  fs >>numseeds;
	  cout<<numseeds<<endl;
	}
      }

      m_SeedCountMat.ReSize(numseeds,m_targetmasknames.size());
      m_SeedCountMat=0;
      m_SeedRow=1;
    }

  }
  

  void Counter::initialise_matrix1(){
    m_Conrow=0;
    int numseeds=0;
    for(int Wz=m_seeds.minz();Wz<=m_seeds.maxz();Wz++)
      for(int Wy=m_seeds.miny();Wy<=m_seeds.maxy();Wy++)
	for(int Wx=m_seeds.minx();Wx<=m_seeds.maxx();Wx++)
	  if(m_seeds.value(Wx,Wy,Wz)!=0)
	    numseeds++;
      
    m_ConMat.reinitialize(numseeds,numseeds,1);
    m_CoordMat.reinitialize(numseeds,3,1);
    int myrow=0;
      
    for(int Wz=m_seeds.minz();Wz<=m_seeds.maxz();Wz++){
      for(int Wy=m_seeds.miny();Wy<=m_seeds.maxy();Wy++){
	for(int Wx=m_seeds.minx();Wx<=m_seeds.maxx();Wx++){
	  if(m_seeds(Wx,Wy,Wz)!=0){
	    m_CoordMat(myrow,0,0)=Wx;
	    m_CoordMat(myrow,1,0)=Wy;
	    m_CoordMat(myrow,2,0)=Wz;
	    myrow++;
	  }
	}
      }
    }
    
  }
  
  void Counter::initialise_matrix2(){
    
    m_Conrow2=0;
    read_volume(m_lrmask,opts.lrmask.value());
    m_beenhere2.reinitialize(m_lrmask.xsize(),m_lrmask.ysize(),m_lrmask.zsize());
    m_lrdim.ReSize(3);
    m_lrdim<<m_lrmask.xdim()<<m_lrmask.ydim()<<m_lrmask.zdim();
    int numseeds=0,numnz=0;
    if(opts.meshfile.value()==""){
    for(int Wz=m_seeds.minz();Wz<=m_seeds.maxz();Wz++)
      for(int Wy=m_seeds.miny();Wy<=m_seeds.maxy();Wy++)
	for(int Wx=m_seeds.minx();Wx<=m_seeds.maxx();Wx++)
	  if(m_seeds.value(Wx,Wy,Wz)!=0)
	    numseeds++;
    }
    else{
      ifstream fs(opts.seedfile.value().c_str());
      if(fs){
	char buffer[1024];
	fs.getline(buffer,1024);
	fs >>numseeds;
	cout<<"numseeds="<<numseeds<<endl;
      }
      
    }
    for(int Wz=m_lrmask.minz();Wz<=m_lrmask.maxz();Wz++)
      for(int Wy=m_lrmask.miny();Wy<=m_lrmask.maxy();Wy++)
	for(int Wx=m_lrmask.minx();Wx<=m_lrmask.maxx();Wx++)
	  if(m_lrmask.value(Wx,Wy,Wz)!=0)
	    numnz++;
    
    
    if(numnz> pow(2,(float)sizeof(short)*8-1)-1){
      cerr<<"Output matrix too big for AVW - stopping."<<endl;
      cerr<<" Remember - you can store your tracts in "<<endl;
      cerr<<" low res even if you want your seeds in high res"<<endl;
      cerr<<" Just subsample the structural space mask"<<endl;
      cerr<<" Although, it must stay in line with the seeds"<<endl;
      exit(-1);
    }

    m_ConMat2.reinitialize(numseeds,numnz,1);
    OUT(m_ConMat2.xsize());

    m_CoordMat2.reinitialize(numseeds,3,1);
    m_CoordMat_tract2.reinitialize(numnz,3,1);
    
    Matrix tempy(numnz,1);
    for(int i=1;i<=numnz;i++){tempy(i,1)=i-1;}
    m_lookup2.addvolume(m_lrmask);
    m_lookup2.setmatrix(tempy.t(),m_lrmask);
      
    int mytrow=0;
    for(int Wz=m_lrmask.minz();Wz<=m_lrmask.maxz();Wz++)
      for(int Wy=m_lrmask.miny();Wy<=m_lrmask.maxy();Wy++)
	for(int Wx=m_lrmask.minx();Wx<=m_lrmask.maxx();Wx++)
	  if(m_lrmask(Wx,Wy,Wz)!=0){
	    m_CoordMat_tract2(mytrow,0,0)=Wx;
	    m_CoordMat_tract2(mytrow,1,0)=Wy;
	    m_CoordMat_tract2(mytrow,2,0)=Wz;
	    mytrow++;
	  }
    
    int myrow=0;
    for(int Wz=m_seeds.minz();Wz<=m_seeds.maxz();Wz++)
      for(int Wy=m_seeds.miny();Wy<=m_seeds.maxy();Wy++)
	for(int Wx=m_seeds.minx();Wx<=m_seeds.maxx();Wx++)
	  if(m_seeds(Wx,Wy,Wz)!=0){
	    m_CoordMat2(myrow,0,0)=Wx;
	    m_CoordMat2(myrow,1,0)=Wy;
	    m_CoordMat2(myrow,2,0)=Wz;
	    myrow++;
	  }
      
      
  }
  
  void Counter::count_streamline(){
    if(opts.simpleout.value()||opts.matrix1out.value()){
      update_pathdist();
    }
    if(opts.s2tout.value()){
      update_seedcounts();
    }
    if(opts.matrix2out.value()){
      update_matrix2_row();
    }
    if(opts.maskmatrixout.value()){
      update_maskmatrix();
    }
  }
  
  void Counter::count_seed(){
    if(opts.matrix1out.value()){
      update_matrix1();
    }
    if(opts.matrix2out.value()){
      next_matrix2_row();
    }
    if(opts.seedcountastext.value()){
      m_SeedRow++;
    }
  }
  
    
  void Counter::clear_streamline(const bool& forwardflag,const bool& backwardflag){
    if(opts.simpleout.value()||opts.matrix1out.value()){
      reset_beenhere(forwardflag,backwardflag);
    }
    if(opts.s2tout.value()){
      reset_targetflags();
    }
    if(opts.matrix2out.value()){
      reset_beenhere2(forwardflag,backwardflag);
    }
    if(opts.maskmatrixout.value()){
      //Do whatever it it you have to do!!
    }
  }
  
  void Counter::update_pathdist(){
    const vector<ColumnVector>& path=m_stline.get_path_ref();
    if(!opts.pathdist.value()){
      for(unsigned int i=0;i<path.size();i++){
	int x_s=int(round(float(path[i](1)))),y_s=int(round(float(path[i](2)))),z_s=int(round(float(path[i](3))));
	if(m_beenhere(x_s,y_s,z_s)==0){
	  m_prob(x_s,y_s,z_s)+=1;
	  m_beenhere(x_s,y_s,z_s)=1;
	}
      }
    }
    else{
      int d=1;
      for(unsigned int i=0;i<path.size();i++){
	int x_s=int(round(float(path[i](1)))),y_s=int(round(float(path[i](2)))),z_s=int(round(float(path[i](3))));
	if(m_beenhere(x_s,y_s,z_s)==0){
	  m_prob(x_s,y_s,z_s)+=d;d++;
	  m_beenhere(x_s,y_s,z_s)=1;
	}
      }
    }
    
  }

  void Counter::reset_beenhere(const bool& forwardflag,const bool& backwardflag){
    if(forwardflag){
      for(unsigned int i=0;i<m_path.size();i++){
	int x_s=int(round(float(m_path[i](1)))),y_s=int(round(float(m_path[i](2)))),z_s=int(round(float(m_path[i](3))));
	m_beenhere(x_s,y_s,z_s)=0;
      }
    }
    if(backwardflag){
      const vector<ColumnVector>& path=m_stline.get_path_ref();
      for(unsigned int i=0;i<path.size();i++){
	int x_s=int(round(float(path[i](1)))),y_s=int(round(float(path[i](2)))),z_s=int(round(float(path[i](3))));
	m_beenhere(x_s,y_s,z_s)=0;
      }
    }
  }
  
  
  void Counter::update_seedcounts(){
    const vector<ColumnVector>& path=m_stline.get_path_ref();
    int xseedvox=int(round(m_stline.get_x_seed()));
    int yseedvox=int(round(m_stline.get_y_seed()));
    int zseedvox=int(round(m_stline.get_z_seed()));

    if(!opts.pathdist.value()){
      for(unsigned int i=0;i<path.size();i++){
	int x_s=int(round(float(path[i](1)))),y_s=int(round(float(path[i](2)))),z_s=int(round(float(path[i](3))));
	for(unsigned int m=0;m<m_targetmasknames.size();m++){
	  if(m_targetmasks[m](x_s,y_s,z_s)!=0 && m_targflags[m]==0){
	    m_seedcounts[m](xseedvox,yseedvox,zseedvox)=m_seedcounts[m](xseedvox,yseedvox,zseedvox)+1;
	    m_targflags[m]=1;
	    //m_particle_numbers[m].push_back(particle_number);

	    if(opts.seedcountastext.value())
	      m_SeedCountMat(m_SeedRow,m+1) += 1;
	    
	  }
	}
      }
    }
    else{
      float d=0;
      int x_s,y_s,z_s;
      for(unsigned int i=0;i<path.size();i++){
	x_s=int(round(float(path[i](1))));y_s=int(round(float(path[i](2))));z_s=int(round(float(path[i](3))));
	if(i>0)
	  d+=sqrt((path[i]-path[i-1]).SumSquare());
	for(unsigned int m=0;m<m_targetmasknames.size();m++){
	  if(m_targetmasks[m](x_s,y_s,z_s)!=0 && m_targflags[m]==0){
	    m_seedcounts[m](xseedvox,yseedvox,zseedvox)+=(int)d;
	    m_targflags[m]=1;
	    //m_particle_numbers[m].push_back(particle_number);
	    
	    if(opts.seedcountastext.value())
	      m_SeedCountMat(m_SeedRow,m+1) += d;

	  }
	}
	
      }
    }
    
  }
  

  
  void Counter::update_matrix1(){
    //after each particle, update_pathdist(), only run this after each voxel
    int Concol=0;
    for(int Wz=m_prob.minz();Wz<=m_prob.maxz();Wz++){
      for(int Wy=m_prob.miny();Wy<=m_prob.maxy();Wy++){
	for(int Wx=m_prob.minx();Wx<=m_prob.maxx();Wx++){
	  if(m_seeds(Wx,Wy,Wz)!=0){
	    if(m_prob(Wx,Wy,Wz)!=0){
	      m_ConMat(m_Conrow,Concol,0)=m_prob(Wx,Wy,Wz);
	    }
	    Concol++;
	  }
	  m_prob(Wx,Wy,Wz)=0;
	  
	}
      }
    }
    
    m_Conrow++;
  }
  
  void Counter::update_matrix2_row(){
    //run this one every streamline - not every voxel..
    const vector<ColumnVector>& path=m_stline.get_path_ref();

    if(!opts.pathdist.value())
      for(unsigned int i=0;i<path.size();i++){
	ColumnVector xyz_seeds=path[i];
	//do something here
	ColumnVector xyz_lr=vox_to_vox(xyz_seeds,m_seedsdim,m_lrdim,m_I);
	
	int x_lr=int(round(float(xyz_lr(1)))),y_lr=int(round(float(xyz_lr(2)))),z_lr=int(round(float(xyz_lr(3))));
	int Concol2=m_lookup2(x_lr,y_lr,z_lr,0);
	if(Concol2!=0){
	  if(m_beenhere2(x_lr,y_lr,z_lr)==0){
	    m_ConMat2(m_Conrow2,Concol2,0)+=1;
	    m_beenhere2(x_lr,y_lr,z_lr)=1;
	  }
	}
	
      }
    else{
      int d=1;
      for(unsigned int i=0;i<path.size();i++){
	ColumnVector xyz_seeds=path[i];
	ColumnVector xyz_lr=vox_to_vox(xyz_seeds,m_seedsdim,m_lrdim,m_I);
	int x_lr=int(round(float(xyz_lr(1)))),y_lr=int(round(float(xyz_lr(2)))),z_lr=int(round(float(xyz_lr(3))));
	int Concol2=m_lookup2(x_lr,y_lr,z_lr,0);
	if(Concol2!=0){
	  if(m_beenhere2(x_lr,y_lr,z_lr)==0){
	    m_ConMat2(m_Conrow2,Concol2,0)+=d;d++;
	    m_beenhere2(x_lr,y_lr,z_lr)=1;
	  }
	}
      }
    }
    
  }
  
  
  
  void Counter::reset_beenhere2(const bool& forwardflag,const bool& backwardflag){
    if(forwardflag){
      for(unsigned int i=0;i<m_path.size();i++){
	ColumnVector xyz_seeds=m_path[i];

	ColumnVector xyz_lr=vox_to_vox(xyz_seeds,m_seedsdim,m_lrdim,m_I);

	int x_lr=int(round(float(xyz_lr(1)))),y_lr=int(round(float(xyz_lr(2)))),z_lr=int(round(float(xyz_lr(3))));
	m_beenhere2(x_lr,y_lr,z_lr)=0;
      }
    }
    if(backwardflag){
      const vector<ColumnVector>& path=m_stline.get_path_ref();
      for(unsigned int i=0;i<path.size();i++){
	ColumnVector xyz_seeds=path[i];

	ColumnVector xyz_lr=vox_to_vox(xyz_seeds,m_seedsdim,m_lrdim,m_I);

	int x_lr=int(round(float(xyz_lr(1)))),y_lr=int(round(float(xyz_lr(2)))),z_lr=int(round(float(xyz_lr(3))));
	m_beenhere2(x_lr,y_lr,z_lr)=0;
      }  
    }
    
  }

  void Counter::save_total(const int& keeptotal){
    
    // save total number of particles that made it through the streamlining
    ColumnVector keeptotvec(1);
    keeptotvec(1)=keeptotal;
    write_ascii_matrix(keeptotvec,logger.appendDir("waytotal"));

  }
  void Counter::save_total(const vector<int>& keeptotal){
    
    // save total number of particles that made it through the streamlining
    ColumnVector keeptotvec(keeptotal.size());
    for (int i=1;i<=(int)keeptotal.size();i++)
      keeptotvec(i)=keeptotal[i-1];
    write_ascii_matrix(keeptotvec,logger.appendDir("waytotal"));

  }

  void Counter::save(){
    if(opts.simpleout.value()){
      save_pathdist();
    }
    if(opts.s2tout.value()){
      save_seedcounts();
    }
    if(opts.matrix1out.value()){
      save_matrix1();
    }
    if(opts.matrix2out.value()){
      save_matrix2();
    }
    if(opts.maskmatrixout.value()){
      save_maskmatrix();
    }
    
  }
  
  void Counter::save_pathdist(){  
    save_volume(m_prob,logger.appendDir("fdt_paths"));
  }
  
  void Counter::save_pathdist(string add){  //for simple mode
    string thisout=opts.outfile.value();
    make_basename(thisout);
    thisout+=add;
    save_volume(m_prob,thisout);
  }

  void Counter::save_seedcounts(){
    for(unsigned int m=0;m<m_targetmasknames.size();m++){
      string tmpname=m_targetmasknames[m];
      
      int pos=tmpname.find("/",0);
      int lastpos=pos;
      
      while(pos>=0){
	lastpos=pos;
	pos=tmpname.find("/",pos);
	// replace / with _
	tmpname[pos]='_';
      }
      
      //only take things after the last pos
      tmpname=tmpname.substr(lastpos+1,tmpname.length()-lastpos-1);
      
      save_volume(m_seedcounts[m],logger.appendDir("seeds_to_"+tmpname));
    }

    if(opts.seedcountastext.value()){
      write_ascii_matrix(m_SeedCountMat,logger.appendDir("matrix_seeds_to_all_targets"));
    }

  }
    
  // the following is a helper function for save_matrix*
  //  to convert between nifti coords (external) and newimage coord (internal)
  void applycoordchange(volume<int>& coordvol, const Matrix& old2new_mat)
  {
    for (int n=0; n<=coordvol.maxx(); n++) {
      ColumnVector v(4);
      v << coordvol(n,0,0) << coordvol(n,1,0) << coordvol(n,2,0) << 1.0;
      v = old2new_mat * v;
      coordvol(n,0,0) = MISCMATHS::round(v(1));
      coordvol(n,1,0) = MISCMATHS::round(v(2));
      coordvol(n,2,0) = MISCMATHS::round(v(3));
    }
  }

  void Counter::save_matrix1(){
    save_volume(m_ConMat,logger.appendDir("fdt_matrix1"));
    applycoordchange(m_CoordMat, m_seeds.niftivox2newimagevox_mat().i());
    save_volume(m_CoordMat,logger.appendDir("coords_for_fdt_matrix1"));
    applycoordchange(m_CoordMat, m_seeds.niftivox2newimagevox_mat());
  }

  void Counter::save_matrix2(){
    if(!opts.splitmatrix2.value()){
      save_volume(m_ConMat2,logger.appendDir("fdt_matrix2"));
      applycoordchange(m_CoordMat2, m_seeds.niftivox2newimagevox_mat().i());
      save_volume(m_CoordMat2,logger.appendDir("coords_for_fdt_matrix2"));
      applycoordchange(m_CoordMat2, m_seeds.niftivox2newimagevox_mat());
      applycoordchange(m_CoordMat_tract2, m_lrmask.niftivox2newimagevox_mat().i());
      save_volume(m_CoordMat_tract2,logger.appendDir("tract_space_coords_for_fdt_matrix2"));
      applycoordchange(m_CoordMat_tract2, m_lrmask.niftivox2newimagevox_mat());
      save_volume4D(m_lookup2,logger.appendDir("lookup_tractspace_fdt_matrix2"));
    }
    else{
      cout << "saving matrix2 into splitted files" << endl;

      int nsplits = 10;
      while( float(m_ConMat2.xsize()/nsplits) >= 32767 ){
	  nsplits++;
      }

      int nrows = std::floor(float(m_ConMat2.xsize()/nsplits))+1;
      volume<int> tmpmat;

      applycoordchange(m_CoordMat2, m_seeds.niftivox2newimagevox_mat().i());

      for(int i=1;i<=nsplits;i++){
	int first_row = (i-1)*nrows+1;
	int last_row  = i*nrows > m_ConMat2.xsize() ? m_ConMat2.xsize() : i*nrows;
	if(first_row > m_ConMat2.xsize()) break;

	// set limits
	m_ConMat2.setROIlimits(first_row-1,m_ConMat2.miny(),m_ConMat2.minz(),last_row-1,m_ConMat2.maxy(),m_ConMat2.maxz());
	m_ConMat2.activateROI();
	tmpmat = m_ConMat2.ROI();
	save_volume(tmpmat,logger.appendDir("fdt_matrix2_"+num2str(i)));

	m_CoordMat2.setROIlimits(first_row-1,m_CoordMat2.miny(),m_CoordMat2.minz(),last_row-1,m_CoordMat2.maxy(),m_CoordMat2.maxz());
	m_CoordMat2.activateROI();
	tmpmat = m_CoordMat2.ROI();
	save_volume(tmpmat,logger.appendDir("coords_for_fdt_matrix2_"+num2str(i)));


      }

      applycoordchange(m_CoordMat_tract2, m_lrmask.niftivox2newimagevox_mat());
      save_volume4D(m_lookup2,logger.appendDir("lookup_tractspace_fdt_matrix2"));

      applycoordchange(m_CoordMat2, m_seeds.niftivox2newimagevox_mat());
      applycoordchange(m_CoordMat_tract2, m_lrmask.niftivox2newimagevox_mat().i());
      save_volume(m_CoordMat_tract2,logger.appendDir("tract_space_coords_for_fdt_matrix2"));

    }
  }
  
  int Seedmanager::run(const float& x,const float& y,const float& z,bool onewayonly, int fibst){
    ColumnVector dir(3);
    dir=0;
    return run(x,y,z,onewayonly,fibst,dir);
  }
  // this function now returns the total number of pathways that survived a streamlining (SJ)
  int Seedmanager::run(const float& x,const float& y,const float& z,bool onewayonly, int fibst,const ColumnVector& dir){
    //onewayonly for mesh things..
    cout <<x<<" "<<y<<" "<<z<<endl;
    if(opts.fibst.set()){
      fibst=opts.fibst.value()-1;
      OUT(fibst);
   }
    else{
      if(fibst == -1){
	fibst=0;//m_seeds(int(round(x)),int(round(y)),int(round(z)))-1;//fibre to start with is taken from seed volume..
    }
      if(opts.randfib.value()){
	float tmp=rand()/RAND_MAX * float(m_stline.nfibres()-1);
	fibst = (int)round(tmp);
	//if(tmp>0.5)
	//fibst=0;
	//else
	//fibst=1;// fix this for > 2 fibres
      } 
    }
    
    int nlines=0;
    for(int p=0;p<opts.nparticles.value();p++){
      if(opts.verbose.value()>1)
	logger.setLogFile("particle"+num2str(p));
      
      m_stline.reset();
      bool forwardflag=false,backwardflag=false;
      bool counted=false;
      if(!onewayonly){
	if(m_stline.streamline(x,y,z,m_seeddims,fibst,dir)){ //returns whether to count the streamline or not
	  forwardflag=true;
	  m_counter.store_path();
	  m_counter.count_streamline();
	  nlines++;counted=true;
	}
	m_stline.reverse();
      }
      if(m_stline.streamline(x,y,z,m_seeddims,fibst,dir)){
	backwardflag=true;
	m_counter.count_streamline();
	if(!counted)nlines++; // the other half has is counted here

      }
     
      m_counter.clear_streamline(forwardflag,backwardflag); 
    }

    m_counter.count_seed();
    
    return nlines;
    
  }


}
  
  

