@echo off
setlocal
REM #****************************************************************
REM # BEGIN: convertPkgFileV11_to_V10.bat
REM #	return 0 when TDV 7.x version 10 package .car file was found and not converted
REM #	return 1 when TDV 8.x version 11 package .car file was found and converted
REM #   return 98 if there was a usage error.
REM #   retrun 99 if there an execution error.
REM #
REM #	Convert a package .car file from TDV 8.x version 11 to 
REM #	TDV 7.x version 10.  This can be used when migrating car 
REM #	files from 8.x to 7.x.  This may be required while 
REM #	performing a server upgrade from version 7.x to 8.x 
REM #	starting with DEV and slowly upgrading the higher 
REM #	environments over the course of several weeks.
REM #
REM # Usage: convertPkgFileV11_to_V10.bat <CAR_file> [-q]
REM #    (optional) -q is quiet option.
REM #****************************************************************
REM #
REM ############################################################################################################################
REM # (c) 2017 TIBCO Software Inc. All rights reserved.
REM # 
REM # Except as specified below, this software is licensed pursuant to the Eclipse Public License v. 1.0.
REM # The details can be found in the file LICENSE.
REM # 
REM # The following proprietary files are included as a convenience, and may not be used except pursuant
REM # to valid license to Composite Information Server or TIBCO(R) Data Virtualization Server:
REM # csadmin-XXXX.jar, csarchive-XXXX.jar, csbase-XXXX.jar, csclient-XXXX.jar, cscommon-XXXX.jar,
REM # csext-XXXX.jar, csjdbc-XXXX.jar, csserverutil-XXXX.jar, csserver-XXXX.jar, cswebapi-XXXX.jar,
REM # and customproc-XXXX.jar (where -XXXX is an optional version number).  Any included third party files
REM # are licensed under the terms contained in their own accompanying LICENSE files, generally named .LICENSE.txt.
REM # 
REM # This software is licensed AS-IS. Support for this software is not covered by standard maintenance agreements with TIBCO.
REM # If you would like to obtain assistance with this software, such assistance may be obtained through a separate paid consulting
REM # agreement with TIBCO.
REM #
REM ############################################################################################################################
REM #
REM #----------------------------
REM # Set the script name
REM #----------------------------
set INDENT=    
set S=%INDENT%%~n0%~x0

REM #----------------------------
REM # Assign input parameters
REM #----------------------------
REM # Determine if there is any input first
set P1=%1
if defined P1 GOTO GET_INPUT
GOTO USAGE

:GET_INPUT
REM # Param 1: CAR_file - resolve relative paths with spaces to a full path.
for /F "tokens=*" %%I in ("%1") do set PKGFILE=%%~fI
REM # Param 1: package file name and extension
for %%I in ("%PKGFILE%") do set PKGNAME=%%~nxI
REM # Param 1: package file extension
for %%I in ("%PKGFILE%") do set PKGEXT=%%~xI

REM #----------------------------
REM # Validate Input
REM #----------------------------
REM # Check for no input
if "%PKGFILE%" == "" GOTO USAGE
REM # Check for file exists
if exist "%PKGFILE%" GOTO VALIDATE_FILE
   echo.%S%: The package .car file does not exist.  PKGFILE=%PKGFILE%
   GOTO USAGE
:VALIDATE_FILE
REM # Check for directory vs file name
if not exist "%PKGFILE%/nul" GOTO VALIDATE_EXTENSION
   echo.%S%: Invalid path.  PKGFILE must point to a file name and not a folder. PKGFILE=%PKGFILE%
   GOTO USAGE
:VALIDATE_EXTENSION   
REM # Validate .car extension
if "%PKGEXT%" == ".car" GOTO VALID_FILE
if "%PKGEXT%" == ".CAR" GOTO VALID_FILE
   echo.%S%: Invalid extension [%PKGEXT%].  PKGFILE must have a .car extension.  PKGFILE=%PKGFILE%
   GOTO USAGE
:VALID_FILE
set QUIET=%2
GOTO CONTINUE1
:USAGE
   echo.%INDENT%"Usage: %0 CAR_file [-q]"
   exit /b 98
:CONTINUE1

REM #----------------------------
REM # Set static variables
REM #----------------------------
set FROM_PKG_VERSION="  <packageFormatVersion>11</packageFormatVersion>"
set   TO_PKG_VERSION="  <packageFormatVersion>10</packageFormatVersion>"

REM #----------------------------
REM # Set additional derived variables
REM #----------------------------
set SCRIPTDIR=%~dp0
set TMPDIR=%SCRIPTDIR%
set TMPDIRZIP=%TMPDIR%tmpzip
set PSNAME_REPLACE=replaceText.ps1
set REPLACETEXT=%SCRIPTDIR%%PSNAME_REPLACE%
set PSNAME_FIND=findText.ps1
set FINDTEXT=%SCRIPTDIR%%PSNAME_FIND%
set SEARCHRESULTS=%SCRIPTDIR%searchResults.txt
set FOUND_PKG_VERSION_V11=0
set REPLACE_PKG_VERSION_V11=0

REM #----------------------------
REM # Display input
REM #----------------------------
if "%QUIET%" == "" (
   echo.%INDENT%==============================================================
   echo.%S%
   echo.%INDENT%   Parameters:
   echo.%INDENT%     PKGFILE=%PKGFILE%
   echo.%INDENT%   Static variables:
   echo.%INDENT%     FROM_PKG_VERSION=%FROM_PKG_VERSION%
   echo.%INDENT%     TO_PKG_VERSION=%TO_PKG_VERSION%
   echo.%INDENT%   Derived variables:
   echo.%INDENT%     SCRIPTDIR=%SCRIPTDIR%
   echo.%INDENT%     TMPDIRZIP=%TMPDIRZIP%
   echo.%INDENT%     FINDTEXT=%FINDTEXT%
   echo.%INDENT%     REPLACETEXT=%REPLACETEXT%
   echo.%INDENT%     SEARCHRESULTS=%SEARCHRESULTS%
)

if exist "%TMPDIRZIP%" (
   REM # delete and remove the temp zip directory
   if "%QUIET%" == "" echo.%S%: del /Q "%TMPDIRZIP%\*"
   del /Q "%TMPDIRZIP%\*"
   if "%QUIET%" == "" echo.%S%: rmdir /S /Q %TMPDIRZIP%\*.*
   for /D %%p in ("%TMPDIRZIP%\*.*") do rmdir "%%p" /s /q
   if exist "%TMPDIRZIP%" rmdir "%TMPDIRZIP%"
)

REM # Unzip the package .car file into the temp zip directory
if "%QUIET%" == "" echo.%S%: call :psunzip "%PKGFILE%" "%TMPDIRZIP%" %QUIET%
call :psunzip "%PKGFILE%" "%TMPDIRZIP%" %QUIET%
set PSERROR=%ERRORLEVEL%
if %PSERROR% NEQ 0 (
   set ERROR=99
   set message=:psunzip failed.  Aborting script.
   goto SCRIPT_CLEANUP_EXIT
)

REM #****************************************************************
REM #
REM # Search binary.xml, contenxt.xml, metadata.xml
REM # Find package format version 11 in .xml files and determine
REM #   if conversion is required or not.
REM #
REM #****************************************************************
REM #
if "%QUIET%" == "" echo.%S%: Begin search for package format version 11
if "%QUIET%" == "" echo.%S%:

set FILENAME=binary.xml
if not exist "%TMPDIRZIP%\%FILENAME%" GOTO FIND_CONTINUE2
   REM # Write out a powershell cmdlet to a file which searches an XML file for packageFormatVersion 11 (8.x .car file).
   REM #   The cmdlet writes out the response of "true" or "false" to a temporary file based on whether it found the search string or not.
   echo.powershell Select-String -Quiet -Path "'%TMPDIRZIP%\%FILENAME%'" -pattern "([regex]::Escape('<packageFormatVersion>11</packageFormatVersion>'))" ^| ForEach-Object{$_.ToString().ToLower()} > "%FINDTEXT%"
   
   REM # Execute the powershell cmdlet
   if "%QUIET%" == "" echo.%S%: powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%FINDTEXT%" ^> "%SEARCHRESULTS%"
   if "%QUIET%" == "" echo.%S%: %PSNAME_FIND% COMMAND:
   if "%QUIET%" == "" CALL:DisplayPowershellFile "%FINDTEXT%"
   call powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%FINDTEXT%" > "%SEARCHRESULTS%"
   set PSERROR=%ERRORLEVEL%
   if %PSERROR% NEQ 0 (
      set ERROR=99
      set message=powershell Find-Text failed.  Aborting script.
      goto SCRIPT_CLEANUP_EXIT
   )

   REM # Get the search result file contents.  Should be "true" or "false".  Anything else is an exception.
   set /p SEARCHRESULTS_CONTENTS=<"%SEARCHRESULTS%"
   if "%SEARCHRESULTS_CONTENTS%" == "true" (
      set FOUND_PKG_VERSION_V11=1
	  GOTO FIND_CONTINUE2_1
   ) 
   if "%SEARCHRESULTS_CONTENTS%" == "false" GOTO FIND_CONTINUE2_1
   
   REM # An exception has occurred because the file contents are not "true" or "false" so exit with an exception.
   set ERROR=99
   set message=FAILURE: %SEARCHRESULTS_CONTENTS% 
   goto SCRIPT_CLEANUP_EXIT
   
   :FIND_CONTINUE2_1
   if "%QUIET%" == "" echo.%S%: Found=%SEARCHRESULTS_CONTENTS%  FOUND_PKG_VERSION_V11 [%FILENAME%]=%FOUND_PKG_VERSION_V11%
   if "%QUIET%" == "" echo.%S%:
   if "%FOUND_PKG_VERSION_V11%" == "1" GOTO FIND_COMPLETE
:FIND_CONTINUE2

set FILENAME=contents.xml
if not exist "%TMPDIRZIP%\%FILENAME%" GOTO FIND_CONTINUE3
   REM # Write out a powershell cmdlet to a file which searches an XML file for packageFormatVersion 11 (8.x .car file).
   REM #   The cmdlet writes out the response of "true" or "false" to a temporary file based on whether it found the search string or not.
   echo.powershell Select-String -Quiet -Path "'%TMPDIRZIP%\%FILENAME%'" -pattern "([regex]::Escape('<packageFormatVersion>11</packageFormatVersion>'))" ^| ForEach-Object{$_.ToString().ToLower()} > "%FINDTEXT%"

   REM # Execute the powershell cmdlet
   if "%QUIET%" == "" echo.%S%: powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%FINDTEXT%" ^> "%SEARCHRESULTS%"
   if "%QUIET%" == "" echo.%S%: %PSNAME_FIND% COMMAND:
   if "%QUIET%" == "" CALL:DisplayPowershellFile "%FINDTEXT%"
   call powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%FINDTEXT%" > "%SEARCHRESULTS%"
   set PSERROR=%ERRORLEVEL%
   if %PSERROR% NEQ 0 (
      set ERROR=99
      set message=powershell Find-Text failed.  Aborting script.
      goto SCRIPT_CLEANUP_EXIT
   )

   REM # Get the search result file contents.  Should be "true" or "false".  Anything else is an exception.
   set /p SEARCHRESULTS_CONTENTS=<"%SEARCHRESULTS%"
   if "%SEARCHRESULTS_CONTENTS%" == "true" (
      set FOUND_PKG_VERSION_V11=1
	  GOTO FIND_CONTINUE3_1
   ) 
   if "%SEARCHRESULTS_CONTENTS%" == "false" GOTO FIND_CONTINUE3_1
   
   REM # An exception has occurred because the file contents are not "true" or "false" so exit with an exception.
   set ERROR=99
   set message=FAILURE: %SEARCHRESULTS_CONTENTS% 
   goto SCRIPT_CLEANUP_EXIT
   
   :FIND_CONTINUE3_1
   if "%QUIET%" == "" echo.%S%: Found=%SEARCHRESULTS_CONTENTS%  FOUND_PKG_VERSION_V11 [%FILENAME%]=%FOUND_PKG_VERSION_V11%
   if "%QUIET%" == "" echo.%S%:
   if "%FOUND_PKG_VERSION_V11%" == "1" GOTO FIND_COMPLETE
:FIND_CONTINUE3

set FILENAME=metadata.xml
if not exist "%TMPDIRZIP%\%FILENAME%" GOTO FIND_CONTINUE4
   REM # Write out a powershell cmdlet to a file which searches an XML file for packageFormatVersion 11 (8.x .car file).
   REM #   The cmdlet writes out the response of "true" or "false" to a temporary file based on whether it found the search string or not.
   echo.powershell Select-String -Quiet -Path "'%TMPDIRZIP%\%FILENAME%'" -pattern "([regex]::Escape('<packageFormatVersion>11</packageFormatVersion>'))" ^| ForEach-Object{$_.ToString().ToLower()} > "%FINDTEXT%"

   REM # Execute the powershell cmdlet
   if "%QUIET%" == "" echo.%S%: powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%FINDTEXT%" ^> "%SEARCHRESULTS%"
   if "%QUIET%" == "" echo.%S%: %PSNAME_FIND% COMMAND:
   if "%QUIET%" == "" CALL:DisplayPowershellFile "%FINDTEXT%"
   call powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%FINDTEXT%" > "%SEARCHRESULTS%"
   set PSERROR=%ERRORLEVEL%
   if %PSERROR% NEQ 0 (
      set ERROR=99
      set message=powershell Find-Text failed.  Aborting script.
      goto SCRIPT_CLEANUP_EXIT
   )

   REM # Get the search result file contents.  Should be "true" or "false".  Anything else is an exception.
   set /p SEARCHRESULTS_CONTENTS=<"%SEARCHRESULTS%"
   if "%SEARCHRESULTS_CONTENTS%" == "true" (
      set FOUND_PKG_VERSION_V11=1
	  GOTO FIND_CONTINUE4_1
   ) 
   if "%SEARCHRESULTS_CONTENTS%" == "false" GOTO FIND_CONTINUE4_1
   
   REM # An exception has occurred because the file contents are not "true" or "false" so exit with an exception.
   set ERROR=99
   set message=FAILURE: %SEARCHRESULTS_CONTENTS% 
   goto SCRIPT_CLEANUP_EXIT
   
   :FIND_CONTINUE4_1
   if "%QUIET%" == "" echo.%S%: Found=%SEARCHRESULTS_CONTENTS%  FOUND_PKG_VERSION_V11 [%FILENAME%]=%FOUND_PKG_VERSION_V11%
   if "%QUIET%" == "" echo.%S%:
   if "%FOUND_PKG_VERSION_V11%" == "1" GOTO FIND_COMPLETE
:FIND_CONTINUE4

:FIND_COMPLETE
if "%FOUND_PKG_VERSION_V11%" == "0" echo.%S%: *** Package Format Version 10 [DV 7.x] found. ***
if "%FOUND_PKG_VERSION_V11%" == "1" echo.%S%: *** Package Format Version 11 [DV 8.x] found. ***

REM # When FOUND_PKG_VERSION_V11=0 then the package .car file version is 10 [comes from DV version 7] then do nothing.
REM # When FOUND_PKG_VERSION_V11=1 then the package .car file version is 11 [comes from DV version 8] then 
REM #    convert the package .car file from package version 11 to package version 10 for DV 7.x import.
if "%FOUND_PKG_VERSION_V11%" == "0" GOTO CONVERSION_COMPLETE


REM #****************************************************************
REM #
REM # Replace text in binary.xml, contenxt.xml, metadata.xml
REM # Replace package format version 11 with 10 in .xml files
REM #
REM #****************************************************************
REM #
if "%QUIET%" == "" echo.%S%:
if "%QUIET%" == "" echo.%S%: Begin replace of package format version 11 with version 10
if "%QUIET%" == "" echo.%S%:

set FILENAME=binary.xml
if not exist "%TMPDIRZIP%\%FILENAME%" GOTO REPLACE_CONTINUE2
   REM # Write out a powershell cmdlet to a file which searches an XML file for packageFormatVersion 11 (8.x .car file) and replace with 10 (7.x .car file).
   echo (get-content "%TMPDIRZIP%\%FILENAME%") ^| ForEach-Object {$_ -replace %FROM_PKG_VERSION%, %TO_PKG_VERSION%} ^| set-content "%TMPDIRZIP%\%FILENAME%" > "%REPLACETEXT%"

   REM # Execute the powershell cmdlet
   if "%QUIET%" == "" echo.%S%: powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%REPLACETEXT%"
   if "%QUIET%" == "" echo.%S%: %PSNAME_REPLACE% COMMAND:
   if "%QUIET%" == "" CALL:DisplayPowershellFile "%REPLACETEXT%"
   if "%QUIET%" == "" echo.%S%:
   call powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%REPLACETEXT%"
   set PSERROR=%ERRORLEVEL%
   if %PSERROR% NEQ 0 (
      set ERROR=99
      set message=powershell Replace-Text failed.  Aborting script.
      goto SCRIPT_CLEANUP_EXIT
   )
   set REPLACE_PKG_VERSION_V11=1
:REPLACE_CONTINUE2

set FILENAME=contents.xml
if not exist "%TMPDIRZIP%\%FILENAME%" GOTO REPLACE_CONTINUE3
   REM # Write out a powershell cmdlet to a file which searches an XML file for packageFormatVersion 11 (8.x .car file) and replace with 10 (7.x .car file).
   echo (get-content "%TMPDIRZIP%\%FILENAME%") ^| ForEach-Object {$_ -replace %FROM_PKG_VERSION%, %TO_PKG_VERSION%} ^| set-content "%TMPDIRZIP%\%FILENAME%" > "%REPLACETEXT%"

   REM # Execute the powershell cmdlet
   if "%QUIET%" == "" echo.%S%: powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%REPLACETEXT%"
   if "%QUIET%" == "" echo.%S%: %PSNAME_REPLACE% COMMAND:
   if "%QUIET%" == "" CALL:DisplayPowershellFile "%REPLACETEXT%"
   if "%QUIET%" == "" echo.%S%:
   call powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%REPLACETEXT%"
   set PSERROR=%ERRORLEVEL%
   if %PSERROR% NEQ 0 (
      set ERROR=99
      set message=powershell Replace-Text failed.  Aborting script.
      goto SCRIPT_CLEANUP_EXIT
   )
   set REPLACE_PKG_VERSION_V11=1
:REPLACE_CONTINUE3

set FILENAME=metadata.xml
if not exist "%TMPDIRZIP%\%FILENAME%" GOTO REPLACE_CONTINUE4
   REM # Write out a powershell cmdlet to a file which searches an XML file for packageFormatVersion 11 (8.x .car file) and replace with 10 (7.x .car file).
   echo (get-content "%TMPDIRZIP%\%FILENAME%") ^| ForEach-Object {$_ -replace %FROM_PKG_VERSION%, %TO_PKG_VERSION%} ^| set-content "%TMPDIRZIP%\%FILENAME%" > "%REPLACETEXT%"

   REM # Execute the powershell cmdlet
   if "%QUIET%" == "" echo.%S%: powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%REPLACETEXT%"
   if "%QUIET%" == "" echo.%S%: %PSNAME_REPLACE% COMMAND:
   if "%QUIET%" == "" CALL:DisplayPowershellFile "%REPLACETEXT%"
   if "%QUIET%" == "" echo.%S%:
   call powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%REPLACETEXT%"
   set PSERROR=%ERRORLEVEL%
   if %PSERROR% NEQ 0 (
      set ERROR=99
      set message=powershell Replace-Text failed.  Aborting script.
      goto SCRIPT_CLEANUP_EXIT
   )
   set REPLACE_PKG_VERSION_V11=1
:REPLACE_CONTINUE4

:CONVERSION_COMPLETE
REM # Set a default message
set MESSAGE=No package .car file conversion required.

REM # Set the result ERROR code to the type of package that was found
set ERROR=%FOUND_PKG_VERSION_V11%

REM # Bypass the update of the package .car file if no changes are required.
if "%REPLACE_PKG_VERSION_V11%" == "0" GOTO SCRIPT_CLEANUP_EXIT

REM # Use pszip to zip up the package .car file from the temporary zip directory
if "%QUIET%" == "" echo.%S%: call :pszip "%TMPDIRZIP%" "%PKGFILE%" %QUIET%
call :pszip "%TMPDIRZIP%" "%PKGFILE%" %QUIET%
set PSERROR=%ERRORLEVEL%
if %PSERROR% NEQ 0 (
   set ERROR=99
   set message=:pszip failed.  Aborting script.
   goto SCRIPT_CLEANUP_EXIT
)
set MESSAGE=Successfully converted packageFormatVersion from 11 to 10 for %PKGNAME%


:SCRIPT_CLEANUP_EXIT
REM # Clean up temporary files
if exist "%FINDTEXT%" del /Q "%FINDTEXT%"
if exist "%SEARCHRESULTS%" del /Q "%SEARCHRESULTS%"
if exist "%REPLACETEXT%" del /Q "%REPLACETEXT%"

REM # delete and remove the temp zip directory
if exist "%TMPDIRZIP%" (
   if "%QUIET%" == "" echo.%S%:
   if "%QUIET%" == "" echo.%S%: del /Q "%TMPDIRZIP%\*"
   del /Q "%TMPDIRZIP%\*"
   if "%QUIET%" == "" echo.%S%: rmdir /S /Q %TMPDIRZIP%\*.*
   for /D %%p in ("%TMPDIRZIP%\*.*") do rmdir "%%p" /s /q
   rmdir "%TMPDIRZIP%"
)

if "%QUIET%" == "" (
	echo.%S%:
	echo.%S%: RESULT=%ERROR%  MESSAGE=%MESSAGE%
	echo.%INDENT%==============================================================
)
exit /b %ERROR%


REM ##############################
REM # FUNCTIONS
REM ##############################
:: -------------------------------------------------------------
:DisplayPowershellFile filename
:: -------------------------------------------------------------
::# Display the powershell file contents using the echo statement.
setlocal ENABLEDELAYEDEXPANSION
set filename=!%1!
set /p str=<"%filename%"
set str=%str:|=^^^|%
echo.%S%: %str%
endlocal
GOTO:EOF

REM #****************************************************************
REM # BEGIN: call :psunzip %1 %2 %3
REM #
REM #	Unzip a package .car file to a target directory.
REM #
REM # Usage: call :psunzip <CAR_file> <directory_to_unzip_to> -q
REM #    (optional) -q is quiet option.
REM #****************************************************************
:: -------------------------------------------------------------
:psunzip CAR_FILE DIRECTORY_ZIP_TO QUIET
:: -------------------------------------------------------------
REM #----------------------------
REM # Set the script name
REM #----------------------------
set INDENT=        
set PSU=%INDENT%:psunzip

REM #----------------------------
REM # Assign input parameters
REM #----------------------------
REM # Param 1: CAR_file - resolve relative paths with spaces to a full path.
for /F "tokens=*" %%I in ("%1") do set PKGFILE=%%~fI
REM # Param 1: path only with no file name
for /F "tokens=*" %%I in ("%PKGFILE%") do set PKGPATH=%%~pI
REM # Param 1: drive letter. e.g. C:
for %%I in ("%PKGFILE%") do set PKGDRIVE=%%~dI
REM # Param 1: package file name only with no extension
for %%I in ("%PKGFILE%") do set PKGNAME=%%~nI
REM # Param 1: package file extension
for %%I in ("%PKGFILE%") do set PKGEXT=%%~xI
REM # Param 2: target directory to unzip to
FOR /F "tokens=*" %%I IN ("%2") DO set TARGETPATH=%%~fI
REM # Param 3: Quiet mode: -q
set QUIET=%3

REM #----------------------------
REM # Set internal variables
REM #----------------------------
set DORENAME=0
set PKGFILE_UNZIP=%PKGFILE%

REM # Display input
if "%QUIET%" == "" (
   echo.%INDENT%==============================================================
   echo.%PSU% 
   echo.%INDENT%   Parameters:
   echo.%INDENT%     PKGFILE=%PKGFILE%
   echo.%INDENT%     PKGDRIVE=%PKGDRIVE%
   echo.%INDENT%     PKGPATH=%PKGPATH%
   echo.%INDENT%     PKGNAME=%PKGNAME%
   echo.%INDENT%     PKGEXT=%PKGEXT%
   echo.%INDENT%     TARGETPATH=%TARGETPATH%
)

REM # Test that the source file exists
if not exist "%PKGFILE%" (
   echo.%PSU%: Invalid source path.  The file does not exist: %PKGFILE%
   exit /b 1
)
REM # Validate package file path
if "%PKGEXT%" == ".zip" (
   REM # Display variables
   if "%QUIET%" neq "" GOTO UNZIP_FILE
      echo.%INDENT%   Derived variables:
      echo.%INDENT%     PKGFILE_UNZIP=%PKGFILE_UNZIP%
      echo.%INDENT%     DORENAME=%DORENAME%
   GOTO UNZIP_FILE
)
if "%PKGEXT%" == ".car" GOTO RENAME_PKGFILE
   echo.%PSU%: Invalid extension [%PKGEXT%] for PKGFILE=%PKGFILE%
   exit /b 1

:RENAME_PKGFILE
set DORENAME=1
set PKGFILE_UNZIP=%PKGDRIVE%%PKGPATH%%PKGNAME%.zip

REM # Display variables
if "%QUIET%" == "" (
   echo.%INDENT%   Derived variables:
   echo.%INDENT%     PKGFILE_UNZIP=%PKGFILE_UNZIP%
   echo.%INDENT%     DORENAME=%DORENAME%
)

REM # Execute the copy of filename.car to filename.zip
if "%QUIET%" == "" echo.%PSU%: powershell Copy-Item -Force -Path "'%PKGFILE%'" -Destination "'%PKGFILE_UNZIP%'"
powershell Copy-Item -Force -Path "'%PKGFILE%'" -Destination "'%PKGFILE_UNZIP%'"
set PSERROR=%ERRORLEVEL%
if %PSERROR% NEQ 0 (
   echo.%PSU%: Copy failed.  Aborting script. Error code: %PSERROR%
   echo.%PSU%: COMMAND: powershell Copy-Item -Force -Path "'%PKGFILE%'" -Destination "'%PKGFILE_UNZIP%'"
   exit /B %PSERROR%
)

:UNZIP_FILE
REM # Execute the unzip of filename.zip to the target directory
if "%QUIET%" == "" echo.%PSU%: powershell Expand-Archive -Force "'%PKGFILE_UNZIP%'" -DestinationPath "'%TARGETPATH%'"
powershell Expand-Archive -Force "'%PKGFILE_UNZIP%'" -DestinationPath "'%TARGETPATH%'"
set PSERROR=%ERRORLEVEL%
if %PSERROR% NEQ 0 (
   echo.%PSU%: Unzip failed.  Aborting script. Error code: %PSERROR%
   echo.%PSU%: COMMAND: powershell Expand-Archive -Force "'%PKGFILE_UNZIP%'" -DestinationPath "'%TARGETPATH%'"
   exit /B %PSERROR%
)
if "%DORENAME%" == "0" GOTO PSUNZIP_FINISHED

REM # Execute the remove of filename.zip
if "%QUIET%" == "" echo.%PSU%: powershell Remove-Item -Force "'%PKGFILE_UNZIP%'"
powershell Remove-Item -Force "'%PKGFILE_UNZIP%'"
set PSERROR=%ERRORLEVEL%
if %PSERROR% NEQ 0 (
   echo.%PSU%: Remove failed.  Aborting script. Error code: %PSERROR%
   echo.%PSU%: COMMAND: powershell Remove-Item -Force "'%PKGFILE_UNZIP%'"
   exit /B %PSERROR%
)

:PSUNZIP_FINISHED
if "%QUIET%" == "" echo.%PSU%: File successfully unzipped.
if "%QUIET%" == "" echo.%PSU%:
if "%QUIET%" == "" echo.%INDENT%==============================================================
exit /b 0


REM #****************************************************************
REM # BEGIN: call :pszip %1 %2 %3
REM #
REM #	Zip a source directory into package .car file.
REM #
REM # Usage: call :pszip <directory_to_zip_from> <CAR_file> -q
REM #    (optional) -q is quiet option.
REM #****************************************************************
:: -------------------------------------------------------------
:pszip DIRECTORY_ZIP_FROM CAR_FILE QUIET
:: -------------------------------------------------------------
REM #----------------------------
REM # Set the script name
REM #----------------------------
set INDENT=        
set PSZ=%INDENT%:pszip

REM #----------------------------
REM # Assign input parameters
REM #----------------------------
REM # Param 1: source directory to zip from
FOR /F "tokens=*" %%I IN ("%1") DO set SOURCEDIR=%%~fI
REM # Param 2: CAR_file - resolve relative paths with spaces to a full path.
for /F "tokens=*" %%I in ("%2") do set PKGFILE=%%~fI
REM # Param 2: path only with no file name
for /F "tokens=*" %%I in ("%PKGFILE%") do set PKGPATH=%%~pI
REM # Param 2: drive letter. e.g. C:
for %%I in ("%PKGFILE%") do set PKGDRIVE=%%~dI
REM # Param 2: package file name only with no extension
for %%I in ("%PKGFILE%") do set PKGNAME=%%~nI
REM # Param 2: package file extension
for %%I in ("%PKGFILE%") do set PKGEXT=%%~xI
REM # Param 3: Quiet mode: -q
set QUIET=%3

REM #----------------------------
REM # Set internal variables
REM #----------------------------
set DORENAME=0
set PKGFILE_ZIP=%PKGFILE%

REM # Display input
if "%QUIET%" == "" (
   echo.%INDENT%==============================================================
   echo.%PSZ% 
   echo.%INDENT%   Parameters:
   echo.%INDENT%     SOURCEDIR=%SOURCEDIR%
   echo.%INDENT%     PKGFILE=%PKGFILE%
   echo.%INDENT%     PKGDRIVE=%PKGDRIVE%
   echo.%INDENT%     PKGPATH=%PKGPATH%
   echo.%INDENT%     PKGNAME=%PKGNAME%
   echo.%INDENT%     PKGEXT=%PKGEXT%
)

REM # Test that the source directory exists
if not exist "%SOURCEDIR%" (
   echo.%PSZ%: Invalid source path.  The directory does not exist: %SOURCEDIR%
   exit /b 1
)
REM # Validate package file path
if "%PKGEXT%" == ".zip" (
   REM # Display variables
   if "%QUIET%" neq "" GOTO ZIP_FILE
      echo.%INDENT%   Derived variables:
      echo.%INDENT%     PKGFILE_ZIP=%PKGFILE_ZIP%
      echo.%INDENT%     DORENAME=%DORENAME%
   GOTO ZIP_FILE
)
if "%PKGEXT%" == ".car" GOTO SET_ZIP_NAME
   echo.%PSZ%: Invalid extension [%PKGEXT%] for PKGFILE=%PKGFILE%
   exit /b 1
   
:SET_ZIP_NAME
set DORENAME=1
set PKGFILE_ZIP=%PKGDRIVE%%PKGPATH%%PKGNAME%.zip

REM # Display variables
if "%QUIET%" == "" (
   echo.%INDENT%   Derived variables:
   echo.%INDENT%     PKGFILE_ZIP=%PKGFILE_ZIP%
   echo.%INDENT%     DORENAME=%DORENAME%
)

:ZIP_FILE
REM # Remove the file if it exists otherwise an error will be thrown by powershell
if "%QUIET%" == "" echo.%PSZ%: del /Q "%PKGFILE_ZIP%"
if exist "%PKGFILE_ZIP%" del /Q "%PKGFILE_ZIP%"

REM # Execute the zip compression on the directory into filename.zip
if "%QUIET%" == "" echo.%PSZ%: call powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::CreateFromDirectory("'%SOURCEDIR%\*'","'%PKGFILE_ZIP%'",[System.IO.Compression.CompressionLevel]::Optimal,$false); }"
call powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::CreateFromDirectory("'%SOURCEDIR%'","'%PKGFILE_ZIP%'",[System.IO.Compression.CompressionLevel]::Optimal,$false); }"
set PSERROR=%ERRORLEVEL%
if %PSERROR% NEQ 0 (
   echo.%PSZ%: Zip failed.  Aborting script. Error code: %PSERROR%
   echo.%PSZ%: COMMAND: powershell Compress-Archive -Force -CompressionLevel Optimal -Path "'%SOURCEDIR%\*'" -DestinationPath  "'%PKGFILE_ZIP%'"
   exit /B %PSERROR%
)
if "%DORENAME%" == "0" GOTO PSZIP_FINISHED

REM # Execute the move from filename.zip to filename.car
if "%QUIET%" == "" echo.%PSZ%: powershell Move-Item -Force -Path "'%PKGFILE_ZIP%'" -Destination "'%PKGFILE%'"
powershell Move-Item -Force -Path "'%PKGFILE_ZIP%'" -Destination "'%PKGFILE%'"
set PSERROR=%ERRORLEVEL%
if %PSERROR% NEQ 0 (
   echo.%PSZ%: Move failed.  Aborting script. Error code: %PSERROR%
   echo.%PSZ%: COMMAND: powershell Move-Item -Force -Path "'%PKGFILE_ZIP%'" -Destination "'%PKGFILE%'"
   exit /B %PSERROR%
)

:PSZIP_FINISHED
if "%QUIET%" == "" echo.%PSZ%: File successfully zipped.
if "%QUIET%" == "" echo.%PSZ%:
if "%QUIET%" == "" echo.%INDENT%==============================================================
exit /b 0