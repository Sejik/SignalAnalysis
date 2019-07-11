# all.tcl --
#
# This file contains a top-level script to run all of the Tcl
# tests.  Execute it by invoking "source all.test" when running tcltest
# in this directory.
#
# Copyright (c) 1998-1999 by Scriptics Corporation.
# Copyright (c) 2000 by Ajuba Solutions
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# RCS: @(#) $Id: all.tcl,v 1.1.1.1 2007/07/10 15:04:24 duncan Exp $

set tcltestVersion [package require tcltest]
namespace import -force tcltest::*

if {$tcl_platform(platform) == "macintosh"} {
	tcltest::singleProcess 1
}

tcltest::testsDirectory [file dir [info script]]
tcltest::runAllTests

return
