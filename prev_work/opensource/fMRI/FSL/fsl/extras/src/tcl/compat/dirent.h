/*
 * dirent.h --
 *
 *	This file is a replacement for <dirent.h> in systems that
 *	support the old BSD-style <sys/dir.h> with a "struct direct".
 *
 * Copyright (c) 1991 The Regents of the University of California.
 * Copyright (c) 1994 Sun Microsystems, Inc.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: dirent.h,v 1.1.1.1 2007/07/10 15:04:23 duncan Exp $
 */

#ifndef _DIRENT
#define _DIRENT

#include <sys/dir.h>

#define dirent direct

#endif /* _DIRENT */
