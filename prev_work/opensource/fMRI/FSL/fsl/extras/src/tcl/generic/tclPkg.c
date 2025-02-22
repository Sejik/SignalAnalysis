/* 
 * tclPkg.c --
 *
 *	This file implements package and version control for Tcl via
 *	the "package" command and a few C APIs.
 *
 * Copyright (c) 1996 Sun Microsystems, Inc.
 * Copyright (c) 2006 Andreas Kupries <andreas_kupries@users.sourceforge.net>
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: tclPkg.c,v 1.1.1.1 2007/07/10 15:04:23 duncan Exp $
 *
 * TIP #268.
 * Heavily rewritten to handle the extend version numbers, and extended
 * package requirements.
 */

#include "tclInt.h"

/*
 * Each invocation of the "package ifneeded" command creates a structure
 * of the following type, which is used to load the package into the
 * interpreter if it is requested with a "package require" command.
 */

typedef struct PkgAvail {
    char *version;		/* Version string; malloc'ed. */
    char *script;		/* Script to invoke to provide this version
				 * of the package.  Malloc'ed and protected
				 * by Tcl_Preserve and Tcl_Release. */
    struct PkgAvail *nextPtr;	/* Next in list of available versions of
				 * the same package. */
} PkgAvail;

/*
 * For each package that is known in any way to an interpreter, there
 * is one record of the following type.  These records are stored in
 * the "packageTable" hash table in the interpreter, keyed by
 * package name such as "Tk" (no version number).
 */

typedef struct Package {
    char *version;		/* Version that has been supplied in this
				 * interpreter via "package provide"
				 * (malloc'ed).  NULL means the package doesn't
				 * exist in this interpreter yet. */
    PkgAvail *availPtr;		/* First in list of all available versions
				 * of this package. */
    ClientData clientData;	/* Client data. */
} Package;

/*
 * Prototypes for procedures defined in this file:
 */

#ifndef TCL_TIP268
static int		CheckVersion _ANSI_ARGS_((Tcl_Interp *interp,
			    CONST char *string));
static int		ComparePkgVersions _ANSI_ARGS_((CONST char *v1, 
                            CONST char *v2,
			    int *satPtr));
static Package *	FindPackage _ANSI_ARGS_((Tcl_Interp *interp,
			    CONST char *name));
#else
static int		CheckVersionAndConvert(Tcl_Interp *interp, CONST char *string,
					       char** internal, int* stable);
static int		CompareVersions(CONST char *v1i, CONST char *v2i,
					int *isMajorPtr);
static int		CheckRequirement(Tcl_Interp *interp, CONST char *string);
static int		CheckAllRequirements(Tcl_Interp* interp,
					     int reqc, Tcl_Obj *CONST reqv[]);
static int		RequirementSatisfied(CONST char *havei, CONST char *req);
static int		AllRequirementsSatisfied(CONST char *havei,
						 int reqc, Tcl_Obj *CONST reqv[]);
static void		AddRequirementsToResult(Tcl_Interp* interp,
						int reqc, Tcl_Obj *CONST reqv[]);
static void		AddRequirementsToDString(Tcl_DString* dstring,
						 int reqc, Tcl_Obj *CONST reqv[]);
static Package *	FindPackage(Tcl_Interp *interp, CONST char *name);
static Tcl_Obj*		ExactRequirement(CONST char* version);
static void		VersionCleanupProc(ClientData clientData,
			    Tcl_Interp *interp);
#endif

/*
 *----------------------------------------------------------------------
 *
 * Tcl_PkgProvide / Tcl_PkgProvideEx --
 *
 *	This procedure is invoked to declare that a particular version
 *	of a particular package is now present in an interpreter.  There
 *	must not be any other version of this package already
 *	provided in the interpreter.
 *
 * Results:
 *	Normally returns TCL_OK;  if there is already another version
 *	of the package loaded then TCL_ERROR is returned and an error
 *	message is left in the interp's result.
 *
 * Side effects:
 *	The interpreter remembers that this package is available,
 *	so that no other version of the package may be provided for
 *	the interpreter.
 *
 *----------------------------------------------------------------------
 */

int
Tcl_PkgProvide(interp, name, version)
     Tcl_Interp *interp;	/* Interpreter in which package is now
				 * available. */
     CONST char *name;		/* Name of package. */
     CONST char *version;	/* Version string for package. */
{
    return Tcl_PkgProvideEx(interp, name, version, (ClientData) NULL);
}

int
Tcl_PkgProvideEx(interp, name, version, clientData)
     Tcl_Interp *interp;	/* Interpreter in which package is now
				 * available. */
     CONST char *name;		/* Name of package. */
     CONST char *version;	/* Version string for package. */
     ClientData clientData;     /* clientdata for this package (normally
				 * used for C callback function table) */
{
    Package *pkgPtr;
#ifdef TCL_TIP268
    char* pvi;
    char* vi;
    int res;
#endif

    pkgPtr = FindPackage(interp, name);
    if (pkgPtr->version == NULL) {
	pkgPtr->version = ckalloc((unsigned) (strlen(version) + 1));
	strcpy(pkgPtr->version, version);
	pkgPtr->clientData = clientData;
	return TCL_OK;
    }
#ifndef TCL_TIP268
    if (ComparePkgVersions(pkgPtr->version, version, (int *) NULL) == 0) {
#else
    if (CheckVersionAndConvert (interp, pkgPtr->version, &pvi, NULL) != TCL_OK) {
	return TCL_ERROR;
    } else if (CheckVersionAndConvert (interp, version, &vi, NULL) != TCL_OK) {
	Tcl_Free (pvi);
	return TCL_ERROR;
    }

    res = CompareVersions(pvi, vi, NULL);
    Tcl_Free (pvi);
    Tcl_Free (vi);

    if (res == 0) {
#endif
	if (clientData != NULL) {
	    pkgPtr->clientData = clientData;
	}
	return TCL_OK;
    }
    Tcl_AppendResult(interp, "conflicting versions provided for package \"",
		     name, "\": ", pkgPtr->version, ", then ", version, (char *) NULL);
    return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_PkgRequire / Tcl_PkgRequireEx / Tcl_PkgRequireProc --
 *
 *	This procedure is called by code that depends on a particular
 *	version of a particular package.  If the package is not already
 *	provided in the interpreter, this procedure invokes a Tcl script
 *	to provide it.  If the package is already provided, this
 *	procedure makes sure that the caller's needs don't conflict with
 *	the version that is present.
 *
 * Results:
 *	If successful, returns the version string for the currently
 *	provided version of the package, which may be different from
 *	the "version" argument.  If the caller's requirements
 *	cannot be met (e.g. the version requested conflicts with
 *	a currently provided version, or the required version cannot
 *	be found, or the script to provide the required version
 *	generates an error), NULL is returned and an error
 *	message is left in the interp's result.
 *
 * Side effects:
 *	The script from some previous "package ifneeded" command may
 *	be invoked to provide the package.
 *
 *----------------------------------------------------------------------
 */

#ifndef TCL_TIP268
/*
 * Empty definition for Stubs when TIP 268 is not activated.
 */
int
Tcl_PkgRequireProc(interp,name,reqc,reqv,clientDataPtr)
     Tcl_Interp *interp;	/* Interpreter in which package is now
				 * available. */
     CONST char *name;		/* Name of desired package. */
     int reqc;                  /* Requirements constraining the desired version. */
     Tcl_Obj *CONST reqv[];     /* 0 means to use the latest version available. */
     ClientData *clientDataPtr;
{
    return TCL_ERROR;
}
#endif

CONST char *
Tcl_PkgRequire(interp, name, version, exact)
    Tcl_Interp *interp;	        /* Interpreter in which package is now
				 * available. */
     CONST char *name;		/* Name of desired package. */
     CONST char *version;	/* Version string for desired version; NULL
				 * means use the latest version available. */
     int exact;			/* Non-zero means that only the particular
				 * version given is acceptable. Zero means use
				 * the latest compatible version. */
{
    return Tcl_PkgRequireEx(interp, name, version, exact, (ClientData *) NULL);
}

CONST char *
Tcl_PkgRequireEx(interp, name, version, exact, clientDataPtr)
     Tcl_Interp *interp;	/* Interpreter in which package is now
				 * available. */
     CONST char *name;		/* Name of desired package. */
     CONST char *version;	/* Version string for desired version;
				 * NULL means use the latest version
				 * available. */
     int exact;			/* Non-zero means that only the particular
				 * version given is acceptable. Zero means
				 * use the latest compatible version. */
     ClientData *clientDataPtr;	/* Used to return the client data for this
				 * package. If it is NULL then the client
				 * data is not returned. This is unchanged
				 * if this call fails for any reason. */
{
#ifndef TCL_TIP268
    Package *pkgPtr;
    PkgAvail *availPtr, *bestPtr;
    char *script;
    int code, satisfies, result, pass;
    Tcl_DString command;
#else
    Tcl_Obj *ov;
    int      res;
#endif

    /*
     * If an attempt is being made to load this into a standalone executable
     * on a platform where backlinking is not supported then this must be
     * a shared version of Tcl (Otherwise the load would have failed).
     * Detect this situation by checking that this library has been correctly
     * initialised. If it has not been then return immediately as nothing will
     * work.
     */
    
    if (tclEmptyStringRep == NULL) {

	/*
	 * OK, so what's going on here?
	 *
	 * First, what are we doing?  We are performing a check on behalf of
	 * one particular caller, Tcl_InitStubs().  When a package is
	 * stub-enabled, it is statically linked to libtclstub.a, which
	 * contains a copy of Tcl_InitStubs().  When a stub-enabled package
	 * is loaded, its *_Init() function is supposed to call
	 * Tcl_InitStubs() before calling any other functions in the Tcl
	 * library.  The first Tcl function called by Tcl_InitStubs() through
	 * the stub table is Tcl_PkgRequireEx(), so this code right here is
	 * the first code that is part of the original Tcl library in the
	 * executable that gets executed on behalf of a newly loaded
	 * stub-enabled package.
	 *
	 * One easy error for the developer/builder of a stub-enabled package
	 * to make is to forget to define USE_TCL_STUBS when compiling the
	 * package.  When that happens, the package will contain symbols
	 * that are references to the Tcl library, rather than function
	 * pointers referencing the stub table.  On platforms that lack
	 * backlinking, those unresolved references may cause the loading
	 * of the package to also load a second copy of the Tcl library,
	 * leading to all kinds of trouble.  We would like to catch that
	 * error and report a useful message back to the user.  That's
	 * what we're doing.
	 *
	 * Second, how does this work?  If we reach this point, then the
	 * global variable tclEmptyStringRep has the value NULL.  Compare
	 * that with the definition of tclEmptyStringRep near the top of
	 * the file generic/tclObj.c.  It clearly should not have the value
	 * NULL; it should point to the char tclEmptyString.  If we see it
	 * having the value NULL, then somehow we are seeing a Tcl library
	 * that isn't completely initialized, and that's an indicator for the
	 * error condition described above.  (Further explanation is welcome.)
	 *
	 * Third, so what do we do about it?  This situation indicates
	 * the package we just loaded wasn't properly compiled to be
	 * stub-enabled, yet it thinks it is stub-enabled (it called
	 * Tcl_InitStubs()).  We want to report that the package just
	 * loaded is broken, so we want to place an error message in
	 * the interpreter result and return NULL to indicate failure
	 * to Tcl_InitStubs() so that it will also fail.  (Further
	 * explanation why we don't want to Tcl_Panic() is welcome.
	 * After all, two Tcl libraries can't be a good thing!)
	 *
	 * Trouble is that's going to be tricky.  We're now using a Tcl
	 * library that's not fully initialized.  In particular, it 
	 * doesn't have a proper value for tclEmptyStringRep.  The
	 * Tcl_Obj system heavily depends on the value of tclEmptyStringRep
	 * and all of Tcl depends (increasingly) on the Tcl_Obj system, we
	 * need to correct that flaw before making the calls to set the 
	 * interpreter result to the error message.  That's the only flaw
	 * corrected; other problems with initialization of the Tcl library
	 * are not remedied, so be very careful about adding any other calls
	 * here without checking how they behave when initialization is
	 * incomplete.
	 */

	tclEmptyStringRep = &tclEmptyString;
        Tcl_AppendResult(interp, "Cannot load package \"", name, 
			 "\" in standalone executable: This package is not ",
			 "compiled with stub support", NULL);
        return NULL;
    }

#ifdef TCL_TIP268
    /* Translate between old and new API, and defer to the new function. */

    if (version == NULL) {
	res = Tcl_PkgRequireProc(interp, name, 0, NULL, clientDataPtr);
    } else {
	if (exact) {
	    ov = ExactRequirement (version);
	} else {
	    ov = Tcl_NewStringObj (version,-1);
	}

	Tcl_IncrRefCount (ov);
	res = Tcl_PkgRequireProc(interp, name, 1, &ov, clientDataPtr);
	Tcl_DecrRefCount (ov);
    }

    if (res != TCL_OK) {
	return NULL;
    }

    /* This function returns the version string explictly, and leaves the
     * interpreter result empty. However "Tcl_PkgRequireProc" above returned
     * the version through the interpreter result. Simply resetting the result
     * now potentially deletes the string (obj), and the pointer to its string
     * rep we have, as our result, may be dangling due to this. Our solution
     * is to remember the object in interp associated data, with a proper
     * reference count, and then reset the result. Now pointers will not
     * dangle. It will be a leak however if nothing is done. So the next time
     * we come through here we delete the object remembered by this call, as
     * we can then be sure that there is no pointer to its string around
     * anymore. Beyond that we have a deletion function which cleans up the last
     * remembered object which was not cleaned up directly, here.
     */

    ov = (Tcl_Obj*) Tcl_GetAssocData (interp, "tcl/Tcl_PkgRequireEx", NULL);
    if (ov != NULL) {
	Tcl_DecrRefCount (ov);
    }

    ov = Tcl_GetObjResult (interp);
    Tcl_IncrRefCount (ov);
    Tcl_SetAssocData(interp, "tcl/Tcl_PkgRequireEx", VersionCleanupProc,
		     (ClientData) ov);
    Tcl_ResetResult (interp);

    return Tcl_GetString (ov);
}

int
Tcl_PkgRequireProc(interp,name,reqc,reqv,clientDataPtr)
     Tcl_Interp *interp;	/* Interpreter in which package is now
				 * available. */
     CONST char *name;		/* Name of desired package. */
     int reqc;                  /* Requirements constraining the desired version. */
     Tcl_Obj *CONST reqv[];     /* 0 means to use the latest version available. */
     ClientData *clientDataPtr;
{
    Interp *iPtr = (Interp *) interp;
    Package *pkgPtr;
    PkgAvail *availPtr,     *bestPtr, *bestStablePtr;
    char     *availVersion, *bestVersion; /* Internal rep. of versions */
    int       availStable;
    char *script;
    int code, satisfies, pass;
    Tcl_DString command;
    char* pkgVersionI;

#endif
    /*
     * It can take up to three passes to find the package: one pass to run the
     * "package unknown" script, one to run the "package ifneeded" script for
     * a specific version, and a final pass to lookup the package loaded by
     * the "package ifneeded" script.
     */

    for (pass = 1; ; pass++) {
	pkgPtr = FindPackage(interp, name);
	if (pkgPtr->version != NULL) {
	    break;
	}

	/* 
	 * Check whether we're already attempting to load some version
	 * of this package (circular dependency detection).
	 */

	if (pkgPtr->clientData != NULL) {
	    Tcl_AppendResult(interp, "circular package dependency: ",
			     "attempt to provide ", name, " ",
			     (char *)(pkgPtr->clientData), " requires ", name, NULL);
#ifndef TCL_TIP268
	    if (version != NULL) {
		Tcl_AppendResult(interp, " ", version, NULL);
	    }
	    return NULL;
#else
	    AddRequirementsToResult (interp, reqc, reqv);
	    return TCL_ERROR;
#endif
	}

	/*
	 * The package isn't yet present. Search the list of available
	 * versions and invoke the script for the best available version.
	 *
	 * For TIP 268 we are actually locating the best, and the best stable
	 * version.  One of them is then chosen based on the selection mode.
	 */
#ifndef TCL_TIP268    
	bestPtr = NULL;
	for (availPtr = pkgPtr->availPtr; availPtr != NULL;
		availPtr = availPtr->nextPtr) {
	    if ((bestPtr != NULL) && (ComparePkgVersions(availPtr->version,
		    bestPtr->version, (int *) NULL) <= 0)) {
#else
	bestPtr        = NULL;
	bestStablePtr  = NULL;
	bestVersion    = NULL;

	for (availPtr = pkgPtr->availPtr;
	     availPtr != NULL;
	     availPtr = availPtr->nextPtr) {
	    if (CheckVersionAndConvert (interp, availPtr->version,
					&availVersion, &availStable) != TCL_OK) {
		/* The provided version number is has invalid syntax. This
		 * should not happen. This should have been caught by the
		 * 'package ifneeded' registering the package.
		 */
#endif
		continue;
	    }
#ifndef TCL_TIP268
	    if (version != NULL) {
		result = ComparePkgVersions(availPtr->version, version,
			&satisfies);
		if ((result != 0) && exact) {
#else
	    if (bestPtr != NULL) {
		int res = CompareVersions (availVersion, bestVersion, NULL);
		/* Note: Use internal reps! */
		if (res <= 0) {
		    /* The version of the package sought is not as good as the
		     * currently selected version. Ignore it. */
		    Tcl_Free (availVersion);
		    availVersion = NULL;
#endif
		    continue;
		}
#ifdef TCL_TIP268
	    }

	    /* We have found a version which is better than our max. */

	    if (reqc > 0) {
		/* Check satisfaction of requirements */
		satisfies = AllRequirementsSatisfied (availVersion, reqc, reqv);
#endif
		if (!satisfies) {
#ifdef TCL_TIP268
		    Tcl_Free (availVersion);
		    availVersion = NULL;
#endif
		    continue;
		}
	    }
	    bestPtr = availPtr;
#ifdef TCL_TIP268
	    if (bestVersion != NULL) Tcl_Free (bestVersion);
	    bestVersion  = availVersion;
	    availVersion = NULL;

	    /* If this new best version is stable then it also has to be
	     * better than the max stable version found so far.
	     */

	    if (availStable) {
		bestStablePtr = availPtr;
	    }
	}

	if (bestVersion != NULL) {
	    Tcl_Free (bestVersion);
	}

	/* Now choose a version among the two best. For 'latest' we simply
	 * take (actually keep) the best. For 'stable' we take the best
	 * stable, if there is any, or the best if there is nothing stable.
	 */

	if ((iPtr->packagePrefer == PKG_PREFER_STABLE) && (bestStablePtr != NULL)) {
	    bestPtr = bestStablePtr;
#endif
	}
	if (bestPtr != NULL) {
	    /*
	     * We found an ifneeded script for the package. Be careful while
	     * executing it: this could cause reentrancy, so (a) protect the
	     * script itself from deletion and (b) don't assume that bestPtr
	     * will still exist when the script completes.
	     */

	    CONST char *versionToProvide = bestPtr->version;
	    script = bestPtr->script;
	    pkgPtr->clientData = (ClientData) versionToProvide;
	    Tcl_Preserve((ClientData) script);
	    Tcl_Preserve((ClientData) versionToProvide);
	    code = Tcl_EvalEx(interp, script, -1, TCL_EVAL_GLOBAL);
	    Tcl_Release((ClientData) script);
	    pkgPtr = FindPackage(interp, name);
	    if (code == TCL_OK) {
#ifdef TCL_TIP268
		Tcl_ResetResult(interp);
#endif
		if (pkgPtr->version == NULL) {
#ifndef TCL_TIP268
		    Tcl_ResetResult(interp);
#endif
		    code = TCL_ERROR;
		    Tcl_AppendResult(interp, "attempt to provide package ",
				     name, " ", versionToProvide,
				     " failed: no version of package ", name,
				     " provided", NULL);
#ifndef TCL_TIP268
		} else if (0 != ComparePkgVersions(
			pkgPtr->version, versionToProvide, NULL)) {
		    /* At this point, it is clear that a prior
		     * [package ifneeded] command lied to us.  It said
		     * that to get a particular version of a particular
		     * package, we needed to evaluate a particular script.
		     * However, we evaluated that script and got a different
		     * version than we were told.  This is an error, and we
		     * ought to report it.
		     *
		     * However, we've been letting this type of error slide
		     * for a long time, and as a result, a lot of packages
		     * suffer from them.
		     *
		     * It's a bit too harsh to make a large number of
		     * existing packages start failing by releasing a
		     * new patch release, so we forgive this type of error
		     * for the rest of the Tcl 8.4 series.
		     *
		     * We considered reporting a warning, but in practice
		     * even that appears too harsh a change for a patch release.
		     *
		     * We limit the error reporting to only
		     * the situation where a broken ifneeded script leads
		     * to a failure to satisfy the requirement.
		     */
		    if (version) {
			result = ComparePkgVersions(
				pkgPtr->version, version, &satisfies);
			if (result && (exact || !satisfies)) {
			    Tcl_ResetResult(interp);
			    code = TCL_ERROR;
			    Tcl_AppendResult(interp,
				    "attempt to provide package ", name, " ",
				    versionToProvide, " failed: package ",
				    name, " ", pkgPtr->version,
				    " provided instead", NULL);
#else
		} else {
		    char* pvi;
		    char* vi;
		    int res;

		    if (CheckVersionAndConvert (interp, pkgPtr->version, &pvi, NULL) != TCL_OK) {
			code = TCL_ERROR;
		    } else if (CheckVersionAndConvert (interp, versionToProvide, &vi, NULL) != TCL_OK) {
			Tcl_Free (pvi);
			code = TCL_ERROR;
		    } else {
			res = CompareVersions(pvi, vi, NULL);
			Tcl_Free (vi);

			if (res != 0) {
			    /* At this point, it is clear that a prior
			     * [package ifneeded] command lied to us.  It said
			     * that to get a particular version of a particular
			     * package, we needed to evaluate a particular script.
			     * However, we evaluated that script and got a different
			     * version than we were told.  This is an error, and we
			     * ought to report it.
			     *
			     * However, we've been letting this type of error slide
			     * for a long time, and as a result, a lot of packages
			     * suffer from them.
			     *
			     * It's a bit too harsh to make a large number of
			     * existing packages start failing by releasing a
			     * new patch release, so we forgive this type of error
			     * for the rest of the Tcl 8.4 series.
			     *
			     * We considered reporting a warning, but in practice
			     * even that appears too harsh a change for a patch release.
			     *
			     * We limit the error reporting to only
			     * the situation where a broken ifneeded script leads
			     * to a failure to satisfy the requirement.
			     */

			    if (reqc > 0) {
			        satisfies = AllRequirementsSatisfied (pvi, reqc, reqv);
				if (!satisfies) {
				    Tcl_ResetResult(interp);
				    code = TCL_ERROR;
				    Tcl_AppendResult(interp,
						     "attempt to provide package ", name, " ",
						     versionToProvide, " failed: package ",
						     name, " ", pkgPtr->version,
						     " provided instead", NULL);
				}
			    }
			    /*
			     * Warning generation now disabled
			     if (code == TCL_OK) {
			     Tcl_Obj *msg = Tcl_NewStringObj(
			     "attempt to provide package ", -1);
			     Tcl_Obj *cmdPtr = Tcl_NewListObj(0, NULL);
			     Tcl_ListObjAppendElement(NULL, cmdPtr,
			     Tcl_NewStringObj("tclLog", -1));
			     Tcl_AppendStringsToObj(msg, name, " ", versionToProvide,
			     " failed: package ", name, " ",
			     pkgPtr->version, " provided instead", NULL);
			     Tcl_ListObjAppendElement(NULL, cmdPtr, msg);
			     Tcl_IncrRefCount(cmdPtr);
			     Tcl_EvalObjEx(interp, cmdPtr, TCL_EVAL_GLOBAL);
			     Tcl_DecrRefCount(cmdPtr);
			     Tcl_ResetResult(interp);
			     }
			    */
#endif
			}
#ifdef TCL_TIP268
			Tcl_Free (pvi);
#endif
		    }
#ifndef TCL_TIP268
		    /*
		     * Warning generation now disabled
		    if (code == TCL_OK) {
			Tcl_Obj *msg = Tcl_NewStringObj(
				"attempt to provide package ", -1);
			Tcl_Obj *cmdPtr = Tcl_NewListObj(0, NULL);
			Tcl_ListObjAppendElement(NULL, cmdPtr,
				Tcl_NewStringObj("tclLog", -1));
			Tcl_AppendStringsToObj(msg, name, " ", versionToProvide,
				" failed: package ", name, " ",
				pkgPtr->version, " provided instead", NULL);
			Tcl_ListObjAppendElement(NULL, cmdPtr, msg);
			Tcl_IncrRefCount(cmdPtr);
			Tcl_EvalObjEx(interp, cmdPtr, TCL_EVAL_GLOBAL);
			Tcl_DecrRefCount(cmdPtr);
			Tcl_ResetResult(interp);
		    }
		    */
#endif
		}
	    } else if (code != TCL_ERROR) {
		Tcl_Obj *codePtr = Tcl_NewIntObj(code);
		Tcl_ResetResult(interp);
		Tcl_AppendResult(interp, "attempt to provide package ",
				 name, " ", versionToProvide, " failed: ",
				 "bad return code: ", Tcl_GetString(codePtr), NULL);
		Tcl_DecrRefCount(codePtr);
		code = TCL_ERROR;
	    }
	    Tcl_Release((ClientData) versionToProvide);

	    if (code != TCL_OK) {
		/*
		 * Take a non-TCL_OK code from the script as an
		 * indication the package wasn't loaded properly,
		 * so the package system should not remember an
		 * improper load.
		 *
		 * This is consistent with our returning NULL.
		 * If we're not willing to tell our caller we
		 * got a particular version, we shouldn't store
		 * that version for telling future callers either.
		 */
		Tcl_AddErrorInfo(interp, "\n    (\"package ifneeded\" script)");
		if (pkgPtr->version != NULL) {
		    ckfree(pkgPtr->version);
		    pkgPtr->version = NULL;
		}
		pkgPtr->clientData = NULL;
#ifndef TCL_TIP268
		return NULL;
#else
		return TCL_ERROR;
#endif
	    }
	    break;
	}

	/*
	 * The package is not in the database. If there is a "package unknown"
	 * command, invoke it (but only on the first pass; after that, we
	 * should not get here in the first place).
	 */

	if (pass > 1) {
	    break;
	}
	script = ((Interp *) interp)->packageUnknown;
	if (script != NULL) {
	    Tcl_DStringInit(&command);
	    Tcl_DStringAppend(&command, script, -1);
	    Tcl_DStringAppendElement(&command, name);
#ifndef TCL_TIP268
	    Tcl_DStringAppend(&command, " ", 1);
	    Tcl_DStringAppend(&command, (version != NULL) ? version : "{}",
		    -1);
	    if (exact) {
		Tcl_DStringAppend(&command, " -exact", 7);
	    }
#else
	    AddRequirementsToDString(&command, reqc, reqv);
#endif
	    code = Tcl_EvalEx(interp, Tcl_DStringValue(&command),
			      Tcl_DStringLength(&command), TCL_EVAL_GLOBAL);
	    Tcl_DStringFree(&command);
	    if ((code != TCL_OK) && (code != TCL_ERROR)) {
		Tcl_Obj *codePtr = Tcl_NewIntObj(code);
		Tcl_ResetResult(interp);
		Tcl_AppendResult(interp, "bad return code: ",
				 Tcl_GetString(codePtr), NULL);
		Tcl_DecrRefCount(codePtr);
		code = TCL_ERROR;
	    }
	    if (code == TCL_ERROR) {
		Tcl_AddErrorInfo(interp, "\n    (\"package unknown\" script)");
#ifndef TCL_TIP268
		return NULL;
#else
		return TCL_ERROR;
#endif
	    }
	    Tcl_ResetResult(interp);
	}
    }

    if (pkgPtr->version == NULL) {
	Tcl_AppendResult(interp, "can't find package ", name, (char *) NULL);
#ifndef TCL_TIP268
	if (version != NULL) {
	    Tcl_AppendResult(interp, " ", version, (char *) NULL);
	}
	return NULL;
#else
	AddRequirementsToResult(interp, reqc, reqv);
	return TCL_ERROR;
#endif
    }

    /*
     * At this point we know that the package is present. Make sure that the
     * provided version meets the current requirements.
     */

#ifndef TCL_TIP268
    if (version == NULL) {
        if (clientDataPtr) {
	    *clientDataPtr = pkgPtr->clientData;
	}
	return pkgPtr->version;
#else
    if (reqc == 0) {
	satisfies = 1;
    } else {
	CheckVersionAndConvert (interp, pkgPtr->version, &pkgVersionI, NULL);
	satisfies = AllRequirementsSatisfied (pkgVersionI, reqc, reqv);

	Tcl_Free (pkgVersionI);
#endif
    }
#ifndef TCL_TIP268
    result = ComparePkgVersions(pkgPtr->version, version, &satisfies);
    if ((satisfies && !exact) || (result == 0)) {
#else
    if (satisfies) {
#endif
	if (clientDataPtr) {
	    *clientDataPtr = pkgPtr->clientData;
	}
#ifndef TCL_TIP268
	return pkgPtr->version;
#else
	Tcl_SetObjResult (interp, Tcl_NewStringObj (pkgPtr->version, -1));
	return TCL_OK;
#endif
    }
    Tcl_AppendResult(interp, "version conflict for package \"",
		     name, "\": have ", pkgPtr->version,
#ifndef TCL_TIP268
		      ", need ", version, (char *) NULL);
    return NULL;
#else
                      ", need", (char*) NULL);
    AddRequirementsToResult (interp, reqc, reqv);
    return TCL_ERROR;
#endif
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_PkgPresent / Tcl_PkgPresentEx --
 *
 *	Checks to see whether the specified package is present. If it
 *	is not then no additional action is taken.
 *
 * Results:
 *	If successful, returns the version string for the currently
 *	provided version of the package, which may be different from
 *	the "version" argument.  If the caller's requirements
 *	cannot be met (e.g. the version requested conflicts with
 *	a currently provided version), NULL is returned and an error
 *	message is left in interp->result.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

CONST char *
Tcl_PkgPresent(interp, name, version, exact)
     Tcl_Interp *interp;	/* Interpreter in which package is now
				 * available. */
     CONST char *name;		/* Name of desired package. */
     CONST char *version;	/* Version string for desired version;
				 * NULL means use the latest version
				 * available. */
     int exact;			/* Non-zero means that only the particular
				 * version given is acceptable. Zero means
				 * use the latest compatible version. */
{
    return Tcl_PkgPresentEx(interp, name, version, exact, (ClientData *) NULL);
}

CONST char *
Tcl_PkgPresentEx(interp, name, version, exact, clientDataPtr)
     Tcl_Interp *interp;	/* Interpreter in which package is now
				 * available. */
     CONST char *name;		/* Name of desired package. */
     CONST char *version;	/* Version string for desired version;
				 * NULL means use the latest version
				 * available. */
     int exact;			/* Non-zero means that only the particular
				 * version given is acceptable. Zero means
				 * use the latest compatible version. */
     ClientData *clientDataPtr;	/* Used to return the client data for this
				 * package. If it is NULL then the client
				 * data is not returned. This is unchanged
				 * if this call fails for any reason. */
{
    Interp *iPtr = (Interp *) interp;
    Tcl_HashEntry *hPtr;
    Package *pkgPtr;
    int satisfies, result;

    hPtr = Tcl_FindHashEntry(&iPtr->packageTable, name);
    if (hPtr) {
	pkgPtr = (Package *) Tcl_GetHashValue(hPtr);
	if (pkgPtr->version != NULL) {
#ifdef TCL_TIP268
	    char* pvi;
	    char* vi;
	    int thisIsMajor;
#endif
	    
	    /*
	     * At this point we know that the package is present.  Make sure
	     * that the provided version meets the current requirement.
	     */

	    if (version == NULL) {
		if (clientDataPtr) {
		    *clientDataPtr = pkgPtr->clientData;
		}
		
		return pkgPtr->version;
	    }
#ifndef TCL_TIP268
	    result = ComparePkgVersions(pkgPtr->version, version, &satisfies);
#else
	    if (CheckVersionAndConvert (interp, pkgPtr->version, &pvi, NULL) != TCL_OK) {
		return NULL;
	    } else if (CheckVersionAndConvert (interp, version, &vi, NULL) != TCL_OK) {
		Tcl_Free (pvi);
		return NULL;
	    }
	    result = CompareVersions(pvi, vi, &thisIsMajor);
	    Tcl_Free (pvi);
	    Tcl_Free (vi);
	    satisfies = (result == 0) || ((result == 1) && !thisIsMajor);
#endif
	    if ((satisfies && !exact) || (result == 0)) {
		if (clientDataPtr) {
		    *clientDataPtr = pkgPtr->clientData;
		}
    
		return pkgPtr->version;
	    }
	    Tcl_AppendResult(interp, "version conflict for package \"",
			     name, "\": have ", pkgPtr->version,
			     ", need ", version, (char *) NULL);
	    return NULL;
	}
    }

    if (version != NULL) {
	Tcl_AppendResult(interp, "package ", name, " ", version,
			 " is not present", (char *) NULL);
    } else {
	Tcl_AppendResult(interp, "package ", name, " is not present",
			 (char *) NULL);
    }
    return NULL;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_PackageObjCmd --
 *
 *	This procedure is invoked to process the "package" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

/* ARGSUSED */
int
Tcl_PackageObjCmd(dummy, interp, objc, objv)
     ClientData dummy;		/* Not used. */
     Tcl_Interp *interp;	/* Current interpreter. */
     int objc;			/* Number of arguments. */
     Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    static CONST char *pkgOptions[] = {
	"forget", "ifneeded", "names",
#ifdef TCL_TIP268
	"prefer",
#endif
	"present", "provide", "require", "unknown", "vcompare",
	"versions", "vsatisfies", (char *) NULL
    };
    enum pkgOptions {
	PKG_FORGET, PKG_IFNEEDED, PKG_NAMES,
#ifdef TCL_TIP268
	PKG_PREFER,
#endif
	PKG_PRESENT, PKG_PROVIDE, PKG_REQUIRE, PKG_UNKNOWN, PKG_VCOMPARE,
	PKG_VERSIONS, PKG_VSATISFIES
    };
    Interp *iPtr = (Interp *) interp;
    int optionIndex, exact, i, satisfies;
    PkgAvail *availPtr, *prevPtr;
    Package *pkgPtr;
    Tcl_HashEntry *hPtr;
    Tcl_HashSearch search;
    Tcl_HashTable *tablePtr;
    CONST char *version;
    char *argv2, *argv3, *argv4;
#ifdef TCL_TIP268
    char* iva = NULL;
    char* ivb = NULL;
#endif

    if (objc < 2) {
        Tcl_WrongNumArgs(interp, 1, objv, "option ?arg arg ...?");
	return TCL_ERROR;
    }

    if (Tcl_GetIndexFromObj(interp, objv[1], pkgOptions, "option", 0,
			    &optionIndex) != TCL_OK) {
	return TCL_ERROR;
    }
    switch ((enum pkgOptions) optionIndex) {
#ifndef TCL_TIP268
	case PKG_FORGET: {
	    char *keyString;
	    for (i = 2; i < objc; i++) {
		keyString = Tcl_GetString(objv[i]);
		hPtr = Tcl_FindHashEntry(&iPtr->packageTable, keyString);
		if (hPtr == NULL) {
		    continue;	
		}
		pkgPtr = (Package *) Tcl_GetHashValue(hPtr);
		Tcl_DeleteHashEntry(hPtr);
		if (pkgPtr->version != NULL) {
		    ckfree(pkgPtr->version);
		}
		while (pkgPtr->availPtr != NULL) {
		    availPtr = pkgPtr->availPtr;
		    pkgPtr->availPtr = availPtr->nextPtr;
		    Tcl_EventuallyFree((ClientData)availPtr->version, TCL_DYNAMIC);
		    Tcl_EventuallyFree((ClientData)availPtr->script, TCL_DYNAMIC);
		    ckfree((char *) availPtr);
		}
		ckfree((char *) pkgPtr);
	    }
	    break;
#else
    case PKG_FORGET: {
	char *keyString;
	for (i = 2; i < objc; i++) {
	    keyString = Tcl_GetString(objv[i]);
	    hPtr = Tcl_FindHashEntry(&iPtr->packageTable, keyString);
	    if (hPtr == NULL) {
		continue;	
	    }
	    pkgPtr = (Package *) Tcl_GetHashValue(hPtr);
	    Tcl_DeleteHashEntry(hPtr);
	    if (pkgPtr->version != NULL) {
		ckfree(pkgPtr->version);
	    }
	    while (pkgPtr->availPtr != NULL) {
		availPtr = pkgPtr->availPtr;
		pkgPtr->availPtr = availPtr->nextPtr;
		Tcl_EventuallyFree((ClientData)availPtr->version, TCL_DYNAMIC);
		Tcl_EventuallyFree((ClientData)availPtr->script, TCL_DYNAMIC);
		ckfree((char *) availPtr);
	    }
	    ckfree((char *) pkgPtr);
	}
	break;
    }
    case PKG_IFNEEDED: {
	int length;
	char* argv3i;
	char* avi;
	int res;

	if ((objc != 4) && (objc != 5)) {
	    Tcl_WrongNumArgs(interp, 2, objv, "package version ?script?");
	    return TCL_ERROR;
	}
	argv3 = Tcl_GetString(objv[3]);
	if (CheckVersionAndConvert(interp, argv3, &argv3i, NULL) != TCL_OK) {
	    return TCL_ERROR;
#endif
	}
#ifndef TCL_TIP268
	case PKG_IFNEEDED: {
	    int length;
	    if ((objc != 4) && (objc != 5)) {
		Tcl_WrongNumArgs(interp, 2, objv, "package version ?script?");
		return TCL_ERROR;
#else
	argv2 = Tcl_GetString(objv[2]);
	if (objc == 4) {
	    hPtr = Tcl_FindHashEntry(&iPtr->packageTable, argv2);
	    if (hPtr == NULL) {
		Tcl_Free (argv3i);
		return TCL_OK;
#endif
	    }
#ifndef TCL_TIP268
	    argv3 = Tcl_GetString(objv[3]);
	    if (CheckVersion(interp, argv3) != TCL_OK) {
#else
	    pkgPtr = (Package *) Tcl_GetHashValue(hPtr);
	} else {
	    pkgPtr = FindPackage(interp, argv2);
	}
	argv3 = Tcl_GetStringFromObj(objv[3], &length);

	for (availPtr = pkgPtr->availPtr, prevPtr = NULL;
	     availPtr != NULL;
	     prevPtr = availPtr, availPtr = availPtr->nextPtr) {

	    if (CheckVersionAndConvert (interp, availPtr->version, &avi, NULL) != TCL_OK) {
		Tcl_Free (argv3i);
#endif
		return TCL_ERROR;
	    }
#ifndef TCL_TIP268
	    argv2 = Tcl_GetString(objv[2]);
	    if (objc == 4) {
		hPtr = Tcl_FindHashEntry(&iPtr->packageTable, argv2);
		if (hPtr == NULL) {
#else

	    res = CompareVersions(avi, argv3i, NULL);
	    Tcl_Free (avi);

	    if (res == 0){
		if (objc == 4) {
		    Tcl_Free (argv3i);
		    Tcl_SetResult(interp, availPtr->script, TCL_VOLATILE);
#endif
		    return TCL_OK;
		}
#ifndef TCL_TIP268
		pkgPtr = (Package *) Tcl_GetHashValue(hPtr);
	    } else {
		pkgPtr = FindPackage(interp, argv2);
	    }
	    argv3 = Tcl_GetStringFromObj(objv[3], &length);
	    for (availPtr = pkgPtr->availPtr, prevPtr = NULL; availPtr != NULL;
		 prevPtr = availPtr, availPtr = availPtr->nextPtr) {
		if (ComparePkgVersions(availPtr->version, argv3, (int *) NULL)
			== 0) {
		    if (objc == 4) {
			Tcl_SetResult(interp, availPtr->script, TCL_VOLATILE);
			return TCL_OK;
		    }
		    Tcl_EventuallyFree((ClientData)availPtr->script, TCL_DYNAMIC);
		    break;
		}
	    }
	    if (objc == 4) {
		return TCL_OK;
#else
		Tcl_EventuallyFree((ClientData)availPtr->script, TCL_DYNAMIC);
		break;
#endif
	    }
#ifndef TCL_TIP268
	    if (availPtr == NULL) {
		availPtr = (PkgAvail *) ckalloc(sizeof(PkgAvail));
		availPtr->version = ckalloc((unsigned) (length + 1));
		strcpy(availPtr->version, argv3);
		if (prevPtr == NULL) {
		    availPtr->nextPtr = pkgPtr->availPtr;
		    pkgPtr->availPtr = availPtr;
		} else {
		    availPtr->nextPtr = prevPtr->nextPtr;
		    prevPtr->nextPtr = availPtr;
		}
#else
	}
	Tcl_Free (argv3i);
	if (objc == 4) {
	    return TCL_OK;
	}
	if (availPtr == NULL) {
	    availPtr = (PkgAvail *) ckalloc(sizeof(PkgAvail));
	    availPtr->version = ckalloc((unsigned) (length + 1));
	    strcpy(availPtr->version, argv3);
	    if (prevPtr == NULL) {
		availPtr->nextPtr = pkgPtr->availPtr;
		pkgPtr->availPtr = availPtr;
	    } else {
		availPtr->nextPtr = prevPtr->nextPtr;
		prevPtr->nextPtr = availPtr;
#endif
	    }
#ifndef TCL_TIP268
	    argv4 = Tcl_GetStringFromObj(objv[4], &length);
	    availPtr->script = ckalloc((unsigned) (length + 1));
	    strcpy(availPtr->script, argv4);
	    break;
#endif
	}
#ifndef TCL_TIP268
	case PKG_NAMES: {
	    if (objc != 2) {
		Tcl_WrongNumArgs(interp, 2, objv, NULL);
#else
	argv4 = Tcl_GetStringFromObj(objv[4], &length);
	availPtr->script = ckalloc((unsigned) (length + 1));
	strcpy(availPtr->script, argv4);
	break;
    }
    case PKG_NAMES: {
	if (objc != 2) {
	    Tcl_WrongNumArgs(interp, 2, objv, NULL);
	    return TCL_ERROR;
	}
	tablePtr = &iPtr->packageTable;
	for (hPtr = Tcl_FirstHashEntry(tablePtr, &search); hPtr != NULL;
	     hPtr = Tcl_NextHashEntry(&search)) {
	    pkgPtr = (Package *) Tcl_GetHashValue(hPtr);
	    if ((pkgPtr->version != NULL) || (pkgPtr->availPtr != NULL)) {
		Tcl_AppendElement(interp, Tcl_GetHashKey(tablePtr, hPtr));
	    }
	}
	break;
    }
    case PKG_PRESENT: {
	if (objc < 3) {
	presentSyntax:
	    Tcl_WrongNumArgs(interp, 2, objv, "?-exact? package ?version?");
	    return TCL_ERROR;
	}
	argv2 = Tcl_GetString(objv[2]);
	if ((argv2[0] == '-') && (strcmp(argv2, "-exact") == 0)) {
	    exact = 1;
	} else {
	    exact = 0;
	}
	version = NULL;
	if (objc == (4 + exact)) {
	    version =  Tcl_GetString(objv[3 + exact]);
	    if (CheckVersionAndConvert(interp, version, NULL, NULL) != TCL_OK) {
#endif
		return TCL_ERROR;
	    }
#ifndef TCL_TIP268
	    tablePtr = &iPtr->packageTable;
	    for (hPtr = Tcl_FirstHashEntry(tablePtr, &search); hPtr != NULL;
		 hPtr = Tcl_NextHashEntry(&search)) {
#else
	} else if ((objc != 3) || exact) {
	    goto presentSyntax;
	}
	if (exact) {
	    argv3   = Tcl_GetString(objv[3]);
	    version = Tcl_PkgPresent(interp, argv3, version, exact);
	} else {
	    version = Tcl_PkgPresent(interp, argv2, version, exact);
	}
	if (version == NULL) {
	    return TCL_ERROR;
	}
	Tcl_SetObjResult( interp, Tcl_NewStringObj( version, -1 ) );
	break;
    }
    case PKG_PROVIDE: {
	if ((objc != 3) && (objc != 4)) {
	    Tcl_WrongNumArgs(interp, 2, objv, "package ?version?");
	    return TCL_ERROR;
	}
	argv2 = Tcl_GetString(objv[2]);
	if (objc == 3) {
	    hPtr = Tcl_FindHashEntry(&iPtr->packageTable, argv2);
	    if (hPtr != NULL) {
#endif
		pkgPtr = (Package *) Tcl_GetHashValue(hPtr);
#ifndef TCL_TIP268
		if ((pkgPtr->version != NULL) || (pkgPtr->availPtr != NULL)) {
		    Tcl_AppendElement(interp, Tcl_GetHashKey(tablePtr, hPtr));
#else
		if (pkgPtr->version != NULL) {
		    Tcl_SetResult(interp, pkgPtr->version, TCL_VOLATILE);
#endif
		}
	    }
#ifndef TCL_TIP268
	    break;
#else
	    return TCL_OK;
#endif
	}
#ifndef TCL_TIP268
	case PKG_PRESENT: {
	    if (objc < 3) {
		presentSyntax:
		Tcl_WrongNumArgs(interp, 2, objv, "?-exact? package ?version?");
		return TCL_ERROR;
#else
	argv3 = Tcl_GetString(objv[3]);
	if (CheckVersionAndConvert(interp, argv3, NULL, NULL) != TCL_OK) {
	    return TCL_ERROR;
	}
	return Tcl_PkgProvide(interp, argv2, argv3);
    }
    case PKG_REQUIRE: {
	if (objc < 3) {
	requireSyntax:
	    Tcl_WrongNumArgs(interp, 2, objv, "?-exact? package ?requirement...?");
	    return TCL_ERROR;
	}
	version = NULL;
	argv2   = Tcl_GetString(objv[2]);
	if ((argv2[0] == '-') && (strcmp(argv2, "-exact") == 0)) {
	    Tcl_Obj* ov;
	    int res;

	    if (objc != 5) {
		goto requireSyntax;
#endif
	    }
#ifndef TCL_TIP268
	    argv2 = Tcl_GetString(objv[2]);
	    if ((argv2[0] == '-') && (strcmp(argv2, "-exact") == 0)) {
		exact = 1;
	    } else {
		exact = 0;
#else
	    version = Tcl_GetString(objv[4]);
	    if (CheckVersionAndConvert(interp, version, NULL, NULL) != TCL_OK) {
		return TCL_ERROR;
#endif
	    }
#ifdef TCL_TIP268
	    /* Create a new-style requirement for the exact version. */

	    ov      = ExactRequirement (version);
#endif
	    version = NULL;
#ifndef TCL_TIP268
	    if (objc == (4 + exact)) {
		version =  Tcl_GetString(objv[3 + exact]);
		if (CheckVersion(interp, version) != TCL_OK) {
		    return TCL_ERROR;
		}
	    } else if ((objc != 3) || exact) {
		goto presentSyntax;
	    }
	    if (exact) {
		argv3 =  Tcl_GetString(objv[3]);
		version = Tcl_PkgPresent(interp, argv3, version, exact);
	    } else {
		version = Tcl_PkgPresent(interp, argv2, version, exact);
	    }
	    if (version == NULL) {
#else
	    argv3   = Tcl_GetString(objv[3]);

	    Tcl_IncrRefCount (ov);
	    res = Tcl_PkgRequireProc(interp, argv3, 1, &ov, NULL);
	    Tcl_DecrRefCount (ov);
	    return res;
	} else {
	    if (CheckAllRequirements (interp, objc-3, objv+3) != TCL_OK) {
#endif
		return TCL_ERROR;
	    }
#ifndef TCL_TIP268
	    Tcl_SetObjResult( interp, Tcl_NewStringObj( version, -1 ) );
	    break;
#else
	    return Tcl_PkgRequireProc(interp, argv2, objc-3, objv+3, NULL);
#endif
	}
#ifndef TCL_TIP268
	case PKG_PROVIDE: {
	    if ((objc != 3) && (objc != 4)) {
		Tcl_WrongNumArgs(interp, 2, objv, "package ?version?");
#else
	break;
    }
    case PKG_UNKNOWN: {
	int length;
	if (objc == 2) {
	    if (iPtr->packageUnknown != NULL) {
		Tcl_SetResult(interp, iPtr->packageUnknown, TCL_VOLATILE);
	    }
	} else if (objc == 3) {
	    if (iPtr->packageUnknown != NULL) {
		ckfree(iPtr->packageUnknown);
	    }
	    argv2 = Tcl_GetStringFromObj(objv[2], &length);
	    if (argv2[0] == 0) {
		iPtr->packageUnknown = NULL;
	    } else {
		iPtr->packageUnknown = (char *) ckalloc((unsigned)
							(length + 1));
		strcpy(iPtr->packageUnknown, argv2);
	    }
	} else {
	    Tcl_WrongNumArgs(interp, 2, objv, "?command?");
	    return TCL_ERROR;
	}
	break;
    }
    case PKG_PREFER: {
	/* See tclInt.h for the enum, just before Interp */
	static CONST char *pkgPreferOptions[] = {
	    "latest", "stable", NULL
	};

	if (objc > 3) {
	    Tcl_WrongNumArgs(interp, 2, objv, "?latest|stable?");
	    return TCL_ERROR;
	} else if (objc == 3) {
	    /* Set value. */
	    int new;
	    if (Tcl_GetIndexFromObj(interp, objv[2], pkgPreferOptions, "preference", 0,
				    &new) != TCL_OK) {
#endif
		return TCL_ERROR;
	    }
#ifndef TCL_TIP268
	    argv2 = Tcl_GetString(objv[2]);
	    if (objc == 3) {
		hPtr = Tcl_FindHashEntry(&iPtr->packageTable, argv2);
		if (hPtr != NULL) {
		    pkgPtr = (Package *) Tcl_GetHashValue(hPtr);
		    if (pkgPtr->version != NULL) {
			Tcl_SetResult(interp, pkgPtr->version, TCL_VOLATILE);
		    }
		}
		return TCL_OK;
#else
	    if (new < iPtr->packagePrefer) {
		iPtr->packagePrefer = new;
#endif
	    }
#ifndef TCL_TIP268
	    argv3 = Tcl_GetString(objv[3]);
	    if (CheckVersion(interp, argv3) != TCL_OK) {
		return TCL_ERROR;
	    }
	    return Tcl_PkgProvide(interp, argv2, argv3);
#endif
	}
#ifndef TCL_TIP268
	case PKG_REQUIRE: {
	    if (objc < 3) {
		requireSyntax:
		Tcl_WrongNumArgs(interp, 2, objv, "?-exact? package ?version?");
		return TCL_ERROR;
	    }
	    argv2 = Tcl_GetString(objv[2]);
	    if ((argv2[0] == '-') && (strcmp(argv2, "-exact") == 0)) {
		exact = 1;
	    } else {
		exact = 0;
	    }
	    version = NULL;
	    if (objc == (4 + exact)) {
		version =  Tcl_GetString(objv[3 + exact]);
		if (CheckVersion(interp, version) != TCL_OK) {
		    return TCL_ERROR;
		}
	    } else if ((objc != 3) || exact) {
		goto requireSyntax;
	    }
	    if (exact) {
		argv3 =  Tcl_GetString(objv[3]);
		version = Tcl_PkgRequire(interp, argv3, version, exact);
	    } else {
		version = Tcl_PkgRequire(interp, argv2, version, exact);
	    }
	    if (version == NULL) {
		return TCL_ERROR;
	    }
	    Tcl_SetObjResult( interp, Tcl_NewStringObj( version, -1 ) );
	    break;
#else
	/* Always return current value. */
	Tcl_SetObjResult(interp, Tcl_NewStringObj (pkgPreferOptions [iPtr->packagePrefer], -1));
	break;
    }
    case PKG_VCOMPARE: {
	if (objc != 4) {
	    Tcl_WrongNumArgs(interp, 2, objv, "version1 version2");
	    return TCL_ERROR;
#endif
	}
#ifndef TCL_TIP268
	case PKG_UNKNOWN: {
	    int length;
	    if (objc == 2) {
		if (iPtr->packageUnknown != NULL) {
		    Tcl_SetResult(interp, iPtr->packageUnknown, TCL_VOLATILE);
		}
	    } else if (objc == 3) {
		if (iPtr->packageUnknown != NULL) {
		    ckfree(iPtr->packageUnknown);
		}
		argv2 = Tcl_GetStringFromObj(objv[2], &length);
		if (argv2[0] == 0) {
		    iPtr->packageUnknown = NULL;
		} else {
		    iPtr->packageUnknown = (char *) ckalloc((unsigned)
			    (length + 1));
		    strcpy(iPtr->packageUnknown, argv2);
		}
	    } else {
		Tcl_WrongNumArgs(interp, 2, objv, "?command?");
		return TCL_ERROR;
	    }
	    break;
#else
	argv3 = Tcl_GetString(objv[3]);
	argv2 = Tcl_GetString(objv[2]);
	if ((CheckVersionAndConvert (interp, argv2, &iva, NULL) != TCL_OK) ||
	    (CheckVersionAndConvert (interp, argv3, &ivb, NULL) != TCL_OK)) {
	    if (iva != NULL) { Tcl_Free (iva); }
	    /* ivb cannot be set in this branch */
	    return TCL_ERROR;
#endif
	}
#ifndef TCL_TIP268
	case PKG_VCOMPARE: {
	    if (objc != 4) {
		Tcl_WrongNumArgs(interp, 2, objv, "version1 version2");
		return TCL_ERROR;
	    }
	    argv3 = Tcl_GetString(objv[3]);
	    argv2 = Tcl_GetString(objv[2]);
	    if ((CheckVersion(interp, argv2) != TCL_OK)
		    || (CheckVersion(interp, argv3) != TCL_OK)) {
		return TCL_ERROR;
	    }
	    Tcl_SetIntObj(Tcl_GetObjResult(interp),
		    ComparePkgVersions(argv2, argv3, (int *) NULL));
	    break;
#else

	/* Comparison is done on the internal representation */
	Tcl_SetObjResult(interp,Tcl_NewIntObj(CompareVersions(iva, ivb, NULL)));
	Tcl_Free (iva);
	Tcl_Free (ivb);
	break;
    }
    case PKG_VERSIONS: {
	if (objc != 3) {
	    Tcl_WrongNumArgs(interp, 2, objv, "package");
	    return TCL_ERROR;
#endif
	}
#ifndef TCL_TIP268
	case PKG_VERSIONS: {
	    if (objc != 3) {
		Tcl_WrongNumArgs(interp, 2, objv, "package");
		return TCL_ERROR;
#else
	argv2 = Tcl_GetString(objv[2]);
	hPtr = Tcl_FindHashEntry(&iPtr->packageTable, argv2);
	if (hPtr != NULL) {
	    pkgPtr = (Package *) Tcl_GetHashValue(hPtr);
	    for (availPtr = pkgPtr->availPtr; availPtr != NULL;
		 availPtr = availPtr->nextPtr) {
		Tcl_AppendElement(interp, availPtr->version);
#endif
	    }
#ifndef TCL_TIP268
	    argv2 = Tcl_GetString(objv[2]);
	    hPtr = Tcl_FindHashEntry(&iPtr->packageTable, argv2);
	    if (hPtr != NULL) {
		pkgPtr = (Package *) Tcl_GetHashValue(hPtr);
		for (availPtr = pkgPtr->availPtr; availPtr != NULL;
		     availPtr = availPtr->nextPtr) {
		    Tcl_AppendElement(interp, availPtr->version);
		}
	    }
	    break;
#endif
	}
#ifndef TCL_TIP268
	case PKG_VSATISFIES: {
	    if (objc != 4) {
		Tcl_WrongNumArgs(interp, 2, objv, "version1 version2");
		return TCL_ERROR;
	    }
	    argv3 = Tcl_GetString(objv[3]);
	    argv2 = Tcl_GetString(objv[2]);
	    if ((CheckVersion(interp, argv2) != TCL_OK)
		    || (CheckVersion(interp, argv3) != TCL_OK)) {
		return TCL_ERROR;
	    }
	    ComparePkgVersions(argv2, argv3, &satisfies);
	    Tcl_SetIntObj(Tcl_GetObjResult(interp), satisfies);
	    break;
#else
	break;
    }
    case PKG_VSATISFIES: {
	char* argv2i = NULL;

	if (objc < 4) {
	    Tcl_WrongNumArgs(interp, 2, objv, "version requirement requirement...");
	    return TCL_ERROR;
#endif
	}
#ifndef TCL_TIP268
	default: {
	    panic("Tcl_PackageObjCmd: bad option index to pkgOptions");
#else

	argv2 = Tcl_GetString(objv[2]);
	if ((CheckVersionAndConvert(interp, argv2, &argv2i, NULL) != TCL_OK)) {
	    return TCL_ERROR;
	} else if (CheckAllRequirements (interp, objc-3, objv+3) != TCL_OK) {
	    Tcl_Free (argv2i);
	    return TCL_ERROR;
#endif
	}
#ifdef TCL_TIP268

	satisfies = AllRequirementsSatisfied (argv2i, objc-3, objv+3);
	Tcl_Free (argv2i);

	Tcl_SetIntObj(Tcl_GetObjResult(interp), satisfies);
	break;
    }
    default: {
	panic("Tcl_PackageObjCmd: bad option index to pkgOptions");
    }
#endif
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * FindPackage --
 *
 *	This procedure finds the Package record for a particular package
 *	in a particular interpreter, creating a record if one doesn't
 *	already exist.
 *
 * Results:
 *	The return value is a pointer to the Package record for the
 *	package.
 *
 * Side effects:
 *	A new Package record may be created.
 *
 *----------------------------------------------------------------------
 */

static Package *
FindPackage(interp, name)
     Tcl_Interp *interp;	/* Interpreter to use for package lookup. */
     CONST char *name;		/* Name of package to fine. */
{
    Interp *iPtr = (Interp *) interp;
    Tcl_HashEntry *hPtr;
    int new;
    Package *pkgPtr;

    hPtr = Tcl_CreateHashEntry(&iPtr->packageTable, name, &new);
    if (new) {
	pkgPtr = (Package *) ckalloc(sizeof(Package));
	pkgPtr->version = NULL;
	pkgPtr->availPtr = NULL;
	pkgPtr->clientData = NULL;
	Tcl_SetHashValue(hPtr, pkgPtr);
    } else {
	pkgPtr = (Package *) Tcl_GetHashValue(hPtr);
    }
    return pkgPtr;
}

/*
 *----------------------------------------------------------------------
 *
 * TclFreePackageInfo --
 *
 *	This procedure is called during interpreter deletion to
 *	free all of the package-related information for the
 *	interpreter.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Memory is freed.
 *
 *----------------------------------------------------------------------
 */

void
TclFreePackageInfo(iPtr)
     Interp *iPtr;	/* Interpreter that is being deleted. */
{
    Package *pkgPtr;
    Tcl_HashSearch search;
    Tcl_HashEntry *hPtr;
    PkgAvail *availPtr;

    for (hPtr = Tcl_FirstHashEntry(&iPtr->packageTable, &search);
	 hPtr != NULL;  hPtr = Tcl_NextHashEntry(&search)) {
	pkgPtr = (Package *) Tcl_GetHashValue(hPtr);
	if (pkgPtr->version != NULL) {
	    ckfree(pkgPtr->version);
	}
	while (pkgPtr->availPtr != NULL) {
	    availPtr = pkgPtr->availPtr;
	    pkgPtr->availPtr = availPtr->nextPtr;
	    Tcl_EventuallyFree((ClientData)availPtr->version, TCL_DYNAMIC);
	    Tcl_EventuallyFree((ClientData)availPtr->script, TCL_DYNAMIC);
	    ckfree((char *) availPtr);
	}
	ckfree((char *) pkgPtr);
    }
    Tcl_DeleteHashTable(&iPtr->packageTable);
    if (iPtr->packageUnknown != NULL) {
	ckfree(iPtr->packageUnknown);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * CheckVersion / CheckVersionAndConvert --
 *
 *	This procedure checks to see whether a version number has
 *	valid syntax.
 *
 * Results:
 *	If string is a properly formed version number the TCL_OK
 *	is returned.  Otherwise TCL_ERROR is returned and an error
 *	message is left in the interp's result.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static int
#ifndef TCL_TIP268
CheckVersion(interp, string)
    Tcl_Interp *interp;		/* Used for error reporting. */
    CONST char *string;		/* Supposedly a version number, which is
				 * groups of decimal digits separated
				 * by dots. */
#else
CheckVersionAndConvert(interp, string, internal, stable)
     Tcl_Interp *interp;	/* Used for error reporting. */
     CONST char *string;	/* Supposedly a version number, which is
				 * groups of decimal digits separated by
				 * dots. */
     char** internal;    /* Internal normalized representation */
     int*   stable;      /* Flag: Version is (un)stable. */
#endif
{
    CONST char *p = string;
    char prevChar;
#ifdef TCL_TIP268
    int hasunstable = 0;
    /* 4* assuming that each char is a separator (a,b become ' -x ').
     * 4+ to have spce for an additional -2 at the end
     */
    char* ibuf = Tcl_Alloc (4+4*strlen(string));
    char* ip   = ibuf;

    /* Basic rules
     * (1) First character has to be a digit.
     * (2) All other characters have to be a digit or '.'
     * (3) Two '.'s may not follow each other.

     * TIP 268, Modified rules
     * (1) s.a.
     * (2) All other characters have to be a digit, 'a', 'b', or '.'
     * (3) s.a.
     * (4) Only one of 'a' or 'b' may occur.
     * (5) Neither 'a', nor 'b' may occur before or after a '.'
     */

#endif
    if (!isdigit(UCHAR(*p))) {	/* INTL: digit */
	goto error;
    }
#ifdef TCL_TIP268
    *ip++ = *p;
#endif
    for (prevChar = *p, p++; *p != 0; p++) {
#ifndef TCL_TIP268
	if (!isdigit(UCHAR(*p)) &&
		((*p != '.') || (prevChar == '.'))) { /* INTL: digit */
#else
	if (
	    (!isdigit(UCHAR(*p))) &&
	    (((*p != '.') && (*p != 'a') && (*p != 'b')) ||
	     ((hasunstable && ((*p == 'a') || (*p == 'b'))) ||
	      (((prevChar == 'a') || (prevChar == 'b') || (prevChar == '.')) && (*p       == '.')) ||
	      (((*p       == 'a') || (*p       == 'b') || (*p       == '.')) && (prevChar == '.'))))
	    ) {
	    /* INTL: digit */
#endif
	    goto error;
	}
#ifdef TCL_TIP268
	if ((*p == 'a') || (*p == 'b')) { hasunstable = 1 ; }

	/* Translation to the internal rep. Regular version chars are copied
	 * as is. The separators are translated to numerics. The new separator
	 * for all parts is space. */

	if      (*p == '.') { *ip++ = ' ';              *ip++ = '0'; *ip++ = ' '; }
	else if (*p == 'a') { *ip++ = ' '; *ip++ = '-'; *ip++ = '2'; *ip++ = ' '; }
	else if (*p == 'b') { *ip++ = ' '; *ip++ = '-'; *ip++ = '1'; *ip++ = ' '; }
	else                { *ip++ = *p; }
#endif
	prevChar = *p;
    }
#ifndef TCL_TIP268
    if (prevChar != '.') {
#else
    if ((prevChar != '.') && (prevChar != 'a') && (prevChar != 'b')) {
	*ip = '\0';
	if (internal != NULL) {
	    *internal = ibuf;
	} else {
	    Tcl_Free (ibuf);
	}
	if (stable != NULL) {
	    *stable = !hasunstable;
	}
#endif
	return TCL_OK;
    }

 error:
#ifdef TCL_TIP268
    Tcl_Free (ibuf);
#endif
    Tcl_AppendResult(interp, "expected version number but got \"",
	    string, "\"", (char *) NULL);
    return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * ComparePkgVersions / CompareVersions --
 *
 *	This procedure compares two version numbers. (268: in internal rep).
 *
 * Results:
 *	The return value is -1 if v1 is less than v2, 0 if the two
 *	version numbers are the same, and 1 if v1 is greater than v2.
 *	If *satPtr is non-NULL, the word it points to is filled in
 *	with 1 if v2 >= v1 and both numbers have the same major number
 *	or 0 otherwise.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static int
#ifndef TCL_TIP268
ComparePkgVersions(v1, v2, satPtr)
    CONST char *v1;
    CONST char *v2;		/* Versions strings, of form 2.1.3 (any
				 * number of version numbers). */
    int *satPtr;		/* If non-null, the word pointed to is
				 * filled in with a 0/1 value.  1 means
				 * v1 "satisfies" v2:  v1 is greater than
				 * or equal to v2 and both version numbers
				 * have the same major number. */
#else
CompareVersions(v1, v2, isMajorPtr)
     CONST char *v1;	/* Versions strings, of form 2.1.3 (any number */
     CONST char *v2;	/* of version numbers). */
     int *isMajorPtr;   /* If non-null, the word pointed to is filled
			 * in with a 0/1 value. 1 means that the difference
			 * occured in the first element. */
#endif
{
    int thisIsMajor, n1, n2;
#ifdef TCL_TIP268
    int res, flip;
#endif

    /*
     * Each iteration of the following loop processes one number from each
     * string, terminated by a " " (space). If those numbers don't match then the
     * comparison is over; otherwise, we loop back for the next number.
     *
     * TIP 268.
     * This is identical the function 'ComparePkgVersion', but using the new
     * space separator as used by the internal rep of version numbers. The
     * special separators 'a' and 'b' have already been dealt with in
     * 'CheckVersionAndConvert', they were translated into numbers as
     * well. This keeps the comparison sane. Otherwise we would have to
     * compare numerics, the separators, and also deal with the special case
     * of end-of-string compared to separators. The semi-list rep we get here
     * is much easier to handle, as it is still regular.
     */

    thisIsMajor = 1;
    while (1) {
	/*
	 * Parse one decimal number from the front of each string.
	 */

	n1 = n2 = 0;
#ifndef TCL_TIP268
	while ((*v1 != 0) && (*v1 != '.')) {
#else
	flip = 0;
	while ((*v1 != 0) && (*v1 != ' ')) {
	    if (*v1 == '-') {flip = 1 ; v1++ ; continue;}
#endif
	    n1 = 10*n1 + (*v1 - '0');
	    v1++;
	}
#ifndef TCL_TIP268
	while ((*v2 != 0) && (*v2 != '.')) {
#else
	if (flip) n1 = -n1;
	flip = 0;
	while ((*v2 != 0) && (*v2 != ' ')) {
	    if (*v2 == '-') {flip = 1; v2++ ; continue;}
#endif
	    n2 = 10*n2 + (*v2 - '0');
	    v2++;
	}
#ifdef TCL_TIP268
	if (flip) n2 = -n2;
#endif

	/*
	 * Compare and go on to the next version number if the current numbers
	 * match.
	 */

	if (n1 != n2) {
	    break;
	}
	if (*v1 != 0) {
	    v1++;
	} else if (*v2 == 0) {
	    break;
	}
	if (*v2 != 0) {
	    v2++;
	}
	thisIsMajor = 0;
    }
#ifndef TCL_TIP268
    if (satPtr != NULL) {
	*satPtr = (n1 == n2) || ((n1 > n2) && !thisIsMajor);
    }
#endif
    if (n1 > n2) {
#ifndef TCL_TIP268
	return 1;
#else
	res = 1;
#endif
    } else if (n1 == n2) {
#ifndef TCL_TIP268
	return 0;
#else
	res = 0;
#endif
    } else {
#ifndef TCL_TIP268
	return -1;
#else
	res = -1;
    }

    if (isMajorPtr != NULL) {
	*isMajorPtr = thisIsMajor;
    }

    return res;
}

/*
 *----------------------------------------------------------------------
 *
 * CheckAllRequirements --
 *
 *	This function checks to see whether all requirements in a set
 *	have valid syntax.
 *
 * Results:
 *	TCL_OK is returned if all requirements are valid.
 *	Otherwise TCL_ERROR is returned and an error message
 *	is left in the interp's result.
 *
 * Side effects:
 *	May modify the interpreter result.
 *
 *----------------------------------------------------------------------
 */

static int
CheckAllRequirements(interp, reqc, reqv)
     Tcl_Interp* interp;
     int reqc;                   /* Requirements to check. */
     Tcl_Obj *CONST reqv[];
{
    int i;
    for (i = 0; i < reqc; i++) {
	if ((CheckRequirement(interp, Tcl_GetString(reqv[i])) != TCL_OK)) {
	    return TCL_ERROR;
	}
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * CheckRequirement --
 *
 *	This function checks to see whether a requirement has valid syntax.
 *
 * Results:
 *	If string is a properly formed requirement then TCL_OK is returned.
 *	Otherwise TCL_ERROR is returned and an error message is left in the
 *	interp's result.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static int
CheckRequirement(interp, string)
     Tcl_Interp *interp;	/* Used for error reporting. */
     CONST char *string;	/* Supposedly a requirement. */
{
    /* Syntax of requirement = version
     *                       = version-version
     *                       = version-
     */

    char* dash = NULL;
    char* buf;

    dash = strchr (string, '-');
    if (dash == NULL) {
	/* no dash found, has to be a simple version */
	return CheckVersionAndConvert (interp, string, NULL, NULL);
    }
    if (strchr (dash+1, '-') != NULL) {
	/* More dashes found after the first. This is wrong. */
	Tcl_AppendResult(interp, "expected versionMin-versionMax but got \"", string,
			 "\"", NULL);
	return TCL_ERROR;
#endif
    }
#ifdef TCL_TIP268

    /* Exactly one dash is present. Copy the string, split at the location of
     * dash and check that both parts are versions. Note that the max part can
     * be empty.
     */

    buf   = strdup (string);
    dash  = buf + (dash - string);  
    *dash = '\0';     /* buf  now <=> min part */
    dash ++;          /* dash now <=> max part */

    if ((CheckVersionAndConvert(interp, buf, NULL, NULL) != TCL_OK) ||
	((*dash != '\0') &&
	 (CheckVersionAndConvert(interp, dash, NULL, NULL) != TCL_OK))) {
	free (buf);
	return TCL_ERROR;
    }

    free (buf);
    return TCL_OK;
#endif
}
#ifdef TCL_TIP268

/*
 *----------------------------------------------------------------------
 *
 * AddRequirementsToResult --
 *
 *	This function accumulates requirements in the interpreter result.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The interpreter result is extended.
 *
 *----------------------------------------------------------------------
 */

static void
AddRequirementsToResult(interp, reqc, reqv)
     Tcl_Interp* interp;
     int reqc;                   /* Requirements constraining the desired version. */
     Tcl_Obj *CONST reqv[];      /* 0 means to use the latest version available. */
{
    if (reqc > 0) {
	int i;
	for (i = 0; i < reqc; i++) {
	    Tcl_AppendResult(interp, " ", TclGetString(reqv[i]), NULL);
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * AddRequirementsToDString --
 *
 *	This function accumulates requirements in a DString.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The DString argument is extended.
 *
 *----------------------------------------------------------------------
 */

static void
AddRequirementsToDString(dstring, reqc, reqv)
     Tcl_DString* dstring;
     int reqc;                   /* Requirements constraining the desired version. */
     Tcl_Obj *CONST reqv[];      /* 0 means to use the latest version available. */
{
    if (reqc > 0) {
	int i;
	for (i = 0; i < reqc; i++) {
	    Tcl_DStringAppend(dstring, " ", 1);
	    Tcl_DStringAppend(dstring, TclGetString(reqv[i]), -1);
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * AllRequirementSatisfied --
 *
 *	This function checks to see whether a version satisfies at
 *	least one of a set of requirements.
 *
 * Results:
 *	If the requirements are satisfied 1 is returned.
 *	Otherwise 0 is returned. The function assumes
 *	that all pieces have valid syntax. And is allowed
 *	to make that assumption.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static int
AllRequirementsSatisfied(availVersionI, reqc, reqv)
     CONST char* availVersionI;  /* Candidate version to check against the requirements */
     int reqc;                   /* Requirements constraining the desired version. */
     Tcl_Obj *CONST reqv[];      /* 0 means to use the latest version available. */
{
    int i, satisfies;

    for (satisfies = i = 0; i < reqc; i++) {
	satisfies = RequirementSatisfied(availVersionI, Tcl_GetString(reqv[i]));
	if (satisfies) break;
    }
    return satisfies;
}

/*
 *----------------------------------------------------------------------
 *
 * RequirementSatisfied --
 *
 *	This function checks to see whether a version satisfies a requirement.
 *
 * Results:
 *	If the requirement is satisfied 1 is returned.
 *	Otherwise 0 is returned. The function assumes
 *	that all pieces have valid syntax. And is allowed
 *	to make that assumption.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static int
RequirementSatisfied(havei, req)
     CONST char *havei; /* Version string, of candidate package we have */
     CONST char *req;   /* Requirement string the candidate has to satisfy */
{
    /* The have candidate is already in internal rep. */

    int satisfied, res;
    char* dash = NULL;
    char* buf, *min, *max;

    dash = strchr (req, '-');
    if (dash == NULL) {
	/* No dash found, is a simple version, fallback to regular check.
	 * The 'CheckVersionAndConvert' cannot fail. We pad the requirement with
	 * 'a0', i.e '-2' before doing the comparison to properly accept
	 * unstables as well.
	 */

	char* reqi = NULL;
	int thisIsMajor;

	CheckVersionAndConvert (NULL, req, &reqi, NULL);
	strcat (reqi, " -2");
	res       = CompareVersions(havei, reqi, &thisIsMajor);
	satisfied = (res == 0) || ((res == 1) && !thisIsMajor);
	Tcl_Free (reqi);
	return satisfied;
    }

    /* Exactly one dash is present (Assumption of valid syntax). Copy the req,
     * split at the location of dash and check that both parts are
     * versions. Note that the max part can be empty.
     */

    buf   = strdup (req);
    dash  = buf + (dash - req);  
    *dash = '\0';     /* buf  now <=> min part */
    dash ++;          /* dash now <=> max part */

    if (*dash == '\0') {
	/* We have a min, but no max. For the comparison we generate the
	 * internal rep, padded with 'a0' i.e. '-2'.
	 */

	/* No max part, unbound */

	CheckVersionAndConvert (NULL, buf, &min, NULL);
	strcat (min, " -2");
	satisfied = (CompareVersions(havei, min, NULL) >= 0);
	Tcl_Free (min);
	free (buf);
	return satisfied;
    }

    /* We have both min and max, and generate their internal reps.
     * When identical we compare as is, otherwise we pad with 'a0'
     * to ove the range a bit.
     */

    CheckVersionAndConvert (NULL, buf,  &min, NULL);
    CheckVersionAndConvert (NULL, dash, &max, NULL);

    if (CompareVersions(min, max, NULL) == 0) {
	satisfied = (CompareVersions(min, havei, NULL) == 0);
    } else {
	strcat (min, " -2");
	strcat (max, " -2");
	satisfied = ((CompareVersions(min, havei, NULL) <= 0) &&
		     (CompareVersions(havei, max, NULL) < 0));
    }

    Tcl_Free (min);
    Tcl_Free (max);
    free (buf);
    return satisfied;
}

/*
 *----------------------------------------------------------------------
 *
 * ExactRequirement --
 *
 *	This function is the core for the translation of -exact requests.
 *	It translates the request of the version into a range of versions.
 *	The translation was chosen for backwards compatibility.
 *
 * Results:
 *	A Tcl_Obj containing the version range as string.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static Tcl_Obj*
ExactRequirement(version)
     CONST char* version;
{
    /* A -exact request for a version X.y is translated into the range
     * X.y-X.(y+1). For example -exact 8.4 means the range "8.4-8.5".
     *
     * This translation was chosen to prevent packages which currently use a
     * 'package require -exact tclversion' from being affected by the core now
     * registering itself as 8.4.x (patchlevel) instead of 8.4
     * (version). Examples are tbcload, compiler, and ITcl.
     *
     * Translating -exact 8.4 to the range "8.4-8.4" instead would require us
     * and everyone else to rebuild these packages to require -exact 8.4.14,
     * or whatever the exact current patchlevel is. A backward compatibility
     * issue with effects similar to the bugfix made in 8.5 now requiring
     * ifneeded and provided versions to match. Instead we have chosen to
     * interpret exactness to not be exactly equal, but to be exact only
     * within the specified level, and allowing variation in the deeper
     * level. More examples:
     *
     * -exact 8      => "8-9"
     * -exact 8.4    => "8.4-8.5"
     * -exact 8.4.14 => "8.4.14-8.4.15"
     * -exact 8.0a2  => "8.0a2-8.0a3"
     */

    char*        iv;
    int          lc, i;
    CONST char** lv;
    char         buf [30];
    Tcl_Obj* o = Tcl_NewStringObj (version,-1);
    Tcl_AppendStringsToObj (o, "-", NULL);

    /* Assuming valid syntax here */
    CheckVersionAndConvert (NULL, version, &iv, NULL);

    /* Split the list into components */
    Tcl_SplitList (NULL, iv, &lc, &lv);

    /* Iterate over the components and make them parts of the result. Except
     * for the last, which is handled separately, to allow the
     * incrementation.
     */

    for (i=0; i < (lc-1); i++) {
	/* Regular component */
	Tcl_AppendStringsToObj (o, lv[i], NULL);
	/* Separator component */
	i ++;
	if (0 == strcmp ("-1", lv[i])) {
	    Tcl_AppendStringsToObj (o, "b", NULL);
	} else if (0 == strcmp ("-2", lv[i])) {
	    Tcl_AppendStringsToObj (o, "a", NULL);
	} else {
	    Tcl_AppendStringsToObj (o, ".", NULL);
	}
    }
    /* Regular component, last */
    sprintf (buf, "%d", atoi (lv [lc-1]) + 1);
    Tcl_AppendStringsToObj (o, buf, NULL);

    ckfree ((char*) lv);
    return o;
}

/*
 *----------------------------------------------------------------------
 *
 * VersionCleanupProc --
 *
 *	This function is called to delete the last remember package version
 *	string for an interpreter when the interpreter is deleted. It gets
 *	invoked via the Tcl AssocData mechanism.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Storage for the version object for interp get deleted.
 *
 *----------------------------------------------------------------------
 */

static void
VersionCleanupProc (
    ClientData clientData,	/* Pointer to remembered version string object
				 * for interp. */
    Tcl_Interp *interp)		/* Interpreter that is being deleted. */
{
    Tcl_Obj* ov = (Tcl_Obj*) clientData;
    if (ov != NULL) {
	Tcl_DecrRefCount (ov);
    }
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif
