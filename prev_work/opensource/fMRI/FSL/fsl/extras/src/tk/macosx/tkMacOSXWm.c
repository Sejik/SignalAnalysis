/* 
 * tkMacOSXWm.c --
 *
 *	This module takes care of the interactions between a Tk-based
 *	application and the window manager.  Among other things, it
 *	implements the "wm" command and passes geometry information
 *	to the window manager.
 *
 * Copyright (c) 1994-1997 Sun Microsystems, Inc.
 * Copyright 2001, Apple Computer, Inc.
 * Copyright (c) 2006 Daniel A. Steffen <das@users.sourceforge.net>
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: tkMacOSXWm.c,v 1.1.1.1 2007/07/10 15:05:18 duncan Exp $
 */

#include "tkMacOSXInt.h"
#include "tkScrollbar.h"
#include "tkMacOSXWm.h"
#include "tkMacOSXEvent.h"

/* Define constants only available on Mac OS X 10.3 or later */
#if MAC_OS_X_VERSION_MAX_ALLOWED < 1030
    #define kSimpleWindowClass 18
    #define kWindowDoesNotCycleAttribute (1L << 15)
#endif
/* Define constants only available on Mac OS X 10.4 or later */
#if MAC_OS_X_VERSION_MAX_ALLOWED < 1040
    #define kWindowNoTitleBarAttribute (1L << 9)
    #define kWindowMetalNoContentSeparatorAttribute (1L << 11)
#endif

/*
 * This is a list of all of the toplevels that have been mapped so far. It is
 * used by the menu code to inval windows that were damaged by menus, and will
 * eventually also be used to keep track of floating windows.
 */

TkMacOSXWindowList *tkMacOSXWindowListPtr = NULL;

/*
 * The variable below is used to enable or disable tracing in this
 * module.  If tracing is enabled, then information is printed on
 * standard output about interesting interactions with the window
 * manager.
 */

static int wmTracing = 0;

/*
 * The following structure is the official type record for geometry
 * management of top-level windows.
 */

static void		TopLevelReqProc _ANSI_ARGS_((ClientData dummy,
	Tk_Window tkwin));

static Tk_GeomMgr wmMgrType = {
    "wm",				/* name */
    TopLevelReqProc,			/* requestProc */
    (Tk_GeomLostSlaveProc *) NULL,	/* lostSlaveProc */
};

/*
 * Hash table for Mac Window -> TkWindow mapping.
 */

static Tcl_HashTable windowTable;
static int windowHashInit = false;

/*
 * Forward declarations for procedures defined in this file:
 */

static void		InitialWindowBounds _ANSI_ARGS_((TkWindow *winPtr, 
			    Rect *geometry));
static int		ParseGeometry _ANSI_ARGS_((Tcl_Interp *interp,
			    char *string, TkWindow *winPtr));
static void		TopLevelEventProc _ANSI_ARGS_((ClientData clientData,
			    XEvent *eventPtr));
static void             WmStackorderToplevelWrapperMap _ANSI_ARGS_((
                            TkWindow *winPtr,
                            Display *display,
                            Tcl_HashTable *table));
static void		TopLevelReqProc _ANSI_ARGS_((ClientData dummy,
			    Tk_Window tkwin));
static void		UpdateGeometryInfo _ANSI_ARGS_((
			    ClientData clientData));
static void		UpdateSizeHints _ANSI_ARGS_((TkWindow *winPtr));
static void		UpdateVRootGeometry _ANSI_ARGS_((WmInfo *wmPtr));
static int 		WmAspectCmd _ANSI_ARGS_((Tk_Window tkwin,
                                      TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                      Tcl_Obj *CONST objv[]));
static int 		WmAttributesCmd _ANSI_ARGS_((Tk_Window tkwin,
                                          TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                          Tcl_Obj *CONST objv[]));
static Tcl_Obj *	WmAttrGetModifiedStatus(WindowRef macWindow);
static Tcl_Obj *	WmAttrGetTitlePath(WindowRef macWindow);
static Tcl_Obj *	WmAttrGetAlpha(WindowRef macWindow);
static int 		WmClientCmd _ANSI_ARGS_((Tk_Window tkwin,
                                      TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                      Tcl_Obj *CONST objv[]));
static int 		WmColormapwindowsCmd _ANSI_ARGS_((Tk_Window tkwin,
                                               TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                               Tcl_Obj *CONST objv[]));
static int 		WmCommandCmd _ANSI_ARGS_((Tk_Window tkwin,
                                       TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                       Tcl_Obj *CONST objv[]));
static int 		WmDeiconifyCmd _ANSI_ARGS_((Tk_Window tkwin,
                                         TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                         Tcl_Obj *CONST objv[]));
static int 		WmFocusmodelCmd _ANSI_ARGS_((Tk_Window tkwin,
                                          TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                          Tcl_Obj *CONST objv[]));
static int 		WmFrameCmd _ANSI_ARGS_((Tk_Window tkwin,
                                     TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                     Tcl_Obj *CONST objv[]));
static int 		WmGeometryCmd _ANSI_ARGS_((Tk_Window tkwin,
                                        TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                        Tcl_Obj *CONST objv[]));
static int 		WmGridCmd _ANSI_ARGS_((Tk_Window tkwin,
                                    TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                    Tcl_Obj *CONST objv[]));
static int 		WmGroupCmd _ANSI_ARGS_((Tk_Window tkwin,
                                     TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                     Tcl_Obj *CONST objv[]));
static int 		WmIconbitmapCmd _ANSI_ARGS_((Tk_Window tkwin,
                                          TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                          Tcl_Obj *CONST objv[]));
static int 		WmIconifyCmd _ANSI_ARGS_((Tk_Window tkwin,
                                       TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                       Tcl_Obj *CONST objv[]));
static int 		WmIconmaskCmd _ANSI_ARGS_((Tk_Window tkwin,
                                        TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                        Tcl_Obj *CONST objv[]));
static int 		WmIconnameCmd _ANSI_ARGS_((Tk_Window tkwin,
                                        TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                        Tcl_Obj *CONST objv[]));
static int 		WmIconphotoCmd _ANSI_ARGS_((Tk_Window tkwin,
			    TkWindow *winPtr, Tcl_Interp *interp, int objc,
			    Tcl_Obj *CONST objv[]));
static int 		WmIconpositionCmd _ANSI_ARGS_((Tk_Window tkwin,
                                            TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                            Tcl_Obj *CONST objv[]));
static int 		WmIconwindowCmd _ANSI_ARGS_((Tk_Window tkwin,
                                          TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                          Tcl_Obj *CONST objv[]));
static int 		WmMaxsizeCmd _ANSI_ARGS_((Tk_Window tkwin,
                                       TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                       Tcl_Obj *CONST objv[]));
static int 		WmMinsizeCmd _ANSI_ARGS_((Tk_Window tkwin,
                                       TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                       Tcl_Obj *CONST objv[]));
static int 		WmOverrideredirectCmd _ANSI_ARGS_((Tk_Window tkwin,
                                                TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                                Tcl_Obj *CONST objv[]));
static int 		WmPositionfromCmd _ANSI_ARGS_((Tk_Window tkwin,
                                            TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                            Tcl_Obj *CONST objv[]));
static int 		WmProtocolCmd _ANSI_ARGS_((Tk_Window tkwin,
                                        TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                        Tcl_Obj *CONST objv[]));
static int 		WmResizableCmd _ANSI_ARGS_((Tk_Window tkwin,
                                         TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                         Tcl_Obj *CONST objv[]));
static int 		WmSizefromCmd _ANSI_ARGS_((Tk_Window tkwin,
                                        TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                        Tcl_Obj *CONST objv[]));
static int 		WmStackorderCmd _ANSI_ARGS_((Tk_Window tkwin,
                                          TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                          Tcl_Obj *CONST objv[]));
static int 		WmStateCmd _ANSI_ARGS_((Tk_Window tkwin,
                                     TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                     Tcl_Obj *CONST objv[]));
static int 		WmTitleCmd _ANSI_ARGS_((Tk_Window tkwin,
                                     TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                     Tcl_Obj *CONST objv[]));
static int 		WmTransientCmd _ANSI_ARGS_((Tk_Window tkwin,
                                         TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                         Tcl_Obj *CONST objv[]));
static int 		WmWithdrawCmd _ANSI_ARGS_((Tk_Window tkwin,
                                        TkWindow *winPtr, Tcl_Interp *interp, int objc,
                                        Tcl_Obj *CONST objv[]));
static void		WmUpdateGeom _ANSI_ARGS_((WmInfo *wmPtr,
                                       TkWindow *winPtr));
static int 		WmWinStyle _ANSI_ARGS_((Tcl_Interp *interp,
				    TkWindow *winPtr, int objc,
				    Tcl_Obj * CONST objv[]));
static void 		ApplyWindowAttributeChanges _ANSI_ARGS_((
				    TkWindow *winPtr, int newAttributes,
				    int oldAttributes, int create));

/*
 *--------------------------------------------------------------
 *
 * TkWmNewWindow --
 *
 *	This procedure is invoked whenever a new top-level
 *	window is created.  Its job is to initialize the WmInfo
 *	structure for the window.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	A WmInfo structure gets allocated and initialized.
 *
 *--------------------------------------------------------------
 */

void
TkWmNewWindow(
    TkWindow *winPtr)		/* Newly-created top-level window. */
{
    WmInfo *wmPtr;

    wmPtr = (WmInfo *) ckalloc(sizeof(WmInfo));
    wmPtr->winPtr = winPtr;
    wmPtr->reparent = None;
    wmPtr->titleUid = NULL;
    wmPtr->iconName = NULL;
    wmPtr->master = None;
    wmPtr->hints.flags = InputHint | StateHint;
    wmPtr->hints.input = True;
    wmPtr->hints.initial_state = NormalState;
    wmPtr->hints.icon_pixmap = None;
    wmPtr->hints.icon_window = None;
    wmPtr->hints.icon_x = wmPtr->hints.icon_y = 0;
    wmPtr->hints.icon_mask = None;
    wmPtr->hints.window_group = None;
    wmPtr->leaderName = NULL;
    wmPtr->masterWindowName = NULL;
    wmPtr->icon = NULL;
    wmPtr->iconFor = NULL;
    wmPtr->sizeHintsFlags = 0;
    wmPtr->minWidth = wmPtr->minHeight = 1;

    /*
     * Default the maximum dimensions to the size of the display, minus
     * a guess about how space is needed for window manager decorations.
     */

    wmPtr->maxWidth = DisplayWidth(winPtr->display, winPtr->screenNum) - 15;
    wmPtr->maxHeight = DisplayHeight(winPtr->display, winPtr->screenNum) - 30;
    wmPtr->gridWin = NULL;
    wmPtr->widthInc = wmPtr->heightInc = 1;
    wmPtr->minAspect.x = wmPtr->minAspect.y = 1;
    wmPtr->maxAspect.x = wmPtr->maxAspect.y = 1;
    wmPtr->reqGridWidth = wmPtr->reqGridHeight = -1;
    wmPtr->gravity = NorthWestGravity;
    wmPtr->width = -1;
    wmPtr->height = -1;
    wmPtr->x = winPtr->changes.x;
    wmPtr->y = winPtr->changes.y;
    wmPtr->parentWidth = winPtr->changes.width
	+ 2*winPtr->changes.border_width;
    wmPtr->parentHeight = winPtr->changes.height
	+ 2*winPtr->changes.border_width;
    wmPtr->xInParent = 0;
    wmPtr->yInParent = 0;
    wmPtr->cmapList = NULL;
    wmPtr->cmapCount = 0;
    wmPtr->configWidth = -1;
    wmPtr->configHeight = -1;
    wmPtr->vRoot = None;
    wmPtr->protPtr = NULL;
    wmPtr->cmdArgv = NULL;
    wmPtr->clientMachine = NULL;
    wmPtr->flags = WM_NEVER_MAPPED;
    wmPtr->style = -1;
    wmPtr->macClass = kDocumentWindowClass;
    wmPtr->attributes = kWindowStandardDocumentAttributes;
    wmPtr->scrollWinPtr = NULL;
    winPtr->wmInfoPtr = wmPtr;

    UpdateVRootGeometry(wmPtr);

    /*
     * Tk must monitor structure events for top-level windows, in order
     * to detect size and position changes caused by window managers.
     */

    Tk_CreateEventHandler((Tk_Window) winPtr, StructureNotifyMask,
	    TopLevelEventProc, (ClientData) winPtr);

    /*
     * Arrange for geometry requests to be reflected from the window
     * to the window manager.
     */

    Tk_ManageGeometry((Tk_Window) winPtr, &wmMgrType, (ClientData) 0);
}

/*
 *--------------------------------------------------------------
 *
 * TkWmMapWindow --
 *
 *	This procedure is invoked to map a top-level window.  This
 *	module gets a chance to update all window-manager-related
 *	information in properties before the window manager sees
 *	the map event and checks the properties.  It also gets to
 *	decide whether or not to even map the window after all.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Properties of winPtr may get updated to provide up-to-date
 *	information to the window manager.  The window may also get
 *	mapped, but it may not be if this procedure decides that
 *	isn't appropriate (e.g. because the window is withdrawn).
 *
 *--------------------------------------------------------------
 */

void
TkWmMapWindow(
    TkWindow *winPtr)		/* Top-level window that's about to
				 * be mapped. */
{
    WmInfo *wmPtr = winPtr->wmInfoPtr;
    Rect widths;

    if (wmPtr->flags & WM_NEVER_MAPPED) {
	wmPtr->flags &= ~WM_NEVER_MAPPED;

	/*
	 * Create the underlying Mac window for this Tk window.
	 */
	if (!TkMacOSXHostToplevelExists(winPtr)) {
	    TkMacOSXMakeRealWindowExist(winPtr);
	}

	/*
	 * Generate configure event when we first map the window.
	 */
	TkGenWMConfigureEvent((Tk_Window) winPtr, wmPtr->x, wmPtr->y, -1, -1,
		TK_LOCATION_CHANGED);

	/*
	 * This is the first time this window has ever been mapped.
	 * Store all the window-manager-related information for the
	 * window.
	 */

	if (wmPtr->titleUid == NULL) {
	    wmPtr->titleUid = winPtr->nameUid;
	}

	if (!Tk_IsEmbedded(winPtr)) {
	    TkSetWMName(winPtr, wmPtr->titleUid);
	}

	TkWmSetClass(winPtr);

	if (wmPtr->iconName != NULL) {
	    XSetIconName(winPtr->display, winPtr->window, wmPtr->iconName);
	}

	wmPtr->flags |= WM_UPDATE_SIZE_HINTS;
    }
    if (wmPtr->hints.initial_state == WithdrawnState) {
	return;
    }
    
    /*
     * TODO: we need to display a window if it's iconic on creation.
     */

    if (wmPtr->hints.initial_state == IconicState) {
	return;
    }
    
    /*
     * Update geometry information.
     */
    wmPtr->flags |= WM_ABOUT_TO_MAP;
    if (wmPtr->flags & WM_UPDATE_PENDING) {
	Tk_CancelIdleCall(UpdateGeometryInfo, (ClientData) winPtr);
    }
    UpdateGeometryInfo((ClientData) winPtr);
    wmPtr->flags &= ~WM_ABOUT_TO_MAP;

    /*
     * Map the window.
     */

    XMapWindow(winPtr->display, winPtr->window);
    
    /*
     * Now that the window is visible we can determine the offset
     * from the window's content orgin to the window's decorative
     * orgin (structure orgin).
     */
    GetWindowStructureWidths(GetWindowFromPort(TkMacOSXGetDrawablePort(
	    Tk_WindowId(winPtr))), &widths);
    wmPtr->xInParent = widths.left;
    wmPtr->yInParent = widths.top;
    wmPtr->parentWidth = winPtr->changes.width + widths.left + widths.right;
    wmPtr->parentHeight = winPtr->changes.height + widths.top + widths.bottom;
}

/*
 *--------------------------------------------------------------
 *
 * TkWmUnmapWindow --
 *
 *	This procedure is invoked to unmap a top-level window.
 *	On the Macintosh all we do is call XUnmapWindow.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Unmaps the window.
 *
 *--------------------------------------------------------------
 */

void
TkWmUnmapWindow(
    TkWindow *winPtr)		/* Top-level window that's about to
				 * be mapped. */
{
    XUnmapWindow(winPtr->display, winPtr->window);
}

/*
 *--------------------------------------------------------------
 *
 * TkWmDeadWindow --
 *
 *	This procedure is invoked when a top-level window is
 *	about to be deleted.  It cleans up the wm-related data
 *	structures for the window.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The WmInfo structure for winPtr gets freed up.
 *
 *--------------------------------------------------------------
 */

void
TkWmDeadWindow(winPtr)
    TkWindow *winPtr;		/* Top-level window that's being deleted. */
{
    WmInfo *wmPtr = winPtr->wmInfoPtr;
    WmInfo *wmPtr2;

    if (wmPtr == NULL) {
	return;
    }
    if (wmPtr->hints.flags & IconPixmapHint) {
	Tk_FreeBitmap(winPtr->display, wmPtr->hints.icon_pixmap);
    }
    if (wmPtr->hints.flags & IconMaskHint) {
	Tk_FreeBitmap(winPtr->display, wmPtr->hints.icon_mask);
    }
    if (wmPtr->leaderName != NULL) {
	ckfree(wmPtr->leaderName);
    }
    if (wmPtr->masterWindowName != NULL) {
	ckfree(wmPtr->masterWindowName);
    }
    if (wmPtr->icon != NULL) {
	wmPtr2 = ((TkWindow *) wmPtr->icon)->wmInfoPtr;
	wmPtr2->iconFor = NULL;
    }
    if (wmPtr->iconFor != NULL) {
	wmPtr2 = ((TkWindow *) wmPtr->iconFor)->wmInfoPtr;
	wmPtr2->icon = NULL;
	wmPtr2->hints.flags &= ~IconWindowHint;
    }
    while (wmPtr->protPtr != NULL) {
	ProtocolHandler *protPtr;

	protPtr = wmPtr->protPtr;
	wmPtr->protPtr = protPtr->nextPtr;
	Tcl_EventuallyFree((ClientData) protPtr, TCL_DYNAMIC);
    }
    if (wmPtr->cmdArgv != NULL) {
	ckfree((char *) wmPtr->cmdArgv);
    }
    if (wmPtr->clientMachine != NULL) {
	ckfree((char *) wmPtr->clientMachine);
    }
    if (wmPtr->flags & WM_UPDATE_PENDING) {
	Tk_CancelIdleCall(UpdateGeometryInfo, (ClientData) winPtr);
    }
    ckfree((char *) wmPtr);
    winPtr->wmInfoPtr = NULL;
}

/*
 *--------------------------------------------------------------
 *
 * TkWmSetClass --
 *
 *	This procedure is invoked whenever a top-level window's
 *	class is changed.  If the window has been mapped then this
 *	procedure updates the window manager property for the
 *	class.  If the window hasn't been mapped, the update is
 *	deferred until just before the first mapping.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	A window property may get updated.
 *
 *--------------------------------------------------------------
 */

void
TkWmSetClass(
    TkWindow *winPtr)		/* Newly-created top-level window. */
{
    return;
}
/*
 *----------------------------------------------------------------------
 *
 * Tk_WmObjCmd --
 *
 *	This procedure is invoked to process the "wm" Tcl command.
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
Tk_WmObjCmd(
            ClientData clientData,	/* Main window associated with
            * interpreter. */
            Tcl_Interp *interp,		/* Current interpreter. */
            int objc,			/* Number of arguments. */
            Tcl_Obj *CONST objv[])	/* Argument objects. */
            {
    Tk_Window tkwin = (Tk_Window) clientData;
    static CONST char *optionStrings[] = {
        "aspect", "attributes", "client", "colormapwindows",
        "command", "deiconify", "focusmodel", "frame",
        "geometry", "grid", "group", "iconbitmap",
        "iconify", "iconmask", "iconname",
	"iconphoto", "iconposition",
        "iconwindow", "maxsize", "minsize", "overrideredirect",
        "positionfrom", "protocol", "resizable", "sizefrom",
        "stackorder", "state", "title", "transient",
        "withdraw", (char *) NULL };
    enum options {
        WMOPT_ASPECT, WMOPT_ATTRIBUTES, WMOPT_CLIENT, WMOPT_COLORMAPWINDOWS,
        WMOPT_COMMAND, WMOPT_DEICONIFY, WMOPT_FOCUSMODEL, WMOPT_FRAME,
        WMOPT_GEOMETRY, WMOPT_GRID, WMOPT_GROUP, WMOPT_ICONBITMAP,
        WMOPT_ICONIFY, WMOPT_ICONMASK, WMOPT_ICONNAME,
	WMOPT_ICONPHOTO, WMOPT_ICONPOSITION,
        WMOPT_ICONWINDOW, WMOPT_MAXSIZE, WMOPT_MINSIZE, WMOPT_OVERRIDEREDIRECT,
        WMOPT_POSITIONFROM, WMOPT_PROTOCOL, WMOPT_RESIZABLE, WMOPT_SIZEFROM,
        WMOPT_STACKORDER, WMOPT_STATE, WMOPT_TITLE, WMOPT_TRANSIENT,
        WMOPT_WITHDRAW };
    int index, length;
    char *argv1;
    TkWindow *winPtr;

    if (objc < 2) {
wrongNumArgs:
        Tcl_WrongNumArgs(interp, 1, objv, "option window ?arg ...?");
        return TCL_ERROR;
    }

    argv1 = Tcl_GetStringFromObj(objv[1], &length);
    if ((argv1[0] == 't') && (strncmp(argv1, "tracing", length) == 0)
        && (length >= 3)) {
        if ((objc != 2) && (objc != 3)) {
            Tcl_WrongNumArgs(interp, 2, objv, "?boolean?");
            return TCL_ERROR;
        }
        if (objc == 2) {
            Tcl_SetResult(interp, ((wmTracing) ? "on" : "off"), TCL_STATIC);
            return TCL_OK;
        }
        return Tcl_GetBooleanFromObj(interp, objv[2], &wmTracing);
    }

    if (Tcl_GetIndexFromObj(interp, objv[1], optionStrings, "option", 0,
                            &index) != TCL_OK) {
        return TCL_ERROR;
    }

    if (objc < 3) {
        goto wrongNumArgs;
    }

    if (TkGetWindowFromObj(interp, tkwin, objv[2], (Tk_Window *) &winPtr)
        != TCL_OK) {
        return TCL_ERROR;
    }
    if (!Tk_IsTopLevel(winPtr)) {
        Tcl_AppendResult(interp, "window \"", winPtr->pathName,
                         "\" isn't a top-level window", (char *) NULL);
        return TCL_ERROR;
    }

    switch ((enum options) index) {
        case WMOPT_ASPECT:
            return WmAspectCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_ATTRIBUTES:
            return WmAttributesCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_CLIENT:
            return WmClientCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_COLORMAPWINDOWS:
            return WmColormapwindowsCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_COMMAND:
            return WmCommandCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_DEICONIFY:
            return WmDeiconifyCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_FOCUSMODEL:
            return WmFocusmodelCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_FRAME:
            return WmFrameCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_GEOMETRY:
            return WmGeometryCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_GRID:
            return WmGridCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_GROUP:
            return WmGroupCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_ICONBITMAP:
            return WmIconbitmapCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_ICONIFY:
            return WmIconifyCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_ICONMASK:
            return WmIconmaskCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_ICONNAME:
            return WmIconnameCmd(tkwin, winPtr, interp, objc, objv);
	case WMOPT_ICONPHOTO:
	    return WmIconphotoCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_ICONPOSITION:
            return WmIconpositionCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_ICONWINDOW:
            return WmIconwindowCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_MAXSIZE:
            return WmMaxsizeCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_MINSIZE:
            return WmMinsizeCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_OVERRIDEREDIRECT:
            return WmOverrideredirectCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_POSITIONFROM:
            return WmPositionfromCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_PROTOCOL:
            return WmProtocolCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_RESIZABLE:
            return WmResizableCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_SIZEFROM:
            return WmSizefromCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_STACKORDER:
            return WmStackorderCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_STATE:
            return WmStateCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_TITLE:
            return WmTitleCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_TRANSIENT:
            return WmTransientCmd(tkwin, winPtr, interp, objc, objv);
        case WMOPT_WITHDRAW:
            return WmWithdrawCmd(tkwin, winPtr, interp, objc, objv);
    }

    /* This should not happen */
    return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * WmAspectCmd --
 *
 *	This procedure is invoked to process the "wm aspect" Tcl command.
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

static int
WmAspectCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    int numer1, denom1, numer2, denom2;

    if ((objc != 3) && (objc != 7)) {
        Tcl_WrongNumArgs(interp, 2, objv,
                         "window ?minNumer minDenom maxNumer maxDenom?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        if (wmPtr->sizeHintsFlags & PAspect) {
            char buf[TCL_INTEGER_SPACE * 4];

            sprintf(buf, "%d %d %d %d", wmPtr->minAspect.x,
                    wmPtr->minAspect.y, wmPtr->maxAspect.x,
                    wmPtr->maxAspect.y);
            Tcl_SetResult(interp, buf, TCL_VOLATILE);
        }
        return TCL_OK;
    }
    if (*Tcl_GetString(objv[3]) == '\0') {
        wmPtr->sizeHintsFlags &= ~PAspect;
    } else {
        if ((Tcl_GetIntFromObj(interp, objv[3], &numer1) != TCL_OK)
            || (Tcl_GetIntFromObj(interp, objv[4], &denom1) != TCL_OK)
            || (Tcl_GetIntFromObj(interp, objv[5], &numer2) != TCL_OK)
            || (Tcl_GetIntFromObj(interp, objv[6], &denom2) != TCL_OK)) {
            return TCL_ERROR;
        }
        if ((numer1 <= 0) || (denom1 <= 0) || (numer2 <= 0) ||
            (denom2 <= 0)) {
            Tcl_SetResult(interp, "aspect number can't be <= 0",
                          TCL_STATIC);
            return TCL_ERROR;
        }
        wmPtr->minAspect.x = numer1;
        wmPtr->minAspect.y = denom1;
        wmPtr->maxAspect.x = numer2;
        wmPtr->maxAspect.y = denom2;
        wmPtr->sizeHintsFlags |= PAspect;
    }
    wmPtr->flags |= WM_UPDATE_SIZE_HINTS;
    WmUpdateGeom(wmPtr, winPtr);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmAttributesCmd --
 *
 *	This procedure is invoked to process the "wm attributes" Tcl command.
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

static int
WmAttributesCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    int i;
    int index;
    WindowRef macWindow;
    Tcl_Obj *objPtr = NULL;
    const char *optionTable[] = {
	"-alpha",
	"-modified",
	"-titlepath",
	(char *)NULL
    };
    enum optionIdx {
	WmAttrAlphaIdx,
	WmAttrModifiedIdx,
	WmAttrTitlePathIdx,
    };

    /* Must have objc >= 3 at this point. */
    if (objc < 3) {
	Tcl_WrongNumArgs(interp, 1, objv,
	    "attributes window ?-modified ?bool?? ?-titlepath ?path?? ?-alpha ?double??");
	return TCL_ERROR;
    }

    if (winPtr->window == None) {
	Tk_MakeWindowExist((Tk_Window) winPtr);
    }
    if (!TkMacOSXHostToplevelExists(winPtr)) {
	TkMacOSXMakeRealWindowExist(winPtr);
    }
    macWindow = GetWindowFromPort(TkMacOSXGetDrawablePort(winPtr->window));

    if (objc == 3) {
	objPtr = Tcl_NewObj();
	Tcl_ListObjAppendElement(NULL, objPtr,
		Tcl_NewStringObj("-alpha", -1));
	Tcl_ListObjAppendElement(NULL, objPtr, WmAttrGetAlpha(macWindow));
	Tcl_ListObjAppendElement(NULL, objPtr,
		Tcl_NewStringObj("-modified", -1));
	Tcl_ListObjAppendElement(NULL, objPtr,
		WmAttrGetModifiedStatus(macWindow));
	Tcl_ListObjAppendElement(NULL, objPtr,
		Tcl_NewStringObj("-titlepath", -1));
	Tcl_ListObjAppendElement(NULL, objPtr, WmAttrGetTitlePath(macWindow));
	Tcl_SetObjResult(interp, objPtr);
        return TCL_OK;
    }
    if (objc == 4) {
	if (Tcl_GetIndexFromObj(interp, objv[3], optionTable, "attribute", 0,
	    &index) != TCL_OK) {
	    return TCL_ERROR;
	}
	switch (index) {
	    case WmAttrModifiedIdx:
		objPtr = WmAttrGetModifiedStatus(macWindow);
		break;
	    case WmAttrTitlePathIdx:
		objPtr = WmAttrGetTitlePath(macWindow);
		break;
	    case WmAttrAlphaIdx:
		objPtr = WmAttrGetAlpha(macWindow);
		break;
	}
	Tcl_SetObjResult(interp, objPtr);
	return TCL_OK;
    }

    if ( (objc - 3) % 2 != 0 ) {
	Tcl_WrongNumArgs(interp, 3, objv,
	    "?-modified ?bool?? ?-titlepath ?path?? ?-alpha ?double??");
	return TCL_ERROR;
    }
    for (i = 3; i < objc; i += 2) {
	int boolean;
	const char *path;
	OSErr err;
	double dval;

	if (Tcl_GetIndexFromObj(interp, objv[i], optionTable, "attribute", 0,
	    &index) != TCL_OK) {
	    return TCL_ERROR;
	}
	switch (index) {
	    case WmAttrModifiedIdx:
		if (Tcl_GetBooleanFromObj(interp, objv[i+1], &boolean) !=
		    TCL_OK) {
		    return TCL_ERROR;
		}
		objPtr = objv[i+1];
		SetWindowModified(macWindow, boolean);
		break;
	    case WmAttrTitlePathIdx:
                path = Tcl_FSGetNativePath(objv[i+1]);
		if (path && *path) {
		    FSRef ref;
		    Boolean d;
		    err = FSPathMakeRef((unsigned char*) path, &ref, &d);
		    if (err == noErr) {
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1040
			if (HIWindowSetProxyFSRef != NULL) {
			    err = HIWindowSetProxyFSRef(macWindow, &ref);
			} else
#endif
			{
			    AliasHandle alias;
			    err = FSNewAlias(NULL, &ref, &alias);
			    if (err == noErr) {
				err = SetWindowProxyAlias(macWindow, alias);
				DisposeHandle((Handle) alias);
			    }
			}
		    }
		} else {
		    int len;
		    Tcl_GetStringFromObj(objv[i+1], &len);
		    if (len == 0) {
			err = RemoveWindowProxy(macWindow);
		    } else {
			err = fnfErr;
		    }
		}
		if (err != noErr) {
		    Tcl_SetObjResult(interp,
		    Tcl_NewStringObj("couldn't set window proxy title path",
			-1));
		    return TCL_ERROR;
		} else {
		    objPtr = objv[i+1];
		}
		break;
	    case WmAttrAlphaIdx:
		if (Tcl_GetDoubleFromObj(interp, objv[i+1], &dval) !=
		    TCL_OK) {
		    return TCL_ERROR;
		}
		/*
		 * The user should give (transparent) 0 .. 1.0 (opaque)
		 */
		if (dval < 0.0) {
		    dval = 0.0;
		} else if (dval > 1.0) {
		    dval = 1.0;
		}
		objPtr = Tcl_NewDoubleObj(dval);
		SetWindowAlpha(macWindow, dval);
		break;
	}
    }
    Tcl_SetObjResult(interp, objPtr);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 * WmAttrGetModifiedStatus --
 *
 *	Helper procedure to retrieve the -modified option for the wm
 *	attributes command.
 *
 * Results:
 *	Returns value in unrefcounted Tcl_Obj.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */
static Tcl_Obj *
WmAttrGetModifiedStatus(WindowRef macWindow)
{
    return Tcl_NewBooleanObj((IsWindowModified(macWindow) == true));
}

/*
 *----------------------------------------------------------------------
 * WmAttrGetTitlePath --
 *
 *	Helper procedure to retrieve the -titlepath option for the wm
 *	attributes command.
 *
 * Results:
 *	Returns value in unrefcounted Tcl_Obj.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */
static Tcl_Obj *
WmAttrGetTitlePath(WindowRef macWindow)
{
    FSRef ref;
    Boolean wasChanged;
    UInt8 path[2048];
    OSStatus err = fnfErr;

#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1040
    if (HIWindowGetProxyFSRef != NULL) {
	err = HIWindowGetProxyFSRef(macWindow, &ref);
    }
#endif
    if (err != noErr) {
	AliasHandle alias;
	err = GetWindowProxyAlias(macWindow, &alias);
	if (err == noErr) {
	    err = FSResolveAlias(NULL, alias, &ref, &wasChanged);
	}
    }
    if (err == noErr) {
	err = FSRefMakePath(&ref, path, 2048);
    }
    if (err == noErr) {
	return Tcl_NewStringObj((char*) path, -1);
    } else {
	return Tcl_NewStringObj("", 0);
    }
}

/*
 *----------------------------------------------------------------------
 * WmAttrGetAlpha --
 *
 *	Helper procedure to retrieve the -alpha option for the wm
 *	attributes command.
 *
 * Results:
 *	Returns value in unrefcounted Tcl_Obj.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */
static Tcl_Obj *
WmAttrGetAlpha(WindowRef macWindow)
{
    float fval;
    if (GetWindowAlpha(macWindow, &fval) != noErr) {
        fval = 1.0;
    }
    return Tcl_NewDoubleObj(fval);
}

/*
 *----------------------------------------------------------------------
 *
 * WmClientCmd --
 *
 *	This procedure is invoked to process the "wm client" Tcl command.
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

static int
WmClientCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    char *argv3;
    int length;

    if ((objc != 3) && (objc != 4)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?name?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        if (wmPtr->clientMachine != NULL) {
            Tcl_SetResult(interp, wmPtr->clientMachine, TCL_STATIC);
        }
        return TCL_OK;
    }
    argv3 = Tcl_GetStringFromObj(objv[3], &length);
    if (argv3[0] == 0) {
        if (wmPtr->clientMachine != NULL) {
            ckfree((char *) wmPtr->clientMachine);
            wmPtr->clientMachine = NULL;
        }
        return TCL_OK;
    }
    if (wmPtr->clientMachine != NULL) {
        ckfree((char *) wmPtr->clientMachine);
    }
    wmPtr->clientMachine = (char *)
        ckalloc((unsigned) (length + 1));
    strcpy(wmPtr->clientMachine, argv3);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmColormapwindowsCmd --
 *
 *	This procedure is invoked to process the "wm colormapwindows"
 *	Tcl command.
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

static int
WmColormapwindowsCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    TkWindow **cmapList;
    TkWindow *winPtr2;
    int i, windowObjc, gotToplevel = 0;
    Tcl_Obj **windowObjv;

    if ((objc != 3) && (objc != 4)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?windowList?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        Tk_MakeWindowExist((Tk_Window) winPtr);
        for (i = 0; i < wmPtr->cmapCount; i++) {
            if ((i == (wmPtr->cmapCount-1))
                && (wmPtr->flags & WM_ADDED_TOPLEVEL_COLORMAP)) {
                break;
            }
            Tcl_AppendElement(interp, wmPtr->cmapList[i]->pathName);
        }
        return TCL_OK;
    }
    if (Tcl_ListObjGetElements(interp, objv[3], &windowObjc, &windowObjv)
        != TCL_OK) {
        return TCL_ERROR;
    }
    cmapList = (TkWindow **) ckalloc((unsigned)
                                     ((windowObjc+1)*sizeof(TkWindow*)));
    for (i = 0; i < windowObjc; i++) {
        if (TkGetWindowFromObj(interp, tkwin, windowObjv[i],
                               (Tk_Window *) &winPtr2) != TCL_OK)
        {
            ckfree((char *) cmapList);
            return TCL_ERROR;
        }
        if (winPtr2 == winPtr) {
            gotToplevel = 1;
        }
        if (winPtr2->window == None) {
            Tk_MakeWindowExist((Tk_Window) winPtr2);
        }
        cmapList[i] = winPtr2;
    }
    if (!gotToplevel) {
        wmPtr->flags |= WM_ADDED_TOPLEVEL_COLORMAP;
        cmapList[windowObjc] = winPtr;
        windowObjc++;
    } else {
        wmPtr->flags &= ~WM_ADDED_TOPLEVEL_COLORMAP;
    }
    wmPtr->flags |= WM_COLORMAPS_EXPLICIT;
    if (wmPtr->cmapList != NULL) {
        ckfree((char *)wmPtr->cmapList);
    }
    wmPtr->cmapList = cmapList;
    wmPtr->cmapCount = windowObjc;

    /*
     * On the Macintosh all of this is just an excercise
     * in compatability as we don't support colormaps.  If
     * we did they would be installed here.
     */

    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmCommandCmd --
 *
 *	This procedure is invoked to process the "wm command" Tcl command.
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

static int
WmCommandCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    char *argv3;
    int cmdArgc;
    CONST char **cmdArgv;

    if ((objc != 3) && (objc != 4)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?value?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        if (wmPtr->cmdArgv != NULL) {
            Tcl_SetResult(interp,
                          Tcl_Merge(wmPtr->cmdArgc, wmPtr->cmdArgv),
                          TCL_DYNAMIC);
        }
        return TCL_OK;
    }
    argv3 = Tcl_GetString(objv[3]);
    if (argv3[0] == 0) {
        if (wmPtr->cmdArgv != NULL) {
            ckfree((char *) wmPtr->cmdArgv);
            wmPtr->cmdArgv = NULL;
        }
        return TCL_OK;
    }
    if (Tcl_SplitList(interp, argv3, &cmdArgc, &cmdArgv) != TCL_OK) {
        return TCL_ERROR;
    }
    if (wmPtr->cmdArgv != NULL) {
        ckfree((char *) wmPtr->cmdArgv);
    }
    wmPtr->cmdArgc = cmdArgc;
    wmPtr->cmdArgv = cmdArgv;
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmDeiconifyCmd --
 *
 *	This procedure is invoked to process the "wm deiconify" Tcl command.
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

static int
WmDeiconifyCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    if (objc != 3) {
        Tcl_WrongNumArgs(interp, 2, objv, "window");
        return TCL_ERROR;
    }
    if (wmPtr->iconFor != NULL) {
        Tcl_AppendResult(interp, "can't deiconify ", Tcl_GetString(objv[2]),
                         ": it is an icon for ", Tk_PathName(wmPtr->iconFor),
                         (char *) NULL);
        return TCL_ERROR;
    }
    if (winPtr->flags & TK_EMBEDDED) {
        Tcl_AppendResult(interp, "can't deiconify ", winPtr->pathName,
                         ": it is an embedded window", (char *) NULL);
        return TCL_ERROR;
    }
    TkpWmSetState(winPtr, TkMacOSXIsWindowZoomed(winPtr) ?
	    ZoomState : NormalState);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmFocusmodelCmd --
 *
 *	This procedure is invoked to process the "wm focusmodel" Tcl command.
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

static int
WmFocusmodelCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    static CONST char *optionStrings[] = {
        "active", "passive", (char *) NULL };
    enum options {
        OPT_ACTIVE, OPT_PASSIVE };
    int index;

    if ((objc != 3) && (objc != 4)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?active|passive?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        Tcl_SetResult(interp, (wmPtr->hints.input ? "passive" : "active"),
                      TCL_STATIC);
        return TCL_OK;
    }

    if (Tcl_GetIndexFromObj(interp, objv[3], optionStrings, "argument", 0,
                            &index) != TCL_OK) {
        return TCL_ERROR;
    }
    if (index == OPT_ACTIVE) {
        wmPtr->hints.input = False;
    } else { /* OPT_PASSIVE */
        wmPtr->hints.input = True;
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmFrameCmd --
 *
 *	This procedure is invoked to process the "wm frame" Tcl command.
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

static int
WmFrameCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    Window window;
    char buf[TCL_INTEGER_SPACE];

    if (objc != 3) {
        Tcl_WrongNumArgs(interp, 2, objv, "window");
        return TCL_ERROR;
    }
    window = wmPtr->reparent;
    if (window == None) {
        window = Tk_WindowId((Tk_Window) winPtr);
    }
    sprintf(buf, "0x%x", (unsigned int) window);
    Tcl_SetResult(interp, buf, TCL_VOLATILE);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmGeometryCmd --
 *
 *	This procedure is invoked to process the "wm geometry" Tcl command.
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

static int
WmGeometryCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    char xSign, ySign;
    int width, height;
    char *argv3;

    if ((objc != 3) && (objc != 4)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?newGeometry?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        char buf[16 + TCL_INTEGER_SPACE * 4];

        xSign = (wmPtr->flags & WM_NEGATIVE_X) ? '-' : '+';
        ySign = (wmPtr->flags & WM_NEGATIVE_Y) ? '-' : '+';
        if (wmPtr->gridWin != NULL) {
            width = wmPtr->reqGridWidth + (winPtr->changes.width
                                           - winPtr->reqWidth)/wmPtr->widthInc;
            height = wmPtr->reqGridHeight + (winPtr->changes.height
                                             - winPtr->reqHeight)/wmPtr->heightInc;
        } else {
            width = winPtr->changes.width;
            height = winPtr->changes.height;
        }
        sprintf(buf, "%dx%d%c%d%c%d", width, height, xSign, wmPtr->x,
                ySign, wmPtr->y);
        Tcl_SetResult(interp, buf, TCL_VOLATILE);
        return TCL_OK;
    }
    argv3 = Tcl_GetString(objv[3]);
    if (*argv3 == '\0') {
        wmPtr->width = -1;
        wmPtr->height = -1;
        WmUpdateGeom(wmPtr, winPtr);
        return TCL_OK;
    }
    return ParseGeometry(interp, argv3, winPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * WmGridCmd --
 *
 *	This procedure is invoked to process the "wm grid" Tcl command.
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

static int
WmGridCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    int reqWidth, reqHeight, widthInc, heightInc;

    if ((objc != 3) && (objc != 7)) {
        Tcl_WrongNumArgs(interp, 2, objv,
                         "window ?baseWidth baseHeight widthInc heightInc?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        if (wmPtr->sizeHintsFlags & PBaseSize) {
            char buf[TCL_INTEGER_SPACE * 4];

            sprintf(buf, "%d %d %d %d", wmPtr->reqGridWidth,
                    wmPtr->reqGridHeight, wmPtr->widthInc,
                    wmPtr->heightInc);
            Tcl_SetResult(interp, buf, TCL_VOLATILE);
        }
        return TCL_OK;
    }
    if (*Tcl_GetString(objv[3]) == '\0') {
        /*
         * Turn off gridding and reset the width and height
         * to make sense as ungridded numbers.
         */

        wmPtr->sizeHintsFlags &= ~(PBaseSize|PResizeInc);
        if (wmPtr->width != -1) {
            wmPtr->width = winPtr->reqWidth + (wmPtr->width
                                               - wmPtr->reqGridWidth)*wmPtr->widthInc;
            wmPtr->height = winPtr->reqHeight + (wmPtr->height
                                                 - wmPtr->reqGridHeight)*wmPtr->heightInc;
        }
        wmPtr->widthInc = 1;
        wmPtr->heightInc = 1;
    } else {
        if ((Tcl_GetIntFromObj(interp, objv[3], &reqWidth) != TCL_OK)
            || (Tcl_GetIntFromObj(interp, objv[4], &reqHeight) != TCL_OK)
            || (Tcl_GetIntFromObj(interp, objv[5], &widthInc) != TCL_OK)
            || (Tcl_GetIntFromObj(interp, objv[6], &heightInc) != TCL_OK)) {
            return TCL_ERROR;
        }
        if (reqWidth < 0) {
            Tcl_SetResult(interp, "baseWidth can't be < 0", TCL_STATIC);
            return TCL_ERROR;
        }
        if (reqHeight < 0) {
            Tcl_SetResult(interp, "baseHeight can't be < 0", TCL_STATIC);
            return TCL_ERROR;
        }
        if (widthInc <= 0) {
            Tcl_SetResult(interp, "widthInc can't be <= 0", TCL_STATIC);
            return TCL_ERROR;
        }
        if (heightInc <= 0) {
            Tcl_SetResult(interp, "heightInc can't be <= 0", TCL_STATIC);
            return TCL_ERROR;
        }
        Tk_SetGrid((Tk_Window) winPtr, reqWidth, reqHeight, widthInc,
                   heightInc);
    }
    wmPtr->flags |= WM_UPDATE_SIZE_HINTS;
    WmUpdateGeom(wmPtr, winPtr);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmGroupCmd --
 *
 *	This procedure is invoked to process the "wm group" Tcl command.
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

static int
WmGroupCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    Tk_Window tkwin2;
    char *argv3;
    int length;

    if ((objc != 3) && (objc != 4)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?pathName?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        if (wmPtr->hints.flags & WindowGroupHint) {
            Tcl_SetResult(interp, wmPtr->leaderName, TCL_STATIC);
        }
        return TCL_OK;
    }
    argv3 = Tcl_GetStringFromObj(objv[3], &length);
    if (*argv3 == '\0') {
        wmPtr->hints.flags &= ~WindowGroupHint;
        if (wmPtr->leaderName != NULL) {
            ckfree(wmPtr->leaderName);
        }
        wmPtr->leaderName = NULL;
    } else {
        if (TkGetWindowFromObj(interp, tkwin, objv[3], &tkwin2) != TCL_OK) {
            return TCL_ERROR;
        }
        Tk_MakeWindowExist(tkwin2);
        if (wmPtr->leaderName != NULL) {
            ckfree(wmPtr->leaderName);
        }
        wmPtr->hints.window_group = Tk_WindowId(tkwin2);
        wmPtr->hints.flags |= WindowGroupHint;
        wmPtr->leaderName = ckalloc((unsigned) (length + 1));
        strcpy(wmPtr->leaderName, argv3);
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmIconbitmapCmd --
 *
 *	This procedure is invoked to process the "wm iconbitmap" Tcl command.
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

static int
WmIconbitmapCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    Pixmap pixmap;
    const char *path;
    int len = -1;
    OSErr err = fnfErr;
    FSRef ref;

    if ((objc != 3) && (objc != 4)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?bitmap?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        if (wmPtr->hints.flags & IconPixmapHint) {
            Tcl_SetResult(interp,
                          (char *) Tk_NameOfBitmap(winPtr->display, wmPtr->hints.icon_pixmap),
                          TCL_STATIC);
        }
        return TCL_OK;
    }
    path = Tcl_FSGetNativePath(objv[3]);
    if (path && *path) {
	Boolean d;
	err = FSPathMakeRef((unsigned char*) path, &ref, &d);
    } else {
	Tcl_GetStringFromObj(objv[3], &len);
    }
    if (err == noErr || len == 0) {
	WindowRef macWindow;
	if (winPtr->window == None) {
	    Tk_MakeWindowExist((Tk_Window) winPtr);
	}
	if (!TkMacOSXHostToplevelExists(winPtr)) {
	    TkMacOSXMakeRealWindowExist(winPtr);
	}
	macWindow = GetWindowFromPort(TkMacOSXGetDrawablePort(winPtr->window));
	if (len) {
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1040
	    if (HIWindowSetProxyFSRef != NULL) {
		err = HIWindowSetProxyFSRef(macWindow, &ref);
	    } else
#endif
	    {
		AliasHandle alias;
		err = FSNewAlias(NULL, &ref, &alias);
		if (err == noErr) {
		    err = SetWindowProxyAlias(macWindow, alias);
		    DisposeHandle((Handle) alias);
		}
	    }
	} else {
	    err = RemoveWindowProxy(macWindow);
	    if (wmPtr->hints.icon_pixmap != None) {
		Tk_FreeBitmap(winPtr->display, wmPtr->hints.icon_pixmap);
		wmPtr->hints.icon_pixmap = None;
	    }
	    wmPtr->hints.flags &= ~IconPixmapHint;
	}
    } else {
        pixmap = Tk_GetBitmap(interp, (Tk_Window) winPtr,
                              Tk_GetUid(Tcl_GetStringFromObj(objv[3], NULL)));
        if (pixmap == None) {
            return TCL_ERROR;
        }
        wmPtr->hints.icon_pixmap = pixmap;
        wmPtr->hints.flags |= IconPixmapHint;
    }
    
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmIconifyCmd --
 *
 *	This procedure is invoked to process the "wm iconify" Tcl command.
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

static int
WmIconifyCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    if (objc != 3) {
        Tcl_WrongNumArgs(interp, 2, objv, "window");
        return TCL_ERROR;
    }
    if (Tk_Attributes((Tk_Window) winPtr)->override_redirect) {
        Tcl_AppendResult(interp, "can't iconify \"", winPtr->pathName,
                         "\": override-redirect flag is set", (char *) NULL);
        return TCL_ERROR;
    }
    if (wmPtr->master != None) {
        Tcl_AppendResult(interp, "can't iconify \"", winPtr->pathName,
                         "\": it is a transient", (char *) NULL);
        return TCL_ERROR;
    }
    if (wmPtr->iconFor != NULL) {
        Tcl_AppendResult(interp, "can't iconify ", winPtr->pathName,
                         ": it is an icon for ", Tk_PathName(wmPtr->iconFor),
                         (char *) NULL);
        return TCL_ERROR;
    }
    if (winPtr->flags & TK_EMBEDDED) {
        Tcl_AppendResult(interp, "can't iconify ", winPtr->pathName,
                         ": it is an embedded window", (char *) NULL);
        return TCL_ERROR;
    }
    TkpWmSetState(winPtr, IconicState);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmIconmaskCmd --
 *
 *	This procedure is invoked to process the "wm iconmask" Tcl command.
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

static int
WmIconmaskCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    Pixmap pixmap;
    char *argv3;

    if ((objc != 3) && (objc != 4)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?bitmap?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        if (wmPtr->hints.flags & IconMaskHint) {
            Tcl_SetResult(interp,
                          (char *) Tk_NameOfBitmap(winPtr->display, wmPtr->hints.icon_mask),
                          TCL_STATIC);
        }
        return TCL_OK;
    }
    argv3 = Tcl_GetString(objv[3]);
    if (*argv3 == '\0') {
        if (wmPtr->hints.icon_mask != None) {
            Tk_FreeBitmap(winPtr->display, wmPtr->hints.icon_mask);
        }
        wmPtr->hints.flags &= ~IconMaskHint;
    } else {
        pixmap = Tk_GetBitmap(interp, tkwin, argv3);
        if (pixmap == None) {
            return TCL_ERROR;
        }
        wmPtr->hints.icon_mask = pixmap;
        wmPtr->hints.flags |= IconMaskHint;
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmIconnameCmd --
 *
 *	This procedure is invoked to process the "wm iconname" Tcl command.
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

static int
WmIconnameCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    CONST char *argv3;
    int length;

    if (objc > 4) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?newName?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        Tcl_SetResult(interp,
                      (char *) ((wmPtr->iconName != NULL) ? wmPtr->iconName : ""),
                      TCL_STATIC);
        return TCL_OK;
    } else {
        if (wmPtr->iconName != NULL) {
            ckfree((char *) wmPtr->iconName);
        }
        argv3 = Tcl_GetStringFromObj(objv[3], &length);
        wmPtr->iconName = ckalloc((unsigned) (length + 1));
        strcpy(wmPtr->iconName, argv3);
        if (!(wmPtr->flags & WM_NEVER_MAPPED)) {
            XSetIconName(winPtr->display, winPtr->window, wmPtr->iconName);
        }
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmIconphotoCmd --
 *
 *	This procedure is invoked to process the "wm iconphoto"
 *	Tcl command.
 *	See the user documentation for details on what it does.
 *	Not yet implemented for OS X.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

static int
WmIconphotoCmd(tkwin, winPtr, interp, objc, objv)
    Tk_Window tkwin;		/* Main window of the application. */
    TkWindow *winPtr;           /* Toplevel to work with */
    Tcl_Interp *interp;		/* Current interpreter. */
    int objc;			/* Number of arguments. */
    Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    Tk_PhotoHandle photo;
    int i, width, height, isDefault = 0;

    if (objc < 4) {
	Tcl_WrongNumArgs(interp, 2, objv,
		"window ?-default? image1 ?image2 ...?");
	return TCL_ERROR;
    }
    if (strcmp(Tcl_GetString(objv[3]), "-default") == 0) {
	isDefault = 1;
	if (objc == 4) {
	    Tcl_WrongNumArgs(interp, 2, objv,
		    "window ?-default? image1 ?image2 ...?");
	    return TCL_ERROR;
	}
    }
    /*
     * Iterate over all images to retrieve their sizes, in order to allocate a
     * buffer large enough to hold all images.
     */
    for (i = 3 + isDefault; i < objc; i++) {
	photo = Tk_FindPhoto(interp, Tcl_GetString(objv[i]));
	if (photo == NULL) {
	    Tcl_AppendResult(interp, "can't use \"", Tcl_GetString(objv[i]),
		    "\" as iconphoto: not a photo image", (char *) NULL);
	    return TCL_ERROR;
	}
	Tk_PhotoGetSize(photo, &width, &height);
    }
    /*
     * This requires implementation for OS X, but we silently return
     * for now.
     */
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmIconpositionCmd --
 *
 *	This procedure is invoked to process the "wm iconposition"
 *	Tcl command.
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

static int
WmIconpositionCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    int x, y;

    if ((objc != 3) && (objc != 5)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?x y?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        if (wmPtr->hints.flags & IconPositionHint) {
            char buf[TCL_INTEGER_SPACE * 2];

            sprintf(buf, "%d %d", wmPtr->hints.icon_x,
                    wmPtr->hints.icon_y);
            Tcl_SetResult(interp, buf, TCL_VOLATILE);
        }
        return TCL_OK;
    }
    if (*Tcl_GetString(objv[3]) == '\0') {
        wmPtr->hints.flags &= ~IconPositionHint;
    } else {
        if ((Tcl_GetIntFromObj(interp, objv[3], &x) != TCL_OK)
            || (Tcl_GetIntFromObj(interp, objv[4], &y) != TCL_OK)){
            return TCL_ERROR;
        }
        wmPtr->hints.icon_x = x;
        wmPtr->hints.icon_y = y;
        wmPtr->hints.flags |= IconPositionHint;
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmIconwindowCmd --
 *
 *	This procedure is invoked to process the "wm iconwindow" Tcl command.
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

static int
WmIconwindowCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    Tk_Window tkwin2;
    WmInfo *wmPtr2;

    if ((objc != 3) && (objc != 4)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?pathName?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        if (wmPtr->icon != NULL) {
            Tcl_SetResult(interp, Tk_PathName(wmPtr->icon), TCL_STATIC);
        }
        return TCL_OK;
    }
    if (*Tcl_GetString(objv[3]) == '\0') {
        wmPtr->hints.flags &= ~IconWindowHint;
        if (wmPtr->icon != NULL) {
            wmPtr2 = ((TkWindow *) wmPtr->icon)->wmInfoPtr;
            wmPtr2->iconFor = NULL;
            wmPtr2->hints.initial_state = WithdrawnState;
        }
        wmPtr->icon = NULL;
    } else {
        if (TkGetWindowFromObj(interp, tkwin, objv[3], &tkwin2) != TCL_OK) {
            return TCL_ERROR;
        }
        if (!Tk_IsTopLevel(tkwin2)) {
            Tcl_AppendResult(interp, "can't use ", Tcl_GetString(objv[3]),
                             " as icon window: not at top level", (char *) NULL);
            return TCL_ERROR;
        }
        wmPtr2 = ((TkWindow *) tkwin2)->wmInfoPtr;
        if (wmPtr2->iconFor != NULL) {
            Tcl_AppendResult(interp, Tcl_GetString(objv[3]),
                             " is already an icon for ",
                             Tk_PathName(wmPtr2->iconFor), (char *) NULL);
            return TCL_ERROR;
        }
        if (wmPtr->icon != NULL) {
            WmInfo *wmPtr3 = ((TkWindow *) wmPtr->icon)->wmInfoPtr;
            wmPtr3->iconFor = NULL;
        }
        Tk_MakeWindowExist(tkwin2);
        wmPtr->hints.icon_window = Tk_WindowId(tkwin2);
        wmPtr->hints.flags |= IconWindowHint;
        wmPtr->icon = tkwin2;
        wmPtr2->iconFor = (Tk_Window) winPtr;
        if (!(wmPtr2->flags & WM_NEVER_MAPPED)) {
            /*
             * Don't have iconwindows on the Mac.  We just withdraw.
             */

            Tk_UnmapWindow(tkwin2);
        }
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmMaxsizeCmd --
 *
 *	This procedure is invoked to process the "wm maxsize" Tcl command.
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

static int
WmMaxsizeCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    int width, height;

    if ((objc != 3) && (objc != 5)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?width height?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        char buf[TCL_INTEGER_SPACE * 2];

        sprintf(buf, "%d %d", wmPtr->maxWidth, wmPtr->maxHeight);
        Tcl_SetResult(interp, buf, TCL_VOLATILE);
        return TCL_OK;
    }
    if ((Tcl_GetIntFromObj(interp, objv[3], &width) != TCL_OK)
        || (Tcl_GetIntFromObj(interp, objv[4], &height) != TCL_OK)) {
        return TCL_ERROR;
    }
    wmPtr->maxWidth = width;
    wmPtr->maxHeight = height;
    wmPtr->flags |= WM_UPDATE_SIZE_HINTS;
    WmUpdateGeom(wmPtr, winPtr);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmMinsizeCmd --
 *
 *	This procedure is invoked to process the "wm minsize" Tcl command.
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

static int
WmMinsizeCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    int width, height;

    if ((objc != 3) && (objc != 5)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?width height?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        char buf[TCL_INTEGER_SPACE * 2];

        sprintf(buf, "%d %d", wmPtr->minWidth, wmPtr->minHeight);
        Tcl_SetResult(interp, buf, TCL_VOLATILE);
        return TCL_OK;
    }
    if ((Tcl_GetIntFromObj(interp, objv[3], &width) != TCL_OK)
        || (Tcl_GetIntFromObj(interp, objv[4], &height) != TCL_OK)) {
        return TCL_ERROR;
    }
    wmPtr->minWidth = width;
    wmPtr->minHeight = height;
    wmPtr->flags |= WM_UPDATE_SIZE_HINTS;
    WmUpdateGeom(wmPtr, winPtr);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmOverrideredirectCmd --
 *
 *	This procedure is invoked to process the "wm overrideredirect"
 *	Tcl command.
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

static int
WmOverrideredirectCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    int boolean;
    XSetWindowAttributes atts;
    int oldAttributes = wmPtr->attributes;

    if ((objc != 3) && (objc != 4)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?boolean?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        Tcl_SetBooleanObj(Tcl_GetObjResult(interp),
                          Tk_Attributes((Tk_Window) winPtr)->override_redirect);
        return TCL_OK;
    }
    if (Tcl_GetBooleanFromObj(interp, objv[3], &boolean) != TCL_OK) {
        return TCL_ERROR;
    }
    atts.override_redirect = (boolean) ? True : False;
    Tk_ChangeWindowAttributes((Tk_Window) winPtr, CWOverrideRedirect,
                              &atts);
    /*
     * FIX: We need an UpdateWrapper equivalent to make this 100% correct
     */
    if (boolean) {
	if (wmPtr->macClass == kDocumentWindowClass || (wmPtr->master != None &&
		wmPtr->macClass == kFloatingWindowClass)) {
	    wmPtr->macClass = kSimpleWindowClass;
	    wmPtr->attributes = kWindowNoAttributes;
	}
	wmPtr->attributes |= kWindowNoActivatesAttribute;
    } else {
	wmPtr->attributes &= ~kWindowNoActivatesAttribute;
	if (wmPtr->macClass == kSimpleWindowClass) {
	    if (wmPtr->master != None) {
		wmPtr->macClass = kFloatingWindowClass; // override && transient
		wmPtr->attributes = kWindowStandardFloatingAttributes;
	    } else {
		wmPtr->macClass = kDocumentWindowClass;
		wmPtr->attributes = kWindowStandardDocumentAttributes;
	    }
	}
    }
    ApplyWindowAttributeChanges(winPtr, wmPtr->attributes, oldAttributes, 0);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmPositionfromCmd --
 *
 *	This procedure is invoked to process the "wm positionfrom"
 *	Tcl command.
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

static int
WmPositionfromCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    static CONST char *optionStrings[] = {
        "program", "user", (char *) NULL };
    enum options {
        OPT_PROGRAM, OPT_USER };
    int index;

    if ((objc != 3) && (objc != 4)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?user/program?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        if (wmPtr->sizeHintsFlags & USPosition) {
            Tcl_SetResult(interp, "user", TCL_STATIC);
        } else if (wmPtr->sizeHintsFlags & PPosition) {
            Tcl_SetResult(interp, "program", TCL_STATIC);
        }
        return TCL_OK;
    }
    if (*Tcl_GetString(objv[3]) == '\0') {
        wmPtr->sizeHintsFlags &= ~(USPosition|PPosition);
    } else {
        if (Tcl_GetIndexFromObj(interp, objv[3], optionStrings, "argument", 0,
                                &index) != TCL_OK) {
            return TCL_ERROR;
        }
        if (index == OPT_USER) {
            wmPtr->sizeHintsFlags &= ~PPosition;
            wmPtr->sizeHintsFlags |= USPosition;
        } else {
            wmPtr->sizeHintsFlags &= ~USPosition;
            wmPtr->sizeHintsFlags |= PPosition;
        }
    }
    wmPtr->flags |= WM_UPDATE_SIZE_HINTS;
    WmUpdateGeom(wmPtr, winPtr);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmProtocolCmd --
 *
 *	This procedure is invoked to process the "wm protocol" Tcl command.
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

static int
WmProtocolCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    register ProtocolHandler *protPtr, *prevPtr;
    Atom protocol;
    char *cmd;
    int cmdLength;

    if ((objc < 3) || (objc > 5)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?name? ?command?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        /*
         * Return a list of all defined protocols for the window.
         */
        for (protPtr = wmPtr->protPtr; protPtr != NULL;
             protPtr = protPtr->nextPtr) {
            Tcl_AppendElement(interp,
                              Tk_GetAtomName((Tk_Window) winPtr, protPtr->protocol));
        }
        return TCL_OK;
    }
    protocol = Tk_InternAtom((Tk_Window) winPtr, Tcl_GetString(objv[3]));
    if (objc == 4) {
        /*
         * Return the command to handle a given protocol.
         */
        for (protPtr = wmPtr->protPtr; protPtr != NULL;
             protPtr = protPtr->nextPtr) {
            if (protPtr->protocol == protocol) {
                Tcl_SetResult(interp, protPtr->command, TCL_STATIC);
                return TCL_OK;
            }
        }
        return TCL_OK;
    }

    /*
     * Delete any current protocol handler, then create a new
     * one with the specified command, unless the command is
     * empty.
     */

    for (protPtr = wmPtr->protPtr, prevPtr = NULL; protPtr != NULL;
         prevPtr = protPtr, protPtr = protPtr->nextPtr) {
        if (protPtr->protocol == protocol) {
            if (prevPtr == NULL) {
                wmPtr->protPtr = protPtr->nextPtr;
            } else {
                prevPtr->nextPtr = protPtr->nextPtr;
            }
            Tcl_EventuallyFree((ClientData) protPtr, TCL_DYNAMIC);
            break;
        }
    }
    cmd = Tcl_GetStringFromObj(objv[4], &cmdLength);
    if (cmdLength > 0) {
        protPtr = (ProtocolHandler *) ckalloc(HANDLER_SIZE(cmdLength));
        protPtr->protocol = protocol;
        protPtr->nextPtr = wmPtr->protPtr;
        wmPtr->protPtr = protPtr;
        protPtr->interp = interp;
        strcpy(protPtr->command, cmd);
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmResizableCmd --
 *
 *	This procedure is invoked to process the "wm resizable" Tcl command.
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

static int
WmResizableCmd(tkwin, winPtr, interp, objc, objv)
    Tk_Window tkwin;		/* Main window of the application. */
    TkWindow *winPtr;           /* Toplevel to work with */
    Tcl_Interp *interp;		/* Current interpreter. */
    int objc;			/* Number of arguments. */
    Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    int width, height;
    int oldAttributes = wmPtr->attributes;

    if ((objc != 3) && (objc != 5)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?width height?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        char buf[TCL_INTEGER_SPACE * 2];

        sprintf(buf, "%d %d",
                (wmPtr->flags  & WM_WIDTH_NOT_RESIZABLE) ? 0 : 1,
                (wmPtr->flags  & WM_HEIGHT_NOT_RESIZABLE) ? 0 : 1);
        Tcl_SetResult(interp, buf, TCL_VOLATILE);
        return TCL_OK;
    }
    if ((Tcl_GetBooleanFromObj(interp, objv[3], &width) != TCL_OK)
        || (Tcl_GetBooleanFromObj(interp, objv[4], &height) != TCL_OK)) {
        return TCL_ERROR;
    }
    if (width) {
        wmPtr->flags &= ~WM_WIDTH_NOT_RESIZABLE;
        wmPtr->attributes |= kWindowHorizontalZoomAttribute;
    } else {
        wmPtr->flags |= WM_WIDTH_NOT_RESIZABLE;
        wmPtr->attributes &= ~kWindowHorizontalZoomAttribute;
    }
    if (height) {
        wmPtr->flags &= ~WM_HEIGHT_NOT_RESIZABLE;
        wmPtr->attributes |= kWindowVerticalZoomAttribute;
    } else {
        wmPtr->flags |= WM_HEIGHT_NOT_RESIZABLE;
        wmPtr->attributes &= ~kWindowVerticalZoomAttribute;
    }
    if (width || height) {
        wmPtr->attributes |= kWindowResizableAttribute;
    } else {
        wmPtr->attributes &= ~kWindowResizableAttribute;
    }
    wmPtr->flags |= WM_UPDATE_SIZE_HINTS;
    if (wmPtr->scrollWinPtr != NULL) {
        TkScrollbarEventuallyRedraw((TkScrollbar *)
		wmPtr->scrollWinPtr->instanceData);
    }
    WmUpdateGeom(wmPtr, winPtr);
    ApplyWindowAttributeChanges(winPtr, wmPtr->attributes, oldAttributes, 1);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmSizefromCmd --
 *
 *	This procedure is invoked to process the "wm sizefrom" Tcl command.
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

static int
WmSizefromCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    static CONST char *optionStrings[] = {
        "program", "user", (char *) NULL };
    enum options {
        OPT_PROGRAM, OPT_USER };
    int index;

    if ((objc != 3) && (objc != 4)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?user|program?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        if (wmPtr->sizeHintsFlags & USSize) {
            Tcl_SetResult(interp, "user", TCL_STATIC);
        } else if (wmPtr->sizeHintsFlags & PSize) {
            Tcl_SetResult(interp, "program", TCL_STATIC);
        }
        return TCL_OK;
    }

    if (*Tcl_GetString(objv[3]) == '\0') {
        wmPtr->sizeHintsFlags &= ~(USSize|PSize);
    } else {
        if (Tcl_GetIndexFromObj(interp, objv[3], optionStrings, "argument", 0,
                                &index) != TCL_OK) {
            return TCL_ERROR;
        }
        if (index == OPT_USER) {
            wmPtr->sizeHintsFlags &= ~PSize;
            wmPtr->sizeHintsFlags |= USSize;
        } else { /* OPT_PROGRAM */
            wmPtr->sizeHintsFlags &= ~USSize;
            wmPtr->sizeHintsFlags |= PSize;
        }
    }
    wmPtr->flags |= WM_UPDATE_SIZE_HINTS;
    WmUpdateGeom(wmPtr, winPtr);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmStackorderCmd --
 *
 *	This procedure is invoked to process the "wm stackorder" Tcl command.
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

static int
WmStackorderCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    TkWindow **windows, **window_ptr;
    static CONST char *optionStrings[] = {
        "isabove", "isbelow", (char *) NULL };
    enum options {
        OPT_ISABOVE, OPT_ISBELOW };
    int index;

    if ((objc != 3) && (objc != 5)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?isabove|isbelow window?");
        return TCL_ERROR;
    }

    if (objc == 3) {
        windows = TkWmStackorderToplevel(winPtr);
        if (windows == NULL) {
            Tcl_Panic("TkWmStackorderToplevel failed");
        } else {
            for (window_ptr = windows; *window_ptr ; window_ptr++) {
                Tcl_AppendElement(interp, (*window_ptr)->pathName);
            }
            ckfree((char *) windows);
            return TCL_OK;
        }
    } else {
        TkWindow *winPtr2;
        int index1=-1, index2=-1, result;

        if (TkGetWindowFromObj(interp, tkwin, objv[4], (Tk_Window *) &winPtr2)
            != TCL_OK) {
            return TCL_ERROR;
        }

        if (!Tk_IsTopLevel(winPtr2)) {
            Tcl_AppendResult(interp, "window \"", winPtr2->pathName,
                             "\" isn't a top-level window", (char *) NULL);
            return TCL_ERROR;
        }

        if (!Tk_IsMapped(winPtr)) {
            Tcl_AppendResult(interp, "window \"", winPtr->pathName,
                             "\" isn't mapped", (char *) NULL);
            return TCL_ERROR;
        }

        if (!Tk_IsMapped(winPtr2)) {
            Tcl_AppendResult(interp, "window \"", winPtr2->pathName,
                             "\" isn't mapped", (char *) NULL);
            return TCL_ERROR;
        }

        /*
         * Lookup stacking order of all toplevels that are children
         * of "." and find the position of winPtr and winPtr2
         * in the stacking order.
         */

        windows = TkWmStackorderToplevel(winPtr->mainPtr->winPtr);

        if (windows == NULL) {
            Tcl_AppendResult(interp, "TkWmStackorderToplevel failed",
                             (char *) NULL);
            return TCL_ERROR;
        } else {
            for (window_ptr = windows; *window_ptr ; window_ptr++) {
                if (*window_ptr == winPtr)
                    index1 = (window_ptr - windows);
                if (*window_ptr == winPtr2)
                    index2 = (window_ptr - windows);
            }
            if (index1 == -1)
                Tcl_Panic("winPtr window not found");
            if (index2 == -1)
                Tcl_Panic("winPtr2 window not found");

            ckfree((char *) windows);
        }

        if (Tcl_GetIndexFromObj(interp, objv[3], optionStrings, "argument", 0,
                                &index) != TCL_OK) {
            return TCL_ERROR;
        }
        if (index == OPT_ISABOVE) {
            result = index1 > index2;
        } else { /* OPT_ISBELOW */
            result = index1 < index2;
        }
        Tcl_SetIntObj(Tcl_GetObjResult(interp), result);
        return TCL_OK;
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmStateCmd --
 *
 *	This procedure is invoked to process the "wm state" Tcl command.
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

static int
WmStateCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    static CONST char *optionStrings[] = {
        "normal", "iconic", "withdrawn", "zoomed", (char *) NULL };
    enum options {
        OPT_NORMAL, OPT_ICONIC, OPT_WITHDRAWN, OPT_ZOOMED };
    int index;

    if ((objc < 3) || (objc > 4)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?state?");
        return TCL_ERROR;
    }
    if (objc == 4) {
        if (wmPtr->iconFor != NULL) {
            Tcl_AppendResult(interp, "can't change state of ",
                             Tcl_GetString(objv[2]),
                             ": it is an icon for ", Tk_PathName(wmPtr->iconFor),
                             (char *) NULL);
            return TCL_ERROR;
        }
        if (winPtr->flags & TK_EMBEDDED) {
            Tcl_AppendResult(interp, "can't change state of ",
                             winPtr->pathName, ": it is an embedded window",
                             (char *) NULL);
            return TCL_ERROR;
        }

        if (Tcl_GetIndexFromObj(interp, objv[3], optionStrings, "argument", 0,
                                &index) != TCL_OK) {
            return TCL_ERROR;
        }

        if (index == OPT_NORMAL) {
            TkpWmSetState(winPtr, NormalState);
            /*
             * This varies from 'wm deiconify' because it does not
             * force the window to be raised and receive focus
             */
        } else if (index == OPT_ICONIC) {
            if (Tk_Attributes((Tk_Window) winPtr)->override_redirect) {
                Tcl_AppendResult(interp, "can't iconify \"",
                                 winPtr->pathName,
                                 "\": override-redirect flag is set",
                                 (char *) NULL);
                return TCL_ERROR;
            }
            if (wmPtr->master != None) {
                Tcl_AppendResult(interp, "can't iconify \"",
                                 winPtr->pathName,
                                 "\": it is a transient", (char *) NULL);
                return TCL_ERROR;
            }
            TkpWmSetState(winPtr, IconicState);
        } else if (index == OPT_WITHDRAWN) {
            TkpWmSetState(winPtr, WithdrawnState);
        } else { /* OPT_ZOOMED */
            TkpWmSetState(winPtr, ZoomState);
        }
    } else {
        if (wmPtr->iconFor != NULL) {
            Tcl_SetResult(interp, "icon", TCL_STATIC);
        } else {
	    if (wmPtr->hints.initial_state == NormalState ||
		    wmPtr->hints.initial_state == ZoomState) {
		wmPtr->hints.initial_state = (TkMacOSXIsWindowZoomed(winPtr) ?
			ZoomState : NormalState);
	    }
            switch (wmPtr->hints.initial_state) {
                case NormalState:
                    Tcl_SetResult(interp, "normal", TCL_STATIC);
                    break;
                case IconicState:
                    Tcl_SetResult(interp, "iconic", TCL_STATIC);
                    break;
                case WithdrawnState:
                    Tcl_SetResult(interp, "withdrawn", TCL_STATIC);
                    break;
                case ZoomState:
                    Tcl_SetResult(interp, "zoomed", TCL_STATIC);
                    break;
            }
        }
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmTitleCmd --
 *
 *	This procedure is invoked to process the "wm title" Tcl command.
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

static int
WmTitleCmd(tkwin, winPtr, interp, objc, objv)
Tk_Window tkwin;		/* Main window of the application. */
TkWindow *winPtr;           /* Toplevel to work with */
Tcl_Interp *interp;		/* Current interpreter. */
int objc;			/* Number of arguments. */
Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    char *argv3;
    int length;

    if (objc > 4) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?newTitle?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        Tcl_SetResult(interp,
                      (char *) ((wmPtr->titleUid != NULL) ? wmPtr->titleUid : winPtr->nameUid),
                      TCL_STATIC);
        return TCL_OK;
    } else {
        argv3 = Tcl_GetStringFromObj(objv[3], &length);
        wmPtr->titleUid = Tk_GetUid(argv3);
        if (!(wmPtr->flags & WM_NEVER_MAPPED) && !Tk_IsEmbedded(winPtr)) {
            TkSetWMName(winPtr, wmPtr->titleUid);
        }
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmTransientCmd --
 *
 *	This procedure is invoked to process the "wm transient" Tcl command.
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

static int
WmTransientCmd(tkwin, winPtr, interp, objc, objv)
    Tk_Window tkwin;		/* Main window of the application. */
    TkWindow *winPtr;		/* Toplevel to work with */
    Tcl_Interp *interp;		/* Current interpreter. */
    int objc;			/* Number of arguments. */
    Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;
    Tk_Window master;
    WmInfo *wmPtr2;
    char *argv3;
    int length;
    int oldAttributes = wmPtr->attributes;

    if ((objc != 3) && (objc != 4)) {
        Tcl_WrongNumArgs(interp, 2, objv, "window ?master?");
        return TCL_ERROR;
    }
    if (objc == 3) {
        if (wmPtr->master != None) {
            Tcl_SetResult(interp, wmPtr->masterWindowName, TCL_STATIC);
        }
        return TCL_OK;
    }
    if (Tcl_GetString(objv[3])[0] == '\0') {
        wmPtr->master = None;
        if (wmPtr->masterWindowName != NULL) {
            ckfree(wmPtr->masterWindowName);
        }
        wmPtr->masterWindowName = NULL;
	/* XXX UpdateWrapper */
	if (Tk_Attributes((Tk_Window) winPtr)->override_redirect) {
	    wmPtr->macClass = kSimpleWindowClass;
	    wmPtr->attributes = kWindowNoActivatesAttribute;
	} else {
	    wmPtr->macClass = kDocumentWindowClass;
	    wmPtr->attributes = kWindowStandardDocumentAttributes;
	}
    } else {
        if (TkGetWindowFromObj(interp, tkwin, objv[3], &master) != TCL_OK) {
            return TCL_ERROR;
        }
        Tk_MakeWindowExist(master);

        if (wmPtr->iconFor != NULL) {
            Tcl_AppendResult(interp, "can't make \"",
                             Tcl_GetString(objv[2]),
                             "\" a transient: it is an icon for ",
                             Tk_PathName(wmPtr->iconFor),
                             (char *) NULL);
            return TCL_ERROR;
        }

        wmPtr2 = ((TkWindow *) master)->wmInfoPtr;

        /* Under some circumstances, wmPtr2 is NULL here */
        if (wmPtr2 != NULL && wmPtr2->iconFor != NULL) {
            Tcl_AppendResult(interp, "can't make \"",
                             Tcl_GetString(objv[3]),
                             "\" a master: it is an icon for ",
                             Tk_PathName(wmPtr2->iconFor),
                             (char *) NULL);
            return TCL_ERROR;
        }

	if ((TkWindow *) master == winPtr) {
	    Tcl_AppendResult(interp, "can't make \"", Tk_PathName(winPtr),
		    "\" its own master", NULL);
	    return TCL_ERROR;
	}
	
        argv3 = Tcl_GetStringFromObj(objv[3], &length);
        wmPtr->master = Tk_WindowId(master);
        wmPtr->masterWindowName = ckalloc((unsigned) length+1);
        strcpy(wmPtr->masterWindowName, argv3);
	/* XXX UpdateWrapper */
	if (Tk_Attributes((Tk_Window) winPtr)->override_redirect) {
	    wmPtr->macClass = kSimpleWindowClass;
	    wmPtr->attributes = kWindowNoActivatesAttribute;
	} else {
	    wmPtr->macClass = kFloatingWindowClass;
	    wmPtr->attributes = kWindowStandardFloatingAttributes;
	}
    }
    ApplyWindowAttributeChanges(winPtr, wmPtr->attributes, oldAttributes, 0);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * WmWithdrawCmd --
 *
 *	This procedure is invoked to process the "wm withdraw" Tcl command.
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

static int
WmWithdrawCmd(tkwin, winPtr, interp, objc, objv)
    Tk_Window tkwin;		/* Main window of the application. */
    TkWindow *winPtr;           /* Toplevel to work with */
    Tcl_Interp *interp;		/* Current interpreter. */
    int objc;			/* Number of arguments. */
    Tcl_Obj *CONST objv[];	/* Argument objects. */
{
    register WmInfo *wmPtr = winPtr->wmInfoPtr;

    if (objc != 3) {
        Tcl_WrongNumArgs(interp, 2, objv, "window");
        return TCL_ERROR;
    }
    if (wmPtr->iconFor != NULL) {
        Tcl_AppendResult(interp, "can't withdraw ", Tcl_GetString(objv[2]),
                         ": it is an icon for ", Tk_PathName(wmPtr->iconFor),
                         (char *) NULL);
        return TCL_ERROR;
    }
    TkpWmSetState(winPtr, WithdrawnState);
    return TCL_OK;
}

/*
 * Invoked by those wm subcommands that affect geometry.
 * Schedules a geometry update.
 */
static void
WmUpdateGeom(wmPtr, winPtr)
WmInfo *wmPtr;
TkWindow *winPtr;
{
    if (!(wmPtr->flags & (WM_UPDATE_PENDING|WM_NEVER_MAPPED))) {
        Tcl_DoWhenIdle(UpdateGeometryInfo, (ClientData) winPtr);
        wmPtr->flags |= WM_UPDATE_PENDING;
    }
}
/*
 *----------------------------------------------------------------------
 *
 * Tk_SetGrid --
 *
 *	This procedure is invoked by a widget when it wishes to set a grid
 *	coordinate system that controls the size of a top-level window.
 *	It provides a C interface equivalent to the "wm grid" command and
 *	is usually asscoiated with the -setgrid option.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Grid-related information will be passed to the window manager, so
 *	that the top-level window associated with tkwin will resize on
 *	even grid units.  If some other window already controls gridding
 *	for the top-level window then this procedure call has no effect.
 *
 *----------------------------------------------------------------------
 */

void
Tk_SetGrid(
    Tk_Window tkwin,		/* Token for window.  New window mgr info
				 * will be posted for the top-level window
				 * associated with this window. */
    int reqWidth,		/* Width (in grid units) corresponding to
				 * the requested geometry for tkwin. */
    int reqHeight,		/* Height (in grid units) corresponding to
				 * the requested geometry for tkwin. */
    int widthInc, int heightInc)/* Pixel increments corresponding to a
				 * change of one grid unit. */
{
    TkWindow *winPtr = (TkWindow *) tkwin;
    WmInfo *wmPtr;

    /*
     * Find the top-level window for tkwin, plus the window manager
     * information.
     */

    while (!(winPtr->flags & TK_TOP_LEVEL)) {
	winPtr = winPtr->parentPtr;
    }
    wmPtr = winPtr->wmInfoPtr;

    if ((wmPtr->gridWin != NULL) && (wmPtr->gridWin != tkwin)) {
	return;
    }

    if ((wmPtr->reqGridWidth == reqWidth)
	    && (wmPtr->reqGridHeight == reqHeight)
	    && (wmPtr->widthInc == widthInc)
	    && (wmPtr->heightInc == heightInc)
	    && ((wmPtr->sizeHintsFlags & (PBaseSize|PResizeInc))
		    == (PBaseSize|PResizeInc))) {
	return;
    }

    /*
     * If gridding was previously off, then forget about any window
     * size requests made by the user or via "wm geometry":  these are
     * in pixel units and there's no easy way to translate them to
     * grid units since the new requested size of the top-level window in
     * pixels may not yet have been registered yet (it may filter up
     * the hierarchy in DoWhenIdle handlers).  However, if the window
     * has never been mapped yet then just leave the window size alone:
     * assume that it is intended to be in grid units but just happened
     * to have been specified before this procedure was called.
     */

    if ((wmPtr->gridWin == NULL) && !(wmPtr->flags & WM_NEVER_MAPPED)) {
	wmPtr->width = -1;
	wmPtr->height = -1;
    }

    /* 
     * Set the new gridding information, and start the process of passing
     * all of this information to the window manager.
     */

    wmPtr->gridWin = tkwin;
    wmPtr->reqGridWidth = reqWidth;
    wmPtr->reqGridHeight = reqHeight;
    wmPtr->widthInc = widthInc;
    wmPtr->heightInc = heightInc;
    wmPtr->sizeHintsFlags |= PBaseSize|PResizeInc;
    wmPtr->flags |= WM_UPDATE_SIZE_HINTS;
    if (!(wmPtr->flags & (WM_UPDATE_PENDING|WM_NEVER_MAPPED))) {
	Tcl_DoWhenIdle(UpdateGeometryInfo, (ClientData) winPtr);
	wmPtr->flags |= WM_UPDATE_PENDING;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * Tk_UnsetGrid --
 *
 *	This procedure cancels the effect of a previous call
 *	to Tk_SetGrid.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	If tkwin currently controls gridding for its top-level window,
 *	gridding is cancelled for that top-level window;  if some other
 *	window controls gridding then this procedure has no effect.
 *
 *----------------------------------------------------------------------
 */

void
Tk_UnsetGrid(
    Tk_Window tkwin)		/* Token for window that is currently
				 * controlling gridding. */
{
    TkWindow *winPtr = (TkWindow *) tkwin;
    WmInfo *wmPtr;

    /*
     * Find the top-level window for tkwin, plus the window manager
     * information.
     */

    while (!(winPtr->flags & TK_TOP_LEVEL)) {
	winPtr = winPtr->parentPtr;
    }
    wmPtr = winPtr->wmInfoPtr;
    if (tkwin != wmPtr->gridWin) {
	return;
    }

    wmPtr->gridWin = NULL;
    wmPtr->sizeHintsFlags &= ~(PBaseSize|PResizeInc);
    if (wmPtr->width != -1) {
	wmPtr->width = winPtr->reqWidth + (wmPtr->width
		- wmPtr->reqGridWidth)*wmPtr->widthInc;
	wmPtr->height = winPtr->reqHeight + (wmPtr->height
		- wmPtr->reqGridHeight)*wmPtr->heightInc;
    }
    wmPtr->widthInc = 1;
    wmPtr->heightInc = 1;

    wmPtr->flags |= WM_UPDATE_SIZE_HINTS;
    if (!(wmPtr->flags & (WM_UPDATE_PENDING|WM_NEVER_MAPPED))) {
	Tcl_DoWhenIdle(UpdateGeometryInfo, (ClientData) winPtr);
	wmPtr->flags |= WM_UPDATE_PENDING;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TopLevelEventProc --
 *
 *	This procedure is invoked when a top-level (or other externally-
 *	managed window) is restructured in any way.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Tk's internal data structures for the window get modified to
 *	reflect the structural change.
 *
 *----------------------------------------------------------------------
 */

static void
TopLevelEventProc(
    ClientData clientData,		/* Window for which event occurred. */
    XEvent *eventPtr)			/* Event that just happened. */
{
    TkWindow *winPtr = (TkWindow *) clientData;

    winPtr->wmInfoPtr->flags |= WM_VROOT_OFFSET_STALE;
    if (eventPtr->type == DestroyNotify) {
	Tk_ErrorHandler handler;

	if (!(winPtr->flags & TK_ALREADY_DEAD)) {
	    /*
	     * A top-level window was deleted externally (e.g., by the window
	     * manager).  This is probably not a good thing, but cleanup as
	     * best we can.  The error handler is needed because
	     * Tk_DestroyWindow will try to destroy the window, but of course
	     * it's already gone.
	     */
    
	    handler = Tk_CreateErrorHandler(winPtr->display, -1, -1, -1,
		    (Tk_ErrorProc *) NULL, (ClientData) NULL);
	    Tk_DestroyWindow((Tk_Window) winPtr);
	    Tk_DeleteErrorHandler(handler);
	}
	if (wmTracing) {
	    printf("TopLevelEventProc: %s deleted\n", winPtr->pathName);
	}
    } else if (eventPtr->type == ReparentNotify) {
	Tcl_Panic("recieved unwanted reparent event");
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TopLevelReqProc --
 *
 *	This procedure is invoked by the geometry manager whenever
 *	the requested size for a top-level window is changed.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Arrange for the window to be resized to satisfy the request
 *	(this happens as a when-idle action).
 *
 *----------------------------------------------------------------------
 */

	/* ARGSUSED */
static void
TopLevelReqProc(
    ClientData dummy,			/* Not used. */
    Tk_Window tkwin)			/* Information about window. */
{
    TkWindow *winPtr = (TkWindow *) tkwin;
    WmInfo *wmPtr;

    wmPtr = winPtr->wmInfoPtr;
    wmPtr->flags |= WM_UPDATE_SIZE_HINTS;
    if (!(wmPtr->flags & (WM_UPDATE_PENDING|WM_NEVER_MAPPED))) {
	Tcl_DoWhenIdle(UpdateGeometryInfo, (ClientData) winPtr);
	wmPtr->flags |= WM_UPDATE_PENDING;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * UpdateGeometryInfo --
 *
 *	This procedure is invoked when a top-level window is first
 *	mapped, and also as a when-idle procedure, to bring the
 *	geometry and/or position of a top-level window back into
 *	line with what has been requested by the user and/or widgets.
 *	This procedure doesn't return until the window manager has
 *	responded to the geometry change.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The window's size and location may change, unless the WM prevents
 *	that from happening.
 *
 *----------------------------------------------------------------------
 */

static void
UpdateGeometryInfo(
    ClientData clientData)		/* Pointer to the window's record. */
{
    TkWindow *winPtr = (TkWindow *) clientData;
    WmInfo *wmPtr = winPtr->wmInfoPtr;
    int x, y, width, height;
    int min, max;
    unsigned long serial;

    wmPtr->flags &= ~WM_UPDATE_PENDING;

    /*
     * Compute the new size for the top-level window.  See the
     * user documentation for details on this, but the size
     * requested depends on (a) the size requested internally
     * by the window's widgets, (b) the size requested by the
     * user in a "wm geometry" command or via wm-based interactive
     * resizing (if any), and (c) whether or not the window is
     * gridded.  Don't permit sizes <= 0 because this upsets
     * the X server.
     */

    if (wmPtr->width == -1) {
	width = winPtr->reqWidth;
    } else if (wmPtr->gridWin != NULL) {
	width = winPtr->reqWidth
		+ (wmPtr->width - wmPtr->reqGridWidth)*wmPtr->widthInc;
    } else {
	width = wmPtr->width;
    }
    if (width <= 0) {
	width = 1;
    }

    /*
     * Account for window max/min width
     */

    if (wmPtr->gridWin != NULL) {
	min = winPtr->reqWidth
		+ (wmPtr->minWidth - wmPtr->reqGridWidth)*wmPtr->widthInc;
	if (wmPtr->maxWidth > 0) {
	    max = winPtr->reqWidth
		    + (wmPtr->maxWidth - wmPtr->reqGridWidth)*wmPtr->widthInc;
	} else {
	    max = 0;
	}
    } else {
	min = wmPtr->minWidth;
	max = wmPtr->maxWidth;
    }
    if (width < min) {
	width = min;
    } else if ((max > 0) && (width > max)) {
	width = max;
    }

    if (wmPtr->height == -1) {
	height = winPtr->reqHeight;
    } else if (wmPtr->gridWin != NULL) {
	height = winPtr->reqHeight
		+ (wmPtr->height - wmPtr->reqGridHeight)*wmPtr->heightInc;
    } else {
	height = wmPtr->height;
    }
    if (height <= 0) {
	height = 1;
    }

    /*
     * Account for window max/min height
     */

    if (wmPtr->gridWin != NULL) {
	min = winPtr->reqHeight
		+ (wmPtr->minHeight - wmPtr->reqGridHeight)*wmPtr->heightInc;
	if (wmPtr->maxHeight > 0) {
	    max = winPtr->reqHeight
		    + (wmPtr->maxHeight-wmPtr->reqGridHeight)*wmPtr->heightInc;
	} else {
	    max = 0;
	}
    } else {
	min = wmPtr->minHeight;
	max = wmPtr->maxHeight;
    }
    if (height < min) {
	height = min;
    } else if ((max > 0) && (height > max)) {
	height = max;
    }

    /*
     * Compute the new position for the upper-left pixel of the window's
     * decorative frame.  This is tricky, because we need to include the
     * border widths supplied by a reparented parent in this calculation,
     * but can't use the parent's current overall size since that may
     * change as a result of this code.
     */

    if (wmPtr->flags & WM_NEGATIVE_X) {
	x = wmPtr->vRootWidth - wmPtr->x
	    - (width + (wmPtr->parentWidth - winPtr->changes.width));
    } else {
	x =  wmPtr->x;
    }
    if (wmPtr->flags & WM_NEGATIVE_Y) {
	y = wmPtr->vRootHeight - wmPtr->y
	    - (height + (wmPtr->parentHeight - winPtr->changes.height));
    } else {
	y =  wmPtr->y;
    }

    /*
     * If the window's size is going to change and the window is
     * supposed to not be resizable by the user, then we have to
     * update the size hints.  There may also be a size-hint-update
     * request pending from somewhere else, too.
     */

    if (((width != winPtr->changes.width)
	    || (height != winPtr->changes.height))
	    && (wmPtr->gridWin == NULL)
	    && ((wmPtr->sizeHintsFlags & (PMinSize|PMaxSize)) == 0)) {
	wmPtr->flags |= WM_UPDATE_SIZE_HINTS;
    }
    if (wmPtr->flags & WM_UPDATE_SIZE_HINTS) {
	UpdateSizeHints(winPtr);
    }

    /*
     * Reconfigure the window if it isn't already configured correctly.
     * A few tricky points:
     *
     * 1. If the window is embedded and the container is also in this
     *    process, don't actually reconfigure the window; just pass the
     *    desired size on to the container.  Also, zero out any position
     *    information, since embedded windows are not allowed to move.
     * 2. Sometimes the window manager will give us a different size
     *    than we asked for (e.g. mwm has a minimum size for windows), so
     *    base the size check on what we *asked for* last time, not what we
     *    got.
     * 3. Don't move window unless a new position has been requested for
     *	  it.  This is because of "features" in some window managers (e.g.
     *    twm, as of 4/24/91) where they don't interpret coordinates
     *    according to ICCCM.  Moving a window to its current location may
     *    cause it to shift position on the screen.
     */

    if (Tk_IsEmbedded(winPtr)) {
        TkWindow *contWinPtr;

	contWinPtr = TkpGetOtherWindow(winPtr);
	
	/*
	 * NOTE: Here we should handle out of process embedding.
	 */

	if (contWinPtr != NULL) {	    
	    /*
	     * This window is embedded and the container is also in this
	     * process, so we don't need to do anything special about the
	     * geometry, except to make sure that the desired size is known
	     * by the container.  Also, zero out any position information,
	     * since embedded windows are not allowed to move.
	     */

	    wmPtr->x = wmPtr->y = 0;
	    wmPtr->flags &= ~(WM_NEGATIVE_X|WM_NEGATIVE_Y);
	    Tk_GeometryRequest((Tk_Window) contWinPtr, width, height);
        }
	return;
    }
    serial = NextRequest(winPtr->display);
    if (wmPtr->flags & WM_MOVE_PENDING) {
	wmPtr->configWidth = width;
	wmPtr->configHeight = height;
	if (wmTracing) {
	    printf(
		"UpdateGeometryInfo moving to %d %d, resizing to %d x %d,\n",
		    x, y, width, height);
	}
	Tk_MoveResizeWindow((Tk_Window) winPtr, x, y, (unsigned) width,
		(unsigned) height);
    } else if ((width != wmPtr->configWidth)
	    || (height != wmPtr->configHeight)) {
	wmPtr->configWidth = width;
	wmPtr->configHeight = height;
	if (wmTracing) {
	    printf("UpdateGeometryInfo resizing to %d x %d\n", width, height);
	}
	Tk_ResizeWindow((Tk_Window) winPtr, (unsigned) width,
		(unsigned) height);
    } else {
	return;
    }
}

/*
 *--------------------------------------------------------------
 *
 * UpdateSizeHints --
 *
 *	This procedure is called to update the window manager's
 *	size hints information from the information in a WmInfo
 *	structure.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Properties get changed for winPtr.
 *
 *--------------------------------------------------------------
 */

static void
UpdateSizeHints(
    TkWindow *winPtr)
{
    WmInfo *wmPtr = winPtr->wmInfoPtr;

    wmPtr->flags &= ~WM_UPDATE_SIZE_HINTS;

    return;
}

/*
 *--------------------------------------------------------------
 *
 * ParseGeometry --
 *
 *	This procedure parses a geometry string and updates
 *	information used to control the geometry of a top-level
 *	window.
 *
 * Results:
 *	A standard Tcl return value, plus an error message in
 *	the interp's result if an error occurs.
 *
 * Side effects:
 *	The size and/or location of winPtr may change.
 *
 *--------------------------------------------------------------
 */

static int
ParseGeometry(
    Tcl_Interp *interp,		/* Used for error reporting. */
    char *string,		/* String containing new geometry.  Has the
				 * standard form "=wxh+x+y". */
    TkWindow *winPtr)		/* Pointer to top-level window whose
				 * geometry is to be changed. */
{
    WmInfo *wmPtr = winPtr->wmInfoPtr;
    int x, y, width, height, flags;
    char *end;
    char *p = string;

    /*
     * The leading "=" is optional.
     */

    if (*p == '=') {
	p++;
    }

    /*
     * Parse the width and height, if they are present.  Don't
     * actually update any of the fields of wmPtr until we've
     * successfully parsed the entire geometry string.
     */

    width = wmPtr->width;
    height = wmPtr->height;
    x = wmPtr->x;
    y = wmPtr->y;
    flags = wmPtr->flags;
    if (isdigit(UCHAR(*p))) {
	width = strtoul(p, &end, 10);
	p = end;
	if (*p != 'x') {
	    goto error;
	}
	p++;
	if (!isdigit(UCHAR(*p))) {
	    goto error;
	}
	height = strtoul(p, &end, 10);
	p = end;
    }

    /*
     * Parse the X and Y coordinates, if they are present.
     */

    if (*p != '\0') {
	flags &= ~(WM_NEGATIVE_X | WM_NEGATIVE_Y);
	if (*p == '-') {
	    flags |= WM_NEGATIVE_X;
	} else if (*p != '+') {
	    goto error;
	}
	p++;
	if (!isdigit(UCHAR(*p)) && (*p != '-')) {
	    goto error;
	}
	x = strtol(p, &end, 10);
	p = end;
	if (*p == '-') {
	    flags |= WM_NEGATIVE_Y;
	} else if (*p != '+') {
	    goto error;
	}
	p++;
	if (!isdigit(UCHAR(*p)) && (*p != '-')) {
	    goto error;
	}
	y = strtol(p, &end, 10);
	if (*end != '\0') {
	    goto error;
	}

	/*
	 * Assume that the geometry information came from the user,
	 * unless an explicit source has been specified.  Otherwise
	 * most window managers assume that the size hints were
	 * program-specified and they ignore them.
	 */

	if ((wmPtr->sizeHintsFlags & (USPosition|PPosition)) == 0) {
	    wmPtr->sizeHintsFlags |= USPosition;
	    flags |= WM_UPDATE_SIZE_HINTS;
	}
    }

    /*
     * Everything was parsed OK.  Update the fields of *wmPtr and
     * arrange for the appropriate information to be percolated out
     * to the window manager at the next idle moment.
     */

    wmPtr->width = width;
    wmPtr->height = height;
    if ((x != wmPtr->x) || (y != wmPtr->y)
	    || ((flags & (WM_NEGATIVE_X|WM_NEGATIVE_Y))
		    != (wmPtr->flags & (WM_NEGATIVE_X|WM_NEGATIVE_Y)))) {
	wmPtr->x = x;
	wmPtr->y = y;
	flags |= WM_MOVE_PENDING;
    }
    wmPtr->flags = flags;

    if (!(wmPtr->flags & (WM_UPDATE_PENDING|WM_NEVER_MAPPED))) {
	Tcl_DoWhenIdle(UpdateGeometryInfo, (ClientData) winPtr);
	wmPtr->flags |= WM_UPDATE_PENDING;
    }
    return TCL_OK;

  error:
    Tcl_AppendResult(interp, "bad geometry specifier \"", string, "\"", NULL);
    return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * Tk_GetRootCoords --
 *
 *	Given a token for a window, this procedure traces through the
 *	window's lineage to find the (virtual) root-window coordinates
 *	corresponding to point (0,0) in the window.
 *
 * Results:
 *	The locations pointed to by xPtr and yPtr are filled in with
 *	the root coordinates of the (0,0) point in tkwin.  If a virtual
 *	root window is in effect for the window, then the coordinates
 *	in the virtual root are returned.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

void
Tk_GetRootCoords(
    Tk_Window tkwin,		/* Token for window. */
    int *xPtr,			/* Where to store x-displacement of (0,0). */
    int *yPtr)			/* Where to store y-displacement of (0,0). */
{
    int x, y;
    TkWindow *winPtr = (TkWindow *) tkwin;

    /*
     * Search back through this window's parents all the way to a
     * top-level window, combining the offsets of each window within
     * its parent.
     */

    x = y = 0;
    while (1) {
	x += winPtr->changes.x + winPtr->changes.border_width;
	y += winPtr->changes.y + winPtr->changes.border_width;
	if (winPtr->flags & TK_TOP_LEVEL) {
	    if (!(Tk_IsEmbedded(winPtr))) {
	    	x += winPtr->wmInfoPtr->xInParent;
	    	y += winPtr->wmInfoPtr->yInParent;
	    	break;	    	
	    } else {
	        TkWindow *otherPtr;
		
		otherPtr = TkpGetOtherWindow(winPtr);
		if (otherPtr != NULL) {
		    /*
		     * The container window is in the same application.
		     * Query its coordinates.
		     */
		    winPtr = otherPtr;
		    
		    /*
		     * Remember to offset by the container window here,
		     * since at the end of this if branch, we will
		     * pop out to the container's parent...
		     */
		     
	            x += winPtr->changes.x + winPtr->changes.border_width;
	            y += winPtr->changes.y + winPtr->changes.border_width;
		    
		} else {
		    Point theOffset;
		    
		    if (gMacEmbedHandler->getOffsetProc != NULL) {
		        /*
		         * We do not require that the changes.x & changes.y for 
		         * a non-Tk master window be kept up to date.  So we
		         * first subtract off the possibly bogus values that have
		         * been added on at the top of this pass through the loop,
		         * and then call out to the getOffsetProc to give us
		         * the correct offset.
		         */
		         
	                x -= winPtr->changes.x + winPtr->changes.border_width;
	                y -= winPtr->changes.y + winPtr->changes.border_width;
	                
		        gMacEmbedHandler->getOffsetProc((Tk_Window) winPtr, &theOffset);
		        
		        x += theOffset.h;
		        y += theOffset.v;
		    }
		    break;
		}
	    }
	}
	winPtr = winPtr->parentPtr;
    }
    *xPtr = x;
    *yPtr = y;
}

/*
 *----------------------------------------------------------------------
 *
 * Tk_CoordsToWindow --
 *
 *	This is a Macintosh specific implementation of this function.
 *	Given the root coordinates of a point, this procedure returns
 *	the token for the top-most window covering that point, if
 *	there exists such a window in this application.
 *
 * Results:
 *	The return result is either a token for the window corresponding
 *	to rootX and rootY, or else NULL to indicate that there is no such
 *	window.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

Tk_Window
Tk_CoordsToWindow(
    int rootX, int rootY,	/* Coordinates of point in root window.  If
				 * a virtual-root window manager is in use,
				 * these coordinates refer to the virtual
				 * root, not the real root. */
    Tk_Window tkwin)		/* Token for any window in application;
				 * used to identify the display. */
{
    WindowPtr whichWin;
    Point where;
    Window rootChild;
    TkWindow *winPtr, *childPtr;
    TkWindow *nextPtr;		/* Coordinates of highest child found so
				 * far that contains point. */
    int x, y;			/* Coordinates in winPtr. */
    int tmpx, tmpy, bd;
    TkDisplay *dispPtr;

    /*
     * Step 1: find the top-level window that contains the desired point.
     */
     
    where.h = rootX;
    where.v = rootY;
    FindWindow(where, &whichWin);
    if (whichWin == NULL) {
	return NULL;
    }
    rootChild = TkMacOSXGetXWindow(whichWin);
    dispPtr = TkGetDisplayList();
    winPtr = (TkWindow *) Tk_IdToWindow(dispPtr->display, rootChild);
    if (winPtr == NULL) {
        return NULL;
    }

    /*
     * Step 2: work down through the hierarchy underneath this window.
     * At each level, scan through all the children to find the highest
     * one in the stacking order that contains the point.  Then repeat
     * the whole process on that child.
     */

    x = rootX - winPtr->wmInfoPtr->xInParent;
    y = rootY - winPtr->wmInfoPtr->yInParent;
    while (1) {
	x -= winPtr->changes.x;
	y -= winPtr->changes.y;
	nextPtr = NULL;
	
	/*
	 * Container windows cannot have children.  So if it is a container,
	 * look there, otherwise inspect the children.
	 */
	 
	if (Tk_IsContainer(winPtr)) {
	    childPtr = TkpGetOtherWindow(winPtr);
	    if (childPtr != NULL) {
		if (Tk_IsMapped(childPtr)) {
	            tmpx = x - childPtr->changes.x;
	            tmpy = y - childPtr->changes.y;
	            bd = childPtr->changes.border_width;
	    	          
	            if ((tmpx >= -bd) && (tmpy >= -bd)
		        && (tmpx < (childPtr->changes.width + bd))
		        && (tmpy < (childPtr->changes.height + bd))) {
		        nextPtr = childPtr;
	            }
	    	}
	    }
	    

	    /*
	     * NOTE: Here we should handle out of process embedding.
	     */
	
	} else {
	    for (childPtr = winPtr->childList; childPtr != NULL;
		    childPtr = childPtr->nextPtr) {
	        if (!Tk_IsMapped(childPtr) ||
			(childPtr->flags & TK_TOP_LEVEL)) {
		    continue;
	        }
	        tmpx = x - childPtr->changes.x;
	        tmpy = y - childPtr->changes.y;
	        bd = childPtr->changes.border_width;
	        if ((tmpx >= -bd) && (tmpy >= -bd)
		        && (tmpx < (childPtr->changes.width + bd))
		        && (tmpy < (childPtr->changes.height + bd))) {
		    nextPtr = childPtr;
	        }
	    }
	}
	if (nextPtr == NULL) {
	    break;
	}
	winPtr = nextPtr;
    }
    return (Tk_Window) winPtr;
}

/*
 *----------------------------------------------------------------------
 *
 * Tk_TopCoordsToWindow --
 *
 *	Given a Tk Window, and coordinates of a point relative to that window
 *      this procedure returns the top-most child of the window (excluding
 *      toplevels) covering that point, if there exists such a window in this
 *	application.
 *	It also sets newX, and newY to the coords of the point relative to the
 *      window returned.
 *
 * Results:
 *	The return result is either a token for the window corresponding
 *	to rootX and rootY, or else NULL to indicate that there is no such
 *	window.  newX and newY are also set to the coords of the point relative
 *      to the returned window.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

Tk_Window
Tk_TopCoordsToWindow(
    Tk_Window tkwin,		/* Token for a Tk Window which defines the;
				 * coordinates for rootX & rootY */
    int rootX, int rootY,	/* Coordinates of a point in tkWin. */
    int *newX, int *newY)	/* Coordinates of point in the upperMost child of
                                 * tkWin containing (rootX,rootY) */
{
    TkWindow *winPtr, *childPtr;
    TkWindow *nextPtr;		/* Coordinates of highest child found so
				 * far that contains point. */
    int x, y;			/* Coordinates in winPtr. */
    Window *children;		/* Children of winPtr, or NULL. */

    winPtr = (TkWindow *) tkwin;
    x = rootX;
    y = rootY;
    while (1) {
	nextPtr = NULL;
	children = NULL;

	/*
	 * Container windows cannot have children.  So if it is a container,
	 * look there, otherwise inspect the children.
	 */

	if (Tk_IsContainer(winPtr)) {
	    childPtr = TkpGetOtherWindow(winPtr);
	    if (childPtr != NULL) {
		if (Tk_IsMapped(childPtr) && 
	    	         (x > childPtr->changes.x && 
	    	             x < childPtr->changes.x +
				 childPtr->changes.width) &&
	    	         (y > childPtr->changes.y &&
	    	             y < childPtr->changes.y +
				 childPtr->changes.height)) {
	    	    nextPtr = childPtr;
	    	}
	    }

	    /*
	     * NOTE: Here we should handle out of process embedding.
	     */
	} else {
	    for (childPtr = winPtr->childList; childPtr != NULL;
					   childPtr = childPtr->nextPtr) {
	        if (!Tk_IsMapped(childPtr) ||
			(childPtr->flags & TK_TOP_LEVEL)) {
		    continue;
	        }
	        if (x < childPtr->changes.x || y < childPtr->changes.y) {
		    continue;
	        }
	        if (x > childPtr->changes.x + childPtr->changes.width ||
		        y > childPtr->changes.y + childPtr->changes.height) {
		    continue;
	        }
	        nextPtr = childPtr;
	    }
	}
	if (nextPtr == NULL) {
	    break;
	}
	winPtr = nextPtr;
	x -= winPtr->changes.x;
	y -= winPtr->changes.y;
    }
    *newX = x;
    *newY = y;
    return (Tk_Window) winPtr;
}

/*
 *----------------------------------------------------------------------
 *
 * UpdateVRootGeometry --
 *
 *	This procedure is called to update all the virtual root
 *	geometry information in wmPtr.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The vRootX, vRootY, vRootWidth, and vRootHeight fields in
 *	wmPtr are filled with the most up-to-date information.
 *
 *----------------------------------------------------------------------
 */

static void
UpdateVRootGeometry(
    WmInfo *wmPtr)		/* Window manager information to be
				 * updated.  The wmPtr->vRoot field must
				 * be valid. */
{
    TkWindow *winPtr = wmPtr->winPtr;
    unsigned int bd, dummy;
    Window dummy2;
    Status status;
    Tk_ErrorHandler handler;

    /*
     * If this isn't a virtual-root window manager, just return information
     * about the screen.
     */

    wmPtr->flags &= ~WM_VROOT_OFFSET_STALE;
    if (wmPtr->vRoot == None) {
	noVRoot:
	wmPtr->vRootX = wmPtr->vRootY = 0;
	wmPtr->vRootWidth = DisplayWidth(winPtr->display, winPtr->screenNum);
	wmPtr->vRootHeight = DisplayHeight(winPtr->display, winPtr->screenNum);
	return;
    }

    /*
     * Refresh the virtual root information if it's out of date.
     */

    handler = Tk_CreateErrorHandler(winPtr->display, -1, -1, -1,
	    (Tk_ErrorProc *) NULL, (ClientData) NULL);
    status = XGetGeometry(winPtr->display, wmPtr->vRoot,
	    &dummy2, &wmPtr->vRootX, &wmPtr->vRootY,
	    &wmPtr->vRootWidth, &wmPtr->vRootHeight, &bd, &dummy);
    if (wmTracing) {
	printf("UpdateVRootGeometry: x = %d, y = %d, width = %d, ",
		wmPtr->vRootX, wmPtr->vRootY, wmPtr->vRootWidth);
	printf("height = %d, status = %d\n", wmPtr->vRootHeight, status);
    }
    Tk_DeleteErrorHandler(handler);
    if (status == 0) {
	/*
	 * The virtual root is gone!  Pretend that it never existed.
	 */

	wmPtr->vRoot = None;
	goto noVRoot;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * Tk_GetVRootGeometry --
 *
 *	This procedure returns information about the virtual root
 *	window corresponding to a particular Tk window.
 *
 * Results:
 *	The values at xPtr, yPtr, widthPtr, and heightPtr are set
 *	with the offset and dimensions of the root window corresponding
 *	to tkwin.  If tkwin is being managed by a virtual root window
 *	manager these values correspond to the virtual root window being
 *	used for tkwin;  otherwise the offsets will be 0 and the
 *	dimensions will be those of the screen.
 *
 * Side effects:
 *	Vroot window information is refreshed if it is out of date.
 *
 *----------------------------------------------------------------------
 */

void
Tk_GetVRootGeometry(
    Tk_Window tkwin,		/* Window whose virtual root is to be
				 * queried. */
    int *xPtr, int *yPtr,	/* Store x and y offsets of virtual root
				 * here. */
    int *widthPtr,		/* Store dimensions of virtual root here. */
    int *heightPtr)
{
    WmInfo *wmPtr;
    TkWindow *winPtr = (TkWindow *) tkwin;

    /*
     * Find the top-level window for tkwin, and locate the window manager
     * information for that window.
     */

    while (!(winPtr->flags & TK_TOP_LEVEL)) {
	winPtr = winPtr->parentPtr;
    }
    wmPtr = winPtr->wmInfoPtr;

    /*
     * Make sure that the geometry information is up-to-date, then copy
     * it out to the caller.
     */

    if (wmPtr->flags & WM_VROOT_OFFSET_STALE) {
	UpdateVRootGeometry(wmPtr);
    }
    *xPtr = wmPtr->vRootX;
    *yPtr = wmPtr->vRootY;
    *widthPtr = wmPtr->vRootWidth;
    *heightPtr = wmPtr->vRootHeight;
}

/*
 *----------------------------------------------------------------------
 *
 * Tk_MoveToplevelWindow --
 *
 *	This procedure is called instead of Tk_MoveWindow to adjust
 *	the x-y location of a top-level window.  It delays the actual
 *	move to a later time and keeps window-manager information
 *	up-to-date with the move
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The window is eventually moved so that its upper-left corner
 *	(actually, the upper-left corner of the window's decorative
 *	frame, if there is one) is at (x,y).
 *
 *----------------------------------------------------------------------
 */

void
Tk_MoveToplevelWindow(
    Tk_Window tkwin,		/* Window to move. */
    int x, int y)		/* New location for window (within
				 * parent). */
{
    TkWindow *winPtr = (TkWindow *) tkwin;
    WmInfo *wmPtr = winPtr->wmInfoPtr;

    if (!(winPtr->flags & TK_TOP_LEVEL)) {
	Tcl_Panic("Tk_MoveToplevelWindow called with non-toplevel window");
    }
    wmPtr->x = x;
    wmPtr->y = y;
    wmPtr->flags |= WM_MOVE_PENDING;
    wmPtr->flags &= ~(WM_NEGATIVE_X|WM_NEGATIVE_Y);
    if ((wmPtr->sizeHintsFlags & (USPosition|PPosition)) == 0) {
	wmPtr->sizeHintsFlags |= USPosition;
	wmPtr->flags |= WM_UPDATE_SIZE_HINTS;
    }

    /*
     * If the window has already been mapped, must bring its geometry
     * up-to-date immediately, otherwise an event might arrive from the
     * server that would overwrite wmPtr->x and wmPtr->y and lose the
     * new position.
     */

    if (!(wmPtr->flags & WM_NEVER_MAPPED)) {
	if (wmPtr->flags & WM_UPDATE_PENDING) {
	    Tk_CancelIdleCall(UpdateGeometryInfo, (ClientData) winPtr);
	}
	UpdateGeometryInfo((ClientData) winPtr);
    }
}
/*
 *----------------------------------------------------------------------
 *
 * TkWmRestackToplevel --
 *
 *	This procedure restacks a top-level window.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	WinPtr gets restacked  as specified by aboveBelow and otherPtr.
 *	This procedure doesn't return until the restack has taken
 *	effect and the ConfigureNotify event for it has been received.
 *
 *----------------------------------------------------------------------
 */

void
TkWmRestackToplevel(
    TkWindow *winPtr,		/* Window to restack. */
    int aboveBelow,		/* Gives relative position for restacking;
				 * must be Above or Below. */
    TkWindow *otherPtr)		/* Window relative to which to restack;
				 * if NULL, then winPtr gets restacked
				 * above or below *all* siblings. */
{
    WmInfo *wmPtr;

    WindowRef macWindow, otherMacWindow, frontWindow, tmpWindow;

    wmPtr = winPtr->wmInfoPtr;

    /*
     * Get the mac window.  Make sure it exists & is mapped.
     */
    if (winPtr->window == None) {
	Tk_MakeWindowExist((Tk_Window) winPtr);
    }
    if (winPtr->wmInfoPtr->flags & WM_NEVER_MAPPED) {

	/*
	 * Can't set stacking order properly until the window is on the
	 * screen (mapping it may give it a reparent window), so make sure
	 * it's on the screen.
	 */

	TkWmMapWindow(winPtr);
    }
    macWindow = GetWindowFromPort(TkMacOSXGetDrawablePort(winPtr->window));

    /*
     * Get the window in which a raise or lower is in relation to.
     */
    if (otherPtr != NULL) {
	if (otherPtr->window == None) {
	    Tk_MakeWindowExist((Tk_Window) otherPtr);
	}
	if (otherPtr->wmInfoPtr->flags & WM_NEVER_MAPPED) {
	    TkWmMapWindow(otherPtr);
	}
	otherMacWindow = GetWindowFromPort(TkMacOSXGetDrawablePort(otherPtr->window));
    } else {
	otherMacWindow = NULL;
    }

    frontWindow = ActiveNonFloatingWindow();

    if (aboveBelow == Above) {
	if (macWindow == frontWindow) {
	    /* 
	     * Do nothing - it's already at the top.
	     */
	} else if (otherMacWindow == frontWindow || otherMacWindow == NULL) {
	    /*
	     * Raise the window to the top.  If the window is visible then
	     * we also make it the active window.
	     */

	    if (wmPtr->hints.initial_state == WithdrawnState) {
		BringToFront(macWindow);
	    } else {
		SelectWindow(macWindow);
	    }
	} else {
	    /*
	     * Find the window to be above.  (Front window will actually be the
	     * window to be behind.)  Front window is NULL if no other windows.
	     */
	    while (frontWindow != NULL &&
		    ( tmpWindow = GetNextWindow (frontWindow) ) != otherMacWindow) {
		frontWindow = tmpWindow;
	    }
	    if (frontWindow != NULL) {
		SendBehind(macWindow, frontWindow);
	    }
	}
    } else {
	/*
	 * Send behind.  If it was in front find another window to make active.
	 */
	if (macWindow == frontWindow) {
	    if ( ( tmpWindow = GetNextWindow ( macWindow )) != NULL) {
		SelectWindow(tmpWindow);
	    }
	}
	SendBehind(macWindow, otherMacWindow);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkWmAddToColormapWindows --
 *
 *	This procedure is called to add a given window to the
 *	WM_COLORMAP_WINDOWS property for its top-level, if it
 *	isn't already there.  It is invoked by the Tk code that
 *	creates a new colormap, in order to make sure that colormap
 *	information is propagated to the window manager by default.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	WinPtr's window gets added to the WM_COLORMAP_WINDOWS
 *	property of its nearest top-level ancestor, unless the
 *	colormaps have been set explicitly with the
 *	"wm colormapwindows" command.
 *
 *----------------------------------------------------------------------
 */

void
TkWmAddToColormapWindows(
    TkWindow *winPtr)		/* Window with a non-default colormap.
				 * Should not be a top-level window. */
{
    TkWindow *topPtr;
    TkWindow **oldPtr, **newPtr;
    int count, i;

    if (winPtr->window == None) {
	return;
    }

    for (topPtr = winPtr->parentPtr; ; topPtr = topPtr->parentPtr) {
	if (topPtr == NULL) {
	    /*
	     * Window is being deleted.  Skip the whole operation.
	     */

	    return;
	}
	if (topPtr->flags & TK_TOP_LEVEL) {
	    break;
	}
    }
    if (topPtr->wmInfoPtr->flags & WM_COLORMAPS_EXPLICIT) {
	return;
    }

    /*
     * Make sure that the window isn't already in the list.
     */

    count = topPtr->wmInfoPtr->cmapCount;
    oldPtr = topPtr->wmInfoPtr->cmapList;

    for (i = 0; i < count; i++) {
	if (oldPtr[i] == winPtr) {
	    return;
	}
    }

    /*
     * Make a new bigger array and use it to reset the property.
     * Automatically add the toplevel itself as the last element
     * of the list.
     */

    newPtr = (TkWindow **) ckalloc((unsigned) ((count+2)*sizeof(TkWindow*)));
    if (count > 0) {
	memcpy(newPtr, oldPtr, count * sizeof(TkWindow*));
    }
    if (count == 0) {
	count++;
    }
    newPtr[count-1] = winPtr;
    newPtr[count] = topPtr;
    if (oldPtr != NULL) {
	ckfree((char *) oldPtr);
    }

    topPtr->wmInfoPtr->cmapList = newPtr;
    topPtr->wmInfoPtr->cmapCount = count+1;

    /*
     * On the Macintosh all of this is just an excercise
     * in compatability as we don't support colormaps.  If 
     * we did they would be installed here.
     */
}

/*
 *----------------------------------------------------------------------
 *
 * TkWmRemoveFromColormapWindows --
 *
 *	This procedure is called to remove a given window from the
 *	WM_COLORMAP_WINDOWS property for its top-level.  It is invoked
 *	when windows are deleted.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	WinPtr's window gets removed from the WM_COLORMAP_WINDOWS
 *	property of its nearest top-level ancestor, unless the
 *	top-level itself is being deleted too.
 *
 *----------------------------------------------------------------------
 */

void
TkWmRemoveFromColormapWindows(
    TkWindow *winPtr)		/* Window that may be present in
				 * WM_COLORMAP_WINDOWS property for its
				 * top-level.  Should not be a top-level
				 * window. */
{
    TkWindow *topPtr;
    TkWindow **oldPtr;
    int count, i, j;

    for (topPtr = winPtr->parentPtr; ; topPtr = topPtr->parentPtr) {
	if (topPtr == NULL) {
	    /*
	     * Ancestors have been deleted, so skip the whole operation.
	     * Seems like this can't ever happen?
	     */

	    return;
	}
	if (topPtr->flags & TK_TOP_LEVEL) {
	    break;
	}
    }
    if (topPtr->flags & TK_ALREADY_DEAD) {
	/*
	 * Top-level is being deleted, so there's no need to cleanup
	 * the WM_COLORMAP_WINDOWS property.
	 */

	return;
    }

    /*
     * Find the window and slide the following ones down to cover
     * it up.
     */

    count = topPtr->wmInfoPtr->cmapCount;
    oldPtr = topPtr->wmInfoPtr->cmapList;
    for (i = 0; i < count; i++) {
	if (oldPtr[i] == winPtr) {
	    for (j = i ; j < count-1; j++) {
		oldPtr[j] = oldPtr[j+1];
	    }
	    topPtr->wmInfoPtr->cmapCount = count - 1;
	    break;
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkGetPointerCoords --
 *
 *	Fetch the position of the mouse pointer.
 *
 * Results:
 *	*xPtr and *yPtr are filled in with the (virtual) root coordinates
 *	of the mouse pointer for tkwin's display.  If the pointer isn't
 *	on tkwin's screen, then -1 values are returned for both
 *	coordinates.  The argument tkwin must be a toplevel window.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

void
TkGetPointerCoords(
    Tk_Window tkwin,		/* Toplevel window that identifies screen
				 * on which lookup is to be done. */
    int *xPtr, int *yPtr)	/* Store pointer coordinates here. */
{
    XQueryPointer(NULL, None, NULL, NULL, xPtr, yPtr, NULL, NULL, NULL);
}

/*
 *----------------------------------------------------------------------
 *
 * InitialWindowBounds --
 *
 *	This function calculates the initial bounds for a new Mac
 *	toplevel window.  Unless the geometry is specified by the user
 *	this code will auto place the windows in a cascade diagonially
 *	across the main monitor of the Mac.
 *
 * Results:
 *	The bounds are returned in geometry.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static void
InitialWindowBounds(
    TkWindow *winPtr,		/* Window to get initial bounds for. */
    Rect *geometry)		/* On return the initial bounds. */
{
    WmInfo *wmPtr = winPtr->wmInfoPtr;
    static int defaultX = 5;
    static int defaultY = 45;

    if (!(wmPtr->sizeHintsFlags & (USPosition | PPosition))) {
	/* 
	 * We will override the program & hopefully place the
	 * window in a "better" location.
	 */
        BitMap screenBits;
        GetQDGlobalsScreenBits(&screenBits);
	if (((screenBits.bounds.right - defaultX) < 30) ||
		((screenBits.bounds.bottom - defaultY) < 30)) {
	    defaultX = 5;
	    defaultY = 45;
	}
	wmPtr->x = defaultX;
	wmPtr->y = defaultY;
	defaultX += 20;
	defaultY += 20;
    }

    geometry->left = wmPtr->x;
    geometry->top = wmPtr->y;
    geometry->right = wmPtr->x + winPtr->changes.width;
    geometry->bottom = wmPtr->y + winPtr->changes.height;
}

/*
 *----------------------------------------------------------------------
 *
 * TkMacOSXResizable --
 *
 *	This function determines if the passed in window is part of
 *	a toplevel window that is resizable.  If the window is 
 *	resizable in the x, y or both directions, true is returned.
 *
 * Results:
 *	True if resizable, false otherwise.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
TkMacOSXResizable(
    TkWindow *winPtr)		/* Tk window or NULL. */
{
    WmInfo *wmPtr;

    if (winPtr == NULL) {
	return false;
    }
    while (winPtr->wmInfoPtr == NULL) {
	winPtr = winPtr->parentPtr;
    }
    
    wmPtr = winPtr->wmInfoPtr;
    if ((wmPtr->flags & WM_WIDTH_NOT_RESIZABLE) &&
	    (wmPtr->flags & WM_HEIGHT_NOT_RESIZABLE)) {
	return false;
    } else {
	return true;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkMacOSXGrowToplevel --
 *
 *	The function is invoked when the user clicks in the grow region
 *	of a Tk window.  The function will handle the dragging
 *	procedure and not return until completed.  Finally, the function
 *	may place information Tk's event queue is the window was resized.
 *
 * Results:
 *	True if events were placed on event queue, false otherwise.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
TkMacOSXGrowToplevel(
    WindowRef whichWindow,
    Point start)
{
    Point where = start;
    TkDisplay *dispPtr;
    Rect       portRect;

    SetPort(GetWindowPort(whichWindow));
    GlobalToLocal(&where);
    GetPortBounds(GetWindowPort(whichWindow), &portRect);
    if (where.h > (portRect.right - 16) &&
	    where.v > (portRect.bottom - 16)) {
	Window window;
	TkWindow *winPtr;
	WmInfo *wmPtr;
	Rect bounds;
	long growResult;

	window = TkMacOSXGetXWindow(whichWindow);
	dispPtr = TkGetDisplayList();
	winPtr = (TkWindow *) Tk_IdToWindow(dispPtr->display, window);
	wmPtr = winPtr->wmInfoPtr;

	/* TODO: handle grid size options. */
	if ((wmPtr->flags & WM_WIDTH_NOT_RESIZABLE) &&
		(wmPtr->flags & WM_HEIGHT_NOT_RESIZABLE)) {
	    return false;
	}
	if (wmPtr->flags & WM_WIDTH_NOT_RESIZABLE) {
	    bounds.left = bounds.right = winPtr->changes.width;
	} else {
	    bounds.left = (wmPtr->minWidth < 64) ? 64 : wmPtr->minWidth;
	    bounds.right = (wmPtr->maxWidth < 64) ? 64 : wmPtr->maxWidth;
	}
	if (wmPtr->flags & WM_HEIGHT_NOT_RESIZABLE) {
	    bounds.top = bounds.bottom = winPtr->changes.height;
	} else {
	    bounds.top = (wmPtr->minHeight < 64) ? 64 : wmPtr->minHeight;
	    bounds.bottom = (wmPtr->maxHeight < 64) ? 64 : wmPtr->maxHeight;
	}

	growResult = GrowWindow(whichWindow, start, &bounds);

	if (growResult != 0) {
	    SizeWindow(whichWindow,
		    LoWord(growResult), HiWord(growResult), true);
	    InvalWindowRect(whichWindow, &portRect); /* TODO: may not be needed */
	    TkMacOSXInvalClipRgns((Tk_Window) winPtr);
	    TkGenWMConfigureEvent((Tk_Window) winPtr, -1, -1, 
		    (int) LoWord(growResult), (int) HiWord(growResult),
		    TK_SIZE_CHANGED);
	    return true;
	}
	return false;
    }
    return false;
}

/*
 *----------------------------------------------------------------------
 *
 * TkSetWMName --
 *
 *	Set the title for a toplevel window.  If the window is embedded, 
 *	do not change the window title.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The title of the window is changed.
 *
 *----------------------------------------------------------------------
 */

void
TkSetWMName(
    TkWindow *winPtr,
    Tk_Uid titleUid)
{
    CFStringRef  title;
    WindowRef macWin;
    
    if (Tk_IsEmbedded(winPtr)) {
        return;
    }
    
    title = CFStringCreateWithBytes(NULL, (unsigned char*) titleUid,
	    strlen(titleUid), kCFStringEncodingUTF8, false); 
    if (title) {
	macWin = GetWindowFromPort(TkMacOSXGetDrawablePort(winPtr->window));
	SetWindowTitleWithCFString(macWin, title);
	CFRelease(title);
    }
}


/*
 *----------------------------------------------------------------------
 *
 * TkGetTransientMaster --
 *
 *	If the passed window has the TRANSIENT_FOR property set this
 *	will return the master window.  Otherwise it will return None.
 *
 * Results:
 *      The master window or None.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

Window
TkGetTransientMaster(
    TkWindow *winPtr)
{
    if (winPtr->wmInfoPtr != NULL) {
	return winPtr->wmInfoPtr->master;
    }
    return None;
}

/*
 *----------------------------------------------------------------------
 *
 * TkMacOSXGetXWindow --
 *
 *	Returns the X window Id associated with the given WindowRef.
 *
 * Results:
 *	The window id is returned.  None is returned if not a Tk window.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

Window
TkMacOSXGetXWindow(
    WindowRef macWinPtr)
{
    Tcl_HashEntry *hPtr;

    if ((macWinPtr == NULL) || !windowHashInit) {
	return None;
    }
    hPtr = Tcl_FindHashEntry(&windowTable, (char *) macWinPtr);
    if (hPtr == NULL) {
	return None;
    }
    return (Window) Tcl_GetHashValue(hPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * TkMacOSXIsWindowZoomed --
 *
 *	Ask Carbon if the given window is in the zoomed out state.
 *	Because dragging & growing a window can change the Carbon
 *	zoom state, we cannot rely on wmInfoPtr->hints.initial_state
 *	for this information.
 *
 * Results:
 *	True if window is zoomed out, false otherwise.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

MODULE_SCOPE int
TkMacOSXIsWindowZoomed(
    TkWindow *winPtr)
{
    WmInfo *wmPtr = winPtr->wmInfoPtr;
    Point idealSize;
    
    if ((wmPtr->flags & WM_WIDTH_NOT_RESIZABLE) &&
	    (wmPtr->flags & WM_HEIGHT_NOT_RESIZABLE)) {
	return false;
    }
    if (wmPtr->flags & WM_WIDTH_NOT_RESIZABLE) {
	idealSize.h = winPtr->changes.width;
    } else {
	idealSize.h = wmPtr->maxWidth;
    }
    if (wmPtr->flags & WM_HEIGHT_NOT_RESIZABLE) {
	idealSize.v = winPtr->changes.height;
    } else {
	idealSize.v = wmPtr->maxHeight;
    }

    return IsWindowInStandardState(
	    GetWindowFromPort(TkMacOSXGetDrawablePort(winPtr->window)),
	    &idealSize, NULL);
}

/*
 *----------------------------------------------------------------------
 *
 * TkMacOSXZoomToplevel --
 *
 *	The function is invoked when the user clicks in the zoom region
 *	of a Tk window or when the window state is set/unset to "zoomed"
 *	manually. If the window is to be zoomed (in or out), the window
 *	size is changed and events are generated to let Tk know what
 *	happened.
 *
 * Results:
 *	True if events were placed on event queue, false otherwise.
 *
 * Side effects:
 *	The window may be resized & events placed on Tk's queue.
 *
 *----------------------------------------------------------------------
 */

int
TkMacOSXZoomToplevel(
    WindowRef whichWindow,	/* The Macintosh window to zoom. */
    short zoomPart)		/* Either inZoomIn or inZoomOut */
{
    Window window;
    TkDisplay *dispPtr;
    TkWindow *winPtr;
    WmInfo *wmPtr;
    Point location = {0, 0}, idealSize;
    Rect portRect;
    int xOffset, yOffset;
    OSStatus status;

    window = TkMacOSXGetXWindow(whichWindow);
    dispPtr = TkGetDisplayList();
    winPtr = (TkWindow *) Tk_IdToWindow(dispPtr->display, window);
    wmPtr = winPtr->wmInfoPtr;
    
    if ((wmPtr->flags & WM_WIDTH_NOT_RESIZABLE) &&
	    (wmPtr->flags & WM_HEIGHT_NOT_RESIZABLE)) {
	return false;
    }
    if (wmPtr->flags & WM_WIDTH_NOT_RESIZABLE) {
	idealSize.h = winPtr->changes.width;
    } else {
	idealSize.h = wmPtr->maxWidth;
    }
    if (wmPtr->flags & WM_HEIGHT_NOT_RESIZABLE) {
	idealSize.v = winPtr->changes.height;
    } else {
	idealSize.v = wmPtr->maxHeight;
    }

    /* Do nothing if already in desired zoom state */
    if (!IsWindowInStandardState(whichWindow, &idealSize, NULL) == 
	    (zoomPart == inZoomIn)) {
	return false;
    }

    SetPort(GetWindowPort(whichWindow));
    GetPortBounds(GetWindowPort(whichWindow), &portRect);
    status = ZoomWindowIdeal(whichWindow, zoomPart, &idealSize);
    if (status == noErr) {
	wmPtr->hints.initial_state =
		(zoomPart == inZoomIn ? NormalState : ZoomState);
	InvalWindowRect(whichWindow, &portRect);
	TkMacOSXInvalClipRgns((Tk_Window) winPtr);
	LocalToGlobal(&location);
	TkMacOSXWindowOffset(whichWindow, &xOffset, &yOffset);
	location.h -= xOffset;
	location.v -= yOffset;
	GetPortBounds(GetWindowPort(whichWindow), &portRect);
	TkGenWMConfigureEvent((Tk_Window) winPtr, location.h, location.v, 
		portRect.right - portRect.left, portRect.bottom - portRect.top,
		TK_BOTH_CHANGED);
	return true;
    } else {
	return false;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkUnsupported1Cmd --
 *
 *	This procedure is invoked to process the 
 *	"::tk::unsupported::MacWindowStyle" Tcl command.
 *	This command allows you to set the style of decoration
 *	for a Macintosh window.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	Changes the style of a new Mac window.
 *
 *----------------------------------------------------------------------
 */

/* ARGSUSED */
int
TkUnsupported1ObjCmd(
    ClientData clientData,	/* Main window associated with
				 * interpreter. */
    Tcl_Interp *interp,		/* Current interpreter. */
    int objc,			/* Number of arguments. */
    Tcl_Obj * CONST objv[])	/* Argument objects. */
{
    static CONST char *subcmds[] = {
	"style", NULL
    };
    enum SubCmds {
	TKMWS_STYLE
    };
    Tk_Window tkwin = (Tk_Window) clientData;
    TkWindow *winPtr;
    int index;

    if (objc < 3) {
	Tcl_WrongNumArgs(interp, 1, objv, "option window ?arg ...?");
	return TCL_ERROR;
    }

    winPtr = (TkWindow *) Tk_NameToWindow(interp,
	    Tcl_GetString(objv[2]), tkwin);
    if (winPtr == NULL) {
	return TCL_ERROR;
    }
    if (!(winPtr->flags & TK_TOP_LEVEL)) {
	Tcl_ResetResult(interp);
	Tcl_AppendResult(interp, "window \"", winPtr->pathName,
		"\" isn't a top-level window", (char *) NULL);
	return TCL_ERROR;
    }

    if (Tcl_GetIndexFromObj(interp, objv[1], subcmds, "option",
		0, &index) != TCL_OK) {
	return TCL_ERROR;
    }
    if (((enum SubCmds) index) == TKMWS_STYLE) {
	if ((objc < 3) || (objc > 5)) {
	    Tcl_WrongNumArgs(interp, 2, objv, "window ?class attributes?");
	    return TCL_ERROR;
	}
	return WmWinStyle(interp, winPtr, objc, objv);
    }
    /* won't be reached */
    return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * WmWinStyle --
 *
 *	This procedure is invoked to process the 
 *	"::tk::unsupported::MacWindowStyle style" subcommand.
 *	This command allows you to set the style of decoration
 *	for a Macintosh window.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	Changes the style of a new Mac window.
 *
 *----------------------------------------------------------------------
 */
static int
WmWinStyle(
    Tcl_Interp *interp,		/* Current interpreter. */
    TkWindow *winPtr,		/* Window to be manipulated. */
    int objc,			/* Number of arguments. */
    Tcl_Obj * CONST objv[])	/* Argument objects. */
{
    struct StrIntMap {
	char *strValue;
	int  intValue;
    };
    static CONST struct StrIntMap styleMap[] = {
	{ "documentProc",	    documentProc	  },
	{ "noGrowDocProc",	    documentProc	  },
	{ "dBoxProc",		    dBoxProc		  },
	{ "plainDBox",		    plainDBox		  },
	{ "altDBoxProc",	    altDBoxProc		  },
	{ "movableDBoxProc",	    movableDBoxProc	  },
	{ "zoomDocProc",	    zoomDocProc		  },
	{ "zoomNoGrow",		    zoomNoGrow		  },
	{ "floatProc",		    floatGrowProc	  },
	{ "floatGrowProc",	    floatGrowProc	  },
	{ "floatZoomProc",	    floatZoomGrowProc	  },
	{ "floatZoomGrowProc",	    floatZoomGrowProc	  },
	{ "floatSideProc",	    floatSideGrowProc	  },
	{ "floatSideGrowProc",	    floatSideGrowProc	  },
	{ "floatSideZoomProc",	    floatSideZoomGrowProc },
	{ "floatSideZoomGrowProc",  floatSideZoomGrowProc },
	{ NULL,			    0			  }
    };
    static CONST struct StrIntMap classMap[] = {
	{ "alert",	    kAlertWindowClass	     },
	{ "moveableAlert",  kMovableAlertWindowClass },
	{ "modal",	    kModalWindowClass	     },
	{ "moveableModal",  kMovableModalWindowClass },
	{ "floating",	    kFloatingWindowClass     },
	{ "document",	    kDocumentWindowClass     },
	{ "utility",	    kUtilityWindowClass	     },
	{ "help",	    kHelpWindowClass	     },
	{ "sheet",	    kSheetWindowClass	     },
	{ "toolbar",	    kToolbarWindowClass	     },
	{ "plain",	    kPlainWindowClass	     },
	{ "overlay",	    kOverlayWindowClass	     },
	{ "sheetAlert",	    kSheetAlertWindowClass   },
	{ "altPlain",	    kAltPlainWindowClass     },
	{ "simple",	    kSimpleWindowClass	     },
	{ "drawer",	    kDrawerWindowClass	     },
	{ NULL,		    0			     }
    };
    static CONST struct StrIntMap compositeAttrMap[] = {
	{ "none",	       kWindowNoAttributes		 },
	{ "standardDocument",  kWindowStandardDocumentAttributes },
	{ "standardFloating",  kWindowStandardFloatingAttributes },
	{ NULL,		       0				 }
    };
    static CONST struct StrIntMap attrMap[] = {
	{ "closeBox",	      kWindowCloseBoxAttribute	       },
	{ "horizontalZoom",   kWindowHorizontalZoomAttribute   },
	{ "verticalZoom",     kWindowVerticalZoomAttribute     },
	{ "fullZoom",	      kWindowFullZoomAttribute	       },
	{ "collapseBox",      kWindowCollapseBoxAttribute      },
	{ "resizable",	      kWindowResizableAttribute	       },
	{ "sideTitlebar",     kWindowSideTitlebarAttribute     },
	{ "toolbarButton",    kWindowToolbarButtonAttribute    },
	{ "metal",	      kWindowMetalAttribute	       },
	{ "noTitleBar",	      kWindowNoTitleBarAttribute       },
	{ "metalNoContentSeparator", kWindowMetalNoContentSeparatorAttribute },
	{ "doesNotCycle",     kWindowDoesNotCycleAttribute     },
	{ "noUpdates",	      kWindowNoUpdatesAttribute	       },
	{ "noActivates",      kWindowNoActivatesAttribute      },
	{ "opaqueForEvents",  kWindowOpaqueForEventsAttribute  },
	{ "compositing",      kWindowCompositingAttribute      },
	{ "noShadow",	      kWindowNoShadowAttribute	       },
	{ "hideOnSuspend",    kWindowHideOnSuspendAttribute    },
	{ "standardHandler",  kWindowStandardHandlerAttribute  },
	{ "hideOnFullScreen", kWindowHideOnFullScreenAttribute },
	{ "inWindowMenu",     kWindowInWindowMenuAttribute     },
	{ "ignoreClicks",     kWindowIgnoreClicksAttribute     },
	{ "noConstrain",      kWindowNoConstrainAttribute      },
	{ "standardDocument", kWindowStandardDocumentAttributes },
	{ "standardFloating", kWindowStandardFloatingAttributes },
	{ NULL,		      0				       }
    };
    int index, i;
    WmInfo *wmPtr = winPtr->wmInfoPtr;

    if (objc == 3) {
	if (wmPtr->style != -1) {
	    for (i = 0; styleMap[i].strValue != NULL; i++) {
		if (wmPtr->style == styleMap[i].intValue) {
		    Tcl_SetObjResult(interp, 
			    Tcl_NewStringObj(styleMap[i].strValue, -1));
		    return TCL_OK;
		}
	    }
	    Tcl_Panic("invalid style");
	} else {
	    Tcl_Obj *attributeList, *newResult = NULL;
	    int usesComposite;

	    for (i = 0; classMap[i].strValue != NULL; i++) {
		if (wmPtr->macClass == classMap[i].intValue) {
		    newResult = Tcl_NewStringObj(classMap[i].strValue, -1);
		    break;
		}
	    }
	    if (newResult == NULL) {
		Tcl_Panic("invalid class");
	    }

	    attributeList = Tcl_NewListObj(0, NULL);
	    usesComposite = 0;

	    for (i = 0; compositeAttrMap[i].strValue != NULL; i++) {
		if (wmPtr->attributes == compositeAttrMap[i].intValue) {
		    Tcl_ListObjAppendElement(interp, attributeList,
			    Tcl_NewStringObj(compositeAttrMap[i].strValue, -1));
		    usesComposite = 1;
		    break;
		}
	    }
	    if (!usesComposite) {
		for (i = 0; attrMap[i].strValue != NULL; i++) {
		    if (wmPtr->attributes & attrMap[i].intValue) {
			Tcl_ListObjAppendElement(interp, attributeList,
				Tcl_NewStringObj(attrMap[i].strValue, -1));
		    }
		}
	    }
	    Tcl_ListObjAppendElement(interp, newResult, attributeList);
	    Tcl_SetObjResult(interp, newResult);
	}
    } else if (objc == 4) {
	if (Tcl_GetIndexFromObjStruct(interp, objv[3], styleMap,
		    sizeof(struct StrIntMap), "style", 0, &index) != TCL_OK) {
	    return TCL_ERROR;
	}
	wmPtr->style = styleMap[index].intValue;
    } else if (objc == 5) {
	int attrObjc;
	Tcl_Obj **attrObjv = NULL;
	int oldClass = wmPtr->macClass;
	int oldAttributes = wmPtr->attributes;

	if (Tcl_GetIndexFromObjStruct(interp, objv[3], classMap,
		    sizeof(struct StrIntMap), "class", 0, &index) != TCL_OK) {
	    return TCL_ERROR;
	}
	if (Tcl_ListObjGetElements(interp, objv[4], &attrObjc, &attrObjv)
		!= TCL_OK) {
	    return TCL_ERROR;
	}
	wmPtr->macClass = classMap[index].intValue;
	wmPtr->attributes = kWindowNoAttributes;
	for (i = 0; i < attrObjc; i++) {
	    if (Tcl_GetIndexFromObjStruct(interp, attrObjv[i],
			compositeAttrMap, sizeof(struct StrIntMap),
			"attribute", 0, &index) == TCL_OK) {
		wmPtr->attributes |= compositeAttrMap[index].intValue;
	    } else if (Tcl_GetIndexFromObjStruct(interp, attrObjv[i],
			       attrMap, sizeof(struct StrIntMap),
			       "attribute", 0, &index) == TCL_OK) {
		Tcl_ResetResult (interp);
		wmPtr->attributes |= attrMap[index].intValue;
	    } else {
		wmPtr->macClass = oldClass;
		wmPtr->attributes = oldAttributes;
		return TCL_ERROR;
	    }
	}
	ApplyWindowAttributeChanges(winPtr, wmPtr->attributes,
		oldAttributes, 0);
	wmPtr->style = -1;
    }

    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * TkpMakeMenuWindow --
 *
 *	Configure the window to be either a undecorated pull-down 
 *	(or pop-up) menu, or as a toplevel floating menu (palette).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Changes the style bit used to create a new Mac toplevel.
 *
 *----------------------------------------------------------------------
 */

void
TkpMakeMenuWindow(
    Tk_Window tkwin,		/* New window. */
    int transient)		/* 1 means menu is only posted briefly as
				 * a popup or pulldown or cascade.  0 means
				 * menu is always visible, e.g. as a 
				 * floating menu. */
{
    if (transient) {
	((TkWindow *) tkwin)->wmInfoPtr->macClass = kSimpleWindowClass;
	((TkWindow *) tkwin)->wmInfoPtr->attributes = kWindowNoActivatesAttribute;
    } else {
	((TkWindow *) tkwin)->wmInfoPtr->macClass = kFloatingWindowClass;
	((TkWindow *) tkwin)->wmInfoPtr->attributes = kWindowStandardFloatingAttributes;
	((TkWindow *) tkwin)->wmInfoPtr->flags |= WM_WIDTH_NOT_RESIZABLE;
	((TkWindow *) tkwin)->wmInfoPtr->flags |= WM_HEIGHT_NOT_RESIZABLE;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkMacOSXMakeRealWindowExist --
 *
 *	This function finally creates the real Macintosh window that
 *	the Mac actually understands.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	A new Macintosh toplevel is created.
 *
 *----------------------------------------------------------------------
 */

void
TkMacOSXMakeRealWindowExist(
    TkWindow *winPtr)	/* Tk window. */
{
    WmInfo *wmPtr = winPtr->wmInfoPtr;
    WindowRef  newWindow  = NULL;
    ControlRef rootControl = NULL;
    MacDrawable *macWin;
    Rect geometry = {0,0,0,0};
    Tcl_HashEntry *valueHashPtr;
    int new;
    TkMacOSXWindowList *listPtr;

    if (TkMacOSXHostToplevelExists(winPtr)) {
	return;
    }

    macWin = (MacDrawable *) winPtr->window;

    /*
     * If this is embedded, make sure its container's toplevel exists,
     * then return... 
     */

    if (Tk_IsEmbedded(winPtr)) {
	TkWindow *contWinPtr;

	contWinPtr = TkpGetOtherWindow(winPtr);
	if (contWinPtr != NULL) {
	    TkMacOSXMakeRealWindowExist(contWinPtr->privatePtr->toplevel->winPtr);
	    macWin->flags |= TK_HOST_EXISTS;
	    return;
	} else if (gMacEmbedHandler != NULL) {
	    if (gMacEmbedHandler->containerExistProc != NULL) {
		if (gMacEmbedHandler->containerExistProc((Tk_Window) winPtr) != TCL_OK) {
		    Tcl_Panic("ContainerExistProc could not make container");
		}
	    }
	    return;
	} else {
	    Tcl_Panic("TkMacOSXMakeRealWindowExist could not find container");
	}

	/*
	 * NOTE: Here we should handle out of process embedding.
	 */

    }

    InitialWindowBounds(winPtr, &geometry);

    if (wmPtr->style == -1) {
	OSStatus err;
	/*
	 * There seems to be a bug in CreateNewWindow: If I set the
	 * window geometry to be the too small for the structure region,
	 * then the whole window is positioned incorrectly.
	 * Adding this here makes the positioning work, and the size will
	 * get overwritten when you actually map the contents of the window.
	 */

	geometry.right += 64;
	geometry.bottom += 24;
	err = CreateNewWindow(wmPtr->macClass, wmPtr->attributes,
		&geometry, &newWindow);
	if (err != noErr) {
	    newWindow = NULL;
	}

    } else {
	newWindow = NewCWindow(NULL, &geometry, "\p", false,
		(short) wmPtr->style, (WindowRef) -1, true, 0);
    }

    if (newWindow == NULL) {
	Tcl_Panic("couldn't allocate new Mac window");
    }
    if (CreateRootControl(newWindow,&rootControl) != noErr ) {
        Tcl_Panic("couldn't create root control for new Mac window");
    }

    /*
     * Add this window to the list of toplevel windows.
     */

    listPtr = (TkMacOSXWindowList *) ckalloc(sizeof(TkMacOSXWindowList));
    listPtr->nextPtr = tkMacOSXWindowListPtr;
    listPtr->winPtr = winPtr;
    tkMacOSXWindowListPtr = listPtr;

    macWin->grafPtr = GetWindowPort(newWindow);
    macWin->rootControl = rootControl;
    MoveWindowStructure(newWindow, geometry.left, geometry.top);
    SetPort(GetWindowPort(newWindow));

    if ((wmPtr->master != None) && winPtr->atts.override_redirect) {
	/*
	 * If we are transient and overrideredirect, use the utility class
	 * to ensure we are topmost (for dropdowns).
	 */
	WindowGroupRef group = GetWindowGroupOfClass(kUtilityWindowClass);
	if (group != NULL) {
	    SetWindowGroup(newWindow, group);
	}
    }
    SetWindowModified(newWindow, false);

    if (!windowHashInit) {
	Tcl_InitHashTable(&windowTable, TCL_ONE_WORD_KEYS);
	windowHashInit = true;
    }
    valueHashPtr = Tcl_CreateHashEntry(&windowTable,
	    (char *) newWindow, &new);
    if (!new) {
	Tcl_Panic("same macintosh window allocated twice!");
    }
    Tcl_SetHashValue(valueHashPtr, macWin);

    macWin->flags |= TK_HOST_EXISTS;
}

/*
 *----------------------------------------------------------------------
 *
 * TkMacOSXRegisterOffScreenWindow --
 *
 *	This function adds the passed in Off Screen Port to the
 *	hash table that maps Mac windows to root X windows. 
 *
 *      FIXME: This is not currently used.  Is there any reason
 *      to keep it? 
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	An entry is added to the windowTable hash table.
 *
 *----------------------------------------------------------------------
 */

void 
TkMacOSXRegisterOffScreenWindow(
    Window window,	/* Window structure. */
    GWorldPtr portPtr)	/* Pointer to a Mac GWorld. */
{
    MacDrawable *macWin;
    Tcl_HashEntry *valueHashPtr;
    int new;

    macWin = (MacDrawable *) window;
    if (!windowHashInit) {
	Tcl_InitHashTable(&windowTable, TCL_ONE_WORD_KEYS);
	windowHashInit = true;
    }
    valueHashPtr = Tcl_CreateHashEntry(&windowTable,
	    (char *) portPtr, &new);
    if (!new) {
	Tcl_Panic("same macintosh window allocated twice!");
    }
    Tcl_SetHashValue(valueHashPtr, macWin);
}

/*
 *----------------------------------------------------------------------
 *
 * TkMacOSXUnregisterMacWindow --
 *
 *	Given a macintosh port window, this function removes the 
 *	association between this window and the root X window that
 *	Tk cares about.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	An entry is removed from the windowTable hash table.
 *
 *----------------------------------------------------------------------
 */

void 
TkMacOSXUnregisterMacWindow(
    WindowRef macWinPtr)	/* Reference to a Mac Window */
{
    Tcl_HashEntry *entryPtr;
    if (!windowHashInit) {
	Tcl_Panic("TkMacOSXUnregisterMacWindow: unmapping before inited");
    }
    entryPtr = Tcl_FindHashEntry(&windowTable,(char *) macWinPtr);
    if (!entryPtr) {
#ifdef TK_MAC_DEBUG
          fprintf(stderr,"Unregister:failed to find window %08x\n", 
                 (int) macWinPtr );
#endif
    }
    else {
      Tcl_DeleteHashEntry(entryPtr);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkMacOSXSetScrollbarGrow --
 *
 *	Sets a flag for a toplevel window indicating that the passed
 *	Tk scrollbar window will display the grow region for the 
 *	toplevel window.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	A flag is set int windows toplevel parent.
 *
 *----------------------------------------------------------------------
 */

void 
TkMacOSXSetScrollbarGrow(
    TkWindow *winPtr,		/* Tk scrollbar window. */
    int flag)			/* Boolean value true or false. */
{
    if (flag) {
	winPtr->privatePtr->toplevel->flags |= TK_SCROLLBAR_GROW;
	winPtr->privatePtr->toplevel->winPtr->wmInfoPtr->scrollWinPtr = winPtr;
    } else if (winPtr->privatePtr->toplevel->winPtr->wmInfoPtr->scrollWinPtr
	    == winPtr) {
	winPtr->privatePtr->toplevel->flags &= ~TK_SCROLLBAR_GROW;
	winPtr->privatePtr->toplevel->winPtr->wmInfoPtr->scrollWinPtr = NULL;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkWmFocusToplevel --
 *
 *	This is a utility procedure invoked by focus-management code. It
 *	exists because of the extra wrapper windows that exist under
 *	Unix; its job is to map from wrapper windows to the
 *	corresponding toplevel windows.  On PCs and Macs there are no
 *	wrapper windows so no mapping is necessary;  this procedure just
 *	determines whether a window is a toplevel or not.
 *
 * Results:
 *	If winPtr is a toplevel window, returns the pointer to the
 *	window; otherwise returns NULL.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

TkWindow *
TkWmFocusToplevel(
    TkWindow *winPtr)		/* Window that received a focus-related
				 * event. */
{
    if (!(winPtr->flags & TK_TOP_LEVEL)) {
	return NULL;
    }
    return winPtr;
}

/*
 *----------------------------------------------------------------------
 *
 * TkpGetWrapperWindow --
 *
 *	This is a utility procedure invoked by focus-management code. It
 *	maps to the wrapper for a top-level, which is just the same
 *	as the top-level on Macs and PCs.
 *
 * Results:
 *	If winPtr is a toplevel window, returns the pointer to the
 *	window; otherwise returns NULL.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

TkWindow *
TkpGetWrapperWindow(
    TkWindow *winPtr)		/* Window that received a focus-related
				 * event. */
{
    if (!(winPtr->flags & TK_TOP_LEVEL)) {
	return NULL;
    }
    return winPtr;
}

/*
 *----------------------------------------------------------------------
 *
 * TkpWmSetState --
 *
 *	Sets the window manager state for the wrapper window of a
 *	given toplevel window.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	May maximize, minimize, restore, or withdraw a window.
 *
 *----------------------------------------------------------------------
 */

void
TkpWmSetState(winPtr, state)
     TkWindow *winPtr;		/* Toplevel window to operate on. */
     int state;			/* One of IconicState, ZoomState, NormalState,
				 * or WithdrawnState. */
{
    WmInfo *wmPtr = winPtr->wmInfoPtr;
    WindowRef macWin;
    
    wmPtr->hints.initial_state = state;
    if (wmPtr->flags & WM_NEVER_MAPPED) {
	return;
    }

    macWin = GetWindowFromPort(TkMacOSXGetDrawablePort (winPtr->window));

    if (state == WithdrawnState) {
	Tk_UnmapWindow((Tk_Window) winPtr);
    } else if (state == IconicState) {
	/*
	 * The window always gets unmapped.  If we can show the
	 * icon version of the window we also collapse it.
	 */
	if (IsWindowCollapsable(macWin) && !IsWindowCollapsed(macWin)) {
	    CollapseWindow(macWin, true);
	}
	Tk_UnmapWindow((Tk_Window) winPtr);
    } else if (state == NormalState) {
	Tk_MapWindow((Tk_Window) winPtr);
	if (IsWindowCollapsable(macWin) && IsWindowCollapsed(macWin)) {
	    CollapseWindow(macWin, false);
	}
	TkMacOSXZoomToplevel(macWin, inZoomIn);
    } else if (state == ZoomState) {
	Tk_MapWindow((Tk_Window) winPtr);
	if (IsWindowCollapsable(macWin) && IsWindowCollapsed(macWin)) {
	    CollapseWindow(macWin, false);
	}
	TkMacOSXZoomToplevel(macWin, inZoomOut);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkpIsWindowFloating --
 *
 *        Returns 1 if a window is floating, 0 otherwise.
 *
 * Results:
 *        1 or 0 depending on window's floating attribute.
 *
 * Side effects:
 *        None.
 *
 *----------------------------------------------------------------------
 */

int
TkpIsWindowFloating(WindowRef wRef)
{
    WindowClass class;

    if (wRef == NULL) {
        return 0;
    }
    
    GetWindowClass(wRef, &class);
    return (class == kFloatingWindowClass);
}

/*
 *----------------------------------------------------------------------
 *
 * TkMacOSXWindowClass --
 *
 *        Returns OS X window class of window
 *
 * Results:
 *        1 or 0 depending on window's floating attribute.
 *
 * Side effects:
 *        None.
 *
 *----------------------------------------------------------------------
 */

MODULE_SCOPE WindowClass
TkMacOSXWindowClass(TkWindow *winPtr)
{
    WindowRef wRef;
    WindowClass class;

    if (winPtr == NULL) {
        return 0;
    }
    wRef = GetWindowFromPort(TkMacOSXGetDrawablePort(winPtr->window));
    if (wRef == NULL) {
        return 0;
    }

    GetWindowClass(wRef, &class);
    return class;
}

/*
 *----------------------------------------------------------------------
 *
 * TkMacOSXWindowOffset --
 *
 *        Determines the x and y offset from the orgin of the toplevel
 *        window dressing (the structure region, ie. title bar) and the
 *        orgin of the content area.
 *
 * Results:
 *        The x & y offset in pixels.
 *
 * Side effects:
 *        None.
 *
 *----------------------------------------------------------------------
 */

void
TkMacOSXWindowOffset(
    WindowRef wRef,
    int *xOffset,
    int *yOffset)
{
    Rect widths;

    GetWindowStructureWidths(wRef, &widths);
    *xOffset = widths.left;
    *yOffset = widths.top;
    return;
}

/*
 *----------------------------------------------------------------------
 *
 * TkpGetMS --
 *
 *        Return a relative time in milliseconds.  It doesn't matter
 *        when the epoch was.
 *
 * Results:
 *        Number of milliseconds.
 *
 * Side effects:
 *        None.
 *
 *----------------------------------------------------------------------
 */

unsigned long
TkpGetMS()
{
    long long * int64Ptr;
    UnsignedWide micros;
    
    Microseconds(&micros);
    int64Ptr = (long long *) &micros;

    /*
     * We need 64 bit math to do this.  This is available in CW 11
     * and on.  Other's will need to use a different scheme.
     */

    *int64Ptr /= 1000;

    return (long) *int64Ptr;
}

/*
 *----------------------------------------------------------------------
 *
 * XSetInputFocus --
 *
 *        Change the focus window for the application.
 *
 * Results:
 *        None.
 *
 * Side effects:
 *        None.
 *
 *----------------------------------------------------------------------
 */

void
XSetInputFocus(
    Display* display,
    Window focus,
    int revert_to,
    Time time)
{
    /*
     * Don't need to do a thing.  Tk manages the focus for us.
     */
}

/*
 *----------------------------------------------------------------------
 *
 * TkpChangeFocus --
 *
 *        This procedure is a stub on the Mac because we always own the
 *        focus if we are a front most application.
 *
 * Results:
 *        The return value is the serial number of the command that
 *        changed the focus.  It may be needed by the caller to filter
 *        out focus change events that were queued before the command.
 *        If the procedure doesn't actually change the focus then
 *        it returns 0.
 *
 * Side effects:
 *        None.
 *
 *----------------------------------------------------------------------
 */

int
TkpChangeFocus(winPtr, force)
    TkWindow *winPtr;           /* Window that is to receive the X focus. */
    int force;                  /* Non-zero means claim the focus even
                                 * if it didn't originally belong to
                                 * topLevelPtr's application. */
{
    /*
     * We don't really need to do anything on the Mac.  Tk will
     * keep all this state for us.
     */

    if (winPtr->atts.override_redirect) {
        return 0;
    }

    /*
     * Remember the current serial number for the X server and issue
     * a dummy server request.  This marks the position at which we
     * changed the focus, so we can distinguish FocusIn and FocusOut
     * events on either side of the mark.
     */

    return NextRequest(winPtr->display);
}


/*
 *----------------------------------------------------------------------
 *
 * WmStackorderToplevelWrapperMap --
 *
 *	This procedure will create a table that maps the reparent wrapper
 *	X id for a toplevel to the TkWindow structure that is wraps.
 *	Tk keeps track of a mapping from the window X id to the TkWindow
 *	structure but that does us no good here since we only get the X
 *	id of the wrapper window. Only those toplevel windows that are
 *	mapped have a position in the stacking order.
 *
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Adds entries to the passed hashtable.
 *
 *----------------------------------------------------------------------
 */
static void
WmStackorderToplevelWrapperMap(winPtr, display, table)
    TkWindow *winPtr;				/* TkWindow to recurse on */
    Display *display;                           /* X display of parent window */
    Tcl_HashTable *table;			/* Maps mac window to TkWindow */
{
    TkWindow *childPtr;
    Tcl_HashEntry *hPtr;
    WindowRef macWindow;
    int newEntry;

    if (Tk_IsMapped(winPtr) && Tk_IsTopLevel(winPtr) && (winPtr->display == display)) {
        macWindow = GetWindowFromPort(TkMacOSXGetDrawablePort(winPtr->window));

        hPtr = Tcl_CreateHashEntry(table,
            (const char *) macWindow, &newEntry);
        Tcl_SetHashValue(hPtr, winPtr);
    }

    for (childPtr = winPtr->childList; childPtr != NULL;
            childPtr = childPtr->nextPtr) {
        WmStackorderToplevelWrapperMap(childPtr, display, table);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkWmStackorderToplevel --
 *
 *	This procedure returns the stack order of toplevel windows.
 *
 * Results:
 *	An array of pointers to tk window objects in stacking order
 *	or else NULL if there was an error.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

TkWindow **
TkWmStackorderToplevel(parentPtr)
    TkWindow *parentPtr;		/* Parent toplevel window. */
{
    WindowRef frontWindow;
    TkWindow *childWinPtr, **windows, **window_ptr;
    Tcl_HashTable table;
    Tcl_HashEntry *hPtr;
    Tcl_HashSearch search;

    /*
     * Map mac windows to a TkWindow of the wrapped toplevel.
     */

    Tcl_InitHashTable(&table, TCL_ONE_WORD_KEYS);
    WmStackorderToplevelWrapperMap(parentPtr, parentPtr->display, &table);

    windows = (TkWindow **) ckalloc((table.numEntries+1)
        * sizeof(TkWindow *));

    /*
     * Special cases: If zero or one toplevels were mapped
     * there is no need to enumerate Windows.
     */

    switch (table.numEntries) {
    case 0:
        windows[0] = NULL;
        goto done;
    case 1:
        hPtr = Tcl_FirstHashEntry(&table, &search);
        windows[0] = (TkWindow *) Tcl_GetHashValue(hPtr);
        windows[1] = NULL;
        goto done;
    }

    frontWindow = (WindowRef) FrontWindow();

    if (frontWindow == NULL) {
        ckfree((char *) windows);
        windows = NULL;
    } else {
    	window_ptr = windows + table.numEntries;
    	*window_ptr-- = NULL;
	    while (frontWindow != NULL) {
		    hPtr = Tcl_FindHashEntry(&table, (char *) frontWindow);
            if (hPtr != NULL) {
                childWinPtr = (TkWindow *) Tcl_GetHashValue(hPtr);
                *window_ptr-- = childWinPtr;
            }
            frontWindow = GetNextWindow(frontWindow);
	    }
        if (window_ptr != (windows-1))
            Tcl_Panic("num matched toplevel windows does not equal num children");
    }

    done:
    Tcl_DeleteHashTable(&table);
    return windows;
}

/*
 *----------------------------------------------------------------------
 *
 * ApplyWindowAttributeChanges --
 *
 *	This procedure applies carbon window attribute changes.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static void
ApplyWindowAttributeChanges(TkWindow *winPtr, int newAttributes,
    int oldAttributes, int create)
{
    if (newAttributes != oldAttributes) {
	if (winPtr->window == None) {
	    if (create) {
		Tk_MakeWindowExist((Tk_Window) winPtr);
	    } else {
		return;
	    }
	}
	if (!TkMacOSXHostToplevelExists(winPtr)) {
	    if (create) {
		TkMacOSXMakeRealWindowExist(winPtr);
	    } else {
		return;
	    }
	}
	ChangeWindowAttributes(
		GetWindowFromPort(TkMacOSXGetDrawablePort(winPtr->window)),
		newAttributes & (newAttributes ^ oldAttributes),
		oldAttributes & (newAttributes ^ oldAttributes));
    }
}
