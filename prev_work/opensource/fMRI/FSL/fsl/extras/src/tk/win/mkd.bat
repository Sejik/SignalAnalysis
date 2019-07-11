@echo off
rem RCS: @(#) $Id: mkd.bat,v 1.1.1.1 2007/07/10 15:05:18 duncan Exp $

if exist %1\nul goto end

md %1
if errorlevel 1 goto end

echo Created directory %1

:end



