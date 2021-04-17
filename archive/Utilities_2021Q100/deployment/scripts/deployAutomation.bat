echo off
REM #**************************************************************************
REM # BEGIN: deployAutomation.bat
REM #
REM # Usage: deployAutomation.bat [-f car-file-path] [-p DEPLOY_USER_PASSWORD] [-e external-id]
REM #        optional: -f full path to a .car file to deploy.
REM #                  if -f is NOT provided then this script will search all sub-folders for .car files.
REM #        optional: -p deployment user password
REM #                  If -p is NOT provided then this script will use local variable DEPLOY_USER_PASSWORD.
REM #        optional: -e external id
REM #                  Comes from a 3rd party deployment tool and is no more than 50 characters.
REM #                  
REM # The purpose of deployAutomation.sh is to automate the deployment of .car
REM #   files to the target environment where this script is installed.  This
REM #   script works on the concept of an inbox, where the inbox represents a
REM #   folder structure.  The folder is a direct representation of the TDV
REM #   folder structure and how privileges are to be applied in TDV.
REM # The script will find all .car files in the sub-folder structure from
REM #   oldest to newest and deploy them in sequence one-at-a-time.  If
REM #   collision-detection is configured in deployProjects.sh then .car file
REM #   resources will be checked for timestamp collisions.
REM # The script will output a one-line log entry in ./logs/Deploy_Automation.log
REM #   with success or failure of a .car file deployment.
REM #
REM # Requirements: 
REM #   This script requires powershell to be enabled for execution.
REM #   This script requires TDV 7.x or 8.x to be installed on the same server as these scripts.
REM #
REM # Integration Options:
REM #   Option 1 - Execute stand-alone.
REM #   Option 2 - Integrate with Windows Task Scheduler.
REM #              Refer to "Automation Configuration" section below.
REM #   Option 3 - Integrate with a 3rd party Deployment tool.
REM #              The 3rd party tool should be able to invoke batch scripts on the TDV server.
REM #              If the 3rd party tool can only invoke local scripts then the TDV binaries
REM #                 must be installed on the 3rd party tool server to satisfy pkg_import.bat requirements.
REM #
REM # Assumptions for apply privileges: 
REM #   Organization Name:  ABCBank     Filter in the privilege spreadsheet. 
REM #   Project Name:       Finance     Identifies the project in the privilege spreadsheet.
REM #   SubProject Name:    Accounting  Identifies the sub-project in the privilege spreadsheet.
REM #
REM # TDV Folder Structure:
REM # /services/databases/Finance
REM #                              /Accounting
REM #                              /GL
REM #                              /Taxes
REM # /services/webservices/Finance
REM #                              /Accounting
REM #                              /GL
REM #                              /Taxes
REM # /shared/Finance
REM #               /Application
REM #                        /Views
REM #                              /Accounting
REM #                              /GL
REM #                              /Taxes
REM #               /Business
REM #                        /Business
REM #                              /Accounting
REM #                              /GL
REM #                              /Taxes
REM #                        /Logical
REM #                              /Accounting
REM #                              /GL
REM #                              /Taxes
REM #               /Physical
REM #                        /Formatting
REM #                        /Metadata
REM #
REM # Inbox Folder Structure:
REM #   Base folder is a share accessible from the Windows Server and Windows desktop:
REM #      Z:/tibco/tdv/share
REM #   Standard deployment scripts structure is added to the share:
REM #
REM #      Z:/tibco/tdv/share/config/deployment/carfiles
REM #
REM #   The customized path representing TDV project folders and privileges is added:
REM #      Z:/tibco/tdv/share/config/deployment/carfiles/ABCBank/Finance/Accounting
REM #
REM #      Org      Projet  SubProject
REM #      /ABCBank/Finance
REM #                      /Accounting
REM #                      /Taxes
REM #                      /GL
REM #                      /Sources
REM #
REM # Automation Configuration:
REM #   For a TDV cluster, this should only be configured on the "primary" node as defined by the customer.
REM #
REM #   This script should be invoked by Windows Task Scheduler
REM #
REM #   Instructions to Create Task:
REM #   ----------------------------
REM #   1) Open Windows Task Scheduler on the TDV server
REM #   2) Right-click on Task Scheduler Library and create "New Folder" called "TibcoDV"
REM #   3) Right-click on "TibcoDV" and "Create Task"
REM #      TAB: General
REM #         Name:                 TibcoDV
REM #         Action:               TDV_Deploy_Automation
REM #         Description:          This trigger is used to automatically deploy .car files to TDV
REM #         Change User or Group: Change to run as the tibco user
REM #         Check box:            Run whether user is logged on or not
REM #         Configure for:        select the operating system from the drop down box
REM #      TAB: Trigger
REM #         Click "New" trigger
REM #         Begin Task:          On a schedule
REM #         Settings:            Daily
REM #         Start:               Leave the current date.  Set the time to be 12:00:00 AM
REM #         Repat Task Every:    Check box and change value to [15 minutes] for duration of [1 day]
REM #         Enabled:             Check the box
REM #         All other boxes are unchecked.
REM #         Click OK
REM #      TAB: Action
REM #         Click "New" Action
REM #         Action:              Start a program
REM #         Program/Script:      Browse to \deployment\scripts\deployAutomation.bat
REM #         Add arguments:       Put in the password for the DEPLOY_USER configured in this script.  Syntax: -p password
REM #         Start in:            Put in the path to the deployment scripts directory.
REM #         Click OK
REM #      TAB: Conditions
REM #         Power:               Checked by default
REM #                              Start the task only if computer is on AC power
REM #                              Stop if the computer switches to batter power
REM #         All other boxes are unchecked.
REM #      TAB: Settings
REM #         Allow task to be run on demand
REM #         Stop the task if it runs longer than: [2 hours]
REM #         If running task does not end when requested, force it to stop.
REM #         If the task is already running, then the following rule applies: [Do not start a new service]
REM #      Complete the configuration
REM #         Click OK
REM #         Provide user name and password of the computer administrator
REM #
REM #      The task has been scheduled.
REM #
REM #   Instructions to Disable Task:
REM #   -----------------------------
REM #   1) Open Windows Task Scheduler on the TDV server
REM #   2) Click on the TibcoDV folder
REM #   2) Right-click on the "TibcoDV" task and select "Disable"
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
REM #	Release:	Modified Date:	Modified By:		DV Version:		Reason:
REM #	2020.202	06/11/2020		Mike Tinius			7.0.8 / 8.x		Created new
REM #
REM ############################################################################################################################
REM #
REM #**************************************************************************
REM # MODIFY THE FOLLOWING VARIABLES.
REM #**************************************************************************
REM # debug: Y=debug on.  N=debug off.
set debug=N
REM # listFilesOnly: List the files but do not invoke deployProject.bat
set listFilesOnly=N
REM # pauseEnable: Y=pause on.  N=pause off. Pause after each .car file deployment.
set pauseEnable=N

REM # Environment Specific Variables
set ENV=TST
set DEPLOY_USER=admin
set DEPLOY_DOMAIN=composite
REM # The passed in password takes precedence over this setting.  
REM # If the password is not passed in this value must be set.
set DEPLOY_PASSWORD=
set ENCRYPT_PASSWORD=
set DEPLOY_HOST=%COMPUTERNAME%
set DEPLOY_PORT=9400
set DEPLOYMENT_DIR=C:\MySW\TDV_Scripts\7 0\deployment
set OPTION_FILE=%DEPLOYMENT_DIR%\option_files\options.txt
set CAR_FILE_DIR=%DEPLOYMENT_DIR%\carfiles
set SCRIPTDIR=%DEPLOYMENT_DIR%\scripts
set AUTOMATION_LOG_FILE=%SCRIPTDIR%\logs\Deployment_Automation.log
REM #**************************************************************************
REM # DO NOT MODIFY BELOW THIS LINE.
REM #**************************************************************************
REM #
REM #----------------------------
REM # Assign input parameters
REM #----------------------------
set CAR_FILE_PATH=
set EXTERNAL_ID=
set loopcount=0

:GET_PARAM_1
REM # Get param 1
set P1=%1
setlocal enabledelayedexpansion
if defined P1 set P1=!P1:"=!
endlocal & set P1=%P1%

REM # Get param 2
set P2=%2
setlocal enabledelayedexpansion
if defined P2 set P2=!P2:"=!
endlocal & set P2=%P2%

REM # increase the loop count
set /A loopcount=%loopcount%+1
if "%debug%" == "Y" (
   if "%P1%" ==  "-p" echo loopcount=%loopcount%  P1=[%P1%]   P2=[********]
   if "%P1%" NEQ "-p" echo loopcount=%loopcount%  P1=[%P1%]   P2=[%P2%]
)

REM # Handle use case with no parameters passed in
if "%P1%" NEQ "" GOTO PARSE_INPUT
REM # No more parameters found so the script is finished parsing input.
GOTO FINISHED_OPTIONAL_PARAMS

REM # Begin parsing input
:PARSE_INPUT
REM # Optional parameters
if "%P1%" == "-f" GOTO SET_CAR_FILE
if "%P1%" == "-p" GOTO SET_PASSWORD
if "%P1%" == "-e" GOTO SET_EXTERNAL_ID

REM # If no params found then SHIFT and goto get more parameters
SHIFT
GOTO GET_PARAM_1

:SET_CAR_FILE
set CAR_FILE_PATH=%P2%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_PASSWORD
set DEPLOY_PASSWORD=%P2%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_EXTERNAL_ID
set EXTERNAL_ID=%P2%
SHIFT
SHIFT
GOTO GET_PARAM_1
:FINISHED_OPTIONAL_PARAMS


REM #----------------------------
REM # Change to Script Directory
REM #----------------------------
REM # Change directories to the script directory
if not exist "%SCRIPTDIR%" (
   echo ERROR: The directory does not exist [%SCRIPTDIR%]
   exit /b 1
)
pushd .
cd %SCRIPTDIR%

REM #----------------------------
REM # Create Log File
REM #----------------------------
REM # Create the logs directory
if not exist "%SCRIPTDIR%\logs" mkdir "%SCRIPTDIR%\logs"
REM # Create the automation log file with a header if it does not exist
if not exist "%AUTOMATION_LOG_FILE%" echo.STATUS: :: FILE_DATE:          :: COMMAND: > "%AUTOMATION_LOG_FILE%"

REM #----------------------------
REM # Generate the car file list
REM #----------------------------
REM # If the car file path was passed into this script then only deploy that one car file by setting the CAR_FILE_DIR = CAR_FILE_PATH
if "%CAR_FILE_PATH%" NEQ "" (
   if not exist "%CAR_FILE_PATH%" echo ERROR: The file does not exist [%CAR_FILE_PATH%]
   if not exist "%CAR_FILE_PATH%" exit /b 1
   set CAR_FILE_DIR=%CAR_FILE_PATH%
) else (
   if not exist "%CAR_FILE_DIR%" echo ERROR: The directory does not exist [%CAR_FILE_DIR%]
   if not exist "%CAR_FILE_DIR%" exit /b 1
)

setlocal enabledelayedexpansion
set ERROR=0
REM #----------------------------
REM # Loop through the car file list
REM #----------------------------
FOR /F "eol=; tokens=1,2 delims=," %%I IN ('powershell "gci -rec -file '%CAR_FILE_DIR%' | sort LastWriteTime | select-object  fullname, LastWriteTime | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1"') DO (
   rem echo date=%%J   file=%%I
   REM #----------------------------
   REM # Deploy .CAR File
   REM #----------------------------
   CALL:DeployCarFile %%I %%J
   set ERROR=%ERRORLEVEL%
)

REM #----------------------------
REM # Exit the script
REM #----------------------------
popd
exit /b %ERROR%



REM #------------------
REM # FUNCTIONS
REM #------------------
:: #-------------------------------------------------------------
:LCase
:: #-------------------------------------------------------------
:: Subroutine to convert a variable VALUE to all lower case.
:: The argument for this subroutine is the variable NAME.
FOR %%i IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO CALL SET "%1=%%%1:%%~i%%"
GOTO:EOF

:: #-------------------------------------------------------------
:DeployCarFile filepath filedate
:: #-------------------------------------------------------------
:: # Deploy the .car file.
setlocal EnableDelayedExpansion
   set filepath=%~1
   set PKGDATE=%~2
   
   REM # Extract CAR_file - resolve relative paths with spaces to a full path.
   for /F "tokens=*" %%I in ("%filepath%") do set PKGFILE=%%~fI

   REM # Extract package file name only with extension
   for %%I in ("%PKGFILE%") do set PKGNAME=%%~nxI

   REM # Extract file extension
   for %%I in ("%PKGNAME%") do set PKGEXT=%%~xI
   call :LCase PKGEXT
   
   REM # Extract Parent path
   for /F "tokens=*" %%I in ("%PKGFILE%") do set PARENT=%%~pI
   REM # Extract SUBPROJECT_NAME name
   set "PARENT=%PARENT:~0,-1%"
   for %%I IN ("%PARENT%") DO SET "SUBPROJECT_NAME=%%~nxI"

   REM # Extract Grandparent path
   for /F "tokens=*" %%I in ("%PARENT%") do set GRANDPARENT=%%~pI
   REM # Extract PROJECT_NAME name
   set "GRANDPARENT=%GRANDPARENT:~0,-1%"
   for %%I IN ("%GRANDPARENT%") DO SET "PROJECT_NAME=%%~nxI"

   REM # Extract Great-Grandparent path
   for /F "tokens=*" %%I in ("%GRANDPARENT%") do set GREAT_GRANDPARENT=%%~pI
   REM # Extract ORGANIZATION name
   set "GREAT_GRANDPARENT=%GREAT_GRANDPARENT:~0,-1%"
   for %%I IN ("%GREAT_GRANDPARENT%") DO SET "ORGANIZATION=%%~nxI"

   REM # Debug   
   if "%debug%" == "Y" (
      echo.-----------------------------------------------------------------------------------------------------------------------------------------------
      echo.%0: Invoke deployProject.bat
      echo.-----------------------------------------------------------------------------------------------------------------------------------------------
      echo.PKGDATE=%PKGDATE%
      echo.PKGFILE=%PKGFILE%
      echo.PKGNAME=%PKGNAME%
      echo.PKGEXT=%PKGEXT%
      echo.ORGANIZATION=%ORGANIZATION%
      echo.PROJECT_NAME=%PROJECT_NAME%
      echo.SUBPROJECT_NAME=%SUBPROJECT_NAME%
   )

   REM # Add double quotes around the ENCRYPT_PASSWORD value.
   set ENCRYPT_COMMAND=-ep
   if "%ENCRYPT_PASSWORD%" == "" (
      set ENCRYPT_COMMAND=
   ) else (
      set ENCRYPT_PASSWORD="%ENCRYPT_PASSWORD%"
   )
   REM # Add double quotes around the OPTION_FILE value.
   set OPTION_FILE_COMMAND=-o
   if "%OPTION_FILE%" == "" (
      set OPTION_FILE_COMMAND=
   ) else (
      set OPTION_FILE="%OPTION_FILE%"
   )
   REM # Add double quotes around the ORGANIZATION value.
   set ORGANIZATION_COMMAND=-po
   if "%ORGANIZATION%" == "" (
      set ORGANIZATION_COMMAND=
   ) else (
      set ORGANIZATION="%ORGANIZATION%"
   )
   REM # Add the command in front of the external id
   set EXTERNAL_ID_COMMAND=-inp1
   if "%EXTERNAL_ID%" == "" (
      set EXTERNAL_ID_COMMAND=
   ) else (
      set EXTERNAL_ID="%EXTERNAL_ID%"
   )


   REM # Skip the file if it is not a .car file
   if "%PKGEXT%" NEQ ".car" (
      echo.   
      echo.-----------------------------------------------------------------------------------------------------------------------------------------------
      echo.Skipping non-car file: %PKGFILE%
      echo.-----------------------------------------------------------------------------------------------------------------------------------------------
	  GOTO SKIP_FILE
   )

   echo.   
   echo.-----------------------------------------------------------------------------------------------------------------------------------------------
   echo.CALL "%SCRIPTDIR%\deployProject.bat" -i "%PKGFILE%" %OPTION_FILE_COMMAND% %OPTION_FILE% -h "%DEPLOY_HOST%" -p %DEPLOY_PORT% -u "%DEPLOY_USER%" -d "%DEPLOY_DOMAIN%" -up "********" %ENCRYPT_COMMAND% %ENCRYPT_PASSWORD% -print -c -pd EXCEL -pe "%ENV%" %ORGANIZATION_COMMAND% %ORGANIZATION% -pp "%PROJECT_NAME%" -ps "%SUBPROJECT_NAME%" %EXTERNAL_ID_COMMAND% %EXTERNAL_ID%
   set PKGCMD=CALL ^"%SCRIPTDIR%\deployProject.bat^" -i ^"%PKGFILE%^" %OPTION_FILE_COMMAND% %OPTION_FILE% -h ^"%DEPLOY_HOST%^" -p %DEPLOY_PORT% -u ^"%DEPLOY_USER%^" -d "%DEPLOY_DOMAIN%" -up "********" %ENCRYPT_COMMAND% %ENCRYPT_PASSWORD% -print -c -pd EXCEL -pe ^"%ENV%^" %ORGANIZATION_COMMAND% %ORGANIZATION% -pp ^"%PROJECT_NAME%^" -ps ^"%SUBPROJECT_NAME%^" %EXTERNAL_ID_COMMAND% %EXTERNAL_ID%
   echo.-----------------------------------------------------------------------------------------------------------------------------------------------
   
   REM # Invoke the deployment script
   if "%listFilesOnly%" == "Y" GOTO LIST_ONLY
      call "%SCRIPTDIR%\deployProject.bat" -i "%PKGFILE%" %OPTION_FILE_COMMAND% %OPTION_FILE% -h "%DEPLOY_HOST%" -p %DEPLOY_PORT% -u "%DEPLOY_USER%" -d "%DEPLOY_DOMAIN%" -up "%DEPLOY_PASSWORD%" %ENCRYPT_COMMAND% %ENCRYPT_PASSWORD% -print -c -pd EXCEL -pe "%ENV%" %ORGANIZATION_COMMAND% %ORGANIZATION% -pp "%PROJECT_NAME%" -ps "%SUBPROJECT_NAME%" %EXTERNAL_ID_COMMAND% %EXTERNAL_ID%
      set ERROR=%ERRORLEVEL%
	  if %ERROR% EQU 0 (
         echo.************************************************
         echo.* SUCCESS: %PKGNAME% REMOVED
         echo.************************************************
         echo.SUCCESS :: %PKGDATE% :: %PKGCMD% >> "%AUTOMATION_LOG_FILE%"
         echo.-------------------------------------- >> "%AUTOMATION_LOG_FILE%"
         del /Q "%PKGFILE%"
      ) else (
         echo.************************************************
         echo.* ERROR: %PKGNAME% NOT REMOVED
         echo.************************************************
         echo.ERROR   :: %PKGDATE% :: %PKGCMD% >> "%AUTOMATION_LOG_FILE%"
         echo.-------------------------------------- >> "%AUTOMATION_LOG_FILE%"
      )

   :LIST_ONLY
   if "%pauseEnable%" == "Y" (
      echo.Press the space bar to continue...
      pause>null
   )
   :SKIP_FILE
   REM # exit this function with the error code
   exit /b %ERROR%
endlocal
GOTO:EOF
