#!/bin/bash
#****************************************************************
# BEGIN: deployProject.sh
#
# Usage: deployProject.sh -i <import_CAR_file> -o <options_file> -h <hostname> -p <wsport> -u <username> -d <domain> -up <user_password> -ep <encryptionPassword>
#          [-v] [-c] [-e] [-print] [-printOnly] [-printWarning] [-inp1 value] [-inp2 value] [-inp3 value] 
#          [-privsOnly] [-pe privilege_environment] [-pd privilege_datasource] [-po privilege_organization] [-pp privilege_project] [-ps privilege_sub_project]
#          [-sn privilege_sheet_name] [-rp privilege_resource_path] [-rt privilege_resource_type] [-gn privilege_group_name] [-gt privilege_group_type] [-gd privilege_group_domain] [-be privilege_bypass_errors]
#
# Parameter Definitions:
#  -i  [mandatory] import archive (CAR) file path (full or relative).
#  -h  [mandatory] host name or ip address of the DV server deploying to.
#  -p  [mandatory] web service port of the target DV server deploying to.  e.g. 9400
#  -u  [mandatory] username with admin privileges.
#  -d  [mandatory] domain of the username.
#  -up [mandatory] user password.
#  -o  [optional] options file path (full or relative).
#  -ep [optional] encryption password for the archive .CAR file for TDV 8.x.
#  -v  [optional] verbose mode.  Verbose is turned on for secondary script calls.  Otherwise the default is verbose is off.
#  -c  [optional] execute package .car file version check and conversion.  
#                Use -c in environments where you are migrating from DV 8.x into DV 7.x.
#                If not provided, version checking and .car file conversion will not be done which would be optimal to use
#                      when all environments are of the same major DV version such as all DV 7.x or all DV 8.x
#  -e  [optional] Encrypt the communication between client and TDV server.
#  -print        [optional] print info and contents of the package .car file and import the car file.  If -print is not used, the car will still be imported.
#  -printOnly    [optional] only print info and contents of the package .car file and do not import or execute any other option.  This option overrides -print.
#  -printWarning [optional] print the warnings for updatePrivilegesDriverInterface, importResourcePrivileges, importResourceOwnership and runAfterImport otherwise do not print them.
#  -privsOnly    [optional] execute the configured privilege strategy only.  Do no execute the full deployment.
#                           Either privilege strategy 1 or 2 based on configuration.  If strategy 2 is configured, then resource ownership may also be executed if configured.
#
# The following parameters may be passed into Strategy 1 for Privileges: updatePrivilegesDriverInterface
#   These parameters act as filters against the spreadsheet or database table.  The most common parameters are -pd, -pe, -po, -pp and -ps
#  -pe  [mandatory] privilege environment name.  [DEV, UAT, PROD]
#  -pd  [optional] privilege datasource type.  [EXCEL, DB_LLE_ORA, DB_LLE_SS, DB_PROD_ORA, DB_PROD_SS]
#  -po  [optional] privilege organization name.
#  -pp  [optional] privilege project name.
#  -ps  [optional] privilege sub-project name.
#  -sn  [optional] privilege excel sheet name.  [Privileges_shared, Privileges_databases, Privileges_webservices]
#  -rp  [optional] privilege resource path - The resource path in which to get/update privileges.  It may contain a wildcard "%".
#  -rt  [optional] privilege resource type - The resource type in which to get/update privileges.  It is always upper case. 
#                                               This will only be used when no "Resource_Path" or a single "Resource_Path" is provided.  
#                                               It is not used when a list of "Resource_Path" entries are provided.
#                                               E.g. DATA_SOURCE - a published datasource or physical metadata datasource.
#                                                    CONTAINER - a folder path, a catalog or schema path.
#                                                    COLUMN - a column from a table
#                                                    LINK - a published table or procedure.  If it resides in the path /services and points to a TABLE or PROCEDURE then it is a LINK.
#                                                    TABLE - a view in the /shared path.
#                                                    PROCEDURE a procedure in the /shared path.
#  -gn  [optional] privilege group name - The user/group name in which to get/update privileges.
#  -gt  [optional] privilege group type - Valid values are USER or GROUP
#  -gd  [optional] privilege group domain - The domain name in which to get/update privileges.
#  -be  [optional] privilege bypass errors - Bypass errors.  Throw exception when paths not found. N/Null (default) Do not bypass errors.  Y=bypass resource not found errors but report them.
#
# The following parameters may be passed into Strategy 2 for Privileges: importResourcePrivileges
#  -recurseChildResources [1 or 0] - A bit [default=1] flag indicating whether the privileges of the resources in the XML file should be recursively applied to any child resources (assumes the resource is a container).
#  -recurseDependencies   [1 or 0] - A bit [default=0] flag indicating whether the privileges of the resources in the XML file should be applied to any resources that they use.
#  -recurseDependents     [1 or 0] - A bit [default=0] flag indicating whether the privileges of the resources in the XML file should be applied to any resources that are used by them.
#
# The following parameter may be passed into validateDeployment and runAfterImport:
#  -inp1 [optional] Use this to represent a unique id for validating the deployment contents with an external log.
#     Format: -inp1 value
#             -inp1 signals the variable input.
#             value is the actual value with double quotes when spaces are present.
#  -inp2 [optional] Use this to represent any value
#     Format: -inp2 value
#             -inp2 signals the variable input.
#             value is the actual value with double quotes when spaces are present.
#  -inp3 [optional] Use this to represent any value
#     Format: -inp3 value
#             -inp3 signals the variable input.
#             value is the actual value with double quotes when spaces are present.
#
# DISCLAIMER: 
#    Migrating resources from 8.x to 7.x is not generally supported.
#    However, it does provide a way to move basic functionality coded in 8.x to 7.x.  
#    It does not support the ability to move new features that exist in 8.x but do not exist in 7.x.  
#    Exceptions may be thrown in this circumstance.
#****************************************************************
#
############################################################################################################################
# (c) 2017 TIBCO Software Inc. All rights reserved.
# 
# Except as specified below, this software is licensed pursuant to the Eclipse Public License v. 1.0.
# The details can be found in the file LICENSE.
# 
# The following proprietary files are included as a convenience, and may not be used except pursuant
# to valid license to Composite Information Server or TIBCO(R) Data Virtualization Server:
# csadmin-XXXX.jar, csarchive-XXXX.jar, csbase-XXXX.jar, csclient-XXXX.jar, cscommon-XXXX.jar,
# csext-XXXX.jar, csjdbc-XXXX.jar, csserverutil-XXXX.jar, csserver-XXXX.jar, cswebapi-XXXX.jar,
# and customproc-XXXX.jar (where -XXXX is an optional version number).  Any included third party files
# are licensed under the terms contained in their own accompanying LICENSE files, generally named .LICENSE.txt.
# 
# This software is licensed AS-IS. Support for this software is not covered by standard maintenance agreements with TIBCO.
# If you would like to obtain assistance with this software, such assistance may be obtained through a separate paid consulting
# agreement with TIBCO.
#
#	Release:	Modified Date:	Modified By:		DV Version:		Reason:
#	2019.400	12/31/2019		Mike Tinius			7.0.8 / 8.x		Initially created by several PSG team members
#	2020.202	06/11/2020		Mike Tinius			7.0.8 / 8.x		Modified script to pass in path of contents.xml to VALIDATE_DEPLOYMENT_URL.
#
############################################################################################################################
#
#----------------------------------------------------------------------------------
# Modify the variables below according to your environment.
#----------------------------------------------------------------------------------

####################################################################################################
#   DEBUG=Y will send the DEBUG value to TDV procedures and the procedures will write to DV cs_server.log file.
#         N will do nothing.
get_DEBUG()         { echo "N"; }
####################################################################################################


####################################################################################################
# DV_HOME - This is the path on the deployment server of TDV home
#    Required parameter.
get_DV_HOME()       { echo "/opt/tibco/tdv/8.2"; }
####################################################################################################


####################################################################################################
# FULL_BACKUP_PATH - This is the path on the deployment server where TDV server backup files are stored.
#    Required parameter.
get_FULL_BACKUP_PATH() { echo "/opt/tibco/tdv/share/config/deployment/fullbackup"; }
####################################################################################################


####################################################################################################
# SERVER_ATTRIBUTE_DATABASE - This is the published database "ASAssets" and URL 
#   "Utilities.repository.getServerAttribute" to get a server attribute.
#   This is required if converting a .car file from 8.x to 7.x
#   This is the standard, generic database and URL.
#   Optional-leave blank if not using this feature.  Only database needs to be unset if not using.
#     get_SERVER_ATTRIBUTE_DATABASE()     { echo "ASAssets"; }
get_SERVER_ATTRIBUTE_DATABASE()     { echo "ASAssets"; }
get_SERVER_ATTRIBUTE_URL()          { echo "Utilities.repository.getServerAttribute"; }
####################################################################################################


####################################################################################################
# Privileges and Ownership Strategy 1:
# -------------------------------------
# STRATEGY1_RESOURCE_PRIVILEGE_DATABASE - This is the published database "ASAssets" and URL 
#   "Utilities.deployment.updatePrivilegesDriverInterface" to set resource privileges
#   and resource ownership at a fine-grained level.
#   This strategy requires the open source ASAssets Data Abstraction Best Practices:
#      /shared/ASAssets/BestPractices_v81
#      At a minimum this datasource needs to be configured: 
#         /shared/ASAssets/BestPractices_v81/PrivilegeScripts/Metadata/Privileges_DS_EXCEL
#      The spreadsheet "Resource_Privileges_LOAD_DB.xlsx" is required to be on the DV server.
#   This is the standard, generic database and URL using the fine-grained methodology.
#   Optional-leave blank if not using this feature.  
#     get_STRATEGY1_RESOURCE_PRIVILEGE_DATABASE()  { echo "ASAssets"; }
get_STRATEGY1_RESOURCE_PRIVILEGE_DATABASE()  { echo ""; }
get_STRATEGY1_RESOURCE_PRIVILEGE_URL()       { echo "Utilities.deployment.updatePrivilegesDriverInterface"; }
####################################################################################################


####################################################################################################
# Privileges and Ownership Strategy 2:
# -------------------------------------
# This strategy uses the "ALL or NOTHING" approach where the privileges are stored in an XML file
#   on the server.  The resource ownerhship settings are stored in a text file on the server.
#   In this strategy all privileges in restored across all paths found in the XML file and the 
#   the same for resource ownership text file.  Granularity of settings is low.
# These two settings are packaged together as a similar strategy.  If not using then unset the 
#   database for each one below.
# The privileges and ownership are generated to files on the DV server using the following procedure:
#   /shared/ASAssets/Utilities/deployment/privileges/templates/runPrivilegeExport_1_DEV_template
#   /shared/ASAssets/Utilities/deployment/privileges/templates/runPrivilegeExport_2_TEST_template
#   /shared/ASAssets/Utilities/deployment/privileges/templates/runPrivilegeExport_3_PROD_template
#   Each one is different because the settings may be different in each environment.  It allows the 
#     developer to maintain them on DEV and deploy to the necessary environments and execute them in 
#     their appropriate environment.
#
# STRATEGY2_RESOURCE_PRIVILEGE_DATABASE - This is the published database "ASAssets" and URL 
#   "Utilities.deployment.importResourcePrivileges" to import and set resource privileges.
#   This is the standard, generic database and URL using the XML/text file methodology.
#   Optional-leave blank if not using this feature.  
#     get_STRATEGY2_RESOURCE_PRIVILEGE_DATABASE()  { echo "ASAssets"; }
get_STRATEGY2_RESOURCE_PRIVILEGE_DATABASE()  { echo ""; }
get_STRATEGY2_RESOURCE_PRIVILEGE_URL()       { echo "Utilities.deployment.importResourcePrivileges"; }
# This is the path on the TDV server for "/TIBCO/deployment/privileges/privileges.xml".  
get_STRATEGY2_RESOURCE_PRIVILEGE_FILE()      { echo "/home/qa/deployment/privileges/privileges.xml"; }
#
#
# STRATEGY2_RESOURCE_OWNERSHIP_DATABASE - This is the published database "ASAssets" and URL 
#   "Utilities.deployment.importResourceOwnership" to import and change resource ownership.
#   This is the standard, generic database and URL using the XML/text file methodology.  
#   Optional-leave blank if not using this feature.  Only database needs to be unset if not using.
#     e.g. get_STRATEGY2_RESOURCE_OWNERSHIP_DATABASE()  { echo "ASAssets"; }
get_STRATEGY2_RESOURCE_OWNERSHIP_DATABASE()  { echo ""; }
get_STRATEGY2_RESOURCE_OWNERSHIP_URL()       { echo "Utilities.deployment.importResourceOwnership"; }
# This is the path on the TDV server for "/TIBCO/deployment/privileges/resource_ownership.txt".  
get_STRATEGY2_RESOURCE_OWNERSHIP_FILE()      { echo "/home/qa/deployment/privileges/resource_ownership.txt"; }
####################################################################################################


####################################################################################################
# RUN_AFTER_IMPORT_DATABASE - This is the published database and URL for the "runAfterImport" custom call.  
#   Optional-leave blank if not using this feature.  Only database needs to be unset if not using.
#     e.g. get_RUN_AFTER_IMPORT_DATABASE()     { echo "ADMIN"; }
get_RUN_AFTER_IMPORT_DATABASE()     { echo ""; }
get_RUN_AFTER_IMPORT_URL()          { echo "runAfterImport"; }
####################################################################################################


####################################################################################################
# This is the published database and URL for the "validateDeployment" custom call.
#   Optional-leave blank if not using this feature.  Only database needs to be unset if not using.
#     e.g. get_VALIDATE_DEPLOYMENT_DATABASE()  { echo "ASAssets"; }
get_VALIDATE_DEPLOYMENT_DATABASE()  { echo ""; }
get_VALIDATE_DEPLOYMENT_URL()       { echo "Utilities.deployment.validateDeployment"; }
# This is the remote server location where metadata.xml files will be copied to for the TDV server to read from.
get_VALIDATE_DEPLOYMENT_DIR()       { echo "/opt/tibco/tdv/share/config/deployment/metadata"; }
# This is the full path to the DV Deployment Validation table.  This points to the customer implementation of the "DV_DEPLOYMENT_VALIDATION" table.
#     e.g. /shared/Common/DeploymentValidation/Physical/Formatting/oracle/DV_DEPLOYMENT_VALIDATION
get_VALIDATE_DV_TABLE_PATH()        { echo "/shared/CoE/DeploymentValidation/DV_DEPLOYMENT_VALIDATION"; }
# The full path to the DV sequence num generator procedure path that has no input and returns a single scalar INTEGER output.
#     e.g. /shared/Common/DeploymentValidation/Physical/Formatting/getSequenceNum
get_VALIDATE_DV_PROCEDURE_PATH()    { echo "/shared/CoE/DeploymentValidation/getSequenceNum"; }
####################################################################################################

#----------------------------------------------------------------------------------
# DO NOT MODIFY BELOW THIS POINT:
#----------------------------------------------------------------------------------

#****************************************************************
# FUNCTIONS
#****************************************************************
#-------------------------------------------------------------
# Description: usage
# Show the usage for input parameters.
#-------------------------------------------------------------
usage()
{
   echo "===================================================================================================="
   echo "| $MESSAGE"
   echo "|"
   echo "| Usage: $S -i <import_CAR_file> -o <options_file> -h <hostname> -p <wsport> -u <username> -d <domain> -up <user_password>" 
   echo "|    Mandatory Params:"
   echo "|      -i  [mandatory] import archive (CAR) file path (full or relative)."
   echo "|      -h  [mandatory] host name or ip address of the DV server deploying to."
   echo "|      -p  [mandatory] web service port of the target DV server deploying to.  e.g. 9400"
   echo "|      -u  [mandatory] username with admin privileges."
   echo "|      -d  [mandatory] domain of the username."
   echo "|      -up [mandatory] user password."
   echo "|    Optional Params:"
   echo "|      -o  [optional] options file path (full or relative)."
   echo "|      -ep encryptionPassword [optional] encryption password for the archive (CAR) file for TDV 8.x."
   echo "|      -v  [optional] verbose output" 
   echo "|      -c  [optional] convert 8.x package .car to a 7.x .car file" 
   echo "|      -e  [optional] encrypt the communication with https" 
   echo "|      -print        [optional] print info and contents of the package .car file and import the car file.  If -print is not used, the car will still be imported."
   echo "|      -printOnly    [optional] only print info and contents of the package .car file and do not import or execute any other option.  This option overrides -print."
   echo "|      -printWarning [optional] print the warnings for updatePrivilegesDriverInterface, importResourcePrivileges, importResourceOwnership and runAfterImport otherwise do not print them."
   echo "|      -privsOnly    [optional] execute the configured privilege strategy only.  Do no execute the full deployment."
   echo "|    Optional \"validateDeployment\" and/or \"RunAfterInput\" Params:" 
   echo "|      -inp1 value [optional] Input value 1 [validateDeployment-An external id to correlate to an external system.] or [runAfterImport]" 
   echo "|      -inp2 value [optional] Input value 2 [runAfterImport]" 
   echo "|      -inp3 value [optional] Input value 3 [runAfterImport]" 
   echo "|    Optional Privilege Strategy1 \"updatePrivilegesDriver\" Params:" 
   echo "|      -pe value [mandatory] privileges-environment-name  [DEV, UAT, PROD]" 
   echo "|      -pd value [optional] privileges-datasource  [EXCEL, DB_LLE_ORA, DB_LLE_SS, DB_PROD_ORA, DB_PROD_SS]" 
   echo "|      -po value [optional] privileges-organization-name" 
   echo "|      -pp value [optional] privileges-project-name" 
   echo "|      -ps value [optional] privileges-sub-project name" 
   echo "|      -sn value [optional] privilege excel sheet name.  [Privileges_shared, Privileges_databases, Privileges_webservices]" 
   echo "|      -rp value [optional] privilege resource path - The resource path in which to get/update privileges.  It may contain a wildcard \"%\"." 
   echo "|      -rt value [optional] privilege resource type - The resource type in which to get/update privileges.  It is always upper case. " 
   echo "|      -gn value [optional] privilege group name - The user/group name in which to get/update privileges." 
   echo "|      -gt value [optional] privilege group type - Valid values are USER or GROUP" 
   echo "|      -gd value [optional] privilege group domain - The domain name in which to get/update privileges." 
   echo "|      -be value [optional] privilege bypass errors - Throw exception when paths not found. N=Do not bypass errors. Y=bypass resource not found errors but report them." 
   echo "|    Optional Privilege Strategy2 \"importResourcePrivileges\" Params:" 
   echo "|      -recurseChildResources [1 or 0] - A bit [default=1] flag indicating whether the privileges of the resources in the XML file should be recursively applied to any child resources. " 
   echo "|      -recurseDependencies   [1 or 0] - A bit [default=0] flag indicating whether the privileges of the resources in the XML file should be applied to any resources that they use." 
   echo "|      -recurseDependents     [1 or 0] - A bit [default=0] flag indicating whether the privileges of the resources in the XML file should be applied to any resources that are used by them." 
   echo "===================================================================================================="
   echo ""
}

#-------------------------------------------------------------
# Description: GetDVProcedureResults
# Verify the results from the output of a DV procedure call based on the search text.
# -- SEARCH_TEXT      v[in] - variable name containing the search text.
#                                    ex 1. search for a SUCCESS status returned
#                                          set SEARCH_TEXT=col\[1]=SUCCESS
#                                    ex 2. search for version 8 returned
#                                          set SEARCH_TEXT=col\[1]=8
# -- JDBC_RESULT_FILE v[in] - variable containing the full path to the JdbcSample script output.
# -- JDBC_RESULT_FILE2 [in] - variable containing the full path to the secondary temporary file.
# -- QUIET             [in] - variable containing the quiet value.
# -- DISPLAY_CONTENTS  [in] - variable containing true or false to display the contents of JDBC_RESULT_FILE.
# -- S                 [in] - variable containing this script name.
#
# -- RESULT           [out]   - variable name containing the result code which is set using exit /B %RESULT%
#                                     0=NOT FOUND, search text was not found
#                                     1=FOUND, search text found.
#                                    99=RESULT, file not found.
#-------------------------------------------------------------
GetDVProcedureResults() 
{
    SEARCH_TEXT="$1"
	JDBC_RESULT_FILE="$2"
	JDBC_RESULT_FILE2="$3"
	QUIET="$4"
	DISPLAY_CONTENTS="$5"
	S="$6"

	# Search the $JDBC_RESULT_FILE file for a result row from $SEARCH_TEXT.
	if [ -f "$JDBC_RESULT_FILE" ] ; then
		if [ "$QUIET" == "" ] ; then 
			echo "$S: *** sed 's/\`//g' \"$JDBC_RESULT_FILE\" > \"$JDBC_RESULT_FILE2\" ***"
			echo "$S: *** searchText=\`grep -e \"$SEARCH_TEXT\" \"$JDBC_RESULT_FILE2\"\` ***"
			echo "$S: *** File contents for JDBC_RESULT_FILE=\"$JDBC_RESULT_FILE\" ***"
			cat "$JDBC_RESULT_FILE"
		fi
		# Only display contents if DISPLAY_CONTENTS=true and QUIET=-q
		if [ "$QUIET" == "-q" ] && [ "$DISPLAY_CONTENTS" == "true" ] ; then 
			echo "$S: *** File contents for JDBC_RESULT_FILE=\"$JDBC_RESULT_FILE\" ***"
			cat "$JDBC_RESULT_FILE"
		fi
		# Perform the search for the SEARCH_TEXT in the JDBC_RESULT_FILE
		sed 's/`//g' "$JDBC_RESULT_FILE" > "$JDBC_RESULT_FILE2"
		searchText=`grep -e "$SEARCH_TEXT" "$JDBC_RESULT_FILE2"`
		if [ "$searchText" == "" ] ; then
			# Did not find search text
			RESULT="0"
		    if [ "$QUIET" == "" ] ; then 
				echo "$S: *** Found=false  SEARCH_TEXT:$SEARCH_TEXT ***"
			fi
		else
			# Found search text becuase grep will return the row where the string was found.
			RESULT="1"
			if [ "$QUIET" == "" ] ; then 
				echo "$S: *** Found=true  SEARCH_TEXT:$SEARCH_TEXT ***"
			fi
		fi
		# Clean up temporary files
		if [ -f "$JDBC_RESULT_FILE2" ] ; then rm -f "$JDBC_RESULT_FILE2" ; fi
	else
		# Clean up temporary files
		if [ -f "$JDBC_RESULT_FILE" ]  ; then rm -f "$JDBC_RESULT_FILE" ; fi
		if [ -f "$JDBC_RESULT_FILE2" ] ; then rm -f "$JDBC_RESULT_FILE2" ; fi
		if [ "$QUIET" == "" ] ; then 
			echo "$S: *** Error.  File not found JDBC_RESULT_FILE=$JDBC_RESULT_FILE ***"
		fi
		RESULT="99";
	fi
	return $RESULT
}

#-------------------------------------------------------------
# Description: CleanUpTmpFiles
# Clean up the temporary directories.
CleanUpTmpFiles()
{
	S="$1"
    TMPDIR="$2"
	TMPDIR="$3"
	VALIDATE_PATH1="$4"
	VALIDATE_PATH2="$5"

	echo "$S: **************************************************************"
	echo "$S: Clean-up temporary directories and files."
	echo "$S: **************************************************************"
	if [ "$TMPDIR" != "" ]; then
		if [ -d "$TMPDIR" ]; then 
			echo "$S: Deleting $TMPDIR"
			rm -rf "$TMPDIR"
		fi
	fi
	if [ "$VALIDATE_PATH1" != "" ]; then
		if [ -f "$VALIDATE_PATH1" ]; then 
			echo "$S: Deleting $VALIDATE_PATH1"
			rm -f "$VALIDATE_PATH1"
		fi
	fi
	if [ "$VALIDATE_PATH2" != "" ]; then
		if [ -f "$VALIDATE_PATH2" ]; then 
			echo "$S: Deleting $VALIDATE_PATH2"
			rm -f "$VALIDATE_PATH2"
		fi
	fi
}

#-------------------------------------------------------------
# Description: FailureMessage
# Display failure message.
FailureMessage()
{
	DEPLOYMENT_DATE_BEG="$1"
	JDBC_RESULT_FILE="$2"
	EXCEPTION_LOG="$3"
	
	# Copy the JDBC_RESULTS_FILE to the exception log file
	if [ -f "$JDBC_RESULT_FILE" ]; then
		cp "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
	fi

	# Calculate and format the start and end time difference
	DEPLOYMENT_DATE_END_SECONDS=$(date +%s);
	DT=`date +%Y-%m-%d`
	TM=`date +%H:%M:%S`
	# Replace space with 0
	DT=${DT// /0}
	TM=${TM// /0}
	DEPLOYMENT_DATE_END="$DT $TM"
	DIFF=$((DEPLOYMENT_DATE_END_SECONDS-DEPLOYMENT_DATE_BEG_SECONDS))
	HOUR=`echo $((DIFF/3600)) | awk '{printf "%02d\n", $0;}'`
	MIN=`echo $((DIFF/60)) | awk '{printf "%02d\n", $0;}'`
	SEC=`echo $((DIFF%60)) | awk '{printf "%02d\n", $0;}'`
	# Print out the deployment end date and start date.
	echo ""
	echo "=============================================================="
	echo "DEPLOYMENT_DATE_BEG=$DEPLOYMENT_DATE_BEG"
	echo "DEPLOYMENT_DATE_END=$DEPLOYMENT_DATE_END"
	echo "DURATION=$HOUR:$MIN:$SEC"
	echo "=============================================================="
	echo ""
    echo "$S: **************************************************************"
    echo "$S: ***  ERROR: Migration steps failed with an exception.      ***"
    echo "$S: **************************************************************"
    echo "$S: EXCEPTION LOG: $EXCEPTION_LOG"
	echo ""
}

#****************************************************************
# MAIN SCRIPT BODY
#****************************************************************

#----------------------------
# Set the script name
#----------------------------
S=$(basename -- "$0")

echo "=============================================================="
echo "$S: Begin Deployment"
echo ""

#----------------------------
# Assign local variables
#----------------------------
DEBUG=$(get_DEBUG)
# DV Home Variable
DV_HOME=$(get_DV_HOME)
# Server Attribute Variables
FULL_BACKUP_PATH=$(get_FULL_BACKUP_PATH)
SERVER_ATTRIBUTE_DATABASE=$(get_SERVER_ATTRIBUTE_DATABASE)
SERVER_ATTRIBUTE_URL=$(get_SERVER_ATTRIBUTE_URL)
# Strategy 1 Privilege Variables
STRATEGY1_RESOURCE_PRIVILEGE_DATABASE=$(get_STRATEGY1_RESOURCE_PRIVILEGE_DATABASE)
STRATEGY1_RESOURCE_PRIVILEGE_URL=$(get_STRATEGY1_RESOURCE_PRIVILEGE_URL)
# Strategy 2 Privilege Variables
STRATEGY2_RESOURCE_PRIVILEGE_DATABASE=$(get_STRATEGY2_RESOURCE_PRIVILEGE_DATABASE)
STRATEGY2_RESOURCE_PRIVILEGE_URL=$(get_STRATEGY2_RESOURCE_PRIVILEGE_URL)
STRATEGY2_RESOURCE_PRIVILEGE_FILE=$(get_STRATEGY2_RESOURCE_PRIVILEGE_FILE)
# Strategy 2 Resource Ownership Variables
STRATEGY2_RESOURCE_OWNERSHIP_DATABASE=$(get_STRATEGY2_RESOURCE_OWNERSHIP_DATABASE)
STRATEGY2_RESOURCE_OWNERSHIP_URL=$(get_STRATEGY2_RESOURCE_OWNERSHIP_URL)
STRATEGY2_RESOURCE_OWNERSHIP_FILE=$(get_STRATEGY2_RESOURCE_OWNERSHIP_FILE)
# Run After Import Variables
RUN_AFTER_IMPORT_DATABASE=$(get_RUN_AFTER_IMPORT_DATABASE)
RUN_AFTER_IMPORT_URL=$(get_RUN_AFTER_IMPORT_URL)
# Validate Deployment Variables
VALIDATE_DEPLOYMENT_DATABASE=$(get_VALIDATE_DEPLOYMENT_DATABASE)
VALIDATE_DEPLOYMENT_URL=$(get_VALIDATE_DEPLOYMENT_URL)
VALIDATE_DEPLOYMENT_DIR=$(get_VALIDATE_DEPLOYMENT_DIR)
VALIDATE_DV_TABLE_PATH=$(get_VALIDATE_DV_TABLE_PATH)
VALIDATE_DV_PROCEDURE_PATH=$(get_VALIDATE_DV_PROCEDURE_PATH)

#----------------------------
# Set default parameters
#----------------------------
loopcount=0
QUIET="-q"
CONVERT=
ENCRYPT=
PRINT_OPTION="N"
PRINT_ONLY="N"
PRINT_WARNING="false"
PRIVS_ONLY="false"
PRIVS_CONFIGURED="false"
PKGFILE=
OPTFILE=
HOST=
WSPORT=
DBPORT=
USER=
DOMAIN=
USER_PASSWORD=
ENCRYPTION_PASSWORD=
# Variables for runAfterImport and ValidateDeployment
INPUT1=
INPUT2=
INPUT3=
# Strategy 1 Privilege variables
PRIVILEGE_DATASOURCE=
PRIVILEGE_ENVIRONMENT=
PRIVILEGE_ORGANIZATION=
PRIVILEGE_PROJECT=
PRIVILEGE_SUBPROJECT=
PRIVILEGE_SHEET_NAME=
PRIVILEGE_RESOURCE_PATH=
PRIVILEGE_RESOURCE_TYPE=
PRIVILEGE_GROUP_NAME=
PRIVILEGE_GROUP_TYPE=
PRIVILEGE_GROUP_DOMAIN=
PRIVILEGE_BYPASS_ERRORS="N"
# Strategy 2 Privilege variables
RECURSE_CHILD_RESOURCES="1"
RECURSE_DEPENDENCIES="0"
RECURSE_DEPENDENTS="0"

#----------------------------
# Assign input parameters
#----------------------------
while [ ! -z "$1" ]
do
  loopcount=$((loopcount+1));
  if [ "$DEBUG" == "Y" ]; then 
    if [ "$1" == "-up" ]; then  
       echo "loopcount=$loopcount  P1=[$1]   P2=[********]";
	else
       echo "loopcount=$loopcount  P1=[$1]   P2=[$2]";
	fi
  fi;

  # Beginning of loop and there are no parameters then USAGE and exit.
  if [[ ($loopcount -eq 1) && ("$1" == "") ]]; then
	CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
	usage
	exit 1
  fi

  case "$1" in

    # Optional parameters
    -v)
		export QUIET=""
		;;
    -c)
		export CONVERT="$1"
		;;
    -e)
		export ENCRYPT="-encrypt"
		;;
    -print)
		export PRINT_OPTION="Y"
		;;
    -printOnly)
		export PRINT_OPTION="Y"
		export PRINT_ONLY="Y"
		;;
    -printonly)
		export PRINT_OPTION="Y"
		export PRINT_ONLY="Y"
		;;
    -printWarning)
		export PRINT_WARNING="true"
		;;
    -printwarning)
		export PRINT_WARNING="true"
		;;
    -privsOnly)
		export PRIVS_ONLY="true"
		;;
    -privsonly)
		export PRIVS_ONLY="true"
		;;
	# Mandatory parameters
    -i)
		PKGFILE="$2"
		#echo "PKGFILE=$PKGFILE"
		#----------------------------
		# Resolve relative paths for the package file
		#----------------------------
		if [ "$PKGFILE" != "" ]; then
			absolute="$PKGFILE"
			if [ -d "$PKGFILE" ]; then 
				absolute=$absolute/.
			fi
			absolute=$(cd "$(dirname -- "$absolute")"; printf %s. "$PWD")
			absolute="${absolute%?}"
			FOLDER_NAME="$absolute/${f##*/}"
			FILE_NAME="$(basename -- $PKGFILE)"
			export PKGFILE="${FOLDER_NAME}${FILE_NAME}"
			export PKGNAME="${FILE_NAME}"
		fi
		shift
		;;
    -o)
		OPTFILE="$2"
		#echo "OPTFILE=$OPTFILE"
		#----------------------------
		#----------------------------
		# Resolve relative paths for the option file
		#----------------------------
		if [ "$OPTFILE" != "" ]; then
			absolute="$OPTFILE"
			if [ -d "$OPTFILE" ]; then 
				absolute=$absolute/.
			fi
			absolute=$(cd "$(dirname -- "$absolute")"; printf %s. "$PWD")
			absolute="${absolute%?}"
			FOLDER_NAME="$absolute/${f##*/}"
			FILE_NAME="$(basename -- $OPTFILE)"
			export OPTFILE="${FOLDER_NAME}${FILE_NAME}"
		fi
		shift
		;;
    -h)
		export HOST="$2"
		shift
		;;
    -p)
		export WSPORT="$2"
		DBPORT="$WSPORT"
		export DBPORT=$((DBPORT+1))
		shift
		;;
    -u)
		export USER="$2"
		shift
		;;
    -d)
		export DOMAIN="$2"
		shift
		;;
    -up)
		export USER_PASSWORD="$2"
		shift
		;;
    -ep)
		export ENCRYPTION_PASSWORD="$2"
		shift
		;;

	# Strategy 1 Privilege parameters
    -pd)
		export PRIVILEGE_DATASOURCE="$2"
		shift
		;;
    -pe)
		export PRIVILEGE_ENVIRONMENT="$2"
		shift
		;;
    -po)
		export PRIVILEGE_ORGANIZATION="$2"
		shift
		;;
    -pp)
		export PRIVILEGE_PROJECT="$2"
		shift
		;;
    -ps)
		export PRIVILEGE_SUBPROJECT="$2"
		shift
		;;
    -sn)
		export PRIVILEGE_SHEET_NAME="$2"
		shift
		;;
    -rp)
		export PRIVILEGE_RESOURCE_PATH="$2"
		shift
		;;
    -rt)
		export PRIVILEGE_RESOURCE_TYPE="$2"
		shift
		;;
    -gn)
		export PRIVILEGE_GROUP_NAME="$2"
		shift
		;;
    -gt)
		export PRIVILEGE_GROUP_TYPE="$2"
		shift
		;;
    -gd)
		export PRIVILEGE_GROUP_DOMAIN="$2"
		shift
		;;
    -be)
		export PRIVILEGE_BYPASS_ERRORS="$2"
		shift
		;;
	# Strategy 2 Privilege parameters
    -recurseChildResources)
		export RECURSE_CHILD_RESOURCES="$2"
		shift
		;;
    -recursechildresources)
		export RECURSE_CHILD_RESOURCES="$2"
		shift
		;;
    -recurseDependencies)
		export RECURSE_DEPENDENCIES="$2"
		shift
		;;
    -recursedependencies)
		export RECURSE_DEPENDENCIES="$2"
		shift
		;;
    -recurseDependents)
		export RECURSE_DEPENDENTS="$2"
		shift
		;;
    -recursedependents)
		export RECURSE_DEPENDENTS="$2"
		shift
		;;
	# -input1 value parameters
    -inp1)
		export INPUT1="$2"
		shift
		;;
    -input1)
		export INPUT1="$2"
		shift
		;;
    -inp2)
		export INPUT2="$2"
		shift
		;;
    -input2)
		export INPUT2="$2"
		shift
		;;
    -inp3)
		export INPUT3="$2"
		shift
		;;
    -input3)
		export INPUT3="$2"
		shift
		;;
	*) 
		# unknown option
		shift
		;;
  esac
  
  shift
done

#----------------------------
# Resolve relative paths for the scriptdir
#----------------------------
SCRIPTDIR=`dirname path`
absolute="$SCRIPTDIR"
if [ -d "$SCRIPTDIR" ]; then absolute=${absolute}/.; fi
absolute=$(cd "$(dirname -- "$absolute")"; printf %s. "$PWD")
absolute="${absolute%?}"
SCRIPTDIR="${absolute}"
TMPDIR="${SCRIPTDIR}/tmp_ps"
SCRIPTDIR_LOGS="$SCRIPTDIR/logs"
# Create temp folders
if [ ! -d "$TMPDIR" ]; then
	mkdir "$TMPDIR"
fi
# Create logs folders
if [ ! -d "$SCRIPTDIR_LOGS" ]; then
	mkdir "$SCRIPTDIR_LOGS"
fi

#----------------------------
# Assign dynamic variables
#----------------------------
WARNING="0"
DEPLOYMENT_DATE_BEG_SECONDS=$(date +%s);
DT=`date +%Y_%m_%d`
TM=`date +%H_%M_%S`
MYDATETIME=${DT}_${TM}
# Replace space with 0
DT=${DT// /0}
TM=${TM// /0}
# Replace underscore with dash in date and colon in time
DT=${DT//_/-}
TM=${TM//_/:}
DEPLOYMENT_DATE_BEG="$DT $TM"

# Create 2 different file qualifiers
FILE_QUALIFIER1="${HOST}_${WSPORT}_${INPUT1}_${MYDATETIME}"
FILE_QUALIFIER1=`echo $FILE_QUALIFIER1 | sed 's/\./_/g'`
FILE_QUALIFIER2="${HOST}_${WSPORT}_${MYDATETIME}"
FILE_QUALIFIER2=`echo $FILE_QUALIFIER2 | sed 's/\./_/g'`

BACKUPFILENAME="$FULL_BACKUP_PATH/pre_deploy_fsb_$FILE_QUALIFIER2.car"
JDBC_RESULT_FILE="$TMPDIR/jdbcSampleResults.txt"
JDBC_RESULT_FILE2="$TMPDIR/jdbcSampleResults2.txt"
ARCHIVE_RESULT_FILE="$TMPDIR/archivePkgContents_$MYDATETIME.txt"
ARCHIVE_CREATION_DATE_FILE_PATH="${TMPDIR}/ps_pkgCreationDate_${MYDATETIME}.txt"

VALIDATE_DEPLOYMENT_CONTENTS_PATH="${VALIDATE_DEPLOYMENT_DIR}/archive_contents_${FILE_QUALIFIER1}.xml"
VALIDATE_DEPLOYMENT_METADATA_PATH="${VALIDATE_DEPLOYMENT_DIR}/archive_metadata_${FILE_QUALIFIER1}.xml"
VALIDATE_METADATA_LOG="${SCRIPTDIR_LOGS}/validate_metadata_output_${FILE_QUALIFIER2}.log"
STRATEGY1_RESOURCE_PRIVILEGE_LOG="${SCRIPTDIR_LOGS}/strategy1_privilege_output_${FILE_QUALIFIER2}.log"
STRATEGY2_RESOURCE_PRIVILEGE_LOG="${SCRIPTDIR_LOGS}/strategy2_privilege_output_${FILE_QUALIFIER2}.log"
STRATEGY2_RESOURCE_OWNERSHIP_LOG="${SCRIPTDIR_LOGS}/strategy2_ownership_output_${FILE_QUALIFIER2}.log"
RUN_AFTER_IMPORT_LOG="${SCRIPTDIR_LOGS}/run_after_import_output_${FILE_QUALIFIER2}.log"
EXCEPTION_LOG="${SCRIPTDIR_LOGS}/exception_${FILE_QUALIFIER2}.log"
# Warning variable
WARNING_OUTPUT=""

# Use the JdbcSample.sh in the local directory.
JDBC_SAMPLE_EXEC="$SCRIPTDIR/JdbcSample.sh"
if [ ! -f "$JDBC_SAMPLE_EXEC" ] ; then
	echo "$S Failure: The JdbcSample.sh script could not be found: $JDBC_SAMPLE_EXEC"
	FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
	CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
	exit 1
fi

# Setup the conversion scripts
if [ ! -f "$SCRIPTDIR/convertPkgFileV11_to_V10.sh" ]; then
	echo "$S Failure: The package conversion script could not be found: $SCRIPTDIR/convertPkgFileV11_to_V10.sh"
	FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
	CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
	exit 1
fi
CONVERT_PKG_FILEV11="$SCRIPTDIR/convertPkgFileV11_to_V10.sh"

#----------------------------
# Display input
#----------------------------
# Display Deployment or Privileges Only
if [ "$PRIVS_ONLY" == "true" ]; then
   echo "Executing Privileges Only"
fi
if [ "$PRIVS_ONLY" == "false" ]; then
   echo "Executing Deployment"
fi

echo "=============================================================="
echo "General Parameters:"
echo "   DEPLOYMENT_DATE_BEG=$DEPLOYMENT_DATE_BEG"
echo "   DV_HOME=$DV_HOME"
echo "   DEBUG=$DEBUG"
echo "   QUIET=$QUIET"
echo "   CONVERT=$CONVERT"
echo "   PKGFILE=$PKGFILE"
echo "   PKGNAME=$PKGNAME"
echo "   OPTFILE=$OPTFILE"
echo "   HOST=$HOST"
echo "   WSPORT=$WSPORT"
echo "   DBPORT=$DBPORT"
echo "   USER=$USER"
echo "   DOMAIN=$DOMAIN"
echo "   ENCRYPT=$ENCRYPT"
echo "   PRINT_OPTION=$PRINT_OPTION"
echo "   PRINT_ONLY=$PRINT_ONLY"
echo "   PRINT_WARNING=$PRINT_WARNING"
echo "   PRIVS_ONLY=$PRIVS_ONLY"
echo "   EXCEPTION_LOG=$EXCEPTION_LOG"

# Server Attributes
if [ "$SERVER_ATTRIBUTE_DATABASE" != "" ]; then
   echo "Server Attribute Parameters:"
   echo "   SERVER_ATTRIBUTE_DATABASE=$SERVER_ATTRIBUTE_DATABASE"
   echo "   SERVER_ATTRIBUTE_URL=$SERVER_ATTRIBUTE_URL"
fi

# Validate deployment
if [ "$VALIDATE_DEPLOYMENT_DATABASE" != "" ]; then
   echo "Validate Deployment Parameters:"
   echo "   VALIDATE_DEPLOYMENT_DATABASE=$VALIDATE_DEPLOYMENT_DATABASE"
   echo "   VALIDATE_DEPLOYMENT_DIR=$VALIDATE_DEPLOYMENT_DIR"
   echo "   VALIDATE_DV_TABLE_PATH=$VALIDATE_DV_TABLE_PATH"
   echo "   VALIDATE_DV_PROCEDURE_PATH=$VALIDATE_DV_PROCEDURE_PATH"
   echo "   INPUT1=$INPUT1"
   echo "   VALIDATE_METADATA_LOG=$VALIDATE_METADATA_LOG"
fi

# Strategy 1 Privileges and ownership
if [ "$STRATEGY1_RESOURCE_PRIVILEGE_DATABASE" != "" ]; then
   echo "Strategy 1 Privilege Parameters:"
   echo "   STRATEGY1_RESOURCE_PRIVILEGE_DATABASE=$STRATEGY1_RESOURCE_PRIVILEGE_DATABASE"
   echo "   STRATEGY1_RESOURCE_PRIVILEGE_URL=$STRATEGY1_RESOURCE_PRIVILEGE_URL"
   echo "   STRATEGY1_RESOURCE_PRIVILEGE_LOG=$STRATEGY1_RESOURCE_PRIVILEGE_LOG"
   echo "   PRIVILEGE_DATASOURCE=$PRIVILEGE_DATASOURCE"
   echo "   PRIVILEGE_ENVIRONMENT=$PRIVILEGE_ENVIRONMENT"
   echo "   PRIVILEGE_ORGANIZATION=$PRIVILEGE_ORGANIZATION"
   echo "   PRIVILEGE_PROJECT=$PRIVILEGE_PROJECT"
   echo "   PRIVILEGE_SUBPROJECT=$PRIVILEGE_SUBPROJECT"
   echo "   PRIVILEGE_SHEET_NAME=$PRIVILEGE_SHEET_NAME"
   echo "   PRIVILEGE_RESOURCE_PATH=$PRIVILEGE_RESOURCE_PATH"
   echo "   PRIVILEGE_RESOURCE_TYPE=$PRIVILEGE_RESOURCE_TYPE"
   echo "   PRIVILEGE_GROUP_NAME=$PRIVILEGE_GROUP_NAME"
   echo "   PRIVILEGE_GROUP_TYPE=$PRIVILEGE_GROUP_TYPE"
   echo "   PRIVILEGE_GROUP_DOMAIN=$PRIVILEGE_GROUP_DOMAIN"
   echo "   PRIVILEGE_BYPASS_ERRORS=$PRIVILEGE_BYPASS_ERRORS"
fi

# Strategy 2 Privileges
if [ "$STRATEGY2_RESOURCE_PRIVILEGE_DATABASE" != "" ]; then
   echo "Strategy 2 Privilege Parameters:"
   echo "   STRATEGY2_RESOURCE_PRIVILEGE_DATABASE=$STRATEGY2_RESOURCE_PRIVILEGE_DATABASE"
   echo "   STRATEGY2_RESOURCE_PRIVILEGE_URL=$STRATEGY2_RESOURCE_PRIVILEGE_URL"
   echo "   STRATEGY2_RESOURCE_PRIVILEGE_FILE=$STRATEGY2_RESOURCE_PRIVILEGE_FILE"
   echo "   STRATEGY2_RESOURCE_PRIVILEGE_LOG=$STRATEGY2_RESOURCE_PRIVILEGE_LOG"
   # Strategy 2 additional parameters only if configured
   echo "   RECURSE_CHILD_RESOURCES=$RECURSE_CHILD_RESOURCES"
   echo "   RECURSE_DEPENDENCIES=$RECURSE_DEPENDENCIES"
   echo "   RECURSE_DEPENDENTS=$RECURSE_DEPENDENTS"
fi

# Strategy 2 Ownership
if [ "$STRATEGY2_RESOURCE_OWNERSHIP_DATABASE" != "" ]; then
   echo "Strategy 2 Resource Ownership Parameters:"
   echo "   STRATEGY2_RESOURCE_OWNERSHIP_DATABASE=$STRATEGY2_RESOURCE_OWNERSHIP_DATABASE"
   echo "   STRATEGY2_RESOURCE_OWNERSHIP_URL=$STRATEGY2_RESOURCE_OWNERSHIP_URL"
   echo "   STRATEGY2_RESOURCE_OWNERSHIP_FILE=$STRATEGY2_RESOURCE_OWNERSHIP_FILE"
   echo "   STRATEGY2_RESOURCE_OWNERSHIP_LOG=$STRATEGY2_RESOURCE_OWNERSHIP_LOG"
fi

# Run after input
if [ "$RUN_AFTER_IMPORT_DATABASE" != "" ]; then
   echo "Run After Input Parameters:"
   echo "   RUN_AFTER_IMPORT_DATABASE=$RUN_AFTER_IMPORT_DATABASE"
   echo "   RUN_AFTER_IMPORT_URL=$RUN_AFTER_IMPORT_URL"
   echo "   RUN_AFTER_IMPORT_LOG=$RUN_AFTER_IMPORT_LOG"
   echo "   INPUT1=$INPUT1"
   echo "   INPUT2=$INPUT2"
   echo "   INPUT3=$INPUT3"
fi

# Script variables
echo "Script Variables:"
echo "   SCRIPTDIR=$SCRIPTDIR"
echo "   TMPDIR=$TMPDIR"
echo "   SCRIPTDIR_LOGS=$SCRIPTDIR_LOGS"
echo "   BACKUPFILENAME=$BACKUPFILENAME"
echo "   JDBC_SAMPLE_EXEC=$JDBC_SAMPLE_EXEC"
echo "   CONVERT_PKG_FILEV11=$CONVERT_PKG_FILEV11"
echo "   VALIDATE_DEPLOYMENT_CONTENTS_PATH=$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
echo "   VALIDATE_DEPLOYMENT_METADATA_PATH=$VALIDATE_DEPLOYMENT_METADATA_PATH"
echo "   ARCHIVE_RESULT_FILE=$ARCHIVE_RESULT_FILE"
echo "=============================================================="
echo ""

#----------------------------
# Validate input parameters
#----------------------------
if [ "$HOST" == "" ]; then
	MESSAGE="One or more required input parameters are blank. [HOST]"
	usage
	CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
	exit 1
fi;
if [ "$WSPORT" == "" ]; then
	MESSAGE="One or more required input parameters are blank. [WSPORT]"
	usage
	CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
	exit 1
fi;
if [ "$USER" == "" ]; then
	MESSAGE="One or more required input parameters are blank. [USER]"
	usage
	CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
	exit 1
fi;
if [ "$DOMAIN" == "" ]; then
	MESSAGE="One or more required input parameters are blank. [DOMAIN]"
	usage
	CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
	exit 1
fi;

# Ask for the user password if it was not passed in
if [ "$USER_PASSWORD" == "" ]; then
    read -s -p "Password for $USER: " USER_PASSWORD
fi

# Only validate package file if NOT privs only
if [ "$PRIVS_ONLY" == "false" ]; then

	# Check for no input
	if [ "$PKGFILE" == "" ]; then
		MESSAGE="One or more required input parameters are blank. [PKGFILE]"
		usage
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit 1
	fi;

	#----------------------------
	# Validate files exist
	#----------------------------
	# Make sure the .car package file exists
	if [ ! -f "$PKGFILE" ]; then
		MESSAGE="The package .car file does not exist at path=$PKGFILE"
		usage
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit 1
	fi

	# Make sure the .car package file exists
	if [[ ("$OPTFILE" != "") && (! -f "$OPTFILE") ]]; then
		MESSAGE="The option file does not exist at path=$OPTFILE"
		usage
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit 1
	fi
fi

# Validate that a privilege strategy is configured when PRIVS_ONLY=true
if [ "$PRIVS_ONLY" == "true" ]; then
   if [ "$STRATEGY1_RESOURCE_PRIVILEGE_DATABASE" != "" ]; then
       PRIVS_CONFIGURED="true"
   fi
   if [ "$STRATEGY2_RESOURCE_PRIVILEGE_DATABASE" != "" ]; then
       PRIVS_CONFIGURED="true"
   fi
   if [ "$STRATEGY2_RESOURCE_OWNERSHIP_DATABASE" != "" ]; then
       PRIVS_CONFIGURED="true"
   fi
   if [ "$PRIVS_CONFIGURED" == "false" ]; then
	   MESSAGE="The parameter -privsOnly is set and no privilege strategy database has been configured."
	   usage
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
	   exit 1
   fi
fi

# Error if STRATEGY1_RESOURCE_PRIVILEGE_DATABASE is configured and no PRIVILEGE_ENVIRONMENT is set.
if [[ ("$STRATEGY1_RESOURCE_PRIVILEGE_DATABASE" != "") && ("$PRIVILEGE_ENVIRONMENT" == "") ]]; then
	MESSAGE="The parameter -pe \"PRIVILEGE_ENVIRONMENT\" is required to be set when \"STRATEGY1_RESOURCE_PRIVILEGE_DATABASE\" is configured."
	usage
	CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
	exit 1
fi

   
################################
# BEGIN CHECK SERVER VERSION
################################
if [[ ("$PRIVS_ONLY" == "false" ) && ("$SERVER_ATTRIBUTE_DATABASE" != "") ]]; then
	DV_PROCEDURE="$SERVER_ATTRIBUTE_URL"
	echo "$S: --------------------------------------------------------------------"
	echo "$S: *** Checking Server Version. ***"
	echo "$S: --------------------------------------------------------------------"
	echo "$S: *** \"$JDBC_SAMPLE_EXEC\" \"$SERVER_ATTRIBUTE_DATABASE\" \"$HOST\" \"$DBPORT\" \"$USER\" \"********\" \"$DOMAIN\" \"SELECT * FROM $SERVER_ATTRIBUTE_URL('/server/config/info/versionFull')\" > \"$JDBC_RESULT_FILE\" ***"
	"$JDBC_SAMPLE_EXEC" "$SERVER_ATTRIBUTE_DATABASE" "$HOST" "$DBPORT" "$USER" "$USER_PASSWORD" "$DOMAIN" "SELECT * FROM $SERVER_ATTRIBUTE_URL('/server/config/info/versionFull')" > "$JDBC_RESULT_FILE"
	ERROR=$?
	if [ $ERROR -ne 0 ] ; then
		echo "$S: $DV_PROCEDURE failed.  Aborting script. Error code: $ERROR"
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $ERROR;
	fi
	
	GetDVProcedureResults "col\[1]=8" "$JDBC_RESULT_FILE" "$JDBC_RESULT_FILE2" "$QUIET" "false" "$S"
	RESULT=$?
	if [ -f "$JDBC_RESULT_FILE" ]  ; then rm -f "$JDBC_RESULT_FILE" ; fi
	if [ $RESULT -gt 1 ] ; then 
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $RESULT;
	fi
	# Default so that version 8 was not found
	FOUND_DV_VERSION8="0"
	# Version 8 was found
	if [ $RESULT -eq 1 ] ; then 
		FOUND_DV_VERSION8="1"
	fi
	echo "$S: *** $DV_PROCEDURE successfully completed. ***"

	# If FOUND_DV_VERSION8=0, then this is probably a DV version 7 and conversion may be required.
	# If FOUND_DV_VERSION8=1, then this is a DV version 8 server so no package .car file conversion is required.
	if [ $FOUND_DV_VERSION8 -eq 0 ] ; then
		echo "$S: *** Version 8.x [false] FOUND_DV_VERSION8=$FOUND_DV_VERSION8 ***"
	else
		echo "$S: *** Version 8.x [true] FOUND_DV_VERSION8=$FOUND_DV_VERSION8 ***"
	fi
	echo ""


	################################
	# BEGIN CONVERT PACKAGE FILE
	#       FROM VERSION 11 to 10
	#       FOR MIGRATING 8.x to 7.x
	################################
	# Continue with conversion checking and .car file conversion when CONVERT == -c
	if [ "$CONVERT" == "-c" ]; then
		# Conversion is required for a package format version 11 being imported into a DV version 7.
		echo "$S: --------------------------------------------------------------------"
		echo "$S: *** Converting Package File Version 11 to 10. ***"
		echo "$S: --------------------------------------------------------------------"
		# If FOUND_DV_VERSION8=0, then this is probably a DV version 7 and conversion may be required.
		# If FOUND_DV_VERSION8=1, then this is a DV version 8 server so no package .car file conversion is required.
		if [ $FOUND_DV_VERSION8 -eq 0 ] ; then
			# Perform the conversion
			echo "$S: *** "$CONVERT_PKG_FILEV11" "$PKGFILE" $QUIET ***"
			"$CONVERT_PKG_FILEV11" "$PKGFILE" $QUIET
			IS_V11=$?
			if [ $IS_V11 -gt 1 ] ; then
				echo "$S: Package conversion version failed.  Aborting script. Error code: $IS_V11"
				FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
				CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
				exit $IS_V11;
			fi
			if [ $IS_V11 -eq 0 ] ; then echo "$S: *** No package .car file conversion required. ***" ; fi
			if [ $IS_V11 -eq 1 ] ; then echo "$S: *** Package .car file conversion completed with status=SUCCESS ***" ; fi
		else
			echo "$S: *** No package .car file conversion required. ***"
		fi
		echo ""
	fi
fi


################################
# BEGIN FULL SERVER BACKUP
################################
if [[ ("$PRIVS_ONLY" == "false" ) && ("$FULL_BACKUP_PATH" != "") && ("$PRINT_ONLY" == "N") ]]; then
	echo "$S: --------------------------------------------------------------------"
	echo "$S: *** Backing up target server $HOST:$WSPORT ***"
	echo "$S: --------------------------------------------------------------------"
	echo "$S: *** Backup file will be located at: $BACKUPFILENAME ***"
	# Execute without the encryption password DV 7.x
	if [ "$ENCRYPTION_PASSWORD" == "" ] ; then
	   echo "$S: *** $DV_HOME/bin/backup_export.sh -pkgfile \"$BACKUPFILENAME\" $ENCRYPT -server \"$HOST\" -port \"$WSPORT\" -user \"$USER\" -password \"********\" -domain \"$DOMAIN\" -includeStatistics ***"
	   "$DV_HOME/bin/backup_export.sh" -pkgfile "$BACKUPFILENAME" $ENCRYPT -server "$HOST" -port "$WSPORT" -user "$USER" -password "$USER_PASSWORD" -domain "$DOMAIN" -includeStatistics
	   ERROR=$?
	# Execute with the encryption password DV 8.x
	else
	   echo "$S: *** $DV_HOME/bin/backup_export.sh -pkgfile $BACKUPFILENAME $ENCRYPT -server $HOST -port \"$WSPORT\" -user $USER -password \"********\" -domain $DOMAIN -includeStatistics -encryptionPassword \"********\" ***"
	   "$DV_HOME/bin/backup_export.sh" -pkgfile "$BACKUPFILENAME" $ENCRYPT -server "$HOST" -port "$WSPORT" -user "$USER" -password "$USER_PASSWORD" -domain "$DOMAIN" -includeStatistics -encryptionPassword "$ENCRYPTION_PASSWORD"
	   ERROR=$?
	fi
	if [ $ERROR -ne 0 ] ; then
		echo "$S: backup_export failed.  Aborting script. Error code: $ERROR";
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $ERROR;
	fi
	echo "$S: *** Backup created with status=SUCCESS ***"
	echo ""
fi


################################
# PRINT CAR FILE INFO/CONTENTS
################################
if [[ ("$PRIVS_ONLY" == "false" ) && ("$PRINT_OPTION" == "Y") ]]; then
	echo "$S: --------------------------------------------------------------------"
	echo "$S: *** PRINT CAR file INFO and CONTENTS ***"
	echo "$S: --------------------------------------------------------------------"
	# Execute without the encryption password DV 7.x
	if [ "$ENCRYPTION_PASSWORD" == "" ]; then
		echo "$S: *** \"$DV_HOME/bin/pkg_import.sh\" -pkgfile \"$PKGFILE\" $ENCRYPT -verbose -printinfo -printcontents -server \"$HOST\" -port $WSPORT -user \"$USER\" -password \"********\" -domain \"$DOMAIN\" > \"$ARCHIVE_RESULT_FILE\" ***"
		"$DV_HOME/bin/pkg_import.sh" -pkgfile "$PKGFILE" $ENCRYPT -verbose -printinfo -printcontents -server "$HOST" -port $WSPORT -user "$USER" -password "$USER_PASSWORD" -domain "$DOMAIN" > "$ARCHIVE_RESULT_FILE"
		ERROR=$?
	# Execute with the encryption password DV 8.x
	else
		echo "$S: *** \"$DV_HOME/bin/pkg_import.sh\" -pkgfile \"$PKGFILE\" $ENCRYPT -verbose -printinfo -printcontents -server \"$HOST\" -port $WSPORT -user \"$USER\" -password \"********\" -domain \"$DOMAIN\" -encryptionPassword \"********\" > \"$ARCHIVE_RESULT_FILE\" ***"
		"$DV_HOME/bin/pkg_import.sh" -pkgfile "$PKGFILE" $ENCRYPT -verbose -printinfo -printcontents -server "$HOST" -port $WSPORT -user "$USER" -password "$USER_PASSWORD" -domain "$DOMAIN" -encryptionPassword "$ENCRYPTION_PASSWORD" > "$ARCHIVE_RESULT_FILE"
		ERROR=$?
	fi
	if [ $ERROR -ne 0 ] ; then
		echo "$S: pkg_import print info and contents failed.  Aborting script. Error code: $ERROR";
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $ERROR;
	fi
		
	ContentsFound="0"
	LineCount="0"
	Done="0"
	while IFS= read -r Line
	do
		if echo "$Line" | grep -q "Contents:"; then 
			ContentsFound="1"; 
		fi
		if echo "$Line" | grep -q "Importing file"; then 
			Line=`echo $Line | sed 's/Importing/Printing/'`
		fi
		if echo "$Line" | grep -q "Done importing"; then
			Line=`echo $Line | sed 's/importing/printing/'`
			Done="1"
			ContentsFound="0"; 
			PrintLine="0"
		fi
		if echo "$Line" | grep -q "Referenced (external):"; then 
			Done="1";
			ContentsFound="0"; 
			PrintLine="0"
		fi
		if [ $ContentsFound -eq 1 ]; then
			if [ $LineCount -eq 0 ]; then
				echo "*************************************************************************************************"
				echo "*************************************************************************************************"
				echo "$Line"
			else
				echo "${LineCount}:${Line}"
			fi
			LineCount=$((LineCount+1))
		elif [ $Done -eq 1 ]; then
			echo "*************************************************************************************************"
			echo "*************************************************************************************************"
			echo "$Line"
		else
			echo "$Line"
		fi
	done < "$ARCHIVE_RESULT_FILE"
	echo "$S: *** Package file printed with status=SUCCESS ***"
	echo ""
fi


################################
# BEGIN VALIDATE CAR FILE CONTENTS
################################
if [[ ("$PRIVS_ONLY" == "false" ) && ("$VALIDATE_DEPLOYMENT_DATABASE" != "") && ("$PRINT_ONLY" == "N") ]]; then
	DV_PROCEDURE="$VALIDATE_DEPLOYMENT_URL"
	echo "$S: --------------------------------------------------------------------"
	echo "$S: *** Validating Deployment Content. ***"
	echo "$S: --------------------------------------------------------------------"
	
	# Unzip the package .car file into the temp zip directory
	if [ -f "$PKGFILE" ]; then
		unzip -o -q "$PKGFILE" -d "$TMPDIR"
	else
		ERROR="1"
		echo "$S: ERROR: The package .car file does not exist.  PKGFILE=\"$PKGFILE\"  Aborting script. Error code: $ERROR";
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $ERROR;
	fi
		
	# Copy the unzipped contents.xml to the target directory and file for reading by the validate procedure.
	if [ -f "$TMPDIR/contents.xml" ]; then
		cp "$TMPDIR/contents.xml" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		ERROR=$?
		if [ $ERROR -ne 0 ] ; then
			echo "$S: $DV_PROCEDURE failed.  Aborting script. Error code: $ERROR";
			FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
			CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
			exit $ERROR;
		fi
	else
		ERROR="1"
		echo "$S: ERROR: The unzipped package .car file \"contents.xml\" file does not exist for the extracted PKGFILE=\"$PKGFILE\"  Aborting script. Error code: $ERROR";
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $ERROR;
	fi

	# Copy the unzipped metadata.xml to the target directory and file for reading by the validate procedure.
	if [ -f "$TMPDIR/metadata.xml" ]; then
		cp "$TMPDIR/metadata.xml" "$VALIDATE_DEPLOYMENT_METADATA_PATH"
		ERROR=$?
		if [ $ERROR -ne 0 ] ; then
			echo "$S: $DV_PROCEDURE failed.  Aborting script. Error code: $ERROR";
			FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
			CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
			exit $ERROR;
		fi
	else
		ERROR="1"
		echo "$S: ERROR: The unzipped package .car file \"metadata.xml\" file does not exist for the extracted PKGFILE=\"$PKGFILE\"  Aborting script. Error code: $ERROR";
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $ERROR;
	fi

	# Validate the car file metadata
	echo "$S: *** \"$JDBC_SAMPLE_EXEC\" \"$VALIDATE_DEPLOYMENT_DATABASE\" \"$HOST\" \"$DBPORT\" \"$USER\" \"********\" \"$DOMAIN\" \"SELECT * FROM $VALIDATE_DEPLOYMENT_URL('$DEBUG', '$INPUT1', '$PKGNAME', '$DEPLOYMENT_DATE_BEG', '$HOST', '$WSPORT', '$VALIDATE_DEPLOYMENT_CONTENTS_PATH', '$VALIDATE_DEPLOYMENT_METADATA_PATH', '$VALIDATE_DV_TABLE_PATH', '$VALIDATE_DV_PROCEDURE_PATH')\" > \"$JDBC_RESULT_FILE\" ***"
	"$JDBC_SAMPLE_EXEC" "$VALIDATE_DEPLOYMENT_DATABASE" "$HOST" "$DBPORT" "$USER" "$USER_PASSWORD" "$DOMAIN" "SELECT * FROM $VALIDATE_DEPLOYMENT_URL('$DEBUG', '$INPUT1', '$PKGNAME', '$DEPLOYMENT_DATE_BEG', '$HOST', '$WSPORT', '$VALIDATE_DEPLOYMENT_CONTENTS_PATH', '$VALIDATE_DEPLOYMENT_METADATA_PATH', '$VALIDATE_DV_TABLE_PATH', '$VALIDATE_DV_PROCEDURE_PATH')" > "$JDBC_RESULT_FILE"
	ERROR=$?
	
	if [ $ERROR -ne 0 ] ; then
		echo "$S: $DV_PROCEDURE failed.  Aborting script. Error code: $ERROR";
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $ERROR;
	fi

	# Check for SUCCESS result
	GetDVProcedureResults "col\[1]=SUCCESS" "$JDBC_RESULT_FILE" "$JDBC_RESULT_FILE2" "$QUIET" "false" "$S"
	RESULT=$?
	if [ $RESULT -gt 1 ] ; then 
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $RESULT;
	fi
	if [ $RESULT -eq 0 ] ; then 
		# Check for WARNING result
		GetDVProcedureResults "col\[1]=WARNING" "$JDBC_RESULT_FILE" "$JDBC_RESULT_FILE2" "$QUIET" "$PRINT_WARNING" "$S"
		RESULT=$?
		if [ $RESULT -gt 1 ] ; then 
			FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
			CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
			exit $RESULT;
		fi
		if [ $RESULT -eq 0 ] ; then 
			echo "$S: *** FAILURE: $DV_PROCEDURE did not return with a \"SUCCESS\" or \"WARNING\" status. ***"
			FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
			CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
			exit 1;
		fi
		WARNING="1"
		echo "$S: *** WARNING: REVIEW LOG FILE \"$VALIDATE_METADATA_LOG\""
		echo "$S: *** $DV_PROCEDURE completed with status=WARNING ***"
		echo

		# Copy the JDBC_RESULTS_FILE to the Validate metadata log file
		if [ -f "$JDBC_RESULT_FILE" ]; then
			cp "$JDBC_RESULT_FILE" "$VALIDATE_METADATA_LOG"
		fi
		if [ "$WARNING_OUTPUT" != "" ]; then
			WARNING_OUTPUT="${WARNING_OUTPUT}\r\n    REVIEW LOG FILE \"$VALIDATE_METADATA_LOG\""
		else
			WARNING_OUTPUT="WARNING:\r\n    REVIEW LOG FILE \"$VALIDATE_METADATA_LOG\""
		fi
	else
		echo "$S: *** $DV_PROCEDURE completed with status=SUCCESS ***"
		echo
	fi
fi

################################
# BEGIN CAR FILE IMPORT
################################
if [[ ("$PRIVS_ONLY" == "false" ) && ("$PRINT_ONLY" == "N") ]]; then
	echo "$S: --------------------------------------------------------------------"
	echo "$S: *** Importing CAR file into target server $HOST:$WSPORT ***"
	echo "$S: --------------------------------------------------------------------"
	
	# Execute without the encryption password DV 7.x
	if [ "$ENCRYPTION_PASSWORD" == "" ]; then
		if [ "$OPTFILE" != "" ]; then
			echo "$S: *** \"$DV_HOME/bin/pkg_import.sh\" -pkgfile \"$PKGFILE\" -optfile \"$OPTFILE\" $ENCRYPT -server \"$HOST\" -port $WSPORT -user \"$USER\" -password \"********\" -domain \"$DOMAIN\" > \"$ARCHIVE_RESULT_FILE\" ***"
			"$DV_HOME/bin/pkg_import.sh" -pkgfile "$PKGFILE" -optfile "$OPTFILE" $ENCRYPT -server "$HOST" -port $WSPORT -user "$USER" -password "$USER_PASSWORD" -domain "$DOMAIN" > "$ARCHIVE_RESULT_FILE"
			ERROR=$?
		else
			echo "$S: *** \"$DV_HOME/bin/pkg_import.sh\" -pkgfile \"$PKGFILE\" $ENCRYPT -server \"$HOST\" -port $WSPORT -user \"$USER\" -password \"********\" -domain \"$DOMAIN\" > \"$ARCHIVE_RESULT_FILE\" ***"
			"$DV_HOME/bin/pkg_import.sh" -pkgfile "$PKGFILE" $ENCRYPT -server "$HOST" -port $WSPORT -user "$USER" -password "$USER_PASSWORD" -domain "$DOMAIN" > "$ARCHIVE_RESULT_FILE"
			ERROR=$?
		fi
	# Execute with the encryption password DV 8.x
	else
		if [ "$OPTFILE" != "" ]; then
			echo "$S: *** \"$DV_HOME/bin/pkg_import.sh\" -pkgfile \"$PKGFILE\" -optfile \"$OPTFILE\" $ENCRYPT -server \"$HOST\" -port $WSPORT -user \"$USER\" -password \"********\" -domain \"$DOMAIN\" -encryptionPassword \"********\" > \"$ARCHIVE_RESULT_FILE\" ***"
			"$DV_HOME/bin/pkg_import.sh" -pkgfile "$PKGFILE" -optfile "$OPTFILE" $ENCRYPT -server "$HOST" -port $WSPORT -user "$USER" -password "$USER_PASSWORD" -domain "$DOMAIN" -encryptionPassword "$ENCRYPTION_PASSWORD" > "$ARCHIVE_RESULT_FILE"
			ERROR=$?
		else
			echo "$S: *** \"$DV_HOME/bin/pkg_import.sh\" -pkgfile \"$PKGFILE\" $ENCRYPT -server \"$HOST\" -port $WSPORT -user \"$USER\" -password \"********\" -domain \"$DOMAIN\" -encryptionPassword \"********\" > \"$ARCHIVE_RESULT_FILE\" ***"
			"$DV_HOME/bin/pkg_import.sh" -pkgfile "$PKGFILE" $ENCRYPT -server "$HOST" -port $WSPORT -user "$USER" -password "$USER_PASSWORD" -domain "$DOMAIN" -encryptionPassword "$ENCRYPTION_PASSWORD" > "$ARCHIVE_RESULT_FILE"
			ERROR=$?
		fi
	fi
	if [ $ERROR -ne 0 ] ; then
		echo "$S: pkg_import print info and contents failed.  Aborting script. Error code: $ERROR";
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $ERROR;
	fi

	# Process the pkg_import output and reduce the noise:
	while IFS= read -r Line
	do
	  printLine="1"
	  part1="0"
	  part2="0"
	  part3="0"
	  part4="0"
	  if  echo "$Line" | grep -q "File \"files"; then part1=1; fi
	  if  echo "$Line" | grep -q "Cannot set an attribute"; then part2=1; fi
	  if  echo "$Line" | grep -q "because the resource was not part of the import"; then part3=1; fi
	  if  echo "$Line" | grep -q "because the resource does not exist"; then part4=1; fi
	  if [[ ($part1 -eq 1) || (($part2 -eq 1) && (($part3 -eq 1) || ($part4 -eq 1))) ]]; then
		printLine="0"
	  fi
	  if [ $printLine -eq 1 ]; then
		echo "$Line" | xargs
	  fi
	done < "$ARCHIVE_RESULT_FILE"
	
	echo "$S: *** Package file imported with status=SUCCESS ***"
	echo ""
fi


################################
# STRATEGY 1:
#
# BEGIN RESOURCE PRIVILEGES
#   and RESOURCE OWNERSHIP
################################
if [[ ("$STRATEGY1_RESOURCE_PRIVILEGE_DATABASE" != "") && ("$PRINT_ONLY" == "N") ]]; then
	DV_PROCEDURE="$STRATEGY1_RESOURCE_PRIVILEGE_URL"
	echo "$S: --------------------------------------------------------------------"
	echo "$S: *** STRATEGY 1 ***"
	echo "$S: *** Resetting privileges and ownership on specified resources. ***"
	echo "$S: --------------------------------------------------------------------"
	echo "$S: *** \"$JDBC_SAMPLE_EXEC\" \"$STRATEGY1_RESOURCE_PRIVILEGE_DATABASE\" \"$HOST\" \"$DBPORT\" \"$USER\" \"********\" \"$DOMAIN\" \"SELECT * FROM $STRATEGY1_RESOURCE_PRIVILEGE_URL('$PRIVILEGE_DATASOURCE', 1, '$PRIVILEGE_ENVIRONMENT', '$PRIVILEGE_ORGANIZATION', '$PRIVILEGE_PROJECT', '$PRIVILEGE_SUBPROJECT', '$PRIVILEGE_SHEET_NAME', '$PRIVILEGE_RESOURCE_PATH', '$PRIVILEGE_RESOURCE_TYPE', '$PRIVILEGE_GROUP_NAME', '$PRIVILEGE_GROUP_TYPE', '$PRIVILEGE_GROUP_DOMAIN', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', '$PRIVILEGE_BYPASS_ERRORS')\" > \"$JDBC_RESULT_FILE\" ***"
	"$JDBC_SAMPLE_EXEC" "$STRATEGY1_RESOURCE_PRIVILEGE_DATABASE" "$HOST" "$DBPORT" "$USER" "$USER_PASSWORD" "$DOMAIN" "SELECT * FROM $STRATEGY1_RESOURCE_PRIVILEGE_URL('$PRIVILEGE_DATASOURCE', 1, '$PRIVILEGE_ENVIRONMENT', '$PRIVILEGE_ORGANIZATION', '$PRIVILEGE_PROJECT', '$PRIVILEGE_SUBPROJECT', '$PRIVILEGE_SHEET_NAME', '$PRIVILEGE_RESOURCE_PATH', '$PRIVILEGE_RESOURCE_TYPE', '$PRIVILEGE_GROUP_NAME', '$PRIVILEGE_GROUP_TYPE', '$PRIVILEGE_GROUP_DOMAIN', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', '$PRIVILEGE_BYPASS_ERRORS')" > "$JDBC_RESULT_FILE"
	ERROR=$?
	if [ $ERROR -ne 0 ] ; then
		echo "$S: $DV_PROCEDURE failed.  Aborting script. Error code: $ERROR";
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $ERROR;
	fi

	# Check for SUCCESS result
	GetDVProcedureResults "col\[1]=SUCCESS" "$JDBC_RESULT_FILE" "$JDBC_RESULT_FILE2" "$QUIET" "false" "$S"
	RESULT=$?
	if [ $RESULT -gt 1 ] ; then 
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $RESULT;
	fi
	if [ $RESULT -eq 0 ] ; then 
		# Check for WARNING result
		GetDVProcedureResults "col\[1]=WARNING" "$JDBC_RESULT_FILE" "$JDBC_RESULT_FILE2" "$QUIET" "$PRINT_WARNING" "$S"
		RESULT=$?
		if [ $RESULT -gt 1 ] ; then 
			FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
			CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
			exit $RESULT;
		fi
		if [ $RESULT -eq 0 ] ; then 
			echo "$S: *** FAILURE: $DV_PROCEDURE did not return with a \"SUCCESS\" or \"WARNING\" status. ***"
			FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
			CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
			exit 1;
		fi
		WARNING="1"
		echo "$S: *** WARNING: REVIEW LOG FILE \"$STRATEGY1_RESOURCE_PRIVILEGE_LOG\""
		echo "$S: *** $DV_PROCEDURE completed with status=WARNING ***"
		echo

		# Copy the JDBC_RESULTS_FILE to the Stategy1 privilege log file
		if [ -f "$JDBC_RESULT_FILE" ]; then
			cp "$JDBC_RESULT_FILE" "$STRATEGY1_RESOURCE_PRIVILEGE_LOG"
		fi
		if [ "$WARNING_OUTPUT" != "" ]; then
			WARNING_OUTPUT="${WARNING_OUTPUT}\r\n    REVIEW LOG FILE \"$STRATEGY1_RESOURCE_PRIVILEGE_LOG\""
		else
			WARNING_OUTPUT="WARNING:\r\n    REVIEW LOG FILE \"$STRATEGY1_RESOURCE_PRIVILEGE_LOG\""
		fi
	else
		if [ -f "$STRATEGY1_RESOURCE_PRIVILEGE_LOG" ]; then
			rm -rf "$STRATEGY1_RESOURCE_PRIVILEGE_LOG"
		fi
		echo "$S: *** $DV_PROCEDURE completed with status=SUCCESS ***"
		echo
	fi
fi


################################
# STRATEGY 2:
#
# BEGIN IMPORT RESOURCE OWNERSHIP
################################
if [[ ("$STRATEGY2_RESOURCE_OWNERSHIP_DATABASE" != "") && ("$PRINT_ONLY" == "N") ]]; then
	DV_PROCEDURE="$STRATEGY2_RESOURCE_OWNERSHIP_URL"
	echo "$S: --------------------------------------------------------------------"
	echo "$S: *** STRATEGY 2 ***"
	echo "$S: *** Resetting ownership of objects. ***"
	echo "$S: --------------------------------------------------------------------"
	echo "$S: *** \"$JDBC_SAMPLE_EXEC\" \"$STRATEGY2_RESOURCE_OWNERSHIP_DATABASE\" \"$HOST\" \"$DBPORT\" \"$USER\" \"********\" \"$DOMAIN\" \"SELECT * FROM $STRATEGY2_RESOURCE_OWNERSHIP_URL('$DEBUG', '$STRATEGY2_RESOURCE_OWNERSHIP_FILE')\" > \"$JDBC_RESULT_FILE\" ***"
	"$JDBC_SAMPLE_EXEC" "$STRATEGY2_RESOURCE_OWNERSHIP_DATABASE" "$HOST" "$DBPORT" "$USER" "$USER_PASSWORD" "$DOMAIN" "SELECT * FROM $STRATEGY2_RESOURCE_OWNERSHIP_URL('$DEBUG', '$STRATEGY2_RESOURCE_OWNERSHIP_FILE')" > "$JDBC_RESULT_FILE"
	ERROR=$?
	if [ $ERROR -ne 0 ] ; then
		echo "$S: $DV_PROCEDURE failed.  Aborting script. Error code: $ERROR";
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $ERROR;
	fi

	# Check for SUCCESS result
	GetDVProcedureResults "col\[1]=SUCCESS" "$JDBC_RESULT_FILE" "$JDBC_RESULT_FILE2" "$QUIET" "false" "$S"
	RESULT=$?
	if [ $RESULT -gt 1 ] ; then 
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $RESULT;
	fi
	if [ $RESULT -eq 0 ] ; then 
		# Check for WARNING result
		GetDVProcedureResults "col\[1]=WARNING" "$JDBC_RESULT_FILE" "$JDBC_RESULT_FILE2" "$QUIET" "$PRINT_WARNING" "$S"
		RESULT=$?
		if [ $RESULT -gt 1 ] ; then 
			FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
			CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
			exit $RESULT;
		fi
		if [ $RESULT -eq 0 ] ; then 
			echo "$S: *** FAILURE: $DV_PROCEDURE did not return with a \"SUCCESS\" or \"WARNING\" status. ***"
			FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
			CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
			exit 1;
		fi
		WARNING="1"
		echo "$S: *** WARNING: REVIEW LOG FILE \"$STRATEGY2_RESOURCE_OWNERSHIP_LOG\""
		echo "$S: *** $DV_PROCEDURE completed with status=WARNING ***"
		echo

		# Copy the JDBC_RESULTS_FILE to the Stategy2 ownership log file
		if [ -f "$JDBC_RESULT_FILE" ]; then
			cp "$JDBC_RESULT_FILE" "$STRATEGY2_RESOURCE_OWNERSHIP_LOG"
		fi
		if [ "$WARNING_OUTPUT" != "" ]; then
			WARNING_OUTPUT="${WARNING_OUTPUT}\r\n    REVIEW LOG FILE \"$STRATEGY2_RESOURCE_OWNERSHIP_LOG\""
		else
			WARNING_OUTPUT="WARNING:\r\n    REVIEW LOG FILE \"$STRATEGY2_RESOURCE_OWNERSHIP_LOG\""
		fi
	else
		if [ -f "$STRATEGY2_RESOURCE_OWNERSHIP_LOG" ]; then
			rm -rf "$STRATEGY2_RESOURCE_OWNERSHIP_LOG"
		fi
		echo "$S: *** $DV_PROCEDURE completed with status=SUCCESS ***"
		echo
	fi
fi


################################
# STRATEGY 2:
#
# BEGIN RESOURCE PRIVILEGES
################################
if [[ ("$STRATEGY2_RESOURCE_PRIVILEGE_DATABASE" != "") && ("$PRINT_ONLY" == "N") ]]; then
	DV_PROCEDURE="$STRATEGY2_RESOURCE_PRIVILEGE_URL"
	echo "$S: --------------------------------------------------------------------"
	echo "$S: *** STRATEGY 2 ***"
	echo "$S: *** Resetting privileges on all resources. ***"
	echo "$S: --------------------------------------------------------------------"
	echo "$S: *** \"$JDBC_SAMPLE_EXEC\" \"$STRATEGY2_RESOURCE_PRIVILEGE_DATABASE\" \"$HOST\" \"$DBPORT\" \"$USER\" \"********\" \"$DOMAIN\" \"SELECT * FROM $STRATEGY2_RESOURCE_PRIVILEGE_URL('$DEBUG', $RECURSE_CHILD_RESOURCES, $RECURSE_DEPENDENCIES, $RECURSE_DEPENDENTS, '$STRATEGY2_RESOURCE_PRIVILEGE_FILE', 'SET_EXACTLY')\" > \"$JDBC_RESULT_FILE\" ***"
	"$JDBC_SAMPLE_EXEC" "$STRATEGY2_RESOURCE_PRIVILEGE_DATABASE" "$HOST" "$DBPORT" "$USER" "$USER_PASSWORD" "$DOMAIN" "SELECT * FROM $STRATEGY2_RESOURCE_PRIVILEGE_URL('$DEBUG', $RECURSE_CHILD_RESOURCES, $RECURSE_DEPENDENCIES, $RECURSE_DEPENDENTS, '$STRATEGY2_RESOURCE_PRIVILEGE_FILE', 'SET_EXACTLY')" > "$JDBC_RESULT_FILE"
	ERROR=$?
	if [ $ERROR -ne 0 ] ; then
		echo "$S: $DV_PROCEDURE failed.  Aborting script. Error code: $ERROR";
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $ERROR;
	fi

	# Check for SUCCESS result
	GetDVProcedureResults "col\[1]=SUCCESS" "$JDBC_RESULT_FILE" "$JDBC_RESULT_FILE2" "$QUIET" "false" "$S"
	RESULT=$?
	if [ $RESULT -gt 1 ] ; then 
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $RESULT;
	fi
	if [ $RESULT -eq 0 ] ; then 
		# Check for WARNING result
		GetDVProcedureResults "col\[1]=WARNING" "$JDBC_RESULT_FILE" "$JDBC_RESULT_FILE2" "$QUIET" "$PRINT_WARNING" "$S"
		RESULT=$?
		if [ $RESULT -gt 1 ] ; then 
			FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
			CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
			exit $RESULT;
		fi
		if [ $RESULT -eq 0 ] ; then 
			echo "$S: *** FAILURE: $DV_PROCEDURE did not return with a \"SUCCESS\" or \"WARNING\" status. ***"
			FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
			CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
			exit 1;
		fi
		WARNING="1"
		echo "$S: *** WARNING: REVIEW LOG FILE \"$STRATEGY2_RESOURCE_PRIVILEGE_LOG\""
		echo "$S: *** $DV_PROCEDURE completed with status=WARNING ***"
		echo

		# Copy the JDBC_RESULTS_FILE to the Stategy2 privilege log file
		if [ -f "$JDBC_RESULT_FILE" ]; then
			cp "$JDBC_RESULT_FILE" "$STRATEGY2_RESOURCE_PRIVILEGE_LOG"
		fi
		if [ "$WARNING_OUTPUT" != "" ]; then
			WARNING_OUTPUT="${WARNING_OUTPUT}\r\n    REVIEW LOG FILE \"$STRATEGY2_RESOURCE_PRIVILEGE_LOG\""
		else
			WARNING_OUTPUT="WARNING:\r\n    REVIEW LOG FILE \"$STRATEGY2_RESOURCE_PRIVILEGE_LOG\""
		fi
	else
		if [ -f "$STRATEGY2_RESOURCE_PRIVILEGE_LOG" ]; then
			rm -rf "$STRATEGY2_RESOURCE_PRIVILEGE_LOG"
		fi
		echo "$S: *** $DV_PROCEDURE completed with status=SUCCESS ***"
		echo
	fi
fi


################################
# BEGIN runAfterImport
################################
if [[ ("$PRIVS_ONLY" == "false" ) && ("$RUN_AFTER_IMPORT_DATABASE" != "") && ("$PRINT_ONLY" == "N") ]]; then
	DV_PROCEDURE="$RUN_AFTER_IMPORT_URL"
	echo "$S: --------------------------------------------------------------------"
	echo "$S: *** Calling \"runAfterImport\" for any post-migration steps. ***"
	echo "$S: --------------------------------------------------------------------"
	echo "$S: *** \"$JDBC_SAMPLE_EXEC\" \"$RUN_AFTER_IMPORT_DATABASE\" \"$HOST\" \"$DBPORT\" \"$USER\" \"********\" \"$DOMAIN\" \"SELECT * $FROM RUN_AFTER_IMPORT_URL('$DEBUG', '$INPUT1', '$INPUT2', '$INPUT3')\" > \"$JDBC_RESULT_FILE\" ***"
	"$JDBC_SAMPLE_EXEC" "$RUN_AFTER_IMPORT_DATABASE" "$HOST" "$DBPORT" "$USER" "$USER_PASSWORD" "$DOMAIN" "SELECT * FROM $RUN_AFTER_IMPORT_URL('$DEBUG', '$INPUT1', '$INPUT2', '$INPUT3')" > "$JDBC_RESULT_FILE"
	ERROR=$?
	if [ $ERROR -ne 0 ] ; then
		echo "$S: $DV_PROCEDURE failed.  Aborting script. Error code: $ERROR";
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $ERROR;
	fi

	# Check for SUCCESS result
	GetDVProcedureResults "col\[1]=SUCCESS" "$JDBC_RESULT_FILE" "$JDBC_RESULT_FILE2" "$QUIET" "false" "$S"
	RESULT=$?
	if [ $RESULT -gt 1 ] ; then 
		FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
		CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
		exit $RESULT;
	fi
	if [ $RESULT -eq 0 ] ; then 
		# Check for WARNING result
		GetDVProcedureResults "col\[1]=WARNING" "$JDBC_RESULT_FILE" "$JDBC_RESULT_FILE2" "$QUIET" "$PRINT_WARNING" "$S"
		RESULT=$?
		if [ $RESULT -gt 1 ] ; then 
			FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
			CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
			exit $RESULT;
		fi
		if [ $RESULT -eq 0 ] ; then 
			echo "$S: *** FAILURE: $DV_PROCEDURE did not return with a \"SUCCESS\" or \"WARNING\" status. ***"
			FailureMessage "$DEPLOYMENT_DATE_BEG" "$JDBC_RESULT_FILE" "$EXCEPTION_LOG"
			CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"
			exit 1;
		fi
		WARNING="1"
		echo "$S: *** WARNING: REVIEW LOG FILE \"$RUN_AFTER_IMPORT_LOG\""
		echo "$S: *** $DV_PROCEDURE completed with status=WARNING ***"
		echo

		# Copy the JDBC_RESULTS_FILE to the run after import log file
		if [ -f "$JDBC_RESULT_FILE" ]; then
			cp "$JDBC_RESULT_FILE" "$RUN_AFTER_IMPORT_LOG"
		fi
		if [ "$WARNING_OUTPUT" != "" ]; then
			WARNING_OUTPUT="${WARNING_OUTPUT}\r\n    REVIEW LOG FILE \"$RUN_AFTER_IMPORT_LOG\""
		else
			WARNING_OUTPUT="WARNING:\r\n    REVIEW LOG FILE \"$RUN_AFTER_IMPORT_LOG\""
		fi
	else
		if [ -f "$RUN_AFTER_IMPORT_LOG" ]; then
			rm -rf "$RUN_AFTER_IMPORT_LOG"
		fi
		echo "$S: *** $DV_PROCEDURE completed with status=SUCCESS ***"
		echo
	fi
fi


################################
# COMPLETE
################################
CleanUpTmpFiles "$S" "$TMPDIR" "$TMPDIR" "$VALIDATE_DEPLOYMENT_METADATA_PATH" "$VALIDATE_DEPLOYMENT_CONTENTS_PATH"

# Calculate and format the start and end time difference
DEPLOYMENT_DATE_END_SECONDS=$(date +%s);
DT=`date +%Y-%m-%d`
TM=`date +%H:%M:%S`
# Replace space with 0
DT=${DT// /0}
TM=${TM// /0}
DEPLOYMENT_DATE_END="$DT $TM"
DIFF=$((DEPLOYMENT_DATE_END_SECONDS-DEPLOYMENT_DATE_BEG_SECONDS))
HOUR=`echo $((DIFF/3600)) | awk '{printf "%02d\n", $0;}'`
MIN=`echo $((DIFF/60)) | awk '{printf "%02d\n", $0;}'`
SEC=`echo $((DIFF%60)) | awk '{printf "%02d\n", $0;}'`
# Print out the deployment end date and start date.
echo ""
echo "=============================================================="
echo "DEPLOYMENT_DATE_BEG=$DEPLOYMENT_DATE_BEG"
echo "DEPLOYMENT_DATE_END=$DEPLOYMENT_DATE_END"
echo "DURATION=$HOUR:$MIN:$SEC"
echo "=============================================================="
echo ""
if [ "$WARNING" == "0" ]; then
   echo "$S: **************************************************************"
   echo "$S: ***  SUCCESS: All migration steps successfully completed.  ***"
   echo "$S: **************************************************************"
else
   echo "$S: ****************************************************************************"
   echo "$S: ***  WARNING: All migration steps successfully completed with WARNING.   ***"
   echo "$S: ****************************************************************************"
   echo -e "$S: $WARNING_OUTPUT"
fi
echo ""

exit 0
#****************************************************************
# END: deployProject.sh
#****************************************************************
