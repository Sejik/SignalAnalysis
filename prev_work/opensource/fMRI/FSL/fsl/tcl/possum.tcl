# Possum - GUI for simulating FMRI
#
# Ivana Drobnjak and Mark Jenkinson, FMRIB Image Analysis Group
#
# Copyright (C) 2006-2007 University of Oxford
#
#   Part of FSL - FMRIB's Software Library
#   http://www.fmrib.ox.ac.uk/fsl
#   fsl@fmrib.ox.ac.uk
#   
#   Developed at FMRIB (Oxford Centre for Functional Magnetic Resonance
#   Imaging of the Brain), Department of Clinical Neurology, Oxford
#   University, Oxford, UK
#   
#   
#   LICENCE
#   
#   FMRIB Software Library, Release 4.0 (c) 2007, The University of
#   Oxford (the "Software")
#   
#   The Software remains the property of the University of Oxford ("the
#   University").
#   
#   The Software is distributed "AS IS" under this Licence solely for
#   non-commercial use in the hope that it will be useful, but in order
#   that the University as a charitable foundation protects its assets for
#   the benefit of its educational and research purposes, the University
#   makes clear that no condition is made or to be implied, nor is any
#   warranty given or to be implied, as to the accuracy of the Software,
#   or that it will be suitable for any particular purpose or for use
#   under any specific conditions. Furthermore, the University disclaims
#   all responsibility for the use which is made of the Software. It
#   further disclaims any liability for the outcomes arising from using
#   the Software.
#   
#   The Licensee agrees to indemnify the University and hold the
#   University harmless from and against any and all claims, damages and
#   liabilities asserted by third parties (including claims for
#   negligence) which arise directly or indirectly from the use of the
#   Software or the sale of any products based on the Software.
#   
#   No part of the Software may be reproduced, modified, transmitted or
#   transferred in any form or by any means, electronic or mechanical,
#   without the express permission of the University. The permission of
#   the University is not required if the said reproduction, modification,
#   transmission or transference is done without financial return, the
#   conditions of this Licence are imposed upon the receiver of the
#   product, and all original and amended source code is included in any
#   transmitted product. You may be held legally responsible for any
#   copyright infringement that is caused or encouraged by your failure to
#   abide by these terms and conditions.
#   
#   You are not permitted under this Licence to use this Software
#   commercially. Use for which any financial return is received shall be
#   defined as commercial use, and includes (1) integration of all or part
#   of the source code or the Software into a product for sale or license
#   by or on behalf of Licensee to third parties or (2) use of the
#   Software or any derivative of it for research with the final aim of
#   developing software products for sale or license to a third party or
#   (3) use of the Software or any derivative of it for research with the
#   final aim of developing non-software products for sale or license to a
#   third party, or (4) use of the Software to provide any service to an
#   external organisation for which payment is received. If you are
#   interested in using the Software commercially, please contact Isis
#   Innovation Limited ("Isis"), the technology transfer company of the
#   University, to negotiate a licence. Contact details are:
#   innovation@isis.ox.ac.uk quoting reference DE/1112.


source $FSLDIR/tcl/fslstart.tcl
set VARS(history) {}
if [ info exists env(POSSUMDIR) ] {
    set POSSUMDIR $env(POSSUMDIR)
} else {
   set POSSUMDIR $FSLDIR
}
puts $POSSUMDIR
proc possum { w } {
    global entries guivars FSLDIR PWD HOME 
    # ---- Set up Frames ----
    toplevel $w
    wm title $w "Possum"
    wm iconname $w "Possum"
    wm iconbitmap $w @${FSLDIR}/tcl/fmrib.xbm
    #    tixBalloon    $w.bhelp
    frame $w.f
    NoteBook $w.nb -side top -bd 2 -tabpady {5 5} -arcradius 3
    $w.nb insert 0 object -text "Object"
    $w.nb insert 1 pulse -text "Pulse sequence"
    $w.nb insert 2 b0field -text "B0 field"
    $w.nb insert 3 motion -text "Motion"
    $w.nb insert 4 activation -text "Activation"
    $w.nb insert 5 noise -text "Noise"
    $w.nb insert 6 output -text "Output"
    $w.nb raise object
    
    #----- Object-------
    set objectlf [$w.nb getframe object]
    set entries($w,obvol) ${FSLDIR}/data/possum/brain.nii.gz
    possum:updateOBprop $w ${FSLDIR}/data/possum/brain.nii.gz
    FileEntry $w.obvol \
	-textvariable entries($w,obvol) \
	-filetypes IMAGE \
	-label "Input Object      " \
	-title "Select" \
	-width 40 \
	-filedialog directory \
        -command  "possum:updateOBprop $w; possum:updatecomptime $w "
    pack $w.obvol -in $objectlf -anchor w -padx 3 -pady 3
    frame $w.objim
    label $w.objim.label -image "" -text " "
    button $w.objim.preview -text "Preview image" -command "possum:previewimage $w"
    pack $w.objim.preview $w.objim.label -in $w.objim -pady 10
    pack $w.objim -in  $objectlf -anchor w -padx 3 -pady 3

    #-------- Pulse sequence -----------
    set pulself [$w.nb getframe pulse]
    LabelFrame $w.pul -text "EPI" -font {Helvetica 11 bold}
    pack $w.pul -in $pulself -side top -anchor w -padx 3 -pady 3
    
    # set up default values
    set entries($w,te) 0.030
    set entries($w,tr) 3
    set entries($w,trslc) 0.12
    set entries($w,autotrslc) 1
    set entries($w,outsize_nx) 64
    set entries($w,outsize_ny) 64
    set entries($w,outsize_nz) 1   
    set entries($w,outsize_dx) 4.0
    set entries($w,outsize_dy) 4.0
    set entries($w,outsize_dz) 1.0
    set entries($w,numvol) 1
    set entries($w,gap) 0
    set entries($w,bw) 100000
    set entries($w,zstart) 70
    set entries($w,readgrad) x
    set entries($w,phencode) y
    set entries($w,slcselect) z
    set entries($w,plus) +
    set entries($w,pluss) +
    set entries($w,maxG) 0.055
    set entries($w,riseT) 0.00022
    set entries($w,slcprof) "$FSLDIR/data/possum/slcprof"
    set entries($w,numproc) 1
    set entries($w,comptime) 0
    set entries($w,motion_yn) 0
    set entries($w,pulsechecktest) 1
    set entries($w,b0inh_yn) 0
    set entries($w,b0inhtime_yn) 0
    set entries($w,cover) 100
    set entries($w,flipangle) 90

    # calculate dependendent quantities from the defaults
    possum:updateTRSLC $w
    possum:updateFOV $w 
    possum:updateechosp $w
    possum:updatecomptime $w 
    
    # set up the GUI widgets
    frame $w.t
    label $w.t.lab -text "" -width 0
    LabelSpinBox $w.t.x -label " TE (s)" -width 8 \
         -textvariable entries($w,te) -range {0.0 10000.0 0.001}
    LabelSpinBox $w.t.y -label " TR (s)" -width 8 \
         -textvariable entries($w,tr) -range {0.0 10000.0 0.001} \
	-command "$w.t.y.spin.e validate; possum:updateTRSLC $w" \
	-modifycmd "possum:updateTRSLC $w"
    frame $w.t.trs -borderwidth 1 -relief groove
    LabelSpinBox $w.t.trs.z -label " TRslice (s)" -width 8 \
         -textvariable entries($w,trslc) -range {0.0 10000.0 0.001}
    checkbutton $w.t.trs.yn -text "Autoset" -variable entries($w,autotrslc) -command "possum:updateTRSLC $w" -padx 5
    pack $w.t.trs.z $w.t.trs.yn -in $w.t.trs -side left -anchor w -padx 3 -pady 3
    pack $w.t.lab $w.t.x $w.t.y $w.t.trs -in $w.t -side left -anchor w -padx 3 -pady 3

    frame $w.n
    label $w.n.lab -text "Number of Voxels: " -width 22 -anchor w -justify left 
    LabelSpinBox $w.n.x -label " X "  -width 6 \
         -textvariable entries($w,outsize_nx) -range { 1   10000  1 } \
	-command "$w.n.x.spin.e validate; possum:updateFOV $w; possum:updatecomptime $w; possum:updateechosp $w" \
	-modifycmd "possum:updateFOV $w; possum:updatecomptime $w; possum:updateechosp $w"
    LabelSpinBox $w.n.y -label " Y "  -width 6 \
	 -textvariable entries($w,outsize_ny) -range { 1   10000 1 } \
	-command "$w.n.y.spin.e validate; possum:updateFOV $w;possum:updatecomptime $w;possum:updateechosp $w" \
	 -modifycmd " possum:updateFOV $w;possum:updatecomptime $w;possum:updateechosp $w"
    LabelSpinBox $w.n.z -label " Z "  -width 6 \
	 -textvariable entries($w,outsize_nz) -range { 1   10000 1 } \
	-command "$w.n.z.spin.e validate; possum:updateFOV $w;possum:updatecomptime $w;possum:updateechosp $w; possum:updateTRSLC $w" \
	 -modifycmd " possum:updateFOV $w;possum:updatecomptime $w;possum:updateechosp $w; possum:updateTRSLC $w"
    pack $w.n.lab $w.n.x $w.n.y $w.n.z -in $w.n -side left -anchor w -padx 3 -pady 3
     
    frame $w.d
    label $w.d.lab -text "Voxel Size (mm): " -width 22 -anchor w -justify left 
    LabelSpinBox $w.d.x -label " X " -width 6 \
	 -textvariable entries($w,outsize_dx) -range { 0.000001  10000.0 0.1 } \
	-command "$w.d.x.spin.e validate; possum:updateFOV $w; possum:updatecomptime $w;possum:updateechosp $w" \
	-modifycmd " possum:updateFOV $w; possum:updatecomptime $w;possum:updateechosp $w"
   
    LabelSpinBox $w.d.y -label " Y "  -width 6 \
	 -textvariable entries($w,outsize_dy) -range { 0.000001   10000.0  0.1 } \
	-command "$w.d.y.spin.e validate; possum:updateFOV $w;possum:updatecomptime $w;possum:updateechosp $w" \
	-modifycmd " possum:updateFOV $w; possum:updatecomptime $w;possum:updateechosp $w"
   
    LabelSpinBox $w.d.z -label " Z "  -width 6 \
	 -textvariable entries($w,outsize_dz) -range { 0.000001   10000.0  0.1 } \
	-command "$w.d.z.spin.e validate; possum:updateFOV $w; possum:updatecomptime $w;possum:updateechosp $w" \
	-modifycmd "possum:updateFOV $w; possum:updatecomptime $w;possum:updateechosp $w"
    pack $w.d.lab $w.d.x $w.d.y $w.d.z -in $w.d -side left -anchor w -padx 3 -pady 3 
    
    frame $w.fov
    label $w.fov.lab -text "Field of view (mm): " -width 22 -anchor w -justify left 
    LabelSpinBox $w.fov.x -label " X "  -width 6 \
	 -textvariable entries($w,fov_x) -range { 0.000001   10000.0  0.1 }\
         -command "$w.fov.x.spin.e validate; possum:updateVSIZE $w; possum:updatecomptime $w;possum:updateechosp $w" \
	 -modifycmd "possum:updateVSIZE $w; possum:updatecomptime $w;possum:updateechosp $w"
    LabelSpinBox $w.fov.y -label " Y "  -width 6 \
	 -textvariable entries($w,fov_y) -range { 0.000001   10000.0  0.1 }\
         -command "$w.fov.y.spin.e validate; possum:updateVSIZE $w; possum:updatecomptime $w;possum:updateechosp $w" \
	 -modifycmd "possum:updateVSIZE $w; possum:updatecomptime $w;possum:updateechosp $w"
    LabelSpinBox $w.fov.z -label " Z "  -width 6 \
	 -textvariable entries($w,fov_z) -range { 0.000001   10000.0  0.1 }\
         -command "$w.fov.z.spin.e validate; possum:updateVSIZE $w; possum:updatecomptime $w;possum:updateechosp $w" \
	 -modifycmd "possum:updateVSIZE $w; possum:updatecomptime $w;possum:updateechosp $w"
    pack $w.fov.lab $w.fov.x $w.fov.y $w.fov.z -in $w.fov -side left -anchor w -padx 3 -pady 3  
      
    frame $w.ph
    label $w.ph.lab -text "k-space coverage (%): " -width 22 -anchor w -justify left 
    LabelSpinBox $w.ph.x -label " " -width 6 \
	 -textvariable entries($w,cover) -range { 50   100  0.1 } \
         -command "$w.ph.x.spin.e validate; possum:updatecomptime $w" \
	 -modifycmd "possum:updatecomptime $w"
    pack $w.ph.lab $w.ph.x -in $w.ph -side left -anchor w -padx 3 -pady 3  

    frame $w.fa
    label $w.fa.lab -text "Flip angle (deg): " -width 22 -anchor w -justify left 
    LabelSpinBox $w.fa.x -label " " -width 6 \
	 -textvariable entries($w,flipangle) -range { 0   180  0.1 } 
    pack $w.fa.lab $w.fa.x -in $w.fa -side left -anchor w -padx 3 -pady 3  

    frame $w.v
    label $w.v.lab -text "Number of Volumes: " -width 22 -anchor w -justify left 
    LabelSpinBox $w.v.x -label " " -width 6 \
	 -textvariable entries($w,numvol) -range { 1   10000  1 } \
         -command "$w.v.x.spin.e validate; possum:updatecomptime $w" \
	 -modifycmd "possum:updatecomptime $w"
    pack $w.v.lab $w.v.x -in $w.v -side left -anchor w -padx 3 -pady 3  
    
    frame $w.gap
    label $w.gap.lab -text "Gap (mm): " -width 22 -anchor w -justify left 
    LabelSpinBox $w.gap.v -label " " -width 6 \
	 -textvariable entries($w,gap) -range { 0.0   100.0  0.001 } \
         -command "$w.gap.v.spin.e validate; possum:updatecomptime $w" \
	-modifycmd "possum:updatecomptime $w"
    pack $w.gap.lab $w.gap.v -in $w.gap -side left -anchor w -padx 3 -pady 3 
 
    frame $w.bw 
    label $w.bw.lab -text "BW (Hz): " -width 22 -anchor w -justify left 
    LabelSpinBox $w.bw.x -label " " -width 8 \
	    -textvariable entries($w,bw) -range { 0   1000000  10 }\
            -command "$w.bw.x.spin.e validate; possum:updateechosp $w" \
	    -modifycmd "possum:updateechosp $w"

    frame $w.slcprs
    label $w.slcprs.lab1 -text " "
    label $w.slcprs.lab2 -text "Slice Prescription" -font { Helvetica 12 italic }
    pack $w.slcprs.lab1 $w.slcprs.lab2 -in $w.slcprs
     
    frame $w.s
    label $w.s.lab -text "Starting slice position (mm): " -width 22 -anchor w -justify left 
    LabelSpinBox $w.s.x -label " " -width 6 \
	    -textvariable entries($w,zstart) -range { 0.0   10000.0  1.0 }
    label $w.s.filler -text " " -width 10
    button $w.s.preview -text "Preview slice prescription" -command "possum:previewslices $w"
    pack $w.s.lab $w.s.x $w.s.filler $w.s.preview -in $w.s -side left -anchor w -padx 3 -pady 3  
   
    frame $w.sr
    label $w.sr.lab -text "Read gradient: " -width 22 -anchor w -justify left 
    radiobutton $w.sr.x -text "X" -variable entries($w,readgrad) -value x -anchor w
    radiobutton $w.sr.y -text "Y" -variable entries($w,readgrad) -value y -anchor w
    radiobutton $w.sr.z -text "Z" -variable entries($w,readgrad) -value z -anchor w
    $w.sr.x select
    pack $w.sr.lab $w.sr.x $w.sr.y $w.sr.z -in $w.sr -side left -anchor w -padx 3 -pady 3
 
    frame $w.sp    
    label $w.sp.lab -text "Phase encode gradient: " -width 22 -anchor w -justify left 
    radiobutton $w.sp.x -text "X" -variable entries($w,phencode) -value x -anchor w
    radiobutton $w.sp.y -text "Y" -variable entries($w,phencode) -value y -anchor w
    radiobutton $w.sp.z -text "Z" -variable entries($w,phencode) -value z -anchor w
    $w.sp.y select
    pack $w.sp.lab $w.sp.x $w.sp.y $w.sp.z -in $w.sp -side left -anchor w -padx 3 -pady 3
   

    frame $w.ss
    label $w.ss.lab -text "Slice select gradient: " -width 22 -anchor w -justify left 
    radiobutton $w.ss.x -text "X" -variable entries($w,slcselect) -value x -anchor w
    radiobutton $w.ss.y -text "Y" -variable entries($w,slcselect) -value y -anchor w
    radiobutton $w.ss.z -text "Z" -variable entries($w,slcselect) -value z -anchor w
    $w.ss.z select
    pack $w.ss.lab $w.ss.x $w.ss.y $w.ss.z -in $w.ss -side left -anchor w -padx 3 -pady 3

    frame $w.dir
    label $w.dir.lab -text "Slice acquisition order: " -width 22 -anchor w -justify left 
    radiobutton $w.dir.x -text "+" -variable entries($w,plus) -value + -anchor w
    radiobutton $w.dir.y -text "-" -variable entries($w,plus) -value - -anchor w
    $w.dir.x select
    pack $w.dir.lab $w.dir.x $w.dir.y -in $w.dir -side left -anchor w -padx 3 -pady 3


    collapsible frame $w.scan -title "Scanner properties" -command "$w.nb compute_size; set dummy"
    
    frame $w.maxG
    LabelSpinBox $w.maxG.v -label "Maximal gradient strength (T/m) :" -width 8 \
	 -textvariable entries($w,maxG) -range { 0.0   100.0  0.001 }
    pack $w.maxG.v -in $w.maxG -side left -anchor w -padx 3 -pady 3 
  
    frame $w.riseT
    LabelSpinBox $w.riseT.v -label "Rise time (s): " -width 8 \
	 -textvariable entries($w,riseT) -range { 0.0   100.0  0.00001 }
    pack $w.riseT.v -in $w.riseT -side left -anchor w -padx 3 -pady 3   

    FileEntry $w.slcprof \
	-textvariable entries($w,slcprof) \
	-label "Slice profile  " \
	-title "Select" \
	-width 40 \
	-filedialog directory
    pack $w.maxG $w.riseT $w.slcprof -in $w.scan.b  -anchor w -padx 3 -pady 3 -expand yes -fill both
    
    frame $w.pcheck
    button $w.pulsecheck     -command "Possum:pulsecheck $w" \
	    -text "Consistency check" -width 15
    pack $w.pulsecheck -in $w.pcheck -side left
    
    label $w.bw.echolab -text "    Echo spacing (s):" -anchor w -justify left 
    entry $w.bw.echox -textvariable entries($w,echosp) -width 12 -readonlybackground white -state readonly 
    pack $w.bw.lab $w.bw.x $w.bw.echolab $w.bw.echox -in $w.bw -side left -anchor w -padx 3 -pady 3  
    pack $w.t $w.n $w.d $w.fov $w.ph $w.fa $w.v $w.gap $w.bw $w.slcprs $w.sr $w.sp $w.ss $w.dir $w.s -in  $pulself  -anchor w -padx 3 -pady 3
    pack $w.pcheck -in  $pulself -anchor center -side left -side bottom -padx 5 -pady 5
    pack $w.scan -in  $pulself -side left -padx 5 -pady 5

    
    # -------- B0ield -------------
    set guivars($w,lfb0field) [$w.nb getframe b0field]

    #Field strength
    set entries($w,b0strength) 1
    possum:updateb0field $w
    frame $w.b0test
    LabelSpinBox $w.b0test.b0spin -width 8 \
       -textvariable entries($w,b0fieldstrength) -range { 0.0   1000000.0  0.1 } -disabledbackground gray
    LabelFrame $w.b0test.b0fil -text "Field strength"
    optionMenu2 $w.b0test.b0fil.menu entries($w,b0strength)  -command "possum:updateb0field $w ; possum:updateMRpar $w ; possum:updateb0fieldinh $w ; possum:updateBASEname $w; possum:updateBASEnametime $w " 0 "1.5 T" 1 "3 T" 2 "Custom field ( T )"
    pack $w.b0test.b0fil.menu
    pack $w.b0test.b0fil -in $w.b0test
    pack $w.b0test -in $guivars($w,lfb0field) -side top -anchor w -padx 3 -pady 3

    # MR par
    set entries($w,mrpar) "${FSLDIR}/data/possum/MRpar_3T"
    FileEntry $w.mrpar \
	-textvariable entries($w,mrpar) \
	-label "MR parameters  " \
	-title "Select" \
	-width 40 \
	-filedialog directory
    pack $w.mrpar -in $guivars($w,lfb0field) -anchor w -padx 3 -pady 3

    #B0 field inhomogeneities
    frame $w.b0main
    set entries($w,b0f) "${FSLDIR}/data/possum/b0_ppm.nii.gz"
    possum:updateB0prop $w  $entries($w,b0f)
    FileEntry $w.b0main.b0f \
	-textvariable entries($w,b0f) \
	-label "File name " \
	-filetypes IMAGE \
      	-title "Select" \
	-width 40 \
	-filedialog directory \
        -command  "possum:updateB0prop $w; possum:updatecomptime $w "
    frame $w.b0main.b0im
    label $w.b0main.b0im.label -image "" -text " "
    button $w.b0main.b0im.preview -text "Preview image" -command "possum:previewb0 $w"

    frame $w.b0main.b0u
    radiobutton $w.b0main.b0u.ppm -text "ppm" -variable entries($w,b0units) -value ppm -anchor w
    radiobutton $w.b0main.b0u.tesla -text "Tesla" -variable entries($w,b0units) -value tesla -anchor w
    $w.b0main.b0u.ppm select
    label $w.b0main.b0u.unit -text "Units: "
    pack $w.b0main.b0u.unit $w.b0main.b0u.ppm $w.b0main.b0u.tesla -anchor w -side left
    
    LabelFrame $w.b0main.b0fi -text "B0 field inhomogeneities"
    optionMenu2 $w.b0main.b0fi.menu entries($w,b0inh_yn)  -command "possum:updateb0fieldinh $w; possum:updateBASEname $w ; possum:updatecomptime $w" 0 "None" 1 "Custom file"
    pack $w.b0main.b0fi.menu
    pack $w.b0main.b0fi -in $w.b0main -side top -anchor w -padx 3 -pady 3
    pack $w.b0main -in $guivars($w,lfb0field) -side top -anchor w -padx 3 -pady 3

    #B0 inhomogeneities changing in time
    frame $w.b0maintime
    set entries($w,b0ftime) "${FSLDIR}/data/possum/b0extra.nii.gz"
    possum:updateB0timeprop $w  $entries($w,b0ftime)
    FileEntry $w.b0maintime.b0f \
	-textvariable entries($w,b0ftime) \
	-label "B0 spatial modulation " \
	-filetypes IMAGE \
      	-title "Select" \
	-width 40 \
	-filedialog directory \
        -command  "possum:updateB0timeprop $w; possum:updatecomptime $w "
    set entries($w,b0ftimecourse) "${FSLDIR}/data/possum/b0timecourse"
    FileEntry $w.b0maintime.b0ftime \
	-textvariable entries($w,b0ftimecourse) \
	-label "B0 time course " \
      	-title "Select" \
	-width 40 \
	-filedialog directory \

    frame $w.b0maintime.b0im
    label $w.b0maintime.b0im.label -image "" -text " "
    button $w.b0maintime.b0im.preview -text "Preview image" -command "possum:previewb0time $w"

    frame $w.b0maintime.b0u
    radiobutton $w.b0maintime.b0u.ppm -text "ppm" -variable entries($w,b0unitstime) -value ppm -anchor w
    radiobutton $w.b0maintime.b0u.tesla -text "Tesla" -variable entries($w,b0unitstime) -value tesla -anchor w
    $w.b0maintime.b0u.ppm select
    label $w.b0maintime.b0u.unit -text "Units: "
    pack $w.b0maintime.b0u.unit $w.b0maintime.b0u.ppm $w.b0maintime.b0u.tesla -anchor w -side left

    LabelFrame $w.b0maintime.b0fi -text "B0 field inhomogeneities (changing in time)"
    optionMenu2 $w.b0maintime.b0fi.menu entries($w,b0inhtime_yn)  -command "possum:updateb0fieldinhtime $w; possum:updateBASEnametime $w ; possum:updatecomptime $w" 0 "None" 1 "Custom file"
    pack $w.b0maintime.b0fi.menu
    pack $w.b0maintime.b0fi -in $w.b0maintime  -side top -anchor w -padx 3 -pady 3
    pack $w.b0maintime -in $guivars($w,lfb0field) -side top -anchor w -padx 3 -pady 3 

    # --------Motion-------------
    set guivars($w,lfmotion) [$w.nb getframe motion]
    set entries($w,mot) "${FSLDIR}/data/possum/motionRzLarge_0.12s"
    FileEntry $w.mot \
	-textvariable entries($w,mot) \
	-label "Motion file  " \
	-title "Select" \
	-width 40 \
	-filedialog directory
    LabelFrame $w.moti -text ""
    optionMenu2 $w.moti.menu entries($w,motion_yn)  -command "possum:updatemotion $w; possum:updatecomptime $w " 0 "None" 1 "Custom file"
    pack $w.moti.menu
    pack $w.moti -in $guivars($w,lfmotion) -side top -anchor w -padx 3 -pady 3

    # --------Activation-------------
     set guivars($w,lfactivation) [$w.nb getframe activation]
    set entries($w,activ_yn) 0
    set entries($w,act1) "$FSLDIR/data/possum/activation3D.nii.gz"
    possum:updateACTprop $w $entries($w,act1)
    set entries($w,act2) "$FSLDIR/data/possum/activation3Dtimecourse"
    FileEntry $w.act1 \
	-textvariable entries($w,act1) \
	-filetypes IMAGE \
	-label "T2* spatial modulation  " \
	-title "Select" \
	-width 40 \
	-filedialog directory \
	-command  "possum:updateACTprop $w"
    FileEntry $w.act2 \
	-textvariable entries($w,act2) \
	-label "T2* time course  " \
	-title "Select" \
	-width 40 \
	-filedialog directory

    frame $w.activim
    label $w.activim.label -image "" -text " "
    button $w.activim.preview -text "Preview image" -command "possum:previewactiv $w"
    
    LabelFrame $w.activ -text ""
    optionMenu2 $w.activ.menu entries($w,activ_yn)  -command "possum:updateactivation $w" 0 "None" 1 "Custom file"
    pack $w.activ.menu
    pack $w.activ -in $guivars($w,lfactivation) -side top -anchor w -padx 3 -pady 3

    # ------ Noise--------------------
    set guivars($w,lfnoise) [$w.nb getframe noise]
    set entries($w,noise_yn) 0
    set entries($w,noisesnr) 10
    set entries($w,noisesigma) 0
    frame $w.noiseval
    frame $w.noiseval1
    frame $w.noiseval2
    LabelSpinBox $w.noiseval1.snr -label "" -width 8 \
       -textvariable entries($w,noisesnr) -range { 0.0   1000000.0  0.5 } -disabledbackground gray
    LabelSpinBox $w.noiseval2.sigma -label "" -width 8 \
       -textvariable entries($w,noisesigma) -range { 0.0   100000000.0  0.1 } -disabledbackground gray
    radiobutton $w.noiseval1.unitssnr \
       -text "SNR (relative to median object intensity): " \
       -variable entries($w,noiseunits) \
       -value snr -anchor w \
       -command "possum:updatenoiseunits $w " -width 35
    radiobutton $w.noiseval2.unitssigma \
       -text "Absolute intensity (std dev): " \
       -variable entries($w,noiseunits) \
       -value sigma -anchor w \
       -command "possum:updatenoiseunits $w " -width 35
    pack $w.noiseval1.unitssnr $w.noiseval1.snr \
       -in $w.noiseval1 -side left -anchor w -padx 3 -pady 3 
    pack $w.noiseval2.unitssigma $w.noiseval2.sigma \
       -in $w.noiseval2 -side left -anchor w -padx 3 -pady 3 
    pack $w.noiseval1 $w.noiseval2 -in $w.noiseval
    $w.noiseval1.unitssnr select
    $w.noiseval2.sigma configure -state disabled
    LabelFrame $w.noise -text ""
    optionMenu2 $w.noise.menu entries($w,noise_yn)  -command "possum:updatenoise $w" 0 "None" 1 "Thermal (white) noise "
    pack $w.noise.menu
    pack $w.noise -in $guivars($w,lfnoise) -side top -anchor w -padx 3 -pady 3

    #------Output---------------------
    set outputlf [$w.nb getframe output]
    set entries($w,out) "$PWD/simdir"
    FileEntry $w.out \
    -textvariable entries($w,out) \
    -label "Output directory  " \
    -title "Select" \
    -width 50 \
    -filedialog directory
    pack $w.out -in $outputlf -side top -anchor w -pady 3 -padx 5

    # Outside the nb part.
    frame $w.np
    label $w.np.lab -text "Number of processors: " -anchor w -justify left 
    LabelSpinBox $w.np.x -label " " -textvariable entries($w,numproc) \
	-range { 1   10000  1 } \
	-command "$w.np.x.spin.e validate; possum:updatecomptime $w" \
	-modifycmd "possum:updatecomptime $w"
    pack $w.np.lab $w.np.x -in $w.np -side left -anchor w -padx 3 -pady 3

    possum:updatecomptime $w
    frame $w.ct
    label $w.ct.lab -text "Approximate run time: " -anchor w -justify left 
    entry $w.ct.x -textvariable entries($w,comptime) -width 12 -readonlybackground white -state readonly
    pack $w.ct.lab $w.ct.x -in $w.ct -side left -anchor w -padx 3 -pady 3


    # ---- Pack all of the options ----
    frame $w.f.opts
    pack $w.nb -in $w.f.opts -side top
    pack $w.np $w.ct -in $w.f.opts  -side left -padx 10
    pack $w.f.opts -in $w.f -side left -padx 8 -pady 6 -expand yes -fill both
   
    # ---- Button Frame ----
    frame $w.btns
    frame $w.btns.b -relief raised -borderwidth 1
    button $w.btns.go     -command "Possum:apply $w" \
	    -text "Go" -width 5
    button $w.btns.cancel    -command "destroy $w" \
	    -text "Exit" -width 5
    button $w.btns.save -command "feat_file:setup_dialog $w a a a [namespace current] *.fsf {Save Possum setup} {possum:write $w} {}" -text "Save"

    button $w.btns.load -command "feat_file:setup_dialog $w a a a [namespace current] *.fsf {Load Possum setup} {possum:load $w} {}" -text "Load"
    button $w.btns.help -command "FmribWebHelp file: ${FSLDIR}/doc/possum/index.html" \
            -text "Help" -width 5
    pack $w.btns.b -side bottom -fill x
    pack $w.btns.go $w.btns.save $w.btns.load $w.btns.cancel $w.btns.help -in $w.btns.b \
	    -side left -expand yes -padx 3 -pady 10 -fill y
    pack $w.f $w.btns -expand yes -fill both
}

proc Possum:pulsecheck { w } {
    global entries
    set status [ possum:pulsecheck $w $entries($w,obvol) $entries($w,mrpar) $entries($w,te) $entries($w,tr) $entries($w,trslc) $entries($w,outsize_nx) $entries($w,outsize_ny) $entries($w,outsize_nz) $entries($w,outsize_dx) $entries($w,outsize_dy) $entries($w,outsize_dz) $entries($w,fov_x)  $entries($w,fov_y)  $entries($w,fov_z)  $entries($w,numvol) $entries($w,zstart) $entries($w,gap) $entries($w,bw) $entries($w,readgrad) $entries($w,phencode) $entries($w,slcselect) $entries($w,plus) $entries($w,maxG)  $entries($w,riseT) $entries($w,b0f) $entries($w,mot)  $entries($w,act1) $entries($w,act2) $entries($w,out) $entries($w,numproc) $entries($w,slcprof) $entries($w,cover) $entries($w,flipangle)]
    update idletasks
}

proc Possum:apply { w } {
    global entries FSLDIR

    # start by saving the fsf file (with all variables as they are now)
    #if { ! [ file isdirectory $entries($w,out) ] } { 
	#catch { exec sh -c "mkdir $entries($w,out)" } oval
    #}
    puts ""
    puts ""
    puts "Starting POSSUM..."
    puts ""
    if { $entries($w,obvol) == "" } {
       puts "The input object not specified."
     return
    } 
    if { $entries($w,mrpar) == "" } {
       puts "The input MR parameters not specified."
       return
    }
    if { $entries($w,slcprof) == "" } {
       puts "The slice profile not specified."
     return
    }
    if { $entries($w,b0inhtime_yn) == 1 && $entries($w,motion_yn) == 1 } {
       puts "Warning: At the moment B0 field changing in time can not be simulated while the object is moving. This will be implemented into POSSUM at a later stage."
       return
    }
    # checks if the object is the same size as the b0file 
   if { $entries($w,b0inh_yn) == 1 } {
    if { $entries($w,vcX) != $entries($w,vcXb0) || $entries($w,vcY) != $entries($w,vcYb0) ||  $entries($w,vcZ) != $entries($w,vcZb0) ||  $entries($w,inNx) != $entries($w,inNxb0) ||  $entries($w,inNy) != $entries($w,inNyb0) ||  $entries($w,inNz) != $entries($w,inNzb0) } {
     puts "The object and the B0 file do not match in dimension or voxel size."
     puts "Object dim: $entries($w,inNx), $entries($w,inNy), $entries($w,inNz)"
     puts "B0 dim: $entries($w,inNxb0), $entries($w,inNyb0), $entries($w,inNzb0)"
     puts "Object voxsize: $entries($w,vcX), $entries($w,vcY), $entries($w,vcZ)"
     puts "B0 voxsize: $entries($w,vcXb0), $entries($w,vcYb0), $entries($w,vcZb0)"
     return
    }
   }
    # checks if the object is the same size as the b0time file
    if { $entries($w,b0inhtime_yn) == 1 } {
    if { $entries($w,vcX) != $entries($w,vcXb0time) || $entries($w,vcY) != $entries($w,vcYb0time) ||  $entries($w,vcZ) != $entries($w,vcZb0time) ||  $entries($w,inNx) != $entries($w,inNxb0time) ||  $entries($w,inNy) != $entries($w,inNyb0time) ||  $entries($w,inNz) != $entries($w,inNzb0time) } {
     puts "The object and the B0 file (time changing) do not match in dimension or voxel size."
     puts "Object dim: $entries($w,inNx), $entries($w,inNy), $entries($w,inNz)"
     puts "B0 dim: $entries($w,inNxb0time), $entries($w,inNyb0time), $entries($w,inNzb0time)"
     puts "Object voxsize: $entries($w,vcX), $entries($w,vcY), $entries($w,vcZ)"
     puts "B0 voxsize: $entries($w,vcXb0time), $entries($w,vcYb0time), $entries($w,vcZb0time)"
     return
    }
   }
   if { $entries($w,activ_yn) == 1 } {
    if { $entries($w,vcX) != $entries($w,vcXact) || $entries($w,vcY) != $entries($w,vcYact) ||  $entries($w,vcZ) != $entries($w,vcZact) ||  $entries($w,inNx) != $entries($w,inNxact) ||  $entries($w,inNy) != $entries($w,inNyact) ||  $entries($w,inNz) != $entries($w,inNzact) } {
     puts "The object and the activation file do not match in dimension or voxel size."
     puts "Object dim: $entries($w,inNx), $entries($w,inNy), $entries($w,inNz)"
     puts "Activation dim: $entries($w,inNxact), $entries($w,inNyact), $entries($w,inNzact)"
     puts "Object voxsize: $entries($w,vcX), $entries($w,vcY), $entries($w,vcZ)"
     puts "Activation voxsize: $entries($w,vcXact), $entries($w,vcYact), $entries($w,vcZact)"
     return
    }
   }
   #checks if the output voxel size is smaller than the input voxel size
   if { $entries($w,vcX) > $entries($w,outsize_dx) || $entries($w,vcY) > $entries($w,outsize_dy) ||  $entries($w,vcZ) > $entries($w,outsize_dz)} {
     puts "The input object voxel size (every direction) should not be bigger than the output image voxel size."
     puts "The input object voxel size: $entries($w,vcX), $entries($w,vcY), $entries($w,vcZ) "
puts "The output image voxel size: $entries($w,outsize_dx), $entries($w,outsize_dy), $entries($w,outsize_dz)"
     return
    }
    puts "Creating the POSSUM directory..."
    puts ""
    if { $entries($w,out)  == "" } {
       puts "The output directory not specified."
     exit
    } else { 
	new_file $entries($w,out)
	catch { exec sh -c "mkdir $entries($w,out)" } oval
    }
    possum:write $w $entries($w,out)/possum.fsf

    # now do some logic to figure out the parameters to pass on
    if { $entries($w,b0inh_yn) == 0 } { 
	set b0file "" 
    } else {
	set b0file $entries($w,b0f)
    }
    if { $entries($w,b0inhtime_yn) == 0 } { 
	set b0filetime "" 
	set b0filetimecourse "" 
    } else {
	set b0filetime $entries($w,b0ftime)
	set b0filetimecourse $entries($w,b0ftimecourse)
    }
    if { $entries($w,motion_yn) == 0 } { 
	set motfile "${FSLDIR}/data/possum/zeromotion" 
    } else {
	set motfile $entries($w,mot)
    }
    if { $entries($w,activ_yn) == 0 } { 
	set act1file "" 
	set act2file "" 
    } else {
	set act1file $entries($w,act1)
	set act2file $entries($w,act2)
    }
    set filename "$entries($w,out)/noise"
    set log [open "$filename" w]
    if { $entries($w,noiseunits) == "snr" && $entries($w,noise_yn) == 1 } { 
	puts $log "snr $entries($w,noisesnr) "
    } else {
	puts $log "sigma $entries($w,noisesigma) "
    }
    close $log
    set status [ possum:proc $w $entries($w,proctime) $entries($w,obvol) $entries($w,mrpar) $entries($w,te) $entries($w,tr) $entries($w,trslc) $entries($w,outsize_nx) $entries($w,outsize_ny) $entries($w,outsize_nz) $entries($w,outsize_dx) $entries($w,outsize_dy) $entries($w,outsize_dz) $entries($w,fov_x)  $entries($w,fov_y)  $entries($w,fov_z)  $entries($w,numvol) $entries($w,zstart) $entries($w,gap) $entries($w,bw) $entries($w,readgrad) $entries($w,phencode) $entries($w,slcselect) $entries($w,plus) $entries($w,maxG)  $entries($w,riseT) $b0file $entries($w,b0fieldstrength) $entries($w,b0units)  $b0filetime $b0filetimecourse $entries($w,b0unitstime) $motfile $act1file $act2file $entries($w,out) $entries($w,numproc) $entries($w,slcprof) $entries($w,cover) $entries($w,flipangle)]
    update idletasks
    puts "Job submitted."
    puts ""
    puts "You can follow the POSSUM process by looking at the possum.log file."
    puts ""
    puts "If you want to see the individual processes see the logs directory."
}

proc possum:previewimage { w } {
    global entries FSLDIR
    set convertcom "${FSLDIR}/bin/pngappend"
    set filenm $entries($w,obvol)
    set validim 0
    catch { exec sh -c "${FSLDIR}/bin/imtest $filenm" } oval
    if { $oval == 1 } {
	catch { exec sh -c "${FSLDIR}/bin/tmpnam" } tmpnam
	catch { exec sh -c "${FSLDIR}/bin/slicer $filenm -a ${tmpnam}.png" } oval
	catch { exec sh -c "$convertcom ${tmpnam}.png ${tmpnam}.gif" } oval
	if { [ file exists ${tmpnam}.gif ] } {
	    set graphpic [image create photo -file ${tmpnam}.gif ]
	    set validim 1
	}
	catch { exec sh -c "rm -f ${tmpnam}.gif ${tmpnam}.png ${tmpnam}" } oval
    }
    if { $validim == 1 } {
	$w.objim.label configure -image $graphpic
    } else { 
	$w.objim.label configure -image "" -text "Could not generate preview"
    }
    $w.nb compute_size
}

proc possum:previewimage_steve { w } {
    global entries FSLDIR
    set convertcom "${FSLDIR}/bin/pngappend"
    set filenm $entries($w,obvol)
    set validim 0
    catch { exec sh -c "${FSLDIR}/bin/imtest $filenm" } oval
    if { $oval == 1 } {
	catch { exec sh -c "${FSLDIR}/bin/tmpnam /tmp/possum" } tmpnam
	if { [ exec sh -c "${FSLDIR}/bin/fslnvols $filenm 2> /dev/null" ] == 3 } {
	    catch { exec sh -c "${FSLDIR}/bin/fslsplit $filenm $tmpnam" } oval
	    catch { exec sh -c "${FSLDIR}/bin/overlay 0 0 ${tmpnam}0001 0 1 ${tmpnam}0000 0.5 1 ${tmpnam}0002 0.5 1 ${tmpnam}out" } oval
	    set filenm ${tmpnam}out
	}
	catch { exec sh -c "${FSLDIR}/bin/slicer $filenm -a ${tmpnam}.png" } oval
	catch { exec sh -c "$convertcom ${tmpnam}.png ${tmpnam}.gif" } oval
	if { [ file exists ${tmpnam}.gif ] } {
	    set graphpic [image create photo -file ${tmpnam}.gif ]
	    set validim 1
	}
	catch { exec sh -c "rm -f ${tmpnam}.gif ${tmpnam}.png ${tmpnam}" } oval
    }
    if { $validim == 1 } {
	$w.objim.label configure -image $graphpic
    } else { 
	$w.objim.label configure -image "" -text "Could not generate preview"
    }
    $w.nb compute_size
}

proc possum:updateFOV {w} {
    global entries
    set entries($w,fov_x) [ expr $entries($w,outsize_nx) *$entries($w,outsize_dx) ]
    set entries($w,fov_y) [ expr $entries($w,outsize_ny) *$entries($w,outsize_dy) ]
    set entries($w,fov_z) [ expr $entries($w,outsize_nz) *$entries($w,outsize_dz) ]
}

proc possum:updateVSIZE {w} {
    global entries
    set entries($w,outsize_dx) [ expr $entries($w,fov_x) * 1.0 / $entries($w,outsize_nx) ]
    set entries($w,outsize_dy) [ expr $entries($w,fov_y) * 1.0 / $entries($w,outsize_ny) ]
    set entries($w,outsize_dz) [ expr $entries($w,fov_z) * 1.0 / $entries($w,outsize_nz) ]
}

proc possum:updateTRSLC {w} {
    global entries
    if { $entries($w,autotrslc) == 1 } {
	set tmp [ expr $entries($w,tr)*1.0/$entries($w,outsize_nz) ]
        set entries($w,trslc)  [ possum:twosigfigs $tmp ]  
    }
}

proc possum:updateb0field { w } {
    global entries guivars FSLDIR
    pack forget $w.b0test.b0spin
    if { $entries($w,b0strength) == 2 } {
        pack $w.b0test.b0spin -in $w.b0test  -side left -anchor w -padx 3 -pady 3
    } 
    if { $entries($w,b0strength) == 1 } {
	set entries($w,b0fieldstrength) 3.0
    } 
    if { $entries($w,b0strength) == 0 } {
	set entries($w,b0fieldstrength) 1.5
    }
}

proc possum:updateMRpar { w } {
    global entries guivars FSLDIR
    if { $entries($w,b0strength) == 2 } {
	set entries($w,mrpar) ""
    } 
    if { $entries($w,b0strength) == 1 } {
	set entries($w,mrpar) "${FSLDIR}/data/possum/MRpar_3T"
    } 
    if { $entries($w,b0strength) == 0 } {
	set entries($w,mrpar) "${FSLDIR}/data/possum/MRpar_1.5T"
    }
}

proc possum:updateb0fieldinh { w } {
    global entries guivars FSLDIR
    if { $entries($w,b0inh_yn)} {
	pack $w.b0main.b0f -in $w.b0main -side top -anchor w -padx 3 -pady 3
        pack $w.b0main.b0im.preview $w.b0main.b0im.label -in $w.b0main.b0im -pady 10
        pack $w.b0main.b0u $w.b0main.b0im -in $w.b0main -anchor w -padx 3 -pady 3
    } else {
	pack forget $w.b0main.b0f
        pack forget $w.b0main.b0u
        pack forget $w.b0main.b0im
    }
}

proc possum:updateb0fieldinhtime { w } {
    global entries guivars FSLDIR
    if { $entries($w,b0inhtime_yn)} {
	pack $w.b0maintime.b0ftime -in $w.b0maintime -anchor w -padx 3 -pady 3
	pack $w.b0maintime.b0f -in $w.b0maintime -side top -anchor w -padx 3 -pady 3
        pack $w.b0maintime.b0im.preview $w.b0maintime.b0im.label -in $w.b0maintime.b0im -pady 10
        pack $w.b0maintime.b0u $w.b0maintime.b0im -in $w.b0maintime -anchor w -padx 3 -pady 3
    } else {
	pack forget $w.b0maintime.b0f
	pack forget $w.b0maintime.b0ftime
        pack forget $w.b0maintime.b0u
        pack forget $w.b0maintime.b0im
    }
}

proc possum:updateBASEname { w } {
    global entries guivars FSLDIR
    if { $entries($w,b0inh_yn)} {
	set entries($w,b0f) "${FSLDIR}/data/possum/b0_ppm.nii.gz"
        possum:updateB0prop $w $entries($w,b0f)
    } else {
	set entries($w,b0f) ""
    }
}

proc possum:updateBASEnametime { w } {
    global entries guivars FSLDIR
    if { $entries($w,b0inhtime_yn)} {
	set entries($w,b0ftime) "${FSLDIR}/data/possum/b0extra.nii.gz"
	set entries($w,b0ftimecourse) "${FSLDIR}/data/possum/b0timecourse"
        possum:updateB0timeprop $w $entries($w,b0ftime)
    } else {
	set entries($w,b0ftime) ""
	set entries($w,b0ftimecourse) ""
    }
}

proc possum:previewb0 { w } {
    global entries FSLDIR
    set convertcom "${FSLDIR}/bin/pngappend"
    set filenm "$entries($w,b0f)"
    set validim 0
    catch { exec sh -c "${FSLDIR}/bin/imtest $filenm" } oval
    if { $oval == 1 } {
	catch { exec sh -c "${FSLDIR}/bin/tmpnam" } tmpnam
	catch { exec sh -c "${FSLDIR}/bin/slicer $filenm -a ${tmpnam}.png" } oval
	catch { exec sh -c "$convertcom ${tmpnam}.png ${tmpnam}.gif" } oval
	if { [ file exists ${tmpnam}.gif ] } {
	    set graphpic [image create photo -file ${tmpnam}.gif ]
	    set validim 1
	}
	catch { exec sh -c "rm -f ${tmpnam}.gif ${tmpnam}.png ${tmpnam}" } oval
    }
    if { $validim == 1 } {
	$w.b0main.b0im.label configure -image $graphpic
    } else { 
	$w.b0main.b0im.label configure -image "" -text "Could not generate preview"
    }
    $w.nb compute_size
}

proc possum:previewb0time { w } {
    global entries FSLDIR
    set convertcom "${FSLDIR}/bin/pngappend"
    set filenm "$entries($w,b0ftime)"
    set validim 0
    catch { exec sh -c "${FSLDIR}/bin/imtest $filenm" } oval
    if { $oval == 1 } {
	catch { exec sh -c "${FSLDIR}/bin/tmpnam" } tmpnam
	catch { exec sh -c "${FSLDIR}/bin/slicer $filenm -a ${tmpnam}.png" } oval
	catch { exec sh -c "$convertcom ${tmpnam}.png ${tmpnam}.gif" } oval
	if { [ file exists ${tmpnam}.gif ] } {
	    set graphpic [image create photo -file ${tmpnam}.gif ]
	    set validim 1
	}
	catch { exec sh -c "rm -f ${tmpnam}.gif ${tmpnam}.png ${tmpnam}" } oval
    }
    if { $validim == 1 } {
	$w.b0maintime.b0im.label configure -image $graphpic
    } else { 
	$w.b0maintime.b0im.label configure -image "" -text "Could not generate preview"
    }
    $w.nb compute_size
}

proc possum:previewactiv { w } {
    global entries FSLDIR
    set convertcom "${FSLDIR}/bin/pngappend"
    set filenm $entries($w,act1)
    set validim 0
    catch { exec sh -c "${FSLDIR}/bin/imtest $filenm" } oval
    if { $oval == 1 } {
	catch { exec sh -c "${FSLDIR}/bin/tmpnam" } tmpnam
	catch { exec sh -c "${FSLDIR}/bin/imtest $entries($w,obvol)" } oval
	if { $oval == 1 } {
	    catch { exec sh -c "${FSLDIR}/bin/slicer $filenm $entries($w,obvol) -a ${tmpnam}.png" } oval 
	} else {
	    catch { exec sh -c "${FSLDIR}/bin/slicer $filenm -a ${tmpnam}.png" } oval 
	}
	catch { exec sh -c "$convertcom ${tmpnam}.png ${tmpnam}.gif" } oval
	if { [ file exists ${tmpnam}.gif ] } {
	    set graphpic [image create photo -file ${tmpnam}.gif ]
	    set validim 1
	}
	catch { exec sh -c "rm -f ${tmpnam}.gif ${tmpnam}.png ${tmpnam}" } oval
    }
    if { $validim == 1 } {
	$w.activim.label configure -image $graphpic
    } else { 
	$w.activim.label configure -image "" -text "Could not generate preview"
    }
    $w.nb compute_size
}

proc possum:previewslices { w } {
    global entries FSLDIR
    set count 0
    set w1 ".dialog[incr count]"
    while { [ winfo exists $w1 ] } {
        set w1 ".dialog[incr count]"
    }
    toplevel $w1
    wm title $w1 "Preview of Slice Prescription"
    wm iconname $w1 "SlicePreview"
    wm iconbitmap $w1 @${FSLDIR}/tcl/fmrib.xbm
    frame $w1.sprev
    label $w1.sprev.label -image "" -text "\n    Generating preview ... please wait    \n\n"
    pack $w1.sprev.label -in $w1.sprev
    pack $w1.sprev -in $w1
    # force this message to popup now
    update
    set convertcom "${FSLDIR}/bin/pngappend"
    set filenm $entries($w,obvol)
    set validim 0
    catch { exec sh -c "${FSLDIR}/bin/imtest $filenm" } oval
    if { $oval == 1 } {
	catch { exec sh -c "${FSLDIR}/bin/tmpnam" } tmpnam
	set slcselect $entries($w,slcselect)
	catch { exec sh -c "${FSLDIR}/bin/fslroi $filenm ${tmpnam}_sw 0 1" } oval
	catch { exec sh -c "${FSLDIR}/bin/fslswapdim ${tmpnam}_sw $entries($w,readgrad) $entries($w,phencode) $slcselect ${tmpnam}_sw" } oval
	catch { exec sh -c "${FSLDIR}/bin/fslval ${tmpnam}_sw dim1" } in_nx
	catch { exec sh -c "${FSLDIR}/bin/fslval ${tmpnam}_sw dim2" } in_ny
	catch { exec sh -c "${FSLDIR}/bin/fslval ${tmpnam}_sw pixdim1" } dx	
	catch { exec sh -c "${FSLDIR}/bin/fslval ${tmpnam}_sw pixdim2" } dy	
	catch { exec sh -c "${FSLDIR}/bin/fslval ${tmpnam}_sw pixdim3" } dz	
	catch { exec sh -c "${FSLDIR}/bin/fslstats ${tmpnam}_sw -r | awk '{ print \$2 }'" } imax
	set imax [ expr $imax*6 ]
	set zstart [ expr round($entries($w,zstart)/$dz) ]
	set xsize [ expr  round($entries($w,outsize_nx)*$entries($w,outsize_dx)/$dx) ]
	set ysize [ expr  round($entries($w,outsize_ny)*$entries($w,outsize_dy)/$dy) ]
	set zsize [ expr  round($entries($w,outsize_nz)*($entries($w,outsize_dz)+$entries($w,gap))/$dz) ]
	set xstart [ expr round(($in_nx-$xsize)/2.0) ]
	if { $xstart < 0 } { set xstart 0 }
	set ystart [ expr round(($in_ny-$ysize)/2.0) ]
	if { $ystart < 0 } { set ystart 0 }
	# puts "roi $xstart $xsize $ystart $ysize $zstart $zsize"
	catch { exec sh -c "${FSLDIR}/bin/fslmaths ${tmpnam}_sw -roi $xstart $xsize $ystart $ysize $zstart $zsize 0 1 -mul 5 -add ${tmpnam}_sw ${tmpnam}_sw" } oval	
	catch { exec sh -c "${FSLDIR}/bin/slicer ${tmpnam}_sw -i 0 $imax -a ${tmpnam}.png" } oval
	catch { exec sh -c "$convertcom ${tmpnam}.png ${tmpnam}.gif" } oval
	if { [ file exists ${tmpnam}.gif ] } {
	    set graphpic [image create photo -file ${tmpnam}.gif ]
	    set validim 1
	}
	catch { exec sh -c "rm -f ${tmpnam}.gif ${tmpnam}.png ${tmpnam}_sw* ${tmpnam}" } oval
    }
    if { $validim == 1 } {
	$w1.sprev.label configure -image $graphpic
    } else { 
	$w1.sprev.label configure -image "" -text "Could not generate preview"
    }
    pack forget $w1.sprev.label
    pack forget $w1.sprev
    pack $w1.sprev.label -in $w1.sprev
    button $w1.cancel -command "destroy $w1" -text "Dismiss"
    pack $w1.sprev $w1.cancel -in $w1
    update
}

proc possum:updatemotion { w } {
    global entries guivars FSLDIR
    if { $entries($w,motion_yn) == 1 } {
	pack $w.mot -in  $guivars($w,lfmotion) -side top -anchor w -padx 3 -pady 3
    } else {
	pack forget $w.mot
    }
}

proc possum:updateactivation { w } {
    global entries guivars FSLDIR
    if { $entries($w,activ_yn) == 1 } {
	pack $w.act2 -in  $guivars($w,lfactivation) -side top -anchor w -padx 3 -pady 3
	pack $w.act1 -in  $guivars($w,lfactivation) -side top -anchor w -padx 3 -pady 3
        pack $w.activim.preview $w.activim.label -in $w.activim -pady 10
        pack $w.activim -in  $guivars($w,lfactivation) -anchor w -padx 3 -pady 3
    } else {
        pack forget $w.activim
	pack forget $w.act1
        pack forget $w.act2
    }
}

proc possum:updatenoise { w } {
    global entries guivars FSLDIR
    if { $entries($w,noise_yn) == 1 } {
	pack $w.noiseval -in $guivars($w,lfnoise) -side top -anchor w -padx 3 -pady 3
    } else {
	pack forget $w.noiseval
    }
}
proc possum:updatenoiseunits { w } {
    global entries guivars FSLDIR
    if { $entries($w,noiseunits) == "snr" } {
	$w.noiseval2.sigma configure -state disabled ; $w.noiseval1.snr configure -state normal
    } else {
        $w.noiseval2.sigma configure -state normal ; $w.noiseval1.snr configure -state disabled
    }
}
 

proc possum:twosigfigs { num } {
    set pten [ expr log10($num) ]
    set pten [ expr floor($pten) - 1 ]
    set pten [ expr exp($pten*log(10)) ]
    set tsf [ expr round($num / $pten) ]
    set tsf [ expr $tsf*$pten ]
    return $tsf
}

proc possum:updateOBprop { w { filename foo } } {
 global entries FSLDIR
    set filename $entries($w,obvol)
    set entries($w,vcX) [ exec sh -c "$FSLDIR/bin/fslval $filename pixdim1" ]  
    set entries($w,vcY) [ exec sh -c "$FSLDIR/bin/fslval $filename pixdim2" ]  
    set entries($w,vcZ) [ exec sh -c "$FSLDIR/bin/fslval $filename pixdim3" ]  
    set entries($w,inNx) [ exec sh -c "$FSLDIR/bin/fslval $filename dim1" ]  
    set entries($w,inNy) [ exec sh -c "$FSLDIR/bin/fslval $filename dim2" ]  
    set entries($w,inNz) [ exec sh -c "$FSLDIR/bin/fslval $filename dim3" ] 
    set entries($w,inNt) [ exec sh -c "$FSLDIR/bin/fslval $filename dim4" ] 
    return 0
}

proc possum:updateB0prop { w { filename foo } } {
 global entries FSLDIR
    set filename "$entries($w,b0f)"
    set entries($w,vcXb0) [ exec sh -c "$FSLDIR/bin/fslval $filename pixdim1" ]  
    set entries($w,vcYb0) [ exec sh -c "$FSLDIR/bin/fslval $filename pixdim2" ]  
    set entries($w,vcZb0) [ exec sh -c "$FSLDIR/bin/fslval $filename pixdim3" ]  
    set entries($w,inNxb0) [ exec sh -c "$FSLDIR/bin/fslval $filename dim1" ]  
    set entries($w,inNyb0) [ exec sh -c "$FSLDIR/bin/fslval $filename dim2" ]  
    set entries($w,inNzb0) [ exec sh -c "$FSLDIR/bin/fslval $filename dim3" ] 
    set entries($w,inNtb0) [ exec sh -c "$FSLDIR/bin/fslval $filename dim4" ] 
    return 0
}

proc possum:updateB0timeprop { w { filename foo } } {
 global entries FSLDIR
    set filename "$entries($w,b0ftime)"
    set entries($w,vcXb0time) [ exec sh -c "$FSLDIR/bin/fslval $filename pixdim1" ]  
    set entries($w,vcYb0time) [ exec sh -c "$FSLDIR/bin/fslval $filename pixdim2" ]  
    set entries($w,vcZb0time) [ exec sh -c "$FSLDIR/bin/fslval $filename pixdim3" ]  
    set entries($w,inNxb0time) [ exec sh -c "$FSLDIR/bin/fslval $filename dim1" ]  
    set entries($w,inNyb0time) [ exec sh -c "$FSLDIR/bin/fslval $filename dim2" ]  
    set entries($w,inNzb0time) [ exec sh -c "$FSLDIR/bin/fslval $filename dim3" ] 
    return 0
}

proc possum:updateACTprop { w { filename foo } } {
 global entries FSLDIR
    set filename $entries($w,act1)
    set entries($w,vcXact) [ exec sh -c "$FSLDIR/bin/fslval $filename pixdim1" ]  
    set entries($w,vcYact) [ exec sh -c "$FSLDIR/bin/fslval $filename pixdim2" ]  
    set entries($w,vcZact) [ exec sh -c "$FSLDIR/bin/fslval $filename pixdim3" ]  
    set entries($w,inNxact) [ exec sh -c "$FSLDIR/bin/fslval $filename dim1" ]  
    set entries($w,inNyact) [ exec sh -c "$FSLDIR/bin/fslval $filename dim2" ]  
    set entries($w,inNzact) [ exec sh -c "$FSLDIR/bin/fslval $filename dim3" ] 
    set entries($w,inNtact) [ exec sh -c "$FSLDIR/bin/fslval $filename dim4" ] 
    return 0
}

proc possum:updatecomptime { w { filename foo } } {
    global entries FSLDIR
    # number of voxels per 1mm3
    set Nvpv [ expr 1 / ( $entries($w,vcX) * $entries($w,vcY) * $entries($w,vcZ) )  ]
    set dimX [ expr $entries($w,vcX) * $entries($w,inNx) ] 
    set dimY [ expr $entries($w,vcY) * $entries($w,inNy) ]
    set dimZ [ expr $entries($w,vcZ) * $entries($w,inNz) ]
    if { $entries($w,motion_yn) == 0 } {
       set Zmaxm 0
       set Nfev 50
	if { $entries($w,b0inh_yn) == 1 } {
	    set Nfev 150
	}
    } else {
       set Zmaxm 5
       set Nfev 380
    }
    # max mm extra due to slc profile
    set SlcP [ expr $entries($w,outsize_dz) * 1.5 ]
    # number of events in the pulse sequence
    set Nevent [expr $entries($w,outsize_nx) * $entries($w,outsize_ny) * ( ($Zmaxm + $SlcP ) / $entries($w,outsize_dz) + 1 ) * $entries($w,numvol) * $entries($w,cover)/100.0 ]
    # number of voxels
    set gap [expr $entries($w,gap) * ($entries($w,outsize_nz) - 1 ) ]
#set proportion of the non-zero voxels
    set P 0.4
    set Nvoxel [ expr $Nvpv * $dimX * $dimY * ( $entries($w,outsize_nz) * $entries($w,outsize_dz) + $Zmaxm + $SlcP + $gap ) * $entries($w,inNt) ]
    # number of flops per event and per voxel
    # total number of flops 
    set Nflops [ expr $Nevent * $Nvoxel * $Nfev ]
    # time for N computer proc capable of 1 Giga Flop (in seconds)
    set tottime [ expr $Nflops * 0.000000001 / $entries($w,numproc) ]
    if { $tottime < 1 } { set tottime 1 }
    set entries($w,proctime) [ expr int ( $tottime / 60 ) ]
    if { $tottime > 86400 } {
	set entries($w,comptime) "[ possum:twosigfigs [ expr $tottime / 86400 ] ] days"
	return
    }
    if { $tottime > 3600 } {
	set entries($w,comptime) "[ possum:twosigfigs [ expr $tottime / 3600 ] ] hours"
	return
    }
    if { $tottime > 60 } {
	set entries($w,comptime) "[ possum:twosigfigs [ expr $tottime / 60 ] ] minutes"
	return
    } else {
	set entries($w,comptime) "[ possum:twosigfigs $tottime ] seconds"
    }
}

proc possum:updateechosp { w } {
global entries 
    set dx [ expr $entries($w,outsize_dx) * 0.001 ]
    set dy [ expr $entries($w,outsize_dy) * 0.001 ]
    set dz [ expr $entries($w,outsize_dz)* 0.001 ]
    set zs [ expr $entries($w,zstart) * 0.001 ]
    # checks that the Pulse Sequence parameters are appropriate
    set gammabar 42580000
    set tana [expr $entries($w,maxG)/$entries($w,riseT) ]
    set dtx [ expr 1.0/$entries($w,bw)]
    set dkx [ expr 1.0/($entries($w,outsize_nx)*${dx})]
    set dky [ expr 1.0/($entries($w,outsize_ny)*${dy})]
    set Gx  [ expr ${dkx}/(${gammabar}*${dtx})]
    set dt  [ expr ${Gx}/$tana]
    set dty [ expr sqrt(4*${dky}/(${gammabar}*${tana}))]
    set entries($w,echosp) [expr round(10000000*(($entries($w,outsize_nx)-1)*$dtx+2*$dt))/10000000.0]
  return 0
}

proc possum:pulsecheck { w obvol mrpar te tr trslc outsize_nx outsize_ny outsize_nz outsize_dx outsize_dy outsize_dz fov_x fov_y fov_z numvol zstart gap bw readdir phasedir slcdir plus maxG riseT b0f mot act1 act2 out numproc slcprof cover flipangle} {
    global entries FSLDIR
    set dx [ expr $outsize_dx * 0.001 ]
    set dy [ expr $outsize_dy * 0.001 ]
    set dz [ expr $outsize_dz * 0.001 ]
    set zs [ expr $zstart * 0.001 ]
    # checks that the Pulse Sequence parameters are appropriate
    set gammabar 42580000
    set Gz 7.128*1e-03
    set tana [expr ${maxG}/${riseT} ]
    set dtz [expr $Gz/$tana ]
    set rft [expr 4*0.001 ]
    set dtz1 [expr sqrt($Gz*($dtz+$rft)*2/$tana)]
    set Gz1 [expr $dtz1*$tana/2]
    set TA [expr $rft/2+$dtz+$dtz1 ]
    set dtx [ expr 1.0/$bw]
    set dkx [ expr 1.0/(${outsize_nx}*${dx})]
    set dky [ expr 1.0/(${outsize_ny}*${dy})]
    set Gx  [ expr ${dkx}/(${gammabar}*${dtx})]
    set dt  [ expr ${Gx}/$tana]
    set dty [ expr sqrt(4*${dky}/(${gammabar}*${tana}))]
    set Gy  [expr ${dty}*${tana}/2]
    set dtx1 [expr sqrt(${Gx}*($dt+${outsize_nx}*$dtx)*2/$tana)] 
    set Gx1 [ expr $dtx1*$tana/2]
    set dty1 [expr sqrt(${outsize_ny}/2)*$dty]
    set Gy1 [expr $dty1*$tana/2]
    set TEl [expr $outsize_ny/2*(2*$dt+($outsize_nx-1)*$dtx)+($dt+${outsize_nx}/2*$dtx)]
    set TEr [expr (${outsize_ny}/2-1)*(2*$dt+(${outsize_nx}-1)*$dtx)+($dt+(${outsize_nx}/2-1)*$dtx)]
    set TD [expr $te - $TEl ]
    set TC [expr $TD - $dtx1 ]
    set TB [expr $TC - $dty1 ]
    set TF [expr $te + $TEr ]
    set tcrush [expr 100 * $riseT]
    set TG [expr $TF + 2 * $riseT + $tcrush ]
    set tmpSLC [expr $trslc*$outsize_nz ]
    set count 0
    set w0 ".dialog[incr count]"
    while { [ winfo exists $w0 ] } {
        set w0 ".dialog[incr count]"
    }
    #making sure that the scan FOV does not exceed the given FOV in slcseldir
    set maxFOV [expr $zstart + $fov_z]
    set dimX [ expr $entries($w,vcX) * $entries($w,inNx) ] 
    set dimY [ expr $entries($w,vcY) * $entries($w,inNy) ]
    set dimZ [ expr $entries($w,vcZ) * $entries($w,inNz) ]
    set dim $dimZ
    if { $slcdir == "x" } {
	set dimm $dimX
    } elseif { $slcdir == "y" } { 
	set dim $dimY
    } else {
	set dim $dimZ
    }
    toplevel $w0
    wm title $w0 "Pulse Sequence Check"
    wm iconname $w0 "PulseCheck"
    wm iconbitmap $w0 @${FSLDIR}/tcl/fmrib.xbm
    set chkwarning ""
    set chkmessage ""
    if { $maxFOV > $dim } {
        set newZstart [ expr $zstart - $maxFOV + $dim ]
	if { $newZstart < 0 } {
	    set newZstart 0
	    set newFOV $dim
	    set chkwarning "$chkwarning WARNING: Pulse sequence parameters did not pass the consistency check.\n\n"
	    set entries($w,pulsechecktest) 0 
	    set chkmessage "$chkmessage The selected slices do not fit within the input object. Try changing the starting slice position to $newZstart and the field of view (Z) to less or equal to $newFOV.\n"
	} else {
	    set chkwarning "$chkwarning WARNING: Pulse sequence parameters did not pass the consistency check.\n\n"
	    set entries($w,pulsechecktest) 0 
	    set chkmessage "$chkmessage The selected slices do not fit within the input object. Try changing the starting slice position to $newZstart.\n"
	}  
    } elseif {$tr < $tmpSLC} {
	set chkwarning "$chkwarning WARNING: Pulse sequence parameters did not pass the consistency check.\n\n"
        set entries($w,pulsechecktest) 0 
	set chkmessage "$chkmessage Try changing the TR to $tmpSLC.\n"
    } elseif { $TB < 0 } {
	set chkwarning "$chkwarning WARNING: Pulse sequence parameters did not pass the consistency check.\n\n"
	set entries($w,pulsechecktest) 0 
	set tmpB [expr $te -$TA]
	set tmpC [expr ($outsize_ny*($outsize_nx-1)+$outsize_nx)/2]
	set tmpA [expr $dkx*($outsize_ny+1)/($tana*$gammabar)]
	set tmpABC [expr $tmpB*$tmpB-4*$tmpA*$tmpC]
	set newTE [expr $TEl+$dtx1+$dty1+$TA ]
	if { $tmpABC < 0 } {
	    set chkmessage "$chkmessage Try changing the TE to greater than $newTE s.\n"
	} else {
	    set BW1 [expr ($tmpB-sqrt($tmpABC))/(2*$tmpA)]
	    set BW2 [expr ($tmpB+sqrt($tmpABC))/(2*$tmpA)]
	    if { $BW1 < 0 || $BW2 < 0 } {
		set chkmessage "$chkmessage Try changing the TE to greater than $newTE s. \n"
	    } else {
		set chkmessage "$chkmessage Try changing the BW to a value between $BW1 and $BW2\nOR\nTry changing the TE to greater than $newTE s.\n"
	    }
	}
    } elseif { $TG > $trslc } {
	set chkwarning "$chkwarning WARNING: Pulse sequence parameters did not pass the consistency check.\n\n"
	set entries($w,pulsechecktest) 0 
	set tmpB [expr $trslc-$te-2*$riseT-$tcrush]
	set tmpC [expr ($outsize_ny/2-1)*($outsize_nx-1)+$outsize_nx/2-1]
	set tmpA [expr $dkx*($outsize_ny-1)/($tana*$gammabar)]
	set tmpABC [expr $tmpB*$tmpB-4*$tmpA*$tmpC]
	set newTRslc [expr $te+$TEr+2*$riseT+$tcrush]
	if { $tmpABC < 0 } {
	    set newTRslc [expr $te+$TEr+2*$riseT+$tcrush]
	    set chkmessage "$chkmessage Try changing the TRslc value to greater than $newTRslc s.\n"
	} else {
	    set BW1 [expr ($tmpB-sqrt($tmpABC))/(2*$tmpA)]
	    set BW2 [expr ($tmpB+sqrt($tmpABC))/(2*$tmpA)]
            if { $BW1 < 0 || $BW2 < 0 } {
	      set chkmessage "$chkmessage Try changing the TRslc value to greater than $newTRslc s.\n"
	    } else {
		set chkmessage "$chkmessage Try changing the BW to a value between $BW1 and $BW2\nOR\nTry changing the TRslc value to greater than $newTRslc s.\n"
	    }
	}
    } else {
	if { $readdir == $phasedir || $readdir == $slcdir || $phasedir == $slcdir } {
	    set chkwarning "$chkwarning WARNING: Pulse sequence parameters did not pass the consistency check.\n\n"
	    set entries($w,pulsechecktest) 0 
	    set chkmessage "$chkmessage Read-, phase-, and slice- directions must be different.\n"
	} else {
	    set chkmessage "$chkmessage All is well with the pulse sequence set up.\n"
	    set entries($w,pulsechecktest) 1
	}
    }
    label $w0.msg1 -text "$chkwarning" -font {Helvetica 12 bold} -foreground red
    label $w0.msg2 -text "$chkmessage" -font {Helvetica 12 bold} -foreground black
    button $w0.cancel -command "destroy $w0" -text "Dismiss"
    pack $w0.msg1 $w0.msg2 $w0.cancel -in $w0
    return 0
}


proc possum:write { w filename } {
    global entries FSLDIR
set channel [ open ${filename} "w" ]
puts $channel "set entries(\$w,act1) \"$entries($w,act1)\""
puts $channel "set entries(\$w,act2) \"$entries($w,act2)\""
puts $channel "set entries(\$w,activ_yn) \"$entries($w,activ_yn)\""
puts $channel "set entries(\$w,autotrslc) \"$entries($w,autotrslc)\""
puts $channel "set entries(\$w,b0f) \"$entries($w,b0f)\""
puts $channel "set entries(\$w,b0fieldstrength) \"$entries($w,b0fieldstrength)\""
puts $channel "set entries(\$w,b0ftime) \"$entries($w,b0ftime)\""
puts $channel "set entries(\$w,b0ftimecourse) \"$entries($w,b0ftimecourse)\""
puts $channel "set entries(\$w,b0inh_yn) \"$entries($w,b0inh_yn)\""
puts $channel "set entries(\$w,b0inhtime_yn) \"$entries($w,b0inhtime_yn)\""
puts $channel "set entries(\$w,b0strength) \"$entries($w,b0strength)\""
puts $channel "set entries(\$w,b0units) \"$entries($w,b0units)\""
puts $channel "set entries(\$w,b0unitstime) \"$entries($w,b0unitstime)\""
puts $channel "set entries(\$w,bw) \"$entries($w,bw)\""
puts $channel "set entries(\$w,comptime) \"$entries($w,comptime)\""
puts $channel "set entries(\$w,cover) \"$entries($w,cover)\""
puts $channel "set entries(\$w,flipangle) \"$entries($w,flipangle)\""
puts $channel "set entries(\$w,echosp) \"$entries($w,echosp)\""
puts $channel "set entries(\$w,fov_x) \"$entries($w,fov_x)\""
puts $channel "set entries(\$w,fov_y) \"$entries($w,fov_y)\""
puts $channel "set entries(\$w,fov_z) \"$entries($w,fov_z)\""
puts $channel "set entries(\$w,gap) \"$entries($w,gap)\""
puts $channel "set entries(\$w,inNt) \"$entries($w,inNt)\""
puts $channel "set entries(\$w,inNtact) \"$entries($w,inNtact)\""
puts $channel "set entries(\$w,inNtb0) \"$entries($w,inNtb0)\""
puts $channel "set entries(\$w,inNx) \"$entries($w,inNx)\""
puts $channel "set entries(\$w,inNxact) \"$entries($w,inNxact)\""
puts $channel "set entries(\$w,inNxb0) \"$entries($w,inNxb0)\""
puts $channel "set entries(\$w,inNxb0time) \"$entries($w,inNxb0time)\""
puts $channel "set entries(\$w,inNy) \"$entries($w,inNy)\""
puts $channel "set entries(\$w,inNyact) \"$entries($w,inNyact)\""
puts $channel "set entries(\$w,inNyb0) \"$entries($w,inNyb0)\""
puts $channel "set entries(\$w,inNyb0time) \"$entries($w,inNyb0time)\""
puts $channel "set entries(\$w,inNz) \"$entries($w,inNz)\""
puts $channel "set entries(\$w,inNzact) \"$entries($w,inNzact)\""
puts $channel "set entries(\$w,inNzb0) \"$entries($w,inNzb0)\""
puts $channel "set entries(\$w,inNzb0time) \"$entries($w,inNzb0time)\""
puts $channel "set entries(\$w,maxG) \"$entries($w,maxG)\""
puts $channel "set entries(\$w,mot) \"$entries($w,mot)\""
puts $channel "set entries(\$w,motion_yn) \"$entries($w,motion_yn)\""
puts $channel "set entries(\$w,mrpar) \"$entries($w,mrpar)\""
puts $channel "set entries(\$w,noise_yn) \"$entries($w,noise_yn)\""
puts $channel "set entries(\$w,noisesigma) \"$entries($w,noisesigma)\""
puts $channel "set entries(\$w,noisesnr) \"$entries($w,noisesnr)\""
puts $channel "set entries(\$w,noiseunits) \"$entries($w,noiseunits)\""
puts $channel "set entries(\$w,numproc) \"$entries($w,numproc)\""
puts $channel "set entries(\$w,numvol) \"$entries($w,numvol)\""
puts $channel "set entries(\$w,obvol) \"$entries($w,obvol)\""
puts $channel "set entries(\$w,out) \"$entries($w,out)\""
puts $channel "set entries(\$w,outsize_dx) \"$entries($w,outsize_dx)\""
puts $channel "set entries(\$w,outsize_dy) \"$entries($w,outsize_dy)\""
puts $channel "set entries(\$w,outsize_dz) \"$entries($w,outsize_dz)\""
puts $channel "set entries(\$w,outsize_nx) \"$entries($w,outsize_nx)\""
puts $channel "set entries(\$w,outsize_ny) \"$entries($w,outsize_ny)\""
puts $channel "set entries(\$w,outsize_nz) \"$entries($w,outsize_nz)\""
puts $channel "set entries(\$w,phencode) \"$entries($w,phencode)\""
puts $channel "set entries(\$w,plus) \"$entries($w,plus)\""
puts $channel "set entries(\$w,proctime) \"$entries($w,proctime)\""
puts $channel "set entries(\$w,pulsechecktest) \"$entries($w,pulsechecktest)\""
puts $channel "set entries(\$w,readgrad) \"$entries($w,readgrad)\""
puts $channel "set entries(\$w,riseT) \"$entries($w,riseT)\""
puts $channel "set entries(\$w,slcprof) \"$entries($w,slcprof)\""
puts $channel "set entries(\$w,slcselect) \"$entries($w,slcselect)\""
puts $channel "set entries(\$w,te) \"$entries($w,te)\""
puts $channel "set entries(\$w,tr) \"$entries($w,tr)\""
puts $channel "set entries(\$w,trslc) \"$entries($w,trslc)\""
puts $channel "set entries(\$w,vcX) \"$entries($w,vcX)\""
puts $channel "set entries(\$w,vcXact) \"$entries($w,vcXact)\""
puts $channel "set entries(\$w,vcXb0) \"$entries($w,vcXb0)\""
puts $channel "set entries(\$w,vcXb0time) \"$entries($w,vcXb0time)\""
puts $channel "set entries(\$w,vcY) \"$entries($w,vcY)\""
puts $channel "set entries(\$w,vcYact) \"$entries($w,vcYact)\""
puts $channel "set entries(\$w,vcYb0) \"$entries($w,vcYb0)\""
puts $channel "set entries(\$w,vcYb0time) \"$entries($w,vcYb0time)\""
puts $channel "set entries(\$w,vcZ) \"$entries($w,vcZ)\""
puts $channel "set entries(\$w,vcZact) \"$entries($w,vcZact)\""
puts $channel "set entries(\$w,vcZb0) \"$entries($w,vcZb0)\""
puts $channel "set entries(\$w,vcZb0time) \"$entries($w,vcZb0time)\""
puts $channel "set entries(\$w,zstart) \"$entries($w,zstart)\""
close $channel
}

proc possum:load { w filename } {
    global entries FSLDIR
    source ${filename}
    possum:updateFOV $w
    possum:updateVSIZE $w
    possum:updateTRSLC $w
    possum:updateb0field $w
    possum:updateb0fieldinh $w
    possum:updateb0fieldinhtime $w
    possum:updatemotion $w
    possum:updateactivation $w
    possum:updatenoise $w
    possum:updatenoiseunits $w
    possum:updatecomptime $w 
    possum:updateechosp $w
}

proc possum:proc { w comptime obvol mrpar te tr trslc outsize_nx outsize_ny outsize_nz outsize_dx outsize_dy outsize_dz fov_x fov_y fov_z numvol zstart gap bw readdir phasedir slcdir plus maxG riseT b0f b0fieldstrength b0units b0extra b0timecourse b0extraunits mot act1 act2 out numproc slcprof cover flipangle} {
    global entries FSLDIR POSSUMDIR
    set dx [ expr $outsize_dx * 0.001 ]
    set dy [ expr $outsize_dy * 0.001 ]
    set dz [ expr $outsize_dz * 0.001 ]
    set zs [ expr $zstart * 0.001 ]
    set gap [ expr $gap * 0.001 ]
  
    catch { exec sh -c "${FSLDIR}/bin/imcp $obvol $out/brain" } oval
    catch { exec sh -c "cp $mrpar $out/MRpar" } oval
    catch { exec sh -c "cp $slcprof $out/slcprof" } oval
    catch { exec sh -c "cp $mot $out/motion" } oval
    catch { exec sh -c "${FSLDIR}/bin/imcp $act1 $out/T2" } oval
    catch { exec sh -c "cp $act2 $out/T2timecourse" } oval
    if { $b0f != "" && $mot == "${FSLDIR}/data/possum/zeromotion" } {
       catch { exec sh -c "${FSLDIR}/bin/fslroi ${b0f} ${out}/b0z_dz.nii.gz 0 1" } oval
       if { $b0units == "ppm" } {
	  catch { exec sh -c "${FSLDIR}/bin/fslmaths $out/b0z_dz -mul $b0fieldstrength -div 1000000 $out/b0z_dz" } oval
       }
    }
    if { $b0f != "" && $mot != "${FSLDIR}/data/possum/zeromotion" } {
        if { $b0units == "ppm" } {
	    catch { exec sh -c "${FSLDIR}/bin/fslmaths ${b0f} -mul $b0fieldstrength -div 1000000 $out/b0inh" } oval
	}
	catch { exec sh -c "${FSLDIR}/bin/fslroi $out/b0inh ${out}/b0x_dx.nii.gz 8 1" } oval
	catch { exec sh -c "${FSLDIR}/bin/fslroi $out/b0inh ${out}/b0x_dy.nii.gz 7 1" } oval
	catch { exec sh -c "${FSLDIR}/bin/fslroi $out/b0inh ${out}/b0x_dz.nii.gz 6 1" } oval
	catch { exec sh -c "${FSLDIR}/bin/fslroi $out/b0inh ${out}/b0y_dx.nii.gz 5 1" } oval
	catch { exec sh -c "${FSLDIR}/bin/fslroi $out/b0inh ${out}/b0y_dy.nii.gz 4 1" } oval
	catch { exec sh -c "${FSLDIR}/bin/fslroi $out/b0inh ${out}/b0y_dz.nii.gz 3 1" } oval
	catch { exec sh -c "${FSLDIR}/bin/fslroi $out/b0inh ${out}/b0z_dx.nii.gz 2 1" } oval
	catch { exec sh -c "${FSLDIR}/bin/fslroi $out/b0inh ${out}/b0z_dy.nii.gz 1 1" } oval
	catch { exec sh -c "${FSLDIR}/bin/fslroi $out/b0inh ${out}/b0z_dz.nii.gz 0 1" } oval
	catch { exec sh -c "${FSLDIR}/bin/imrm $out/b0inh" } oval
    }
    if { $b0extra != "" && $mot == "${FSLDIR}/data/possum/zeromotion" } {
       if { $b0extraunits == "ppm" } {
	   catch { exec sh -c "${FSLDIR}/bin/fslmaths ${b0extra} -mul $b0fieldstrength -div 1000000 $out/b0extra" } oval
	   catch { exec sh -c "cp $b0timecourse $out/b0timecourse" } oval
       } else {
	   catch { exec sh -c "${FSLDIR}/bin/imcp $b0extra $out/b0extra" } oval
	   catch { exec sh -c "cp $b0timecourse $out/b0timecourse" } oval
       }
    }
    if { $b0extra != "" && $mot != "${FSLDIR}/data/possum/zeromotion" } {
       puts "Warning: At the moment B0 field changing in time can not be simulated while the object is moving. This will be implemented into POSSUM at a later stage."
       return
    }
    # Generate pulse seq
    puts "Generating the pulse sequence..."
    if { $cover<100 } {
	puts "Partial EPI. $cover % coverage"
    } else {
	puts "Regular EPI. $cover % coverage"
    }
    set seq epi
    set pulsecom  "${POSSUMDIR}/bin/pulse -i $obvol -o ${out}/pulse --te=${te} --tr=${tr} --trslc=${trslc} --nx=${outsize_nx} --ny=${outsize_ny} --dx=${dx} --dy=${dy} --maxG=${maxG} --riset=${riseT} --bw=${bw} --numvol=${numvol} --numslc=${outsize_nz} --slcthk=${dz} --zstart=${zs} --seq=${seq} --slcdir=${slcdir}${plus} --readdir=${readdir}$entries($w,pluss) --phasedir=${phasedir}$entries($w,pluss) --gap=$gap -v --cover=$cover --angle=$flipangle"
    catch { exec sh -c "echo $pulsecom >> $out/pulse.com" } oval
    catch { exec sh -c "echo $pulsecom >> $out/possum.log" } oval
    Possum:pulsecheck $w
    if { $entries($w,pulsechecktest) == 0 } {
	return
    } 
    fsl:exec "$pulsecom >> $out/possum.log 2>&1" 
    
    # Execute possum 
    puts "Submitting the job..."
    set possumcom  "${POSSUMDIR}/bin/possumX $out -n $numproc -t $comptime"
    catch { exec sh -c "echo $possumcom >> $out/possum.log" } oval
    fsl:exec "$possumcom  >> $out/possum.log 2>&1"
    return 0
}

wm withdraw .
possum .rename
tkwait window .rename

