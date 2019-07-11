/*  FSLView - 2D/3D Interactive Image Viewer

    Authors:    Rama Aravind Vorray
		James Saunders
		David Flitney 
		Mark Jenkinson
		Stephen Smith

    FMRIB Image Analysis Group

    Copyright (C) 2002-2005 University of Oxford  */

/*  CCOPYRIGHT */

#include <string>
#include <vector>
#include <boost/shared_ptr.hpp>

#include <qsettings.h>
#include <qrect.h>

class Preferences: public QSettings
{
public:
  typedef boost::shared_ptr<Preferences> Handle;

  std::string inqFSLDir() const;
  std::string inqMni152() const;
  std::string inqAssistantPath() const;
  std::string inqAtlasPath() const;
  QRect inqGeometry(int, int) const;

  std::vector<std::string> inqAtlasPathElements() const;

  void setFSLDir(const std::string&);
  void setMni152(const std::string&);
  void setAssistantPath(const std::string&);
  void setAtlasPath(const std::string&);
  void setGeometry(const QRect&);

  static Handle getInstance();

private:
  Preferences();

  static Handle m_instance;

  struct Implementation;  
  const std::auto_ptr< Implementation > m_impl;
};

