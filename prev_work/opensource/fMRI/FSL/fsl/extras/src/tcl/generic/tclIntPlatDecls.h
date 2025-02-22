/*
 * tclIntPlatDecls.h --
 *
 *	This file contains the declarations for all platform dependent
 *	unsupported functions that are exported by the Tcl library.  These
 *	interfaces are not guaranteed to remain the same between
 *	versions.  Use at your own risk.
 *
 * Copyright (c) 1998-1999 by Scriptics Corporation.
 * All rights reserved.
 *
 * RCS: @(#) $Id: tclIntPlatDecls.h,v 1.1.1.1 2007/07/10 15:04:23 duncan Exp $
 */

#ifndef _TCLINTPLATDECLS
#define _TCLINTPLATDECLS

/*
 * WARNING: This file is automatically generated by the tools/genStubs.tcl
 * script.  Any modifications to the function declarations below should be made
 * in the generic/tclInt.decls script.
 */

/* !BEGIN!: Do not edit below this line. */

/*
 * Exported function declarations:
 */

#if !defined(__WIN32__) && !defined(MAC_TCL) /* UNIX */
/* 0 */
EXTERN void		TclGetAndDetachPids _ANSI_ARGS_((Tcl_Interp * interp, 
				Tcl_Channel chan));
/* 1 */
EXTERN int		TclpCloseFile _ANSI_ARGS_((TclFile file));
/* 2 */
EXTERN Tcl_Channel	TclpCreateCommandChannel _ANSI_ARGS_((
				TclFile readFile, TclFile writeFile, 
				TclFile errorFile, int numPids, 
				Tcl_Pid * pidPtr));
/* 3 */
EXTERN int		TclpCreatePipe _ANSI_ARGS_((TclFile * readPipe, 
				TclFile * writePipe));
/* 4 */
EXTERN int		TclpCreateProcess _ANSI_ARGS_((Tcl_Interp * interp, 
				int argc, CONST char ** argv, 
				TclFile inputFile, TclFile outputFile, 
				TclFile errorFile, Tcl_Pid * pidPtr));
/* Slot 5 is reserved */
/* 6 */
EXTERN TclFile		TclpMakeFile _ANSI_ARGS_((Tcl_Channel channel, 
				int direction));
/* 7 */
EXTERN TclFile		TclpOpenFile _ANSI_ARGS_((CONST char * fname, 
				int mode));
/* 8 */
EXTERN int		TclUnixWaitForFile _ANSI_ARGS_((int fd, int mask, 
				int timeout));
/* 9 */
EXTERN TclFile		TclpCreateTempFile _ANSI_ARGS_((
				CONST char * contents));
/* 10 */
EXTERN Tcl_DirEntry *	TclpReaddir _ANSI_ARGS_((DIR * dir));
/* 11 */
EXTERN struct tm *	TclpLocaltime_unix _ANSI_ARGS_((
				CONST TclpTime_t clock));
/* 12 */
EXTERN struct tm *	TclpGmtime_unix _ANSI_ARGS_((CONST TclpTime_t clock));
/* 13 */
EXTERN char *		TclpInetNtoa _ANSI_ARGS_((struct in_addr addr));
#endif /* UNIX */
#ifdef __WIN32__
/* 0 */
EXTERN void		TclWinConvertError _ANSI_ARGS_((DWORD errCode));
/* 1 */
EXTERN void		TclWinConvertWSAError _ANSI_ARGS_((DWORD errCode));
/* 2 */
EXTERN struct servent *	 TclWinGetServByName _ANSI_ARGS_((CONST char * nm, 
				CONST char * proto));
/* 3 */
EXTERN int		TclWinGetSockOpt _ANSI_ARGS_((SOCKET s, int level, 
				int optname, char FAR * optval, 
				int FAR * optlen));
/* 4 */
EXTERN HINSTANCE	TclWinGetTclInstance _ANSI_ARGS_((void));
/* Slot 5 is reserved */
/* 6 */
EXTERN u_short		TclWinNToHS _ANSI_ARGS_((u_short ns));
/* 7 */
EXTERN int		TclWinSetSockOpt _ANSI_ARGS_((SOCKET s, int level, 
				int optname, CONST char FAR * optval, 
				int optlen));
/* 8 */
EXTERN unsigned long	TclpGetPid _ANSI_ARGS_((Tcl_Pid pid));
/* 9 */
EXTERN int		TclWinGetPlatformId _ANSI_ARGS_((void));
/* Slot 10 is reserved */
/* 11 */
EXTERN void		TclGetAndDetachPids _ANSI_ARGS_((Tcl_Interp * interp, 
				Tcl_Channel chan));
/* 12 */
EXTERN int		TclpCloseFile _ANSI_ARGS_((TclFile file));
/* 13 */
EXTERN Tcl_Channel	TclpCreateCommandChannel _ANSI_ARGS_((
				TclFile readFile, TclFile writeFile, 
				TclFile errorFile, int numPids, 
				Tcl_Pid * pidPtr));
/* 14 */
EXTERN int		TclpCreatePipe _ANSI_ARGS_((TclFile * readPipe, 
				TclFile * writePipe));
/* 15 */
EXTERN int		TclpCreateProcess _ANSI_ARGS_((Tcl_Interp * interp, 
				int argc, CONST char ** argv, 
				TclFile inputFile, TclFile outputFile, 
				TclFile errorFile, Tcl_Pid * pidPtr));
/* Slot 16 is reserved */
/* Slot 17 is reserved */
/* 18 */
EXTERN TclFile		TclpMakeFile _ANSI_ARGS_((Tcl_Channel channel, 
				int direction));
/* 19 */
EXTERN TclFile		TclpOpenFile _ANSI_ARGS_((CONST char * fname, 
				int mode));
/* 20 */
EXTERN void		TclWinAddProcess _ANSI_ARGS_((HANDLE hProcess, 
				DWORD id));
/* Slot 21 is reserved */
/* 22 */
EXTERN TclFile		TclpCreateTempFile _ANSI_ARGS_((
				CONST char * contents));
/* 23 */
EXTERN char *		TclpGetTZName _ANSI_ARGS_((int isdst));
/* 24 */
EXTERN char *		TclWinNoBackslash _ANSI_ARGS_((char * path));
/* 25 */
EXTERN TclPlatformType * TclWinGetPlatform _ANSI_ARGS_((void));
/* 26 */
EXTERN void		TclWinSetInterfaces _ANSI_ARGS_((int wide));
/* 27 */
EXTERN void		TclWinFlushDirtyChannels _ANSI_ARGS_((void));
/* 28 */
EXTERN void		TclWinResetInterfaces _ANSI_ARGS_((void));
/* 29 */
EXTERN int		TclWinCPUID _ANSI_ARGS_((unsigned int index, 
				unsigned int * regs));
#endif /* __WIN32__ */
#ifdef MAC_TCL
/* 0 */
EXTERN VOID *		TclpSysAlloc _ANSI_ARGS_((long size, int isBin));
/* 1 */
EXTERN void		TclpSysFree _ANSI_ARGS_((VOID * ptr));
/* 2 */
EXTERN VOID *		TclpSysRealloc _ANSI_ARGS_((VOID * cp, 
				unsigned int size));
/* 3 */
EXTERN void		TclpExit _ANSI_ARGS_((int status));
/* 4 */
EXTERN int		FSpGetDefaultDir _ANSI_ARGS_((FSSpecPtr theSpec));
/* 5 */
EXTERN int		FSpSetDefaultDir _ANSI_ARGS_((FSSpecPtr theSpec));
/* 6 */
EXTERN OSErr		FSpFindFolder _ANSI_ARGS_((short vRefNum, 
				OSType folderType, Boolean createFolder, 
				FSSpec * spec));
/* 7 */
EXTERN void		GetGlobalMouseTcl _ANSI_ARGS_((Point * mouse));
/* 8 */
EXTERN pascal OSErr	FSpGetDirectoryIDTcl _ANSI_ARGS_((
				CONST FSSpec * spec, long * theDirID, 
				Boolean * isDirectory));
/* 9 */
EXTERN pascal short	FSpOpenResFileCompatTcl _ANSI_ARGS_((
				CONST FSSpec * spec, SignedByte permission));
/* 10 */
EXTERN pascal void	FSpCreateResFileCompatTcl _ANSI_ARGS_((
				CONST FSSpec * spec, OSType creator, 
				OSType fileType, ScriptCode scriptTag));
/* 11 */
EXTERN int		FSpLocationFromPath _ANSI_ARGS_((int length, 
				CONST char * path, FSSpecPtr theSpec));
/* 12 */
EXTERN OSErr		FSpPathFromLocation _ANSI_ARGS_((FSSpecPtr theSpec, 
				int * length, Handle * fullPath));
/* 13 */
EXTERN void		TclMacExitHandler _ANSI_ARGS_((void));
/* 14 */
EXTERN void		TclMacInitExitToShell _ANSI_ARGS_((int usePatch));
/* 15 */
EXTERN OSErr		TclMacInstallExitToShellPatch _ANSI_ARGS_((
				ExitToShellProcPtr newProc));
/* 16 */
EXTERN int		TclMacOSErrorToPosixError _ANSI_ARGS_((int error));
/* 17 */
EXTERN void		TclMacRemoveTimer _ANSI_ARGS_((void * timerToken));
/* 18 */
EXTERN void *		TclMacStartTimer _ANSI_ARGS_((long ms));
/* 19 */
EXTERN int		TclMacTimerExpired _ANSI_ARGS_((void * timerToken));
/* 20 */
EXTERN int		TclMacRegisterResourceFork _ANSI_ARGS_((
				short fileRef, Tcl_Obj * tokenPtr, 
				int insert));
/* 21 */
EXTERN short		TclMacUnRegisterResourceFork _ANSI_ARGS_((
				char * tokenPtr, Tcl_Obj * resultPtr));
/* 22 */
EXTERN int		TclMacCreateEnv _ANSI_ARGS_((void));
/* 23 */
EXTERN FILE *		TclMacFOpenHack _ANSI_ARGS_((CONST char * path, 
				CONST char * mode));
/* 24 */
EXTERN char *		TclpGetTZName _ANSI_ARGS_((int isdst));
/* 25 */
EXTERN int		TclMacChmod _ANSI_ARGS_((CONST char * path, int mode));
/* 26 */
EXTERN int		FSpLLocationFromPath _ANSI_ARGS_((int length, 
				CONST char * path, FSSpecPtr theSpec));
#endif /* MAC_TCL */

typedef struct TclIntPlatStubs {
    int magic;
    struct TclIntPlatStubHooks *hooks;

#if !defined(__WIN32__) && !defined(MAC_TCL) /* UNIX */
    void (*tclGetAndDetachPids) _ANSI_ARGS_((Tcl_Interp * interp, Tcl_Channel chan)); /* 0 */
    int (*tclpCloseFile) _ANSI_ARGS_((TclFile file)); /* 1 */
    Tcl_Channel (*tclpCreateCommandChannel) _ANSI_ARGS_((TclFile readFile, TclFile writeFile, TclFile errorFile, int numPids, Tcl_Pid * pidPtr)); /* 2 */
    int (*tclpCreatePipe) _ANSI_ARGS_((TclFile * readPipe, TclFile * writePipe)); /* 3 */
    int (*tclpCreateProcess) _ANSI_ARGS_((Tcl_Interp * interp, int argc, CONST char ** argv, TclFile inputFile, TclFile outputFile, TclFile errorFile, Tcl_Pid * pidPtr)); /* 4 */
    void *reserved5;
    TclFile (*tclpMakeFile) _ANSI_ARGS_((Tcl_Channel channel, int direction)); /* 6 */
    TclFile (*tclpOpenFile) _ANSI_ARGS_((CONST char * fname, int mode)); /* 7 */
    int (*tclUnixWaitForFile) _ANSI_ARGS_((int fd, int mask, int timeout)); /* 8 */
    TclFile (*tclpCreateTempFile) _ANSI_ARGS_((CONST char * contents)); /* 9 */
    Tcl_DirEntry * (*tclpReaddir) _ANSI_ARGS_((DIR * dir)); /* 10 */
    struct tm * (*tclpLocaltime_unix) _ANSI_ARGS_((CONST TclpTime_t clock)); /* 11 */
    struct tm * (*tclpGmtime_unix) _ANSI_ARGS_((CONST TclpTime_t clock)); /* 12 */
    char * (*tclpInetNtoa) _ANSI_ARGS_((struct in_addr addr)); /* 13 */
#endif /* UNIX */
#ifdef __WIN32__
    void (*tclWinConvertError) _ANSI_ARGS_((DWORD errCode)); /* 0 */
    void (*tclWinConvertWSAError) _ANSI_ARGS_((DWORD errCode)); /* 1 */
    struct servent * (*tclWinGetServByName) _ANSI_ARGS_((CONST char * nm, CONST char * proto)); /* 2 */
    int (*tclWinGetSockOpt) _ANSI_ARGS_((SOCKET s, int level, int optname, char FAR * optval, int FAR * optlen)); /* 3 */
    HINSTANCE (*tclWinGetTclInstance) _ANSI_ARGS_((void)); /* 4 */
    void *reserved5;
    u_short (*tclWinNToHS) _ANSI_ARGS_((u_short ns)); /* 6 */
    int (*tclWinSetSockOpt) _ANSI_ARGS_((SOCKET s, int level, int optname, CONST char FAR * optval, int optlen)); /* 7 */
    unsigned long (*tclpGetPid) _ANSI_ARGS_((Tcl_Pid pid)); /* 8 */
    int (*tclWinGetPlatformId) _ANSI_ARGS_((void)); /* 9 */
    void *reserved10;
    void (*tclGetAndDetachPids) _ANSI_ARGS_((Tcl_Interp * interp, Tcl_Channel chan)); /* 11 */
    int (*tclpCloseFile) _ANSI_ARGS_((TclFile file)); /* 12 */
    Tcl_Channel (*tclpCreateCommandChannel) _ANSI_ARGS_((TclFile readFile, TclFile writeFile, TclFile errorFile, int numPids, Tcl_Pid * pidPtr)); /* 13 */
    int (*tclpCreatePipe) _ANSI_ARGS_((TclFile * readPipe, TclFile * writePipe)); /* 14 */
    int (*tclpCreateProcess) _ANSI_ARGS_((Tcl_Interp * interp, int argc, CONST char ** argv, TclFile inputFile, TclFile outputFile, TclFile errorFile, Tcl_Pid * pidPtr)); /* 15 */
    void *reserved16;
    void *reserved17;
    TclFile (*tclpMakeFile) _ANSI_ARGS_((Tcl_Channel channel, int direction)); /* 18 */
    TclFile (*tclpOpenFile) _ANSI_ARGS_((CONST char * fname, int mode)); /* 19 */
    void (*tclWinAddProcess) _ANSI_ARGS_((HANDLE hProcess, DWORD id)); /* 20 */
    void *reserved21;
    TclFile (*tclpCreateTempFile) _ANSI_ARGS_((CONST char * contents)); /* 22 */
    char * (*tclpGetTZName) _ANSI_ARGS_((int isdst)); /* 23 */
    char * (*tclWinNoBackslash) _ANSI_ARGS_((char * path)); /* 24 */
    TclPlatformType * (*tclWinGetPlatform) _ANSI_ARGS_((void)); /* 25 */
    void (*tclWinSetInterfaces) _ANSI_ARGS_((int wide)); /* 26 */
    void (*tclWinFlushDirtyChannels) _ANSI_ARGS_((void)); /* 27 */
    void (*tclWinResetInterfaces) _ANSI_ARGS_((void)); /* 28 */
    int (*tclWinCPUID) _ANSI_ARGS_((unsigned int index, unsigned int * regs)); /* 29 */
#endif /* __WIN32__ */
#ifdef MAC_TCL
    VOID * (*tclpSysAlloc) _ANSI_ARGS_((long size, int isBin)); /* 0 */
    void (*tclpSysFree) _ANSI_ARGS_((VOID * ptr)); /* 1 */
    VOID * (*tclpSysRealloc) _ANSI_ARGS_((VOID * cp, unsigned int size)); /* 2 */
    void (*tclpExit) _ANSI_ARGS_((int status)); /* 3 */
    int (*fSpGetDefaultDir) _ANSI_ARGS_((FSSpecPtr theSpec)); /* 4 */
    int (*fSpSetDefaultDir) _ANSI_ARGS_((FSSpecPtr theSpec)); /* 5 */
    OSErr (*fSpFindFolder) _ANSI_ARGS_((short vRefNum, OSType folderType, Boolean createFolder, FSSpec * spec)); /* 6 */
    void (*getGlobalMouseTcl) _ANSI_ARGS_((Point * mouse)); /* 7 */
    pascal OSErr (*fSpGetDirectoryIDTcl) _ANSI_ARGS_((CONST FSSpec * spec, long * theDirID, Boolean * isDirectory)); /* 8 */
    pascal short (*fSpOpenResFileCompatTcl) _ANSI_ARGS_((CONST FSSpec * spec, SignedByte permission)); /* 9 */
    pascal void (*fSpCreateResFileCompatTcl) _ANSI_ARGS_((CONST FSSpec * spec, OSType creator, OSType fileType, ScriptCode scriptTag)); /* 10 */
    int (*fSpLocationFromPath) _ANSI_ARGS_((int length, CONST char * path, FSSpecPtr theSpec)); /* 11 */
    OSErr (*fSpPathFromLocation) _ANSI_ARGS_((FSSpecPtr theSpec, int * length, Handle * fullPath)); /* 12 */
    void (*tclMacExitHandler) _ANSI_ARGS_((void)); /* 13 */
    void (*tclMacInitExitToShell) _ANSI_ARGS_((int usePatch)); /* 14 */
    OSErr (*tclMacInstallExitToShellPatch) _ANSI_ARGS_((ExitToShellProcPtr newProc)); /* 15 */
    int (*tclMacOSErrorToPosixError) _ANSI_ARGS_((int error)); /* 16 */
    void (*tclMacRemoveTimer) _ANSI_ARGS_((void * timerToken)); /* 17 */
    void * (*tclMacStartTimer) _ANSI_ARGS_((long ms)); /* 18 */
    int (*tclMacTimerExpired) _ANSI_ARGS_((void * timerToken)); /* 19 */
    int (*tclMacRegisterResourceFork) _ANSI_ARGS_((short fileRef, Tcl_Obj * tokenPtr, int insert)); /* 20 */
    short (*tclMacUnRegisterResourceFork) _ANSI_ARGS_((char * tokenPtr, Tcl_Obj * resultPtr)); /* 21 */
    int (*tclMacCreateEnv) _ANSI_ARGS_((void)); /* 22 */
    FILE * (*tclMacFOpenHack) _ANSI_ARGS_((CONST char * path, CONST char * mode)); /* 23 */
    char * (*tclpGetTZName) _ANSI_ARGS_((int isdst)); /* 24 */
    int (*tclMacChmod) _ANSI_ARGS_((CONST char * path, int mode)); /* 25 */
    int (*fSpLLocationFromPath) _ANSI_ARGS_((int length, CONST char * path, FSSpecPtr theSpec)); /* 26 */
#endif /* MAC_TCL */
} TclIntPlatStubs;

#ifdef __cplusplus
extern "C" {
#endif
extern TclIntPlatStubs *tclIntPlatStubsPtr;
#ifdef __cplusplus
}
#endif

#if defined(USE_TCL_STUBS) && !defined(USE_TCL_STUB_PROCS)

/*
 * Inline function declarations:
 */

#if !defined(__WIN32__) && !defined(MAC_TCL) /* UNIX */
#ifndef TclGetAndDetachPids
#define TclGetAndDetachPids \
	(tclIntPlatStubsPtr->tclGetAndDetachPids) /* 0 */
#endif
#ifndef TclpCloseFile
#define TclpCloseFile \
	(tclIntPlatStubsPtr->tclpCloseFile) /* 1 */
#endif
#ifndef TclpCreateCommandChannel
#define TclpCreateCommandChannel \
	(tclIntPlatStubsPtr->tclpCreateCommandChannel) /* 2 */
#endif
#ifndef TclpCreatePipe
#define TclpCreatePipe \
	(tclIntPlatStubsPtr->tclpCreatePipe) /* 3 */
#endif
#ifndef TclpCreateProcess
#define TclpCreateProcess \
	(tclIntPlatStubsPtr->tclpCreateProcess) /* 4 */
#endif
/* Slot 5 is reserved */
#ifndef TclpMakeFile
#define TclpMakeFile \
	(tclIntPlatStubsPtr->tclpMakeFile) /* 6 */
#endif
#ifndef TclpOpenFile
#define TclpOpenFile \
	(tclIntPlatStubsPtr->tclpOpenFile) /* 7 */
#endif
#ifndef TclUnixWaitForFile
#define TclUnixWaitForFile \
	(tclIntPlatStubsPtr->tclUnixWaitForFile) /* 8 */
#endif
#ifndef TclpCreateTempFile
#define TclpCreateTempFile \
	(tclIntPlatStubsPtr->tclpCreateTempFile) /* 9 */
#endif
#ifndef TclpReaddir
#define TclpReaddir \
	(tclIntPlatStubsPtr->tclpReaddir) /* 10 */
#endif
#ifndef TclpLocaltime_unix
#define TclpLocaltime_unix \
	(tclIntPlatStubsPtr->tclpLocaltime_unix) /* 11 */
#endif
#ifndef TclpGmtime_unix
#define TclpGmtime_unix \
	(tclIntPlatStubsPtr->tclpGmtime_unix) /* 12 */
#endif
#ifndef TclpInetNtoa
#define TclpInetNtoa \
	(tclIntPlatStubsPtr->tclpInetNtoa) /* 13 */
#endif
#endif /* UNIX */
#ifdef __WIN32__
#ifndef TclWinConvertError
#define TclWinConvertError \
	(tclIntPlatStubsPtr->tclWinConvertError) /* 0 */
#endif
#ifndef TclWinConvertWSAError
#define TclWinConvertWSAError \
	(tclIntPlatStubsPtr->tclWinConvertWSAError) /* 1 */
#endif
#ifndef TclWinGetServByName
#define TclWinGetServByName \
	(tclIntPlatStubsPtr->tclWinGetServByName) /* 2 */
#endif
#ifndef TclWinGetSockOpt
#define TclWinGetSockOpt \
	(tclIntPlatStubsPtr->tclWinGetSockOpt) /* 3 */
#endif
#ifndef TclWinGetTclInstance
#define TclWinGetTclInstance \
	(tclIntPlatStubsPtr->tclWinGetTclInstance) /* 4 */
#endif
/* Slot 5 is reserved */
#ifndef TclWinNToHS
#define TclWinNToHS \
	(tclIntPlatStubsPtr->tclWinNToHS) /* 6 */
#endif
#ifndef TclWinSetSockOpt
#define TclWinSetSockOpt \
	(tclIntPlatStubsPtr->tclWinSetSockOpt) /* 7 */
#endif
#ifndef TclpGetPid
#define TclpGetPid \
	(tclIntPlatStubsPtr->tclpGetPid) /* 8 */
#endif
#ifndef TclWinGetPlatformId
#define TclWinGetPlatformId \
	(tclIntPlatStubsPtr->tclWinGetPlatformId) /* 9 */
#endif
/* Slot 10 is reserved */
#ifndef TclGetAndDetachPids
#define TclGetAndDetachPids \
	(tclIntPlatStubsPtr->tclGetAndDetachPids) /* 11 */
#endif
#ifndef TclpCloseFile
#define TclpCloseFile \
	(tclIntPlatStubsPtr->tclpCloseFile) /* 12 */
#endif
#ifndef TclpCreateCommandChannel
#define TclpCreateCommandChannel \
	(tclIntPlatStubsPtr->tclpCreateCommandChannel) /* 13 */
#endif
#ifndef TclpCreatePipe
#define TclpCreatePipe \
	(tclIntPlatStubsPtr->tclpCreatePipe) /* 14 */
#endif
#ifndef TclpCreateProcess
#define TclpCreateProcess \
	(tclIntPlatStubsPtr->tclpCreateProcess) /* 15 */
#endif
/* Slot 16 is reserved */
/* Slot 17 is reserved */
#ifndef TclpMakeFile
#define TclpMakeFile \
	(tclIntPlatStubsPtr->tclpMakeFile) /* 18 */
#endif
#ifndef TclpOpenFile
#define TclpOpenFile \
	(tclIntPlatStubsPtr->tclpOpenFile) /* 19 */
#endif
#ifndef TclWinAddProcess
#define TclWinAddProcess \
	(tclIntPlatStubsPtr->tclWinAddProcess) /* 20 */
#endif
/* Slot 21 is reserved */
#ifndef TclpCreateTempFile
#define TclpCreateTempFile \
	(tclIntPlatStubsPtr->tclpCreateTempFile) /* 22 */
#endif
#ifndef TclpGetTZName
#define TclpGetTZName \
	(tclIntPlatStubsPtr->tclpGetTZName) /* 23 */
#endif
#ifndef TclWinNoBackslash
#define TclWinNoBackslash \
	(tclIntPlatStubsPtr->tclWinNoBackslash) /* 24 */
#endif
#ifndef TclWinGetPlatform
#define TclWinGetPlatform \
	(tclIntPlatStubsPtr->tclWinGetPlatform) /* 25 */
#endif
#ifndef TclWinSetInterfaces
#define TclWinSetInterfaces \
	(tclIntPlatStubsPtr->tclWinSetInterfaces) /* 26 */
#endif
#ifndef TclWinFlushDirtyChannels
#define TclWinFlushDirtyChannels \
	(tclIntPlatStubsPtr->tclWinFlushDirtyChannels) /* 27 */
#endif
#ifndef TclWinResetInterfaces
#define TclWinResetInterfaces \
	(tclIntPlatStubsPtr->tclWinResetInterfaces) /* 28 */
#endif
#ifndef TclWinCPUID
#define TclWinCPUID \
	(tclIntPlatStubsPtr->tclWinCPUID) /* 29 */
#endif
#endif /* __WIN32__ */
#ifdef MAC_TCL
#ifndef TclpSysAlloc
#define TclpSysAlloc \
	(tclIntPlatStubsPtr->tclpSysAlloc) /* 0 */
#endif
#ifndef TclpSysFree
#define TclpSysFree \
	(tclIntPlatStubsPtr->tclpSysFree) /* 1 */
#endif
#ifndef TclpSysRealloc
#define TclpSysRealloc \
	(tclIntPlatStubsPtr->tclpSysRealloc) /* 2 */
#endif
#ifndef TclpExit
#define TclpExit \
	(tclIntPlatStubsPtr->tclpExit) /* 3 */
#endif
#ifndef FSpGetDefaultDir
#define FSpGetDefaultDir \
	(tclIntPlatStubsPtr->fSpGetDefaultDir) /* 4 */
#endif
#ifndef FSpSetDefaultDir
#define FSpSetDefaultDir \
	(tclIntPlatStubsPtr->fSpSetDefaultDir) /* 5 */
#endif
#ifndef FSpFindFolder
#define FSpFindFolder \
	(tclIntPlatStubsPtr->fSpFindFolder) /* 6 */
#endif
#ifndef GetGlobalMouseTcl
#define GetGlobalMouseTcl \
	(tclIntPlatStubsPtr->getGlobalMouseTcl) /* 7 */
#endif
#ifndef FSpGetDirectoryIDTcl
#define FSpGetDirectoryIDTcl \
	(tclIntPlatStubsPtr->fSpGetDirectoryIDTcl) /* 8 */
#endif
#ifndef FSpOpenResFileCompatTcl
#define FSpOpenResFileCompatTcl \
	(tclIntPlatStubsPtr->fSpOpenResFileCompatTcl) /* 9 */
#endif
#ifndef FSpCreateResFileCompatTcl
#define FSpCreateResFileCompatTcl \
	(tclIntPlatStubsPtr->fSpCreateResFileCompatTcl) /* 10 */
#endif
#ifndef FSpLocationFromPath
#define FSpLocationFromPath \
	(tclIntPlatStubsPtr->fSpLocationFromPath) /* 11 */
#endif
#ifndef FSpPathFromLocation
#define FSpPathFromLocation \
	(tclIntPlatStubsPtr->fSpPathFromLocation) /* 12 */
#endif
#ifndef TclMacExitHandler
#define TclMacExitHandler \
	(tclIntPlatStubsPtr->tclMacExitHandler) /* 13 */
#endif
#ifndef TclMacInitExitToShell
#define TclMacInitExitToShell \
	(tclIntPlatStubsPtr->tclMacInitExitToShell) /* 14 */
#endif
#ifndef TclMacInstallExitToShellPatch
#define TclMacInstallExitToShellPatch \
	(tclIntPlatStubsPtr->tclMacInstallExitToShellPatch) /* 15 */
#endif
#ifndef TclMacOSErrorToPosixError
#define TclMacOSErrorToPosixError \
	(tclIntPlatStubsPtr->tclMacOSErrorToPosixError) /* 16 */
#endif
#ifndef TclMacRemoveTimer
#define TclMacRemoveTimer \
	(tclIntPlatStubsPtr->tclMacRemoveTimer) /* 17 */
#endif
#ifndef TclMacStartTimer
#define TclMacStartTimer \
	(tclIntPlatStubsPtr->tclMacStartTimer) /* 18 */
#endif
#ifndef TclMacTimerExpired
#define TclMacTimerExpired \
	(tclIntPlatStubsPtr->tclMacTimerExpired) /* 19 */
#endif
#ifndef TclMacRegisterResourceFork
#define TclMacRegisterResourceFork \
	(tclIntPlatStubsPtr->tclMacRegisterResourceFork) /* 20 */
#endif
#ifndef TclMacUnRegisterResourceFork
#define TclMacUnRegisterResourceFork \
	(tclIntPlatStubsPtr->tclMacUnRegisterResourceFork) /* 21 */
#endif
#ifndef TclMacCreateEnv
#define TclMacCreateEnv \
	(tclIntPlatStubsPtr->tclMacCreateEnv) /* 22 */
#endif
#ifndef TclMacFOpenHack
#define TclMacFOpenHack \
	(tclIntPlatStubsPtr->tclMacFOpenHack) /* 23 */
#endif
#ifndef TclpGetTZName
#define TclpGetTZName \
	(tclIntPlatStubsPtr->tclpGetTZName) /* 24 */
#endif
#ifndef TclMacChmod
#define TclMacChmod \
	(tclIntPlatStubsPtr->tclMacChmod) /* 25 */
#endif
#ifndef FSpLLocationFromPath
#define FSpLLocationFromPath \
	(tclIntPlatStubsPtr->fSpLLocationFromPath) /* 26 */
#endif
#endif /* MAC_TCL */

#endif /* defined(USE_TCL_STUBS) && !defined(USE_TCL_STUB_PROCS) */

/* !END!: Do not edit above this line. */

#endif /* _TCLINTPLATDECLS */
