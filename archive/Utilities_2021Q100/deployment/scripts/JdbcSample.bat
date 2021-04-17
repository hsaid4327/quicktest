@echo off
setlocal
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
REM # Modify the DV_HOME
SET DV_HOME=C:\MySW\TDV8.0
REM # Modify \jre to \jdk for TDV 8.2 and higher
SET JAVA_HOME=%DV_HOME%\jdk

REM # Script Home Directory
SET SCRIPTDIR=%~dp0
REM ############################################################################################################################
REM #
REM # DO NOT MODIFY BELOW THIS LINE
REM # This file is generated and regenerated when certain
REM # configuration settings are changed.
REM # Setup environment variables required for application
REM #
set APPS_INSTALL_DIR=%DV_HOME%\apps\jdbc
set CONF_INSTALL_DIR=%DV_HOME%

if exist "%JAVA_HOME%" goto JAVA_HOME_SET
echo Please configure your JAVA_HOME setting in this script
endlocal
exit /B %ERRORLEVEL%

:JAVA_HOME_SET
rem configure keystore variables
rem
call "%CONF_INSTALL_DIR%\bin\init_server_keystore_files.bat"

rem Program options
rem
set CLASSPATH=%APPS_INSTALL_DIR%;%APPS_INSTALL_DIR%\lib\csjdbc.jar
rem For 8.x
if exist "%APPS_INSTALL_DIR%\lib\bcprov-jdk15on-1.62.jar" set CLASSPATH=%CLASSPATH%;%APPS_INSTALL_DIR%\lib\bcprov-jdk15on-1.62.jar
if exist "%APPS_INSTALL_DIR%\lib\bcpkix-jdk15on-1.62.jar" set CLASSPATH=%CLASSPATH%;%APPS_INSTALL_DIR%\lib\bcpkix-jdk15on-1.62.jar

set JAVA_OPTS=%VM_ARGS%
rem For 8.x
if exist "%APPS_INSTALL_DIR%\java.security" set JAVA_OPTS=%JAVA_OPTS% -Djava.security.properties="%APPS_INSTALL_DIR%\java.security"


rem Program arguments
rem
set DATA_SOURCE_NAME=%1
set HOST_NAME=%2
set PORT=%3
set USER=%4
set PASSWORD=%5
set DOMAIN_NAME=%6
set SQL_QUERY=%7

if "%8" == "-encrypt" goto ENCRYPTION
if "%8" == "-fileEncoding" goto FILE_ENCODING_NO_ENCRYPT
goto RUN

:ENCRYPTION
set ENCRYPT_OPTION=%8

if "%9" == "" goto RUN
if "%9" == "-fileEncoding" goto FILE_ENCODING_WITH_ENCRYPT
echo %9 is an invalid option.
echo Valid options are -encrypt or -fileEncoding <value>.
endlocal
exit 1

:FILE_ENCODING_WITH_ENCRYPT
shift
goto FILE_ENCODING

:FILE_ENCODING_NO_ENCRYPT
set ENCRYPT_OPTION=

:FILE_ENCODING
if not "%9" == "" goto FILE_ENCODING_SPECIFIED
echo Missing file encoding value for %8 option.
endlocal
exit 1

:FILE_ENCODING_SPECIFIED
set FILE_ENCODING_OPTION=-Dfile.encoding=%9
set VM_ARGS=%VM_ARGS% -Dfile.encoding=%9
set JAVA_OPTS=%VM_ARGS%


rem Run application 
rem
:RUN
rem uncomment for debug purposes only
rem echo INVOKE: "CALL %JAVA_HOME%\bin\java" %JAVA_OPTS% -classpath "%CLASSPATH%" JdbcSample %DATA_SOURCE_NAME% %HOST_NAME% %PORT% %USER% "********" %DOMAIN_NAME% %SQL_QUERY% %ENCRYPT_OPTION%
rem echo.
CALL "%JAVA_HOME%\bin\java" %JAVA_OPTS% -classpath "%CLASSPATH%" JdbcSample %DATA_SOURCE_NAME% %HOST_NAME% %PORT% %USER% %PASSWORD% %DOMAIN_NAME% %SQL_QUERY% %ENCRYPT_OPTION%

endlocal
exit /B %ERRORLEVEL%
