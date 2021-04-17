@echo off
setlocal
REM #****************************************************************
REM # BEGIN: deployProject.bat
REM #
REM # Usage: deployProject.bat -i <import_CAR_file> -o <options_file> -h <hostname> -p <wsport> -u <username> -d <domain> -up <user_password> -ep <encryptionPassword>
REM #          [-v] [-c] [-e] [-print] [-printOnly] [-printWarning] [-inp1 value] [-inp2 value] [-inp3 value] 
REM #          [-privsOnly] [-pe privilege_environment] [-pd privilege_datasource] [-po privilege_organization] [-pp privilege_project] [-ps privilege_sub_project]
REM #          [-sn privilege_sheet_name] [-rp privilege_resource_path] [-rt privilege_resource_type] [-gn privilege_group_name] [-gt privilege_group_type] [-gd privilege_group_domain] [-be privilege_bypass_errors]
REM #
REM # Parameter Definitions:
REM #  -i  [mandatory] import archive (CAR) file path (full or relative).
REM #  -h  [mandatory] host name or ip address of the DV server deploying to.
REM #  -p  [mandatory] web service port of the target DV server deploying to.  e.g. 9400
REM #  -u  [mandatory] username with admin privileges.
REM #  -d  [mandatory] domain of the username.
REM #  -up [mandatory] user password.
REM #  -o  [optional] options file path (full or relative).
REM #  -ep [optional] encryption password for the archive .CAR file for TDV 8.x.
REM #  -v  [optional] verbose mode.  Verbose is turned on for secondary script calls.  Otherwise the default is verbose is off.
REM #  -c  [optional] execute package .car file version check and conversion.  
REM #                Use -c in environments where you are migrating from DV 8.x into DV 7.x.
REM #                If not provided, version checking and .car file conversion will not be done which would be optimal to use
REM #                      when all environments are of the same major DV version such as all DV 7.x or all DV 8.x
REM #  -e  [optional] Encrypt the communication between client and TDV server.
REM #  -print        [optional] print info and contents of the package .car file and import the car file.  If -print is not used, the car will still be imported.
REM #  -printOnly    [optional] only print info and contents of the package .car file and do not import or execute any other option.  This option overrides -print.
REM #  -printWarning [optional] print the warnings for updatePrivilegesDriverInterface, importResourcePrivileges, importResourceOwnership and runAfterImport otherwise do not print them.
REM #  -privsOnly    [optional] execute the configured privilege strategy only.  Do no execute the full deployment.
REM #                           Execute either privilege strategy 1 or 2 based on configuration.  If strategy 2 is configured, then resource ownership may also be executed if configured.
REM #
REM # The following parameters may be passed into Strategy 1 for Privileges: updatePrivilegesDriverInterface
REM #   These parameters act as filters against the spreadsheet or database table.  The most common parameters are -pd, -pe, -po, -pp and -ps
REM #  -pe  [mandatory] privilege environment name.  [DEV, UAT, PROD]
REM #  -pd  [optional] privilege datasource type.  [EXCEL, DB_LLE_ORA, DB_LLE_SS, DB_PROD_ORA, DB_PROD_SS]
REM #  -po  [optional] privilege organization name.
REM #  -pp  [optional] privilege project name.
REM #  -ps  [optional] privilege sub-project name.
REM #  -sn  [optional] privilege excel sheet name.  [Privileges_shared, Privileges_databases, Privileges_webservices]
REM #  -rp  [optional] privilege resource path - The resource path in which to get/update privileges.  It may contain a wildcard "%".
REM #  -rt  [optional] privilege resource type - The resource type in which to get/update privileges.  It is always upper case. 
REM #                                               This will only be used when no "Resource_Path" or a single "Resource_Path" is provided.  
REM #                                               It is not used when a list of "Resource_Path" entries are provided.
REM #                                               E.g. DATA_SOURCE - a published datasource or physical metadata datasource.
REM #                                                    CONTAINER - a folder path, a catalog or schema path.
REM #                                                    COLUMN - a column from a table
REM #                                                    LINK - a published table or procedure.  If it resides in the path /services and points to a TABLE or PROCEDURE then it is a LINK.
REM #                                                    TABLE - a view in the /shared path.
REM #                                                    PROCEDURE a procedure in the /shared path.
REM #  -gn  [optional] privilege group name - The user/group name in which to get/update privileges.
REM #  -gt  [optional] privilege group type - Valid values are USER or GROUP
REM #  -gd  [optional] privilege group domain - The domain name in which to get/update privileges.
REM #  -be  [optional] privilege bypass errors - Bypass errors.  Throw exception when paths not found. N/Null (default) Do not bypass errors.  Y=bypass resource not found errors but report them.
REM #
REM # The following parameters may be passed into Strategy 2 for Privileges: importResourcePrivileges
REM #  -recurseChildResources [1 or 0] - A bit [default=1] flag indicating whether the privileges of the resources in the XML file should be recursively applied to any child resources (assumes the resource is a container).
REM #  -recurseDependencies   [1 or 0] - A bit [default=0] flag indicating whether the privileges of the resources in the XML file should be applied to any resources that they use.
REM #  -recurseDependents     [1 or 0] - A bit [default=0] flag indicating whether the privileges of the resources in the XML file should be applied to any resources that are used by them.
REM #
REM # The following parameter may be passed into validateDeployment and/or runAfterImport:
REM #  -inp1 [optional] Use this to represent a unique id for validating the deployment contents with an external log.
REM #     Format: -inp1 value
REM #             -inp1 signals the variable input.
REM #             value is the actual value with double quotes when spaces are present.
REM #  -inp2 [optional] Use this to represent any value
REM #     Format: -inp2 value
REM #             -inp2 signals the variable input.
REM #             value is the actual value with double quotes when spaces are present.
REM #  -inp3 [optional] Use this to represent any value
REM #     Format: -inp3 value
REM #             -inp3 signals the variable input.
REM #             value is the actual value with double quotes when spaces are present.
REM #
REM # DISCLAIMER: 
REM #    Migrating resources from 8.x to 7.x is not generally supported.
REM #    However, it does provide a way to move basic functionality coded in 8.x to 7.x.  
REM #    It does not support the ability to move new features that exist in 8.x but do not exist in 7.x.  
REM #    Exceptions may be thrown in this circumstance.
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
REM #	Release:	Modified Date:	Modified By:		DV Version:		Reason:
REM #	2019.400	12/31/2019		Mike Tinius			7.0.8 / 8.x		Initially created by several PSG team members
REM #	2020.202	06/11/2020		Mike Tinius			7.0.8 / 8.x		Modified script to pass in path of contents.xml to VALIDATE_DEPLOYMENT_URL.
REM #
REM ############################################################################################################################
REM #
REM #----------------------------------------------------------------------------------
REM # Modify the variables below according to your environment.
REM #----------------------------------------------------------------------------------

REM ####################################################################################################
REM #   DEBUG=Y will send the DEBUG value to TDV procedures and the procedures will write to DV cs_server.log file.
REM #         N will do nothing.
set DEBUG=N
REM ####################################################################################################


REM ####################################################################################################
REM # DV_HOME - This is the path on the deployment server of TDV home
REM #    Required parameter.
set DV_HOME=C:\MySW\TIBCO\DV7.0.8
REM ####################################################################################################


REM ####################################################################################################
REM # FULL_BACKUP_PATH - This is the path on the deployment server where TDV server backup files are stored.
REM #    Required parameter.
set FULL_BACKUP_PATH=C:\MySW\TDV_Scripts\7 0\deployment\fullbackup
REM ####################################################################################################


REM ####################################################################################################
REM # SERVER_ATTRIBUTE_DATABASE - This is the published database "ASAssets" and URL 
REM #   "Utilities.repository.getServerAttribute" to get a server attribute.
REM #   This is required if converting a .car file from 8.x to 7.x
REM #   This is the standard, generic database and URL.
REM #   Optional-leave blank if not using this feature.  Only database needs to be unset if not using.
REM #     set SERVER_ATTRIBUTE_DATABASE=ASAssets
set SERVER_ATTRIBUTE_DATABASE=ASAssets
set SERVER_ATTRIBUTE_URL=Utilities.repository.getServerAttribute
REM ####################################################################################################


REM ####################################################################################################
REM # Privileges and Ownership Strategy 1:
REM # -------------------------------------
REM # STRATEGY1_RESOURCE_PRIVILEGE_DATABASE - This is the published database "ASAssets" and URL 
REM #   "Utilities.deployment.updatePrivilegesDriverInterface" to set resource privileges
REM #   and resource ownership at a fine-grained level.
REM #   This strategy requires the open source ASAssets Data Abstraction Best Practices:
REM #      /shared/ASAssets/BestPractices_v81
REM #      At a minimum this datasource needs to be configured: 
REM #         /shared/ASAssets/BestPractices_v81/PrivilegeScripts/Metadata/Privileges_DS_EXCEL
REM #      The spreadsheet "Resource_Privileges_LOAD_DB.xlsx" is required to be on the DV server.
REM #   This is the standard, generic database and URL using the fine-grained methodology.
REM #   Optional-leave blank if not using this feature.  
REM #     set STRATEGY1_RESOURCE_PRIVILEGE_DATABASE=ASAssets
set STRATEGY1_RESOURCE_PRIVILEGE_DATABASE=ASAssets
set STRATEGY1_RESOURCE_PRIVILEGE_URL=Utilities.deployment.updatePrivilegesDriverInterface
REM ####################################################################################################


REM ####################################################################################################
REM # Privileges and Ownership Strategy 2:
REM # -------------------------------------
REM # This strategy uses the "ALL or NOTHING" approach where the privileges are stored in an XML file
REM #   on the server.  The resource ownerhship settings are stored in a text file on the server.
REM #   In this strategy all privileges in restored across all paths found in the XML file and the 
REM #   the same for resource ownership text file.  Granularity of settings is low.
REM # These two settings are packaged together as a similar strategy.  If not using then unset the 
REM #   database for each one below.
REM # The privileges and ownership are generated to files on the DV server using the following procedure:
REM #   /shared/ASAssets/Utilities/deployment/privileges/templates/runPrivilegeExport_1_DEV_template
REM #   /shared/ASAssets/Utilities/deployment/privileges/templates/runPrivilegeExport_2_TEST_template
REM #   /shared/ASAssets/Utilities/deployment/privileges/templates/runPrivilegeExport_3_PROD_template
REM #   Each one is different because the settings may be different in each environment.  It allows the 
REM #     developer to maintain them on DEV and deploy to the necessary environments and execute them in 
REM #     their appropriate environment.
REM #
REM # STRATEGY2_RESOURCE_PRIVILEGE_DATABASE - This is the published database "ASAssets" and URL 
REM #   "Utilities.deployment.importResourcePrivileges" to import and set resource privileges.
REM #   This is the standard, generic database and URL using the XML/text file methodology.
REM #   Optional-leave blank if not using this feature.  
REM #     set STRATEGY2_RESOURCE_PRIVILEGE_DATABASE=ASAssets
set STRATEGY2_RESOURCE_PRIVILEGE_DATABASE=
set STRATEGY2_RESOURCE_PRIVILEGE_URL=Utilities.deployment.importResourcePrivileges
REM # This is the path on the TDV server for "D:\TIBCO\deployment\privileges\privileges.xml".  
set STRATEGY2_RESOURCE_PRIVILEGE_FILE=C:\MySW\TDV_Scripts\7 0\deployment\privileges\privileges.xml
REM #
REM #
REM # STRATEGY2_RESOURCE_OWNERSHIP_DATABASE - This is the published database "ASAssets" and URL 
REM #   "Utilities.deployment.importResourceOwnership" to import and change resource ownership.
REM #   This is the standard, generic database and URL using the XML/text file methodology.  
REM #   Optional-leave blank if not using this feature.  Only database needs to be unset if not using.
REM #     set STRATEGY2_RESOURCE_OWNERSHIP_DATABASE=ASAssets
set STRATEGY2_RESOURCE_OWNERSHIP_DATABASE=
set STRATEGY2_RESOURCE_OWNERSHIP_URL=Utilities.deployment.importResourceOwnership
REM # This is the path on the TDV server for "D:\TIBCO\deployment\privileges\resource_ownership.txt".  
set STRATEGY2_RESOURCE_OWNERSHIP_FILE=C:\MySW\TDV_Scripts\7 0\deployment\privileges\resource_ownership.txt
REM ####################################################################################################


REM ####################################################################################################
REM # RUN_AFTER_IMPORT_DATABASE - This is the published database and URL for the "runAfterImport" custom call.  
REM #   Optional-leave blank if not using this feature.  Only database needs to be unset if not using.
REM #     set RUN_AFTER_IMPORT_DATABASE=ADMIN
set RUN_AFTER_IMPORT_DATABASE=CoE
set RUN_AFTER_IMPORT_URL=Deployment.PostDeployment.runAfterImport
REM ####################################################################################################


REM ####################################################################################################
REM # This is the published database and URL for the "validateDeployment" custom call.
REM #   Optional-leave blank if not using this feature.  Only database needs to be unset if not using.
REM #     set VALIDATE_DEPLOYMENT_DATABASE=ASAssets
set VALIDATE_DEPLOYMENT_DATABASE=ASAssets
set VALIDATE_DEPLOYMENT_URL=Utilities.deployment.validateDeployment
REM # This is the remote server location where metadata.xml files will be copied to for the TDV server to read from.
set VALIDATE_DEPLOYMENT_DIR=C:\MySW\TDV_Scripts\7 0\deployment\metadata
REM # This is the full path to the DV Deployment Validation table.  This points to the customer implementation of the "DV_DEPLOYMENT_VALIDATION" table.
REM #     e.g. /shared/Common/DeploymentValidation/Physical/Formatting/oracle/DV_DEPLOYMENT_VALIDATION
set VALIDATE_DV_TABLE_PATH=/shared/CoE/Deployment/DeploymentValidation/DV_DEPLOYMENT_VALIDATION
REM # The full path to the DV sequence num generator procedure path that has no input and returns a single scalar INTEGER output.
REM #     e.g. /shared/Common/DeploymentValidation/Physical/Formatting/getSequenceNum
set VALIDATE_DV_PROCEDURE_PATH=/shared/CoE/Deployment/DeploymentValidation/getSequenceNum
REM ####################################################################################################


REM #----------------------------------------------------------------------------------
REM # DO NOT MODIFY BELOW THIS POINT:
REM #----------------------------------------------------------------------------------

REM #----------------------------
REM # Set the script name
REM #----------------------------
set S=%~n0%~x0

echo.==============================================================
echo.%0: Begin Deployment
echo.

REM #----------------------------
REM # Set default parameters
REM #----------------------------
set loopcount=0
set QUIET=-q
set CONVERT=
set ENCRYPT=
set PRINT_OPTION=N
set PRINT_ONLY=N
set PRINT_WARNING=false
set PRIVS_ONLY=false
set PRIVS_CONFIGURED=false
set PKGFILE=
set OPTFILE=
set HOST=
set WSPORT=
set DBPORT=
set USER=
set DOMAIN=
set USER_PASSWORD=
set ENCRYPTION_PASSWORD=
REM # Variables for runAfterImport and ValidateDeployment
set INPUT1=
set INPUT2=
set INPUT3=
REM # Strategy 1 Privilege variables
set PRIVILEGE_DATASOURCE=
set PRIVILEGE_ENVIRONMENT=
set PRIVILEGE_ORGANIZATION=
set PRIVILEGE_PROJECT=
set PRIVILEGE_SUBPROJECT=
set PRIVILEGE_SHEET_NAME=
set PRIVILEGE_RESOURCE_PATH=
set PRIVILEGE_RESOURCE_TYPE=
set PRIVILEGE_GROUP_NAME=
set PRIVILEGE_GROUP_TYPE=
set PRIVILEGE_GROUP_DOMAIN=
set PRIVILEGE_BYPASS_ERRORS=N
REM # Strategy 2 Privilege variables
set RECURSE_CHILD_RESOURCES=1
set RECURSE_DEPENDENCIES=0
set RECURSE_DEPENDENTS=0

REM #----------------------------
REM # Assign input parameters
REM #----------------------------

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

if "%DEBUG%" == "Y" echo loopcount=%loopcount%  P1=[%P1%]   P2=[%P2%]

REM # Handle use case with no parameters passed in
if "%P1%" NEQ "" GOTO PARSE_INPUT
if %loopcount% EQU 1 GOTO USAGE
REM # No more parameters found so the script is finished parsing input.
GOTO FINISHED_OPTIONAL_PARAMS

REM # Begin parsing input
:PARSE_INPUT
REM # Optional parameters
if "%P1%" == "-v" GOTO SET_VERBOSE
if "%P1%" == "-c" GOTO SET_CONVERT
if "%P1%" == "-e" GOTO SET_ENCRYPT
if "%P1%" == "-print" GOTO SET_PRINT_OPTION
if "%P1%" == "-printOnly" GOTO SET_PRINT_ONLY
if "%P1%" == "-printonly" GOTO SET_PRINT_ONLY
if "%P1%" == "-printWarning" GOTO SET_PRINT_WARNING
if "%P1%" == "-printwarning" GOTO SET_PRINT_WARNING
if "%P1%" == "-privsOnly" GOTO SET_PRIVS_ONLY
if "%P1%" == "-privsonly" GOTO SET_PRIVS_ONLY
REM # Mandatory parameters
if "%P1%" == "-i" GOTO SET_PKGFILE
if "%P1%" == "-o" GOTO SET_OPTFILE
if "%P1%" == "-h" GOTO SET_HOST
if "%P1%" == "-p" GOTO SET_WSPORT
if "%P1%" == "-u" GOTO SET_USER
if "%P1%" == "-d" GOTO SET_DOMAIN
if "%P1%" == "-up" GOTO SET_USER_PASSWORD
if "%P1%" == "-ep" GOTO SET_ENCRYPTION_PASSWORD
REM # Strategy 1 Privilege parameters
if "%P1%" == "-pd" GOTO SET_PRIVILEGE_DATASOURCE
if "%P1%" == "-pe" GOTO SET_PRIVILEGE_ENVIRONMENT
if "%P1%" == "-po" GOTO SET_PRIVILEGE_ORGANIZATION
if "%P1%" == "-pp" GOTO SET_PRIVILEGE_PROJECT
if "%P1%" == "-ps" GOTO SET_PRIVILEGE_SUBPROJECT
if "%P1%" == "-sn" GOTO SET_PRIVILEGE_SHEET_NAME
if "%P1%" == "-rp" GOTO SET_PRIVILEGE_RESOURCE_PATH
if "%P1%" == "-rt" GOTO SET_PRIVILEGE_RESOURCE_TYPE
if "%P1%" == "-gn" GOTO SET_PRIVILEGE_GROUP_NAME
if "%P1%" == "-gt" GOTO SET_PRIVILEGE_GROUP_TYPE
if "%P1%" == "-gd" GOTO SET_PRIVILEGE_GROUP_DOMAIN
if "%P1%" == "-be" GOTO SET_PRIVILEGE_BYPASS_ERRORS
REM # Strategy 2 Privilege parameters
if "%P1%" == "-recurseChildResources" GOTO SET_RECURSE_CHILD_RESOURCES
if "%P1%" == "-recursechildresources" GOTO SET_RECURSE_CHILD_RESOURCES
if "%P1%" == "-recurseDependencies" GOTO SET_RECURSE_DEPENDENCIES
if "%P1%" == "-recursedependencies" GOTO SET_RECURSE_DEPENDENCIES
if "%P1%" == "-recurseDependents" GOTO SET_RECURSE_DEPENDENTS
if "%P1%" == "-recursedependents" GOTO SET_RECURSE_DEPENDENTS
REM # -input1 value parameters
if "%P1%" == "-inp1" GOTO SET_INPUT1
if "%P1%" == "-input1" GOTO SET_INPUT1
if "%P1%" == "-inp2" GOTO SET_INPUT2
if "%P1%" == "-input2" GOTO SET_INPUT2
if "%P1%" == "-inp3" GOTO SET_INPUT3
if "%P1%" == "-input3" GOTO SET_INPUT3

REM # If no params found then SHIFT and goto get more parameters
SHIFT
GOTO GET_PARAM_1

:SET_VERBOSE
set QUIET=
rem echo.QUIET=%QUIET%
SHIFT
GOTO GET_PARAM_1

:SET_CONVERT
set CONVERT=%P1%
rem echo.CONVERT=%CONVERT%
SHIFT
GOTO GET_PARAM_1

:SET_ENCRYPT
set ENCRYPT=-encrypt
rem echo.ENCRYPT=%ENCRYPT%
SHIFT
GOTO GET_PARAM_1

:SET_PRINT_OPTION
set PRINT_OPTION=Y
rem echo.PRINT_OPTION=%PRINT_OPTION%
SHIFT
GOTO GET_PARAM_1

:SET_PRINT_ONLY
set PRINT_OPTION=Y
set PRINT_ONLY=Y
rem echo.PRINT_ONLY=%PRINT_ONLY%
SHIFT
GOTO GET_PARAM_1

:SET_PRINT_WARNING
set PRINT_WARNING=true
rem echo.PRINT_WARNING=%PRINT_WARNING%
SHIFT
GOTO GET_PARAM_1

:SET_PRIVS_ONLY
set PRIVS_ONLY=true
rem echo.PRIVS_ONLY=%PRIVS_ONLY%
SHIFT
GOTO GET_PARAM_1

:SET_PKGFILE
REM # Param 1: CAR_file - resolve relative paths with spaces to a full path.
for /F "tokens=*" %%I in ("%P2%") do set PKGFILE=%%~fI
REM # Param 1: path only with no file name
for /F "tokens=*" %%I in ("%PKGFILE%") do set PKGPATH=%%~pI
REM # Param 1: package file name and extension
for %%I in ("%PKGFILE%") do set PKGNAME=%%~nxI
REM # Param 1: package file extension
for %%I in ("%PKGFILE%") do set PKGEXT=%%~xI
rem echo.PKGFILE=%PKGFILE%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_OPTFILE
REM # Param 2: option_file - resolve relative paths with spaces to a full path.
for /F "tokens=*" %%I in ("%P2%") do set OPTFILE=%%~fI
rem echo.OPTFILE=%OPTFILE%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_HOST
set HOST=%P2%
rem echo.HOST=%HOST%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_WSPORT
set WSPORT=%P2%
set /A DBPORT=%WSPORT%+1
rem echo.WSPORT=%WSPORT%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_USER
set USER=%P2%
rem echo.USER=%USER%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_DOMAIN
set DOMAIN=%P2%
rem echo.DOMAIN=%DOMAIN%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_USER_PASSWORD
set USER_PASSWORD=%P2%
rem echo.USER_PASSWORD=%USER_PASSWORD%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_ENCRYPTION_PASSWORD
REM # Param 8: encryption password for DV 8.x only [optional]
set ENCRYPTION_PASSWORD=%P2%
rem echo.ENCRYPTION_PASSWORD=%ENCRYPTION_PASSWORD%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_INPUT1
set INPUT1=%P2%
rem echo.INPUT1=%INPUT1%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_INPUT2
set INPUT2=%P2%
rem echo.INPUT2=%INPUT2%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_INPUT3
set INPUT3=%P2%
rem echo.INPUT3=%INPUT3%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_PRIVILEGE_DATASOURCE
set PRIVILEGE_DATASOURCE=%P2%
rem echo.PRIVILEGE_DATASOURCE=%PRIVILEGE_DATASOURCE%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_PRIVILEGE_ENVIRONMENT
set PRIVILEGE_ENVIRONMENT=%P2%
rem echo.PRIVILEGE_ENVIRONMENT=%PRIVILEGE_ENVIRONMENT%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_PRIVILEGE_ORGANIZATION
set PRIVILEGE_ORGANIZATION=%P2%
rem echo.PRIVILEGE_ORGANIZATION=%PRIVILEGE_ORGANIZATION%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_PRIVILEGE_PROJECT
set PRIVILEGE_PROJECT=%P2%
rem echo.PRIVILEGE_PROJECT=%PRIVILEGE_PROJECT%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_PRIVILEGE_SUBPROJECT
set PRIVILEGE_SUBPROJECT=%P2%
rem echo.PRIVILEGE_SUBPROJECT=%PRIVILEGE_SUBPROJECT%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_PRIVILEGE_SHEET_NAME
set PRIVILEGE_SHEET_NAME=%P2%
rem echo.PRIVILEGE_SHEET_NAME=%PRIVILEGE_SHEET_NAME%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_PRIVILEGE_RESOURCE_PATH
set PRIVILEGE_RESOURCE_PATH=%P2%
rem echo.PRIVILEGE_RESOURCE_PATH=%PRIVILEGE_RESOURCE_PATH%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_PRIVILEGE_RESOURCE_TYPE
set PRIVILEGE_RESOURCE_TYPE=%P2%
rem echo.PRIVILEGE_RESOURCE_TYPE=%PRIVILEGE_RESOURCE_TYPE%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_PRIVILEGE_GROUP_NAME
set PRIVILEGE_GROUP_NAME=%P2%
rem echo.PRIVILEGE_GROUP_NAME=%PRIVILEGE_GROUP_NAME%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_PRIVILEGE_GROUP_TYPE
set PRIVILEGE_GROUP_TYPE=%P2%
rem echo.PRIVILEGE_GROUP_TYPE=%PRIVILEGE_GROUP_TYPE%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_PRIVILEGE_GROUP_DOMAIN
set PRIVILEGE_GROUP_DOMAIN=%P2%
rem echo.PRIVILEGE_GROUP_DOMAIN=%PRIVILEGE_GROUP_DOMAIN%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_PRIVILEGE_BYPASS_ERRORS
set PRIVILEGE_BYPASS_ERRORS=%P2%
rem echo.PRIVILEGE_BYPASS_ERRORS=%PRIVILEGE_BYPASS_ERRORS%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_RECURSE_CHILD_RESOURCES
set RECURSE_CHILD_RESOURCES=%P2%
rem echo.RECURSE_CHILD_RESOURCES=%RECURSE_CHILD_RESOURCES%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_RECURSE_DEPENDENCIES
set RECURSE_DEPENDENCIES=%P2%
rem echo.RECURSE_DEPENDENCIES=%RECURSE_DEPENDENCIES%
SHIFT
SHIFT
GOTO GET_PARAM_1

:SET_RECURSE_DEPENDENTS
set RECURSE_DEPENDENTS=%P2%
rem echo.RECURSE_DEPENDENTS=%RECURSE_DEPENDENTS%
SHIFT
SHIFT
GOTO GET_PARAM_1
:FINISHED_OPTIONAL_PARAMS


REM #----------------------------
REM # Assign dynamic variables
REM #----------------------------
set WARNING=0
set SCRIPTDIR=%~dp0
echo SCRIPTDIR=%SCRIPTDIR%
set TMPDIR=%SCRIPTDIR%tmp_ps
set SCRIPTDIR_LOGS=%SCRIPTDIR%logs

set DT1=%DATE:~-4,4%_%DATE:~4,2%_%DATE:~7,2%
set DT1=%DT1: =0%
set TM1=%TIME:~0,2%_%TIME:~3,2%_%TIME:~6,2%
set TM1=%TM1: =0%
set MYDATETIME=%DT1%_%TM1%

set DT1=%DT1:_=-%
set TM1=%TM1:_=:%
set DEPLOYMENT_DATE_BEG=%DT1% %TM1%


REM # Create 2 different file qualifiers
set FILE_QUALIFIER1=%HOST%_%WSPORT%_%INPUT1%_%MYDATETIME%
set FILE_QUALIFIER1=%FILE_QUALIFIER1:.=_%
set FILE_QUALIFIER2=%HOST%_%WSPORT%_%MYDATETIME%
set FILE_QUALIFIER2=%FILE_QUALIFIER2:.=_%

set BACKUPFILENAME=%FULL_BACKUP_PATH%\pre_deploy_fsb_%FILE_QUALIFIER2%.car
set JDBC_RESULT_FILE=%TMPDIR%\jdbcSampleResults.txt
set PSNAME=findText.ps1
set FINDTEXT=%TMPDIR%\%PSNAME%
set SEARCHRESULTS=%TMPDIR%\searchResults.txt
set ARCHIVE_RESULT_FILE=%TMPDIR%\archivePkgContents_%MYDATETIME%.txt
set ARCHIVE_RESULT_FILE2=%TMPDIR%\archivePkgContents2_%MYDATETIME%.txt
set PS1=%TMPDIR%\ps1_pkgInfoContents_%MYDATETIME%.ps1
set PS2=%TMPDIR%\ps2_pkgCreationDate_%MYDATETIME%.ps1
set PS3=%TMPDIR%\ps3_pkgImportResults_%MYDATETIME%.ps1
set PS4=%TMPDIR%\ps4_displayFile_%MYDATETIME%.ps1
set PS5=%TMPDIR%\ps5_duration_%MYDATETIME%.ps1
set ARCHIVE_CREATION_DATE_FILE_PATH=%TMPDIR%\ps_pkgCreationDate_%MYDATETIME%.txt

set VALIDATE_DEPLOYMENT_CONTENT_PATH=%VALIDATE_DEPLOYMENT_DIR%\archive_contents_%FILE_QUALIFIER1%.xml
set VALIDATE_DEPLOYMENT_METADATA_PATH=%VALIDATE_DEPLOYMENT_DIR%\archive_metadata_%FILE_QUALIFIER1%.xml
set VALIDATE_METADATA_LOG=%SCRIPTDIR_LOGS%\validate_metadata_output_%FILE_QUALIFIER2%.log
set STRATEGY1_RESOURCE_PRIVILEGE_LOG=%SCRIPTDIR_LOGS%\strategy1_privilege_output_%FILE_QUALIFIER2%.log
set STRATEGY2_RESOURCE_PRIVILEGE_LOG=%SCRIPTDIR_LOGS%\strategy2_privilege_output_%FILE_QUALIFIER2%.log
set STRATEGY2_RESOURCE_OWNERSHIP_LOG=%SCRIPTDIR_LOGS%\strategy2_ownership_output_%FILE_QUALIFIER2%.log
set RUN_AFTER_IMPORT_LOG=%SCRIPTDIR_LOGS%\run_after_import_output_%FILE_QUALIFIER2%.log
set EXCEPTION_LOG=%SCRIPTDIR_LOGS%\exception_%FILE_QUALIFIER2%.log
set WARNING_OUTPUT=

REM # Create the temp directory for powershell script
if NOT EXIST "%TMPDIR%" mkdir "%TMPDIR%"
REM # Create the logs directory
if NOT EXIST "%SCRIPTDIR_LOGS%" mkdir "%SCRIPTDIR_LOGS%"

REM # Use the JdbcSample.bat in the local directory.
SET JDBC_SAMPLE_EXEC=%SCRIPTDIR%JdbcSample.bat
if NOT EXIST "%JDBC_SAMPLE_EXEC%" (
   echo.%S% Failure: The JdbcSample.bat script could not be found: "%JDBC_SAMPLE_EXEC%"
   echo.
   CALL:CleanUpTmpFiles
   exit /b 1
)

REM # Setup the conversion scripts
if NOT EXIST "%SCRIPTDIR%convertPkgFileV11_to_V10.bat" (
   echo.%S% Failure: The package conversion script could not be found: %SCRIPTDIR%convertPkgFileV11_to_V10.bat
   echo.
   CALL:CleanUpTmpFiles
   exit /b 1
)
set CONVERT_PKG_FILEV11=%SCRIPTDIR%convertPkgFileV11_to_V10.bat

REM #----------------------------
REM # Display input
REM #----------------------------
REM # Display Deployment or Privileges Only
if "%PRIVS_ONLY%" == "true" echo Executing Privileges Only
if "%PRIVS_ONLY%" == "false" echo Executing Deployment

echo.==============================================================
echo General Parameters:
echo    DEPLOYMENT_DATE_BEG=%DEPLOYMENT_DATE_BEG%
echo    DV_HOME=%DV_HOME%
echo    DEBUG=%DEBUG%
echo    QUIET=%QUIET%
echo    CONVERT=%CONVERT%
echo    PKGFILE=%PKGFILE%
echo    PKGNAME=%PKGNAME%
echo    OPTFILE=%OPTFILE%
echo    HOST=%HOST%
echo    WSPORT=%WSPORT%
echo    DBPORT=%DBPORT%
echo    USER=%USER%
echo    DOMAIN=%DOMAIN%
echo    ENCRYPT=%ENCRYPT%
echo    PRINT_OPTION=%PRINT_OPTION%
echo    PRINT_ONLY=%PRINT_ONLY%
echo    PRINT_WARNING=%PRINT_WARNING%
echo    PRIVS_ONLY=%PRIVS_ONLY%
echo    EXCEPTION_LOG=%EXCEPTION_LOG%

REM # Server Attributes
if "%SERVER_ATTRIBUTE_DATABASE%" == "" GOTO BYPASS_SERVER_ATTRIBUTE
   echo Server Attribute Parameters:
   echo    SERVER_ATTRIBUTE_DATABASE=%SERVER_ATTRIBUTE_DATABASE%
   echo    SERVER_ATTRIBUTE_URL=%SERVER_ATTRIBUTE_URL%
:BYPASS_SERVER_ATTRIBUTE

REM # Validate deployment
if "%VALIDATE_DEPLOYMENT_DATABASE%" == "" GOTO BYPASS_VALIDATE_DEPLOYMENT
   echo Validate Deployment Parameters:
   echo    VALIDATE_DEPLOYMENT_DATABASE=%VALIDATE_DEPLOYMENT_DATABASE%
   echo    VALIDATE_DEPLOYMENT_DIR=%VALIDATE_DEPLOYMENT_DIR%
   echo    VALIDATE_DV_TABLE_PATH=%VALIDATE_DV_TABLE_PATH%
   echo    VALIDATE_DV_PROCEDURE_PATH=%VALIDATE_DV_PROCEDURE_PATH%
   echo    INPUT1=%INPUT1%
   echo    VALIDATE_METADATA_LOG=%VALIDATE_METADATA_LOG%
:BYPASS_VALIDATE_DEPLOYMENT

REM # Strategy 1 Privileges and ownership
if "%STRATEGY1_RESOURCE_PRIVILEGE_DATABASE%" == "" GOTO BYPASS_STRATEGY1_PRIVILEGES
   echo Strategy 1 Privilege Parameters:
   echo    STRATEGY1_RESOURCE_PRIVILEGE_DATABASE=%STRATEGY1_RESOURCE_PRIVILEGE_DATABASE%
   echo    STRATEGY1_RESOURCE_PRIVILEGE_URL=%STRATEGY1_RESOURCE_PRIVILEGE_URL%
   echo    STRATEGY1_RESOURCE_PRIVILEGE_LOG=%STRATEGY1_RESOURCE_PRIVILEGE_LOG%
   echo    PRIVILEGE_DATASOURCE=%PRIVILEGE_DATASOURCE%
   echo    PRIVILEGE_ENVIRONMENT=%PRIVILEGE_ENVIRONMENT%
   echo    PRIVILEGE_ORGANIZATION=%PRIVILEGE_ORGANIZATION%
   echo    PRIVILEGE_PROJECT=%PRIVILEGE_PROJECT%
   echo    PRIVILEGE_SUBPROJECT=%PRIVILEGE_SUBPROJECT%
   echo    PRIVILEGE_SHEET_NAME=%PRIVILEGE_SHEET_NAME%
   echo    PRIVILEGE_RESOURCE_PATH=%PRIVILEGE_RESOURCE_PATH%
   echo    PRIVILEGE_RESOURCE_TYPE=%PRIVILEGE_RESOURCE_TYPE%
   echo    PRIVILEGE_GROUP_NAME=%PRIVILEGE_GROUP_NAME%
   echo    PRIVILEGE_GROUP_TYPE=%PRIVILEGE_GROUP_TYPE%
   echo    PRIVILEGE_GROUP_DOMAIN=%PRIVILEGE_GROUP_DOMAIN%
   echo    PRIVILEGE_BYPASS_ERRORS=%PRIVILEGE_BYPASS_ERRORS%
:BYPASS_STRATEGY1_PRIVILEGES

REM # Strategy 2 Privileges
if "%STRATEGY2_RESOURCE_PRIVILEGE_DATABASE%" == "" GOTO BYPASS_STRATEGY2_PRIVILEGES
   echo Strategy 2 Privilege Parameters:
   echo    STRATEGY2_RESOURCE_PRIVILEGE_DATABASE=%STRATEGY2_RESOURCE_PRIVILEGE_DATABASE%
   echo    STRATEGY2_RESOURCE_PRIVILEGE_URL=%STRATEGY2_RESOURCE_PRIVILEGE_URL%
   echo    STRATEGY2_RESOURCE_PRIVILEGE_FILE=%STRATEGY2_RESOURCE_PRIVILEGE_FILE%
   echo    STRATEGY2_RESOURCE_PRIVILEGE_LOG=%STRATEGY2_RESOURCE_PRIVILEGE_LOG%
REM # Strategy 2 additional parameters only if configured
   echo    RECURSE_CHILD_RESOURCES=%RECURSE_CHILD_RESOURCES%
   echo    RECURSE_DEPENDENCIES=%RECURSE_DEPENDENCIES%
   echo    RECURSE_DEPENDENTS=%RECURSE_DEPENDENTS%
:BYPASS_STRATEGY2_PRIVILEGES

REM # Strategy 2 Ownership
if "%STRATEGY2_RESOURCE_OWNERSHIP_DATABASE%" == "" GOTO BYPASS_STRATEGY2_RESOURCE_OWNERSHIP
   echo Strategy 2 Resource Ownership Parameters:
   echo    STRATEGY2_RESOURCE_OWNERSHIP_DATABASE=%STRATEGY2_RESOURCE_OWNERSHIP_DATABASE%
   echo    STRATEGY2_RESOURCE_OWNERSHIP_URL=%STRATEGY2_RESOURCE_OWNERSHIP_URL%
   echo    STRATEGY2_RESOURCE_OWNERSHIP_FILE=%STRATEGY2_RESOURCE_OWNERSHIP_FILE%
   echo    STRATEGY2_RESOURCE_OWNERSHIP_LOG=%STRATEGY2_RESOURCE_OWNERSHIP_LOG%
:BYPASS_STRATEGY2_RESOURCE_OWNERSHIP

REM # Run after input
if "%RUN_AFTER_IMPORT_DATABASE%" == "" GOTO BYPASS_RUN_AFTER_IMPORT
   echo Run After Input Parameters:
   echo    RUN_AFTER_IMPORT_DATABASE=%RUN_AFTER_IMPORT_DATABASE%
   echo    RUN_AFTER_IMPORT_URL=%RUN_AFTER_IMPORT_URL%
   echo    RUN_AFTER_IMPORT_LOG=%RUN_AFTER_IMPORT_LOG%
   echo    INPUT1=%INPUT1%
   echo    INPUT2=%INPUT2%
   echo    INPUT3=%INPUT3%
:BYPASS_RUN_AFTER_IMPORT


REM # Script variables
echo Script Variables:
echo    SCRIPTDIR=%SCRIPTDIR%
echo    TMPDIR=%TMPDIR%
echo    SCRIPTDIR_LOGS=%SCRIPTDIR_LOGS%
echo    BACKUPFILENAME=%BACKUPFILENAME%
echo    JDBC_SAMPLE_EXEC=%JDBC_SAMPLE_EXEC%
echo    CONVERT_PKG_FILEV11=%CONVERT_PKG_FILEV11%
echo    VALIDATE_DEPLOYMENT_CONTENT_PATH=%VALIDATE_DEPLOYMENT_CONTENT_PATH%
echo    VALIDATE_DEPLOYMENT_METADATA_PATH=%VALIDATE_DEPLOYMENT_METADATA_PATH%
echo.==============================================================
echo.

REM #----------------------------
REM # Validate input parameters
REM #----------------------------
REM # Check for no input
set MESSAGE=One or more required input parameters are blank. [HOST]
if "%HOST%" == "" GOTO USAGE
set MESSAGE=One or more required input parameters are blank. [WSPORT]
if "%WSPORT%" == "" GOTO USAGE
set MESSAGE=One or more required input parameters are blank. [USER]
if "%USER%" == "" GOTO USAGE
set MESSAGE=One or more required input parameters are blank. [DOMAIN]
if "%DOMAIN%" == "" GOTO USAGE

REM # Param 6: Prompt for user password if not provided
if "%USER_PASSWORD%" == "" powershell -Command $pword = read-host "enter %USER% PASSWORD" -AsSecureString ; $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pword) ; [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) > .tmp.txt & set /p USER_PASSWORD=<.tmp.txt & del .tmp.txt

REM # Bypass car file validation if privs only execution
if "%PRIVS_ONLY%" == "true" GOTO PRIVSONLY

REM #----------------------------
REM # Validate package file
REM #----------------------------
REM # Validate package file
set MESSAGE=One or more required input parameters are blank. [PKGFILE]
if "%PKGFILE%" == "" GOTO USAGE

REM #----------------------------
REM # Validate files exist
REM #----------------------------
REM # Check for package file exists
if exist "%PKGFILE%" GOTO VALIDATE1
   set MESSAGE=The package .car file does not exist.  PKGFILE=%PKGFILE%
   GOTO USAGE
:VALIDATE1
REM # Check for directory vs file name
if not exist "%PKGFILE%/nul" GOTO VALIDATE2
   set MESSAGE=Invalid path.  PKGFILE must point to a file name and not a folder. PKGFILE=%PKGFILE%
   GOTO USAGE
:VALIDATE2
REM # Validate .car extension
if "%PKGEXT%" == ".car" GOTO VALIDATE3
if "%PKGEXT%" == ".CAR" GOTO VALIDATE3
   set MESSAGE=Invalid extension [%PKGEXT%].  PKGFILE must have a .car extension.  PKGFILE=%PKGFILE%
   GOTO USAGE
:VALIDATE3
REM # Check for option file exists
if "%OPTFILE%" == "" GOTO VALIDATE4
if exist "%OPTFILE%" GOTO VALIDATE4
   set MESSAGE=The option file does not exist.  OPTFILE=%OPTFILE%
   GOTO USAGE


REM #----------------------------
REM # Validate privs only
REM #----------------------------
:PRIVSONLY
REM # Validate that a privilege strategy is configured when PRIVS_ONLY=true
if "%STRATEGY1_RESOURCE_PRIVILEGE_DATABASE%" neq "" set PRIVS_CONFIGURED=true
if "%STRATEGY2_RESOURCE_PRIVILEGE_DATABASE%" neq "" set PRIVS_CONFIGURED=true
if "%STRATEGY2_RESOURCE_OWNERSHIP_DATABASE%" neq "" set PRIVS_CONFIGURED=true
if "%PRIVS_CONFIGURED%" == "true" GOTO VALIDATE4
   set MESSAGE=The parameter -privsOnly is set and no privilege strategy database has been configured.
   GOTO USAGE


:VALIDATE4
if "%STRATEGY1_RESOURCE_PRIVILEGE_DATABASE%" == "" GOTO CONTINUE1
if "%PRIVILEGE_ENVIRONMENT%" neq "" GOTO CONTINUE1
   set MESSAGE=The parameter -pe "PRIVILEGE_ENVIRONMENT" is required to be set when "STRATEGY1_RESOURCE_PRIVILEGE_DATABASE" is configured.
   GOTO USAGE
 

:USAGE
   CALL:CleanUpTmpFiles
   echo.
   echo ====================================================================================================
   echo ^| %MESSAGE%
   echo ^|
   echo ^| Usage: %S% -i ^<import_CAR_file^> -o ^<options_file^> -h ^<hostname^> -p ^<wsport^> -u ^<username^> -d ^<domain^> -up ^<user_password^> 
   echo ^|    Mandatory Params: 
   echo ^|      -i  [mandatory] import archive (CAR) file path (full or relative).
   echo ^|      -h  [mandatory] host name or ip address of the DV server deploying to.
   echo ^|      -p  [mandatory] web service port of the target DV server deploying to.  e.g. 9400
   echo ^|      -u  [mandatory] username with admin privileges.
   echo ^|      -d  [mandatory] domain of the username.
   echo ^|      -up [mandatory] user password.
   echo ^|    Optional Params: 
   echo ^|      -o  [optional] options file path (full or relative).
   echo ^|      -ep encryptionPassword [optional] encryption password for the archive (CAR) file for TDV 8.x.
   echo ^|      -v  [optional] verbose output
   echo ^|      -c  [optional] convert 8.x package .car to a 7.x .car file
   echo ^|      -e  [optional] encrypt the communication with https
   echo ^|      -print        [optional] print info and contents of the package .car file and import the car file.  If -print is not used, the car will still be imported.
   echo ^|      -printOnly    [optional] only print info and contents of the package .car file and do not import or execute any other option.  This option overrides -print.
   echo ^|      -printWarning [optional] print the warnings for updatePrivilegesDriverInterface, importResourcePrivileges, importResourceOwnership and runAfterImport otherwise do not print them.
   echo ^|      -privsOnly    [optional] execute the configured privilege strategy only.  Do no execute the full deployment.
   echo ^|    Optional "validateDeployment" and/or "runAfterInput" Params: 
   echo ^|      -inp1 value [optional] Input value 1 [validateDeployment-An external id to correlate to an external system.] or [runAfterImport]
   echo ^|      -inp2 value [optional] Input value 2 [runAfterImport]
   echo ^|      -inp3 value [optional] Input value 3 [runAfterImport]
   echo ^|    Optional Privilege Strategy1 "updatePrivilegesDriver" Params: 
   echo ^|      -pe value [mandatory] privileges-environment-name  [DEV, UAT, PROD]
   echo ^|      -pd value [optional] privileges-datasource  [EXCEL, DB_LLE_ORA, DB_LLE_SS, DB_PROD_ORA, DB_PROD_SS]
   echo ^|      -po value [optional] privileges-organization-name
   echo ^|      -pp value [optional] privileges-project-name
   echo ^|      -ps value [optional] privileges-sub-project name
   echo ^|      -sn value [optional] privilege excel sheet name.  [Privileges_shared, Privileges_databases, Privileges_webservices]
   echo ^|      -rp value [optional] privilege resource path - The resource path in which to get/update privileges.  It may contain a wildcard "%%".
   echo ^|      -rt value [optional] privilege resource type - The resource type in which to get/update privileges.  It is always upper case. 
   echo ^|      -gn value [optional] privilege group name - The user/group name in which to get/update privileges.
   echo ^|      -gt value [optional] privilege group type - Valid values are USER or GROUP
   echo ^|      -gd value [optional] privilege group domain - The domain name in which to get/update privileges.
   echo ^|      -be value [optional] privilege bypass errors - Throw exception when paths not found. N=Do not bypass errors. Y=bypass resource not found errors but report them.
   echo ^|    Optional Privilege Strategy2 "importResourcePrivileges" Params: 
   echo ^|      -recurseChildResources [1 or 0] - A bit [default=1] flag indicating whether the privileges of the resources in the XML file should be recursively applied to any child resources. 
   echo ^|      -recurseDependencies   [1 or 0] - A bit [default=0] flag indicating whether the privileges of the resources in the XML file should be applied to any resources that they use.
   echo ^|      -recurseDependents     [1 or 0] - A bit [default=0] flag indicating whether the privileges of the resources in the XML file should be applied to any resources that are used by them.
   echo ====================================================================================================
   exit /b 1
:CONTINUE1


REM ################################
REM # BEGIN CHECK SERVER VERSION
REM ################################
if "%PRIVS_ONLY%" == "true" GOTO BYPASS_SERVER_ATTRIBUTES
if "%SERVER_ATTRIBUTE_DATABASE%" == "" GOTO BYPASS_SERVER_ATTRIBUTES
set DV_PROCEDURE="%SERVER_ATTRIBUTE_URL%"
echo.%S%: --------------------------------------------------------------------   
echo.%S%: *** Checking Server Version. ***
echo.%S%: --------------------------------------------------------------------   
echo.%S%: *** CALL "%JDBC_SAMPLE_EXEC%" "%SERVER_ATTRIBUTE_DATABASE%" "%HOST%" "%DBPORT%" "%USER%" "********" "%DOMAIN%" "SELECT * FROM %SERVER_ATTRIBUTE_URL%('/server/config/info/versionFull')" ^> "%JDBC_RESULT_FILE%" ***
CALL "%JDBC_SAMPLE_EXEC%" "%SERVER_ATTRIBUTE_DATABASE%" "%HOST%" "%DBPORT%" "%USER%" "%USER_PASSWORD%" "%DOMAIN%" "SELECT * FROM %SERVER_ATTRIBUTE_URL%('/server/config/info/versionFull')" > "%JDBC_RESULT_FILE%"
set ERROR=%ERRORLEVEL%
if %ERROR% NEQ 0 (
   echo.%S%: %DV_PROCEDURE% failed.  Aborting script. Error code: %ERROR%
   GOTO COMPLETED_ERROR
)

REM # Set the search text to search for version 8
set DISPLAY_CONTENTS=false
set SEARCH_TEXT=col[1]^=``8
CALL:GetDVProcedureResults
set ERROR=%ERRORLEVEL%
if exist "%JDBC_RESULT_FILE%" del /Q "%JDBC_RESULT_FILE%"
if %ERROR% GTR 1 GOTO COMPLETED_ERROR
REM # Default so that version 8 was not found
set FOUND_DV_VERSION8=0
REM # Version 8 was found
if %ERROR% EQU 1 set FOUND_DV_VERSION8=1
echo.%S%: *** %DV_PROCEDURE% successfully completed. ***

REM # If FOUND_DV_VERSION8=1, then this is a DV version 8 server so no package .car file conversion is required.
REM # If FOUND_DV_VERSION8=0, then this is probably a DV version 7 and conversion may be required.
if "%FOUND_DV_VERSION8%" == "0" echo.%S%: *** Version 8.x [false] FOUND_DV_VERSION8=%FOUND_DV_VERSION8% ***
if "%FOUND_DV_VERSION8%" == "1" echo.%S%: *** Version 8.x [true] FOUND_DV_VERSION8=%FOUND_DV_VERSION8% ***
echo.


REM ################################
REM # BEGIN CONVERT PACKAGE FILE
REM #       FROM VERSION 11 to 10
REM #       FOR MIGRATING 8.x to 7.x
REM ################################
REM # Bypass conversion checking and .car file conversion when CONVERT <> -c
if NOT "%CONVERT%" == "-c" GOTO CONVERSION_COMPLETE
REM # Conversion is required for a package format version 11 being imported into a DV version 7.
echo.%S%: --------------------------------------------------------------------   
echo.%S%: *** Converting Package File Version 11 to 10. ***
echo.%S%: --------------------------------------------------------------------   
REM # If FOUND_DV_VERSION8=1, then this is a DV version 8 server so no package .car file conversion is required.
REM # If FOUND_DV_VERSION8=0, then this is probably a DV version 7 and conversion may be required.
if "%FOUND_DV_VERSION8%" == "1" (
   echo.%S%: *** No package .car file conversion required. ***
   echo.
   GOTO CONVERSION_COMPLETE
)
REM # Perform the conversion
echo.%S%: *** CALL "%CONVERT_PKG_FILEV11%" "%PKGFILE%" %QUIET% ***
CALL "%CONVERT_PKG_FILEV11%" "%PKGFILE%" %QUIET%
set IS_V11=%ERRORLEVEL%
if %IS_V11% gtr 1 (
   set ERROR=%IS_V11%
   echo.%S%: Package conversion failed.  Aborting script. Error code: %ERROR%
   GOTO COMPLETED_ERROR
)
if "%IS_V11%" == "0" echo.%S%: *** No package .car file conversion required. ***
if "%IS_V11%" == "1" echo.%S%: *** Package .car file conversion completed with status=SUCCESS ***
echo.
:CONVERSION_COMPLETE
:BYPASS_SERVER_ATTRIBUTES


REM ################################
REM # BEGIN FULL SERVER BACKUP
REM ################################
if "%PRIVS_ONLY%" == "true" GOTO BYPASS_FULL_BACKUP
if "%FULL_BACKUP_PATH%" == "" GOTO BYPASS_FULL_BACKUP
if "%PRINT_ONLY%" == "Y" GOTO BYPASS_FULL_BACKUP
echo.%S%: --------------------------------------------------------------------   
echo.%S%: *** Backing up target server %HOST%:%WSPORT% ***
echo.%S%: --------------------------------------------------------------------   
if "%QUIET%" == "" echo.%S%: *** Backup file will be located at:  %BACKUPFILENAME% ***
REM # Execute without the encryption password DV 7.x
if "%ENCRYPTION_PASSWORD%" neq "" GOTO BACKUP_WITH_ENCRYPTION
   echo.%S%: *** CALL "%DV_HOME%\bin\backup_export.bat" -pkgfile "%BACKUPFILENAME%" %ENCRYPT% -server "%HOST%" -port %WSPORT% -user "%USER%" -domain "%DOMAIN%" -password "********" -includeStatistics ***
   CALL "%DV_HOME%\bin\backup_export.bat" -pkgfile "%BACKUPFILENAME%" %ENCRYPT% -server "%HOST%" -port %WSPORT% -user "%USER%" -domain "%DOMAIN%" -password "%USER_PASSWORD%" -includeStatistics
   set ERROR=%ERRORLEVEL%
   if %ERROR% NEQ 0 (
      echo.%S%: backup_export failed.  Aborting script. Error code: %ERROR%"
      GOTO COMPLETED_ERROR
   )
   GOTO BACKUP_COMPLETE

REM # Execute with the encryption password DV 8.x
:BACKUP_WITH_ENCRYPTION
   echo.%S%: "*** CALL "%DV_HOME%\bin\backup_export.bat" -pkgfile "%BACKUPFILENAME%" %ENCRYPT% -server "%HOST%" -port %WSPORT% -user "%USER%" -domain "%DOMAIN%" -password "********" -includeStatistics -encryptionPassword "********" ***"
   CALL "%DV_HOME%\bin\backup_export.bat" -pkgfile "%BACKUPFILENAME%" %ENCRYPT% -server "%HOST%" -port %WSPORT% -user "%USER%" -domain "%DOMAIN%" -password "%USER_PASSWORD%" -includeStatistics -encryptionPassword "%ENCRYPTION_PASSWORD%"
   set ERROR=%ERRORLEVEL%
   if %ERROR% NEQ 0 (
      echo.%S%: backup_export failed.  Aborting script. Error code: %ERROR%"
      GOTO COMPLETED_ERROR
   )
:BACKUP_COMPLETE
echo.%S%: *** Backup created with status=SUCCESS ***
echo.
:BYPASS_FULL_BACKUP


REM ################################
REM # PRINT CAR FILE INFO/CONTENTS
REM ################################
if "%PRIVS_ONLY%" == "true" GOTO BYPASS_PRINT_CAR_FILE
if "%PRINT_OPTION%" neq "Y" GOTO BYPASS_PRINT_CAR_FILE
echo.%S%: --------------------------------------------------------------------   
echo.%S%: *** PRINT CAR file INFO and CONTENTS ***
echo.%S%: --------------------------------------------------------------------   
REM # Execute without the encryption password DV 7.x
if "%ENCRYPTION_PASSWORD%" neq "" GOTO PRINT_WITH_ENCRYPTION
   echo.%S%: *** CALL "%DV_HOME%\bin\pkg_import.bat" -pkgfile "%PKGFILE%" %ENCRYPT% -verbose -printinfo -printcontents -server "%HOST%" -port %WSPORT% -user "%USER%" -password "********" -domain "%DOMAIN%" ^> "%ARCHIVE_RESULT_FILE%" ***
   CALL "%DV_HOME%\bin\pkg_import.bat" -pkgfile "%PKGFILE%" %ENCRYPT% -verbose -printinfo -printcontents -server "%HOST%" -port %WSPORT% -user "%USER%" -password "%USER_PASSWORD%" -domain "%DOMAIN%" > "%ARCHIVE_RESULT_FILE%"
   set ERROR=%ERRORLEVEL%
   if %ERROR% NEQ 0 (
      echo.%S%: pkg_import failed.  Aborting script. Error code: %ERROR%
      GOTO COMPLETED_ERROR
   )
   GOTO PRINT_COMPLETE
   
REM # Execute with the encryption password DV 8.x
:PRINT_WITH_ENCRYPTION
   echo.%S%: *** CALL "%DV_HOME%\bin\pkg_import.bat" -pkgfile "%PKGFILE%" %ENCRYPT% -verbose -printinfo -printcontents -server "%HOST%" -port %WSPORT% -user "%USER%" -password "********" -domain "%DOMAIN%" -encryptionPassword "********" ^> "%ARCHIVE_RESULT_FILE%" *** 
   CALL "%DV_HOME%\bin\pkg_import.bat" -pkgfile "%PKGFILE%" %ENCRYPT% -verbose -printinfo -printcontents -server "%HOST%" -port %WSPORT% -user "%USER%" -password "%USER_PASSWORD%" -domain "%DOMAIN%" -encryptionPassword "%ENCRYPTION_PASSWORD%" > "%ARCHIVE_RESULT_FILE%"
   set ERROR=%ERRORLEVEL%
   if %ERROR% NEQ 0 (
      echo.%S%: pkg_import failed.  Aborting script. Error code: %ERROR%
      GOTO COMPLETED_ERROR
   )

:PRINT_COMPLETE
REM # Prepare the powershell cmdlet script to print the car file info and contents.
   echo.$ContentsFound = 0 > "%PS1%"
   echo.$LineCount = 0 >> "%PS1%"
   echo.foreach($line in [System.IO.File]::ReadLines("%ARCHIVE_RESULT_FILE%")) { >> "%PS1%"
   echo.    if(($line -match 'Referenced \(external\):') -or ($line -match 'Done importing')){ >> "%PS1%"
   echo.        Write-Host "*************************************************************************************************" >> "%PS1%"
   echo.        Write-Host "*************************************************************************************************" >> "%PS1%"
   echo.        $ContentsFound = 0 >> "%PS1%"
   echo.    } >> "%PS1%"
   echo.    if($ContentsFound -eq 1){ >> "%PS1%"
   echo.        $LineCount++ >> "%PS1%"
   echo.        Write-Host $LineCount":" $line >> "%PS1%"
   echo.    } >> "%PS1%"
   echo.    if($line -match 'Contents:'){ >> "%PS1%"
   echo.        Write-Host "*************************************************************************************************" >> "%PS1%"
   echo.        Write-Host "*************************************************************************************************" >> "%PS1%"
   echo.        Write-Host $line >> "%PS1%"
   echo.        $ContentsFound = 1 >> "%PS1%"
   echo.    } >> "%PS1%"
   echo.    if($line -match 'Importing file'){ $line = $line -replace "Importing file", "Printing file" } >> "%PS1%"
   echo.    if($line -match 'Done importing'){ >> "%PS1%"
   echo.        $line = $line -replace "Done importing", "Done printing"  >> "%PS1%"
   echo.    } >> "%PS1%"
   echo.    if($ContentsFound -eq 0){ Write-Host $line } >> "%PS1%"
   echo.} >> "%PS1%"
   echo.Write-Host $LineCount "resource(s) detected in .car file." >> "%PS1%"


REM # print the car file info and contents
   if "%QUIET%" == "" (
      echo.%S%: powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%PS1%"
      echo.%S%: "%PS1%" COMMAND:
	  type "%PS1%"
   )
   call powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%PS1%"
   set ERROR=%ERRORLEVEL%
   if %ERROR% NEQ 0 (
      echo.%S%: powershell Get Archive Creation Date failed.  Aborting script. Error code: %ERROR%
	  set ERROR=98
      GOTO COMPLETED_ERROR
   )
   echo.%S%: *** Package file printed with status=SUCCESS ***
   echo.

:BYPASS_PRINT_CAR_FILE

   
REM ################################
REM # BEGIN VALIDATE CAR FILE CONTENTS
REM ################################
if "%PRIVS_ONLY%" == "true" GOTO BYPASS_VALIDATE_DEPLOYMENT
if "%VALIDATE_DEPLOYMENT_DATABASE%" == "" GOTO BYPASS_VALIDATE_DEPLOYMENT
if "%PRINT_ONLY%" == "Y" GOTO BYPASS_VALIDATE_DEPLOYMENT
set DV_PROCEDURE="%VALIDATE_DEPLOYMENT_URL%"
echo.%S%: --------------------------------------------------------------------   
echo.%S%: *** Validating Deployment Content. ***
echo.%S%: --------------------------------------------------------------------   

REM # Unzip the package .car file into the temp zip directory
if "%QUIET%" == "" echo.%S%: call :psunzip "%PKGFILE%" "%TMPDIR%" %QUIET%
call :psunzip "%PKGFILE%" "%TMPDIR%" %QUIET%
set ERROR=%ERRORLEVEL%
if %ERROR% NEQ 0 (
   set ERROR=99
   set message=:psunzip failed.  Aborting script.
   goto COMPLETED_ERROR
)
REM # Copy the unzipped content.xml to the target directory and file for reading by the validate procedure.
copy /Y "%TMPDIR%\contents.xml" "%VALIDATE_DEPLOYMENT_CONTENT_PATH%"

REM # Copy the unzipped metadata.xml to the target directory and file for reading by the validate procedure.
copy /Y "%TMPDIR%\metadata.xml" "%VALIDATE_DEPLOYMENT_METADATA_PATH%"

REM # Validate the car file metadata
echo.%S%: *** CALL "%JDBC_SAMPLE_EXEC%" "%VALIDATE_DEPLOYMENT_DATABASE%" "%HOST%" "%DBPORT%" "%USER%" "********" "%DOMAIN%" "SELECT * FROM %VALIDATE_DEPLOYMENT_URL%('%DEBUG%', '%INPUT1%', '%PKGNAME%', '%DEPLOYMENT_DATE_BEG%', '%HOST%', '%WSPORT%', '%VALIDATE_DEPLOYMENT_CONTENT_PATH%', '%VALIDATE_DEPLOYMENT_METADATA_PATH%', '%VALIDATE_DV_TABLE_PATH%', '%VALIDATE_DV_PROCEDURE_PATH%')" ^> "%JDBC_RESULT_FILE%" ***
CALL "%JDBC_SAMPLE_EXEC%" "%VALIDATE_DEPLOYMENT_DATABASE%" "%HOST%" "%DBPORT%" "%USER%" "%USER_PASSWORD%" "%DOMAIN%" "SELECT * FROM %VALIDATE_DEPLOYMENT_URL%('%DEBUG%', '%INPUT1%', '%PKGNAME%', '%DEPLOYMENT_DATE_BEG%', '%HOST%', '%WSPORT%', '%VALIDATE_DEPLOYMENT_CONTENT_PATH%', '%VALIDATE_DEPLOYMENT_METADATA_PATH%', '%VALIDATE_DV_TABLE_PATH%', '%VALIDATE_DV_PROCEDURE_PATH%')" > "%JDBC_RESULT_FILE%"
set ERROR=%ERRORLEVEL%
if %ERROR% NEQ 0 (
   echo.%S%: %DV_PROCEDURE% failed.  Aborting script. Error code: %ERROR%
   GOTO COMPLETED_ERROR
)

REM # Check for SUCCESS result
set DISPLAY_CONTENTS=false
set SEARCH_TEXT=col[1]^=``SUCCESS
CALL:GetDVProcedureResults 
set ERROR=%ERRORLEVEL%
if %ERROR% GTR 1 GOTO COMPLETED_ERROR
if %ERROR% EQU 1 GOTO SUCCESS_VALIDATE

   REM # Check for WARNING result
   set DISPLAY_CONTENTS=%PRINT_WARNING%
   set SEARCH_TEXT=col[1]^=``WARNING
   CALL:GetDVProcedureResults 
   set ERROR=%ERRORLEVEL%
   if %ERROR% GTR 1 GOTO COMPLETED_ERROR
   if %ERROR% EQU 1 GOTO WARNING_VALIDATE
   REM # This is a failure because neither SUCCESS or WARNING was returned.
   echo.%S%: FAILURE: %DV_PROCEDURE% did not return with a "SUCCESS" or "WARNING" status.
   set ERROR=99
   GOTO COMPLETED_ERROR

:WARNING_VALIDATE
set ERROR=0
set WARNING=1
echo.%S%: *** WARNING: REVIEW LOG FILE "%VALIDATE_METADATA_LOG%"
echo.%S%: *** %DV_PROCEDURE% completed with status=WARNING ***
echo.

REM # Copy the JDBC_RESULTS_FILE to the Validate metadata log file
if exist "%JDBC_RESULT_FILE%" copy /Y "%JDBC_RESULT_FILE%" "%VALIDATE_METADATA_LOG%"
if "%WARNING_OUTPUT%" NEQ "" set WARNING_OUTPUT=%WARNING_OUTPUT%newline    REVIEW LOG FILE _QQ_%VALIDATE_METADATA_LOG%_QQ_
if "%WARNING_OUTPUT%" == ""  set WARNING_OUTPUT=WARNING:newline    REVIEW LOG FILE _QQ_%VALIDATE_METADATA_LOG%_QQ_

GOTO BYPASS_VALIDATE_DEPLOYMENT

:SUCCESS_VALIDATE
set ERROR=0
echo.%S%: *** %DV_PROCEDURE% completed with status=SUCCESS ***
echo.

:BYPASS_VALIDATE_DEPLOYMENT

REM ################################
REM # BEGIN CAR FILE IMPORT
REM ################################
if "%PRIVS_ONLY%" == "true" GOTO BYPASS_IMPORT
if "%PRINT_ONLY%" == "Y" GOTO BYPASS_IMPORT
echo.%S%: --------------------------------------------------------------------
echo.%S%: *** Importing CAR file into target server %HOST%:%WSPORT% ***
echo.%S%: --------------------------------------------------------------------

REM # Determine if the OPTFILE was provided during input or not
SET CMD_OPTFILE=
if "%OPTFILE%" neq "" SET CMD_OPTFILE=-optfile "%OPTFILE%"

REM # Execute without the encryption password DV 7.x
if "%ENCRYPTION_PASSWORD%" neq "" GOTO IMPORT_WITH_ENCRYPTION
   echo.%S%: *** CALL "%DV_HOME%\bin\pkg_import.bat" -pkgfile "%PKGFILE%" %ENCRYPT% -server "%HOST%" -port %WSPORT% -user "%USER%" -password "********" -domain "%DOMAIN%" %CMD_OPTFILE% ^> "%ARCHIVE_RESULT_FILE%" ***
   CALL "%DV_HOME%\bin\pkg_import.bat" -pkgfile "%PKGFILE%" %ENCRYPT% -server "%HOST%" -port %WSPORT% -user "%USER%" -password "%USER_PASSWORD%" -domain "%DOMAIN%" %CMD_OPTFILE% > "%ARCHIVE_RESULT_FILE%"
   set ERROR=%ERRORLEVEL%
   if %ERROR% NEQ 0 (
      echo.%S%: pkg_import failed.  Aborting script. Error code: %ERROR%
      GOTO COMPLETED_ERROR
   )
   GOTO IMPORT_COMPLETE

REM # Execute with the encryption password DV 8.x
:IMPORT_WITH_ENCRYPTION
   echo.%S%: *** CALL "%DV_HOME%\bin\pkg_import.bat" -pkgfile "%PKGFILE%" %ENCRYPT% -server "%HOST%" -port %WSPORT% -user "%USER%" -password "********" -domain "%DOMAIN%" -encryptionPassword "********" %CMD_OPTFILE% ^> "%ARCHIVE_RESULT_FILE%"*** 
   CALL "%DV_HOME%\bin\pkg_import.bat" -pkgfile "%PKGFILE%" %ENCRYPT% -server "%HOST%" -port %WSPORT% -user "%USER%" -password "%USER_PASSWORD%" -domain "%DOMAIN%" -encryptionPassword "%ENCRYPTION_PASSWORD%" %CMD_OPTFILE% > "%ARCHIVE_RESULT_FILE%"
   set ERROR=%ERRORLEVEL%
   if %ERROR% NEQ 0 (
      echo.%S%: pkg_import failed.  Aborting script. Error code: %ERROR%
      GOTO COMPLETED_ERROR
   )

:IMPORT_COMPLETE
REM # Prepare the powershell cmdlet script to process pkg_import output and reduce the noise.
   echo.foreach($line in [System.IO.File]::ReadLines("%ARCHIVE_RESULT_FILE%")) { > "%PS3%"
   echo.    $printLine = 1 >> "%PS3%"
   echo.    if(($line -match 'File ^"files') -or >> "%PS3%"
   echo.       ( ($line -match 'Cannot set an attribute') -and >> "%PS3%"
   echo.       ( ($line -match 'because the resource was not part of the import') -or ($line -match 'because the resource does not exist') ) ) >> "%PS3%" 
   echo.      ){ $printLine = 0 } >> "%PS3%"
   echo.    if($printLine -eq 1){ $line.TrimStart() } >> "%PS3%"
   echo.} >> "%PS3%"
  
   REM # Process the pkg_import output and reduce the noise:
   if "%QUIET%" == "" (
      echo.%S%: powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%PS3%" ^> "%ARCHIVE_RESULT_FILE2%"
      echo.%S%: "%PS3%" COMMAND:
	  type "%PS3%"
   )
   call powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%PS3%" > "%ARCHIVE_RESULT_FILE2%"
   set ERROR=%ERRORLEVEL%
   if %ERROR% NEQ 0 (
      echo.%S%: powershell process archive results failed.  Aborting script. Error code: %ERROR%
	  set ERROR=98
      GOTO COMPLETED_ERROR
   )
REM # print the pkg_import output
echo.%S%: pkg_import output results:
type "%ARCHIVE_RESULT_FILE2%"
echo.%S%: *** Package file imported with status=SUCCESS ***
echo.
:BYPASS_IMPORT

REM ################################
REM # STRATEGY 1:
REM #
REM # BEGIN RESOURCE PRIVILEGES
REM #   and RESOURCE OWNERSHIP
REM ################################
if "%STRATEGY1_RESOURCE_PRIVILEGE_DATABASE%" == "" GOTO BYPASS_RESOURCE_PRIVILEGES1
if "%PRINT_ONLY%" == "Y" GOTO BYPASS_RESOURCE_PRIVILEGES1
set DV_PROCEDURE="%STRATEGY1_RESOURCE_PRIVILEGE_URL%"
echo.%S%: --------------------------------------------------------------------   
echo.%S%: *** STRATEGY 1 ***
echo.%S%: *** Resetting privileges and ownership on specified resources. ***
echo.%S%: --------------------------------------------------------------------   
REM # Execute the Strategy 1 privilege sheet execution
echo.%S%: *** CALL "%JDBC_SAMPLE_EXEC%" "%STRATEGY1_RESOURCE_PRIVILEGE_DATABASE%" "%HOST%" "%DBPORT%" "%USER%" "********" "%DOMAIN%" "SELECT * FROM %STRATEGY1_RESOURCE_PRIVILEGE_URL%('%PRIVILEGE_DATASOURCE%', 1, '%PRIVILEGE_ENVIRONMENT%', '%PRIVILEGE_ORGANIZATION%', '%PRIVILEGE_PROJECT%', '%PRIVILEGE_SUBPROJECT%', '%PRIVILEGE_SHEET_NAME%', '%PRIVILEGE_RESOURCE_PATH%', '%PRIVILEGE_RESOURCE_TYPE%', '%PRIVILEGE_GROUP_NAME%', '%PRIVILEGE_GROUP_TYPE%', '%PRIVILEGE_GROUP_DOMAIN%', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', '%PRIVILEGE_BYPASS_ERRORS%')" ^> "%JDBC_RESULT_FILE%" ***
CALL "%JDBC_SAMPLE_EXEC%" "%STRATEGY1_RESOURCE_PRIVILEGE_DATABASE%" "%HOST%" "%DBPORT%" "%USER%" "%USER_PASSWORD%" "%DOMAIN%" "SELECT * FROM %STRATEGY1_RESOURCE_PRIVILEGE_URL%('%PRIVILEGE_DATASOURCE%', 1, '%PRIVILEGE_ENVIRONMENT%', '%PRIVILEGE_ORGANIZATION%', '%PRIVILEGE_PROJECT%', '%PRIVILEGE_SUBPROJECT%', '%PRIVILEGE_SHEET_NAME%', '%PRIVILEGE_RESOURCE_PATH%', '%PRIVILEGE_RESOURCE_TYPE%', '%PRIVILEGE_GROUP_NAME%', '%PRIVILEGE_GROUP_TYPE%', '%PRIVILEGE_GROUP_DOMAIN%', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', '%PRIVILEGE_BYPASS_ERRORS%')" > "%JDBC_RESULT_FILE%"
set ERROR=%ERRORLEVEL%
if %ERROR% NEQ 0 (
   echo.%S%: %DV_PROCEDURE% failed.  Aborting script. Error code: %ERROR%
   GOTO COMPLETED_ERROR
)

REM # Check for SUCCESS result
set DISPLAY_CONTENTS=false
set SEARCH_TEXT=col[1]^=``SUCCESS
CALL:GetDVProcedureResults 
set ERROR=%ERRORLEVEL%
if %ERROR% GTR 1 GOTO COMPLETED_ERROR
if %ERROR% EQU 1 GOTO SUCCESS_PRIVILEGES1

   REM # Check for WARNING result
   set DISPLAY_CONTENTS=%PRINT_WARNING%
   set SEARCH_TEXT=col[1]^=``WARNING
   CALL:GetDVProcedureResults 
   set ERROR=%ERRORLEVEL%
   if %ERROR% GTR 1 GOTO COMPLETED_ERROR
   if %ERROR% EQU 1 GOTO WARNING_PRIVILEGE1
   REM # This is a failure because neither SUCCESS or WARNING was returned.
   echo.%S%: FAILURE: %DV_PROCEDURE% did not return with a "SUCCESS" or "WARNING" status.
   set ERROR=99
   GOTO COMPLETED_ERROR
   
:WARNING_PRIVILEGE1
set ERROR=0
set WARNING=1
echo.%S%: *** WARNING: REVIEW LOG FILE "%STRATEGY1_RESOURCE_PRIVILEGE_LOG%"
echo.%S%: *** %DV_PROCEDURE% completed with status=WARNING ***
echo.

REM # Copy the JDBC_RESULTS_FILE to the Strategy 1 privilege log file
if exist "%JDBC_RESULT_FILE%" copy /Y "%JDBC_RESULT_FILE%" "%STRATEGY1_RESOURCE_PRIVILEGE_LOG%"
if "%WARNING_OUTPUT%" NEQ "" set WARNING_OUTPUT=%WARNING_OUTPUT%newline    REVIEW LOG FILE _QQ_%STRATEGY1_RESOURCE_PRIVILEGE_LOG%_QQ_
if "%WARNING_OUTPUT%" == ""  set WARNING_OUTPUT=WARNING:newline    REVIEW LOG FILE _QQ_%STRATEGY1_RESOURCE_PRIVILEGE_LOG%_QQ_

GOTO BYPASS_RESOURCE_PRIVILEGES1

:SUCCESS_PRIVILEGES1
set ERROR=0
if exist "%STRATEGY1_RESOURCE_PRIVILEGE_LOG%" del /Q /F "%STRATEGY1_RESOURCE_PRIVILEGE_LOG%"
echo.%S%: *** %DV_PROCEDURE% completed with status=SUCCESS ***
echo.
:BYPASS_RESOURCE_PRIVILEGES1

  
REM ################################
REM # STRATEGY 2:
REM #
REM # BEGIN IMPORT RESOURCE OWNERSHIP
REM ################################
if "%STRATEGY2_RESOURCE_OWNERSHIP_DATABASE%" == "" GOTO BYPASS_RESOURCE_OWNERSHIP
if "%PRINT_ONLY%" == "Y" GOTO BYPASS_RESOURCE_OWNERSHIP
set DV_PROCEDURE="%STRATEGY2_RESOURCE_OWNERSHIP_URL%"
echo.%S%: --------------------------------------------------------------------   
echo.%S%: *** STRATEGY 2 ***
echo.%S%: *** Resetting ownership of resources. ***
echo.%S%: --------------------------------------------------------------------   
echo.%S%: *** CALL "%JDBC_SAMPLE_EXEC%" "%STRATEGY2_RESOURCE_OWNERSHIP_DATABASE%" "%HOST%" "%DBPORT%" "%USER%" "********" "%DOMAIN%" "SELECT * FROM %STRATEGY2_RESOURCE_OWNERSHIP_URL%('%DEBUG%', '%STRATEGY2_RESOURCE_OWNERSHIP_FILE%')" ^> "%JDBC_RESULT_FILE%" ***
CALL "%JDBC_SAMPLE_EXEC%" "%STRATEGY2_RESOURCE_OWNERSHIP_DATABASE%" "%HOST%" "%DBPORT%" "%USER%" "%USER_PASSWORD%" "%DOMAIN%" "SELECT * FROM %STRATEGY2_RESOURCE_OWNERSHIP_URL%('%DEBUG%', '%STRATEGY2_RESOURCE_OWNERSHIP_FILE%')" > "%JDBC_RESULT_FILE%"
set ERROR=%ERRORLEVEL%
if %ERROR% NEQ 0 (
   echo.%S%: %DV_PROCEDURE% failed.  Aborting script. Error code: %ERROR%
   GOTO COMPLETED_ERROR
)

REM # Check for SUCCESS result
set DISPLAY_CONTENTS=false
set SEARCH_TEXT=col[1]^=``SUCCESS
CALL:GetDVProcedureResults 
set ERROR=%ERRORLEVEL%
if %ERROR% GTR 1 GOTO COMPLETED_ERROR
if %ERROR% EQU 1 GOTO SUCCESS_OWNERSHIP

   REM # Check for WARNING result
   set DISPLAY_CONTENTS=%PRINT_WARNING%
   set SEARCH_TEXT=col[1]^=``WARNING
   CALL:GetDVProcedureResults 
   set ERROR=%ERRORLEVEL%
   if %ERROR% GTR 1 GOTO COMPLETED_ERROR
   if %ERROR% EQU 1 GOTO WARNING_OWNERSHIP
   REM # This is a failure because neither SUCCESS or WARNING was returned.
   echo.%S%: FAILURE: %DV_PROCEDURE% did not return with a "SUCCESS" or "WARNING" status.
   set ERROR=99
   GOTO COMPLETED_ERROR

:WARNING_OWNERSHIP
set ERROR=0
set WARNING=1
echo.%S%: *** WARNING: REVIEW LOG FILE "%STRATEGY2_RESOURCE_OWNERSHIP_LOG%"
echo.%S%: *** %DV_PROCEDURE% completed with status=WARNING ***
echo.

REM # Copy the JDBC_RESULTS_FILE to the Strategy 2 ownership log file
if exist "%JDBC_RESULT_FILE%" copy /Y "%JDBC_RESULT_FILE%" "%STRATEGY2_RESOURCE_OWNERSHIP_LOG%"
if "%WARNING_OUTPUT%" NEQ "" set WARNING_OUTPUT=%WARNING_OUTPUT%newline    REVIEW LOG FILE _QQ_%STRATEGY2_RESOURCE_OWNERSHIP_LOG%_QQ_
if "%WARNING_OUTPUT%" == ""  set WARNING_OUTPUT=WARNING:newline    REVIEW LOG FILE _QQ_%STRATEGY2_RESOURCE_OWNERSHIP_LOG%_QQ_

GOTO BYPASS_RESOURCE_OWNERSHIP

:SUCCESS_OWNERSHIP
set ERROR=0
if exist "%STRATEGY2_RESOURCE_OWNERSHIP_LOG%" del /Q /F "%STRATEGY2_RESOURCE_OWNERSHIP_LOG%"
echo.%S%: *** %DV_PROCEDURE% completed with status=SUCCESS ***
echo.
:BYPASS_RESOURCE_OWNERSHIP


REM ################################
REM # STRATEGY 2:
REM #
REM # BEGIN RESOURCE PRIVILEGES
REM ################################
if "%STRATEGY2_RESOURCE_PRIVILEGE_DATABASE%" == "" GOTO BYPASS_RESOURCE_PRIVILEGES2
if "%PRINT_ONLY%" == "Y" GOTO BYPASS_RESOURCE_PRIVILEGES2
set DV_PROCEDURE="%STRATEGY2_RESOURCE_PRIVILEGE_URL%"
echo.%S%: --------------------------------------------------------------------   
echo.%S%: *** STRATEGY 2 ***
echo.%S%: *** Resetting privileges on all resources. ***
echo.%S%: --------------------------------------------------------------------   
echo.%S%: *** CALL "%JDBC_SAMPLE_EXEC%" "%STRATEGY2_RESOURCE_PRIVILEGE_DATABASE%" "%HOST%" "%DBPORT%" "%USER%" "********" "%DOMAIN%" "SELECT * FROM %STRATEGY2_RESOURCE_PRIVILEGE_URL%('%DEBUG%', %RECURSE_CHILD_RESOURCES%, %RECURSE_DEPENDENCIES%, %RECURSE_DEPENDENTS%, '%STRATEGY2_RESOURCE_PRIVILEGE_FILE%', 'SET_EXACTLY')" ^> "%JDBC_RESULT_FILE%" ***
CALL "%JDBC_SAMPLE_EXEC%" "%STRATEGY2_RESOURCE_PRIVILEGE_DATABASE%" "%HOST%" "%DBPORT%" "%USER%" "%USER_PASSWORD%" "%DOMAIN%" "SELECT * FROM %STRATEGY2_RESOURCE_PRIVILEGE_URL%('%DEBUG%', %RECURSE_CHILD_RESOURCES%, %RECURSE_DEPENDENCIES%, %RECURSE_DEPENDENTS%, '%STRATEGY2_RESOURCE_PRIVILEGE_FILE%', 'SET_EXACTLY')" > "%JDBC_RESULT_FILE%"
set ERROR=%ERRORLEVEL%
if %ERROR% NEQ 0 (
   echo.%S%: %DV_PROCEDURE% failed.  Aborting script. Error code: %ERROR%
   GOTO COMPLETED_ERROR
)

REM # Check for SUCCESS result
set DISPLAY_CONTENTS=false
set SEARCH_TEXT=col[1]^=``SUCCESS
CALL:GetDVProcedureResults 
set ERROR=%ERRORLEVEL%
if %ERROR% GTR 1 GOTO COMPLETED_ERROR
if %ERROR% EQU 1 GOTO SUCCESS_PRIVILEGES2

   REM # Check for WARNING result
   set DISPLAY_CONTENTS=%PRINT_WARNING%
   set SEARCH_TEXT=col[1]^=``WARNING
   CALL:GetDVProcedureResults 
   set ERROR=%ERRORLEVEL%
   if %ERROR% GTR 1 GOTO COMPLETED_ERROR
   if %ERROR% EQU 1 GOTO WARNING_PRIVILEGES2
   REM # This is a failure because neither SUCCESS or WARNING was returned.
   echo.%S%: FAILURE: %DV_PROCEDURE% did not return with a "SUCCESS" or "WARNING" status.
   set ERROR=99
   GOTO COMPLETED_ERROR

:WARNING_PRIVILEGES2
set ERROR=0
set WARNING=1
echo.%S%: *** WARNING: REVIEW LOG FILE "%STRATEGY2_RESOURCE_PRIVILEGE_LOG%"
echo.%S%: *** %DV_PROCEDURE% completed with status=WARNING ***
echo.

REM # Copy the JDBC_RESULTS_FILE to the Strategy 2 privilege log file
if exist "%JDBC_RESULT_FILE%" copy /Y "%JDBC_RESULT_FILE%" "%STRATEGY2_RESOURCE_PRIVILEGE_LOG%"
if "%WARNING_OUTPUT%" NEQ "" set WARNING_OUTPUT=%WARNING_OUTPUT%newline    REVIEW LOG FILE _QQ_%STRATEGY2_RESOURCE_PRIVILEGE_LOG%_QQ_
if "%WARNING_OUTPUT%" == ""  set WARNING_OUTPUT=WARNING:newline    REVIEW LOG FILE _QQ_%STRATEGY2_RESOURCE_PRIVILEGE_LOG%_QQ_

GOTO BYPASS_RESOURCE_PRIVILEGES2

:SUCCESS_PRIVILEGES2
set ERROR=0
if exist "%STRATEGY2_RESOURCE_PRIVILEGE_LOG%" del /Q /F "%STRATEGY2_RESOURCE_PRIVILEGE_LOG%"
echo.%S%: *** %DV_PROCEDURE% completed with status=SUCCESS ***
echo.
:BYPASS_RESOURCE_PRIVILEGES2


REM ################################
REM # BEGIN runAfterImport
REM ################################
if "%PRIVS_ONLY%" == "true" GOTO BYPASS_RUN_AFTER_IMPORT
if "%RUN_AFTER_IMPORT_DATABASE%" == "" GOTO BYPASS_RUN_AFTER_IMPORT
if "%PRINT_ONLY%" == "Y" GOTO BYPASS_RUN_AFTER_IMPORT
set DV_PROCEDURE="%RUN_AFTER_IMPORT_URL%"
echo.%S%: --------------------------------------------------------------------   
echo.%S%: *** Calling "runAfterImport" for any post-migration steps. ***
echo.%S%: --------------------------------------------------------------------   
echo.%S%: *** CALL "%JDBC_SAMPLE_EXEC%" "%RUN_AFTER_IMPORT_DATABASE%" "%HOST%" "%DBPORT%" "%USER%" "********" "%DOMAIN%" "SELECT * FROM %RUN_AFTER_IMPORT_URL%('%DEBUG%', '%INPUT1%', '%INPUT2%', '%INPUT3%')" ^> "%JDBC_RESULT_FILE%" ***
CALL "%JDBC_SAMPLE_EXEC%" "%RUN_AFTER_IMPORT_DATABASE%" "%HOST%" "%DBPORT%" "%USER%" "%USER_PASSWORD%" "%DOMAIN%" "SELECT * FROM %RUN_AFTER_IMPORT_URL%('%DEBUG%', '%INPUT1%', '%INPUT2%', '%INPUT3%')" > "%JDBC_RESULT_FILE%"
set ERROR=%ERRORLEVEL%
if %ERROR% NEQ 0 (
   echo.%S%: %DV_PROCEDURE% failed.  Aborting script. Error code: %ERROR%
   GOTO COMPLETED_ERROR
)

REM # Check for SUCCESS result
set DISPLAY_CONTENTS=false
set SEARCH_TEXT=col[1]^=``SUCCESS
CALL:GetDVProcedureResults 
set ERROR=%ERRORLEVEL%
if %ERROR% GTR 1 GOTO COMPLETED_ERROR
if %ERROR% EQU 1 GOTO SUCCESS_RUN_AFTER_IMPORT

   REM # Check for WARNING result
   set DISPLAY_CONTENTS=%PRINT_WARNING%
   set SEARCH_TEXT=col[1]^=``WARNING
   CALL:GetDVProcedureResults 
   set ERROR=%ERRORLEVEL%
   if %ERROR% GTR 1 GOTO COMPLETED_ERROR
   if %ERROR% EQU 1 GOTO WARNING_RUN_AFTER_IMPORT
   REM # This is a failure because neither SUCCESS or WARNING was returned.
   echo.%S%: FAILURE: %DV_PROCEDURE% did not return with a "SUCCESS" or "WARNING" status.
   set ERROR=99
   GOTO COMPLETED_ERROR

:WARNING_RUN_AFTER_IMPORT
set ERROR=0
set WARNINGS=1
echo.%S%: *** WARNING: REVIEW LOG FILE "%RUN_AFTER_IMPORT_LOG%"
echo.%S%: *** %DV_PROCEDURE% completed with status=WARNING ***
echo.

REM # Copy the JDBC_RESULTS_FILE to the run after import log file
if exist "%JDBC_RESULT_FILE%" copy /Y "%JDBC_RESULT_FILE%" "%RUN_AFTER_IMPORT_LOG%"
if "%WARNING_OUTPUT%" NEQ "" set WARNING_OUTPUT=%WARNING_OUTPUT%newline    REVIEW LOG FILE _QQ_%RUN_AFTER_IMPORT_LOG%_QQ_
if "%WARNING_OUTPUT%" == ""  set WARNING_OUTPUT=WARNING:newline    REVIEW LOG FILE _QQ_%RUN_AFTER_IMPORT_LOG%_QQ_

GOTO BYPASS_RUN_AFTER_IMPORT

:SUCCESS_RUN_AFTER_IMPORT
set ERROR=0
if exist "%RUN_AFTER_IMPORT_LOG%" del /Q /F "%RUN_AFTER_IMPORT_LOG%"
echo.%S%: *** %DV_PROCEDURE% completed with status=SUCCESS ***
echo.
:BYPASS_RUN_AFTER_IMPORT

REM ################################
REM # End of main processing
REM #   Goto completed success section.
REM ################################
GOTO COMPLETED_SUCCESS
REM ################################
REM #
REM #
REM #
REM ################################
REM # COMPLETE ERROR
REM ################################
:COMPLETED_ERROR
REM # Copy the JDBC_RESULTS_FILE to the exception log file
if exist "%JDBC_RESULT_FILE%" copy /Y "%JDBC_RESULT_FILE%" "%EXCEPTION_LOG%"

REM # Calculate the duration between begin and end date.
set DT1=%DATE:~-4,4%-%DATE:~4,2%-%DATE:~7,2%
set DT1=%DT1: =0%
set TM1=%TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2%
set TM1=%TM1: =0%
set DEPLOYMENT_DATE_END=%DT1% %TM1%
CALL:GetDuration "%DEPLOYMENT_DATE_BEG%" "%DEPLOYMENT_DATE_END%" DURATION

REM # Clean-up temporary files
echo.
CALL:CleanUpTmpFiles

REM # Print out the deployment end date and start date.
echo.
echo.==============================================================
echo DEPLOYMENT_DATE_BEG=%DEPLOYMENT_DATE_BEG%
echo DEPLOYMENT_DATE_END=%DEPLOYMENT_DATE_END%
echo DURATION=%DURATION%
echo.==============================================================
echo.
echo.%S%: **************************************************************
echo.%S%: ***  ERROR: Migration steps failed with an exception.      ***
echo.%S%: **************************************************************
echo.%S%: EXCEPTION LOG: "%EXCEPTION_LOG%"
echo.
exit /b %ERROR%
REM ################################
REM #
REM #
REM #
REM ################################
REM # COMPLETE SUCCESS
REM ################################
:COMPLETED_SUCCESS
REM # Calculate the duration between begin and end date.
set DT1=%DATE:~-4,4%-%DATE:~4,2%-%DATE:~7,2%
set DT1=%DT1: =0%
set TM1=%TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2%
set TM1=%TM1: =0%
set DEPLOYMENT_DATE_END=%DT1% %TM1%
CALL:GetDuration "%DEPLOYMENT_DATE_BEG%" "%DEPLOYMENT_DATE_END%" DURATION

REM # Clean-up temporary files
CALL:CleanUpTmpFiles

REM # Print out the deployment end date and start date.
echo.
echo.==============================================================
echo DEPLOYMENT_DATE_BEG=%DEPLOYMENT_DATE_BEG%
echo DEPLOYMENT_DATE_END=%DEPLOYMENT_DATE_END%
echo DURATION=%DURATION%
echo.==============================================================
echo.
if "%WARNING%" == "0" (
   echo.%S%: **************************************************************
   echo.%S%: ***  SUCCESS: All migration steps successfully completed.  ***
   echo.%S%: **************************************************************
) else (
   echo.%S%: ****************************************************************************
   echo.%S%: ***  WARNING: All migration steps successfully completed with WARNING.   ***
   echo.%S%: ****************************************************************************
   setlocal enabledelayedexpansion
   set LF=^


   rem 2 empty lines are required
   set WARNING_OUTPUT=%WARNING_OUTPUT:newline=^!LF!%
   set WARNING_OUTPUT=!WARNING_OUTPUT:_QQ_=^"!
   echo.%S%: !WARNING_OUTPUT!
   endlocal
)
echo.
set ERROR=0
exit /b %ERROR%
REM #****************************************************************
REM # END: deployProject.bat
REM #****************************************************************
REM #
REM #
REM #
REM #####################################################################################
REM # FUNCTIONS
REM #####################################################################################
:: -------------------------------------------------------------
:CleanUpTmpFiles
::#-------------------------------------------------------------
::# Description: CALL:CleanUpTmpFiles
::# Clean-up the directories and temporary files
::#-------------------------------------------------------------
	echo.%S%: **************************************************************
	echo.%S%: Clean-up temporary directories and files.
	echo.%S%: **************************************************************
	if "%TMPDIR%" == "" GOTO DEL_NEXT1
	if exist "%TMPDIR%" (
		echo.%S%: Deleting "%TMPDIR%"
		rmdir /S /Q "%TMPDIR%"		
	)

	:DEL_NEXT1
	if "%VALIDATE_DEPLOYMENT_CONTENT_PATH%" == "" GOTO DEL_NEXT2
	if exist "%VALIDATE_DEPLOYMENT_CONTENT_PATH%" (
		echo.%S%: Deleting "%VALIDATE_DEPLOYMENT_CONTENT_PATH%"
		del /Q /F "%VALIDATE_DEPLOYMENT_CONTENT_PATH%"
	)
	if "%VALIDATE_DEPLOYMENT_METADATA_PATH%" == "" GOTO DEL_NEXT2
	if exist "%VALIDATE_DEPLOYMENT_METADATA_PATH%" (
		echo.%S%: Deleting "%VALIDATE_DEPLOYMENT_METADATA_PATH%"
		del /Q /F "%VALIDATE_DEPLOYMENT_METADATA_PATH%"
	)
	
	:DEL_NEXT2
endlocal
GOTO:EOF

:: -------------------------------------------------------------
:GetDVProcedureResults
::#-------------------------------------------------------------
::# Description: CALL:GetDVProcedureResults
::# Verify the results from the output of a DV procedure call based on the search text.
::# -- SEARCH_TEXT      [set prior] - variable name containing the search text set prior to the function invocation.
::#                                    ex 1. search for a SUCCESS status returned
::#                                          set SEARCH_TEXT=col[1]^=``SUCCESS
::#                                    ex 2. search for version 8 returned
::#                                          set SEARCH_TEXT=col[1]^=``8
::# -- JDBC_RESULT_FILE [set prior] - variable containing the full path to the JdbcSample.bat script output.
::# -- SEARCHRESULTS    [set prior] - variable containing the full path to the search results file.
::# -- FINDTEXT         [set prior] - variable containing the full path to the find text powershell script file.
::# -- PSNAME           [set prior] - variable containing the name of the powershell script.
::# -- QUIET            [set prior] - variable containing the quiet value.
::# -- DISPLAY_CONTENTS [set prior] - variable containing true or false to display the contents of JDBC_RESULT_FILE.
::# -- S                [set prior] - variable containing this script name.
::#
::# -- RESULT           [exit /b]   - variable name containing the result code which is set using exit /B %RESULT%
::#                                     0=NOT FOUND, search text was not found
::#                                     1=FOUND, search text found.
::#                                    98=RESULT, error executing powershell
::#                                    99=RESULT, powershell return error text which was displayed.
::#-------------------------------------------------------------
   
REM # Write out a powershell cmdlet to a file which searches an file for col[1]=`SUCCESS`.
REM #   The cmdlet writes out the response of "true" or "false" to a temporary file based on whether it found the search string or not.
   echo.powershell Select-String -Quiet -Path "'%JDBC_RESULT_FILE%'" -pattern "([regex]::Escape('%SEARCH_TEXT%'))" ^| ForEach-Object{$_.ToString().ToLower()} > "%FINDTEXT%"

REM # Execute the powershell cmdlet
   if "%QUIET%" == "" (
      echo.%S%: powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%FINDTEXT%" ^> "%SEARCHRESULTS%"
      echo.%S%: %PSNAME% COMMAND:
      CALL:DisplayFile "%FINDTEXT%"
      echo %S%: File contents for JDBC_RESULT_FILE=%JDBC_RESULT_FILE%:
      CALL:DisplayFile "%JDBC_RESULT_FILE%"
	  REM # Don't display contents in next section if not QUIET [QUIET==""]
	  set DISPLAY_CONTENTS=false
   )
   REM # Only display contents if DISPLAY_CONTENTS=true and QUIET=-q
   if "%DISPLAY_CONTENTS%" == "true" (
      echo %S%: File contents for JDBC_RESULT_FILE=%JDBC_RESULT_FILE%:
      CALL:DisplayFile "%JDBC_RESULT_FILE%"
   )
   call powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%FINDTEXT%" > "%SEARCHRESULTS%"
   set ERROR=%ERRORLEVEL%
   if %ERROR% NEQ 0 (
      echo.%S%: powershell Find-Text failed.  Aborting script. Error code: %ERROR%
	  set RESULT=98
      if exist "%JDBC_RESULT_FILE%" del /Q "%JDBC_RESULT_FILE%"
      GOTO CLEAN_UP_AND_RETURN
   )
   
REM # Get the search result file contents.  Should be "true" or "false".  Anything else is an exception.
   set /p SEARCHRESULTS_CONTENTS=<"%SEARCHRESULTS%"
   if "%SEARCHRESULTS_CONTENTS%" == "true" (
      set RESULT=1
      if "%QUIET%" == "" echo.%S%: Found=true  SEARCH_TEXT:%SEARCH_TEXT%
	  GOTO CLEAN_UP_AND_RETURN
   )
   if "%SEARCHRESULTS_CONTENTS%" == "false" (
	  set RESULT=0
      if "%QUIET%" == "" echo.%S%: Found=false  SEARCH_TEXT:%SEARCH_TEXT%
	  GOTO CLEAN_UP_AND_RETURN
   )
   
REM # An exception has occurred because the file contents are not "true" or "false" so exit with an exception.
   echo.%S%: FAILURE: %SEARCHRESULTS_CONTENTS% 
   set RESULT=99
   if exist "%JDBC_RESULT_FILE%" del /Q "%JDBC_RESULT_FILE%"

REM # Clean up temporary files
:CLEAN_UP_AND_RETURN
   if exist "%FINDTEXT%" del /Q "%FINDTEXT%"
   if exist "%SEARCHRESULTS%" del /Q "%SEARCHRESULTS%"
REM # Set the return code
rem echo returning result %RESULT%
exit /b %RESULT%


:: #-------------------------------------------------------------
:DisplayFile filename
:: #-------------------------------------------------------------
:: # Display the file contents using the echo statement.
setlocal EnableDelayedExpansion
   set filename=%~1
   echo.Get-Content "%filename%" ^| Where { $_.Trim(" `t") } > "%PS4%"
   call powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%PS4%"
   set ERROR=%ERRORLEVEL%
   if %ERROR% NEQ 0 echo.%S%: powershell Display File failed.  Error code: %ERROR%
   if exist "%PS4%" del /Q "%PS4%"
endlocal
GOTO:EOF


:: #-------------------------------------------------------------
:GetDuration DATETIME_BEG DATETIME_END DURATION
:: #-------------------------------------------------------------
:: # Get the duration between two dates.
:: # Description: CALL:GetDuration DATETIME_BEG DATETIME_END DURATION
:: # -- DATETIME_BEG      The begin date
:: # -- DATETIME_END      The end date
:: # -- DURATION          The duration is returned in the parameters
::#-------------------------------------------------------------
setlocal EnableDelayedExpansion
   set BEG_DATE=%~1
   set END_DATE=%~2
   echo.$dt1=[Datetime]::ParseExact('%BEG_DATE%', 'yyyy-MM-dd HH:mm:ss', $null) > "%PS5%"
   echo.$dt2=[Datetime]::ParseExact('%END_DATE%', 'yyyy-MM-dd HH:mm:ss', $null) >> "%PS5%"
   echo.$diff=New-TimeSpan -Start $dt1 -End $dt2 >> "%PS5%"
   echo.Write-Output "Duration: $diff" >> "%PS5%"
   call powershell -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%PS5%" > "%SEARCHRESULTS%"
   set ERROR=%ERRORLEVEL%
   if %ERROR% NEQ 0 echo.%S%: powershell Display Duration failed.  Error code: %ERROR%
   if exist "%PS5%" del /Q "%PS5%"
   REM # Get the duration result file contents.
   set /p DURATION=<"%SEARCHRESULTS%"
endlocal & SET DURATION=%DURATION%
   set %3=%DURATION%
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
