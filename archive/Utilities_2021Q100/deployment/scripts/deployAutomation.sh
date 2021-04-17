#!/bin/bash
#**************************************************************************
# BEGIN: deployAutomation.sh 
#
# Usage: deployAutomation.sh [-f car-file-path] [-p DEPLOY_USER_PASSWORD] [-e external-id]
#        optional: -f full path to a .car file to deploy.
#                  if -f is NOT provided then this script will search all sub-folders for .car files.
#        optional: -p deployment user password
#                  If -p is NOT provided then this script will use local variable DEPLOY_USER_PASSWORD.
#        optional: -e external id
#                  Comes from a 3rd party deployment tool and is no more than 50 characters.
#
# The purpose of deployAutomation.sh is to automate the deployment of .car
#   files to the target environment where this script is installed.  This
#   script works on the concept of an inbox, where the inbox represents a
#   folder structure.  The folder is a direct representation of the TDV
#   folder structure and how privileges are to be applied in TDV.
# The script will find all .car files in the sub-folder structure from
#   oldest to newest and deploy them in sequence one-at-a-time.  If
#   collision-detection is configured in deployProjects.sh then .car file
#   resources will be checked for timestamp collisions.
# The script will output a one-line log entry in ./logs/Deploy_Automation.log
#   with success or failure of a .car file deployment.
#
# Requirements:
#   This script requires TDV 7.x or 8.x to be installed on the same server as these scripts.
#
# Integration Options:
#   Option 1 - Execute stand-alone.
#   Option 2 - Integrate with /etc/crontab.
#              Refer to "Automation Configuration" section below.
#   Option 3 - Integrate with a 3rd party Deployment tool.
#              The 3rd party tool should be able to invoke batch scripts on the TDV server.
#              If the 3rd party tool can only invoke local scripts then the TDV binaries
#                 must be installed on the 3rd party tool server to satisfy pkg_import.sh requirements.
#
# Assumptions for apply privileges: 
#   Organization Name:  ABCBank     Filter in the privilege spreadsheet. 
#   Project Name:       Finance     Identifies the project in the privilege spreadsheet.
#   SubProject Name:    Accounting  Identifies the sub-project in the privilege spreadsheet.
#
# TDV Folder Structure:
# /services/databases/Finance
#                              /Accounting
#                              /GL
#                              /Taxes
# /services/webservices/Finance
#                              /Accounting
#                              /GL
#                              /Taxes
# /shared/Finance
#               /Application
#                        /Views
#                              /Accounting
#                              /GL
#                              /Taxes
#               /Business
#                        /Business
#                              /Accounting
#                              /GL
#                              /Taxes
#                        /Logical
#                              /Accounting
#                              /GL
#                              /Taxes
#               /Physical
#                        /Formatting
#                        /Metadata
#
# Inbox Folder Structure:
#   Base folder is a share accessible from UNIX and Windows desktop:
#      /opt/tibco/tdv/share
#   Standard deployment scripts structure is added to the share:
#
#      /opt/tibco/tdv/share/config/deployment/carfiles
#
#   The customized path representing TDV project folders and privileges is added:
#      /opt/tibco/tdv/share/config/deployment/carfiles/ABCBank/Finance/Accounting
#
#      Org      Projet  SubProject
#      /ABCBank/Finance
#                      /Accounting
#                      /Taxes
#                      /GL
#                      /Sources
#
# Automation Configuration:
#   For a TDV cluster, this should only be configured on the "primary" node as defined by the customer.
#
#   This script should be invoked by /etc/crontab
#
# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name  command to be executed
#*/15 * *  *  *            /opt/tibco/tdv/share/config/deployment/scripts/deployAutomation.sh -p deploy_user_password -p pswd >> /opt/tibco/tdv/share/config/deployment/scripts/logs/cron_deployment.log
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
#	2020.202	06/11/2020		Mike Tinius			7.0.8 / 8.x		Created new
#
############################################################################################################################
#
#**************************************************************************
# MODIFY THE FOLLOWING VARIABLES.
#**************************************************************************
# Y=debug on.  N=debug off.
debug="N"
# List the files but do not invoke deployProject.sh
listFilesOnly="N"

# Environment Specific Variables
ENV="TST"
DEPLOY_USER="admin"
DEPLOY_DOMAIN="composite"
# The passed in password takes precedence over this setting.  
# If the password is not passed in this value must be set.
DEPLOY_PASSWORD=""
ENCRYPT_PASSWORD="tdv"
DEPLOY_HOST=`hostname`
DEPLOY_PORT="9400"
DEPLOYMENT_DIR="/opt/tibco/tdv/share/config/deployment"
OPTION_FILE="${DEPLOYMENT_DIR}/option_files/options.txt"
CAR_FILE_DIR="${DEPLOYMENT_DIR}/carfiles"
SCRIPTDIR="${DEPLOYMENT_DIR}/scripts"
AUTOMATION_LOG_FILE="$SCRIPTDIR/logs/Deployment_Automation.log"
#**************************************************************************
# DO NOT MODIFY BELOW THIS LINE.
#**************************************************************************
#
#----------------------------
# Assign input parameters
#----------------------------
CAR_FILE_PATH=""
EXTERNAL_ID=""
loopcount=0

while [ ! -z "$1" ]
do
  loopcount=$((loopcount+1));
  if [ "$debug" == "Y" ]; then
    if [ "$1" == "-p" ]; then  
       echo "loopcount=$loopcount  P1=[$1]   P2=[********]";
	else
       echo "loopcount=$loopcount  P1=[$1]   P2=[$2]";
	fi
  fi;
  case "$1" in
	# Mandatory parameters
    -f)
		CAR_FILE_PATH="$2"
		#----------------------------
		# Resolve relative paths
		#----------------------------
		if [ "$CAR_FILE_PATH" != "" ]; then
			absolute="$CAR_FILE_PATH"
			if [ -d "$CAR_FILE_PATH" ]; then 
				absolute=$absolute/.
			fi
			absolute=$(cd "$(dirname -- "$absolute")"; printf %s. "$PWD")
			absolute="${absolute%?}"
			FOLDER_NAME="$absolute/${f##*/}"
			FILE_NAME="$(basename -- $CAR_FILE_PATH)"
			export CAR_FILE_PATH="${FOLDER_NAME}${FILE_NAME}"
		fi
		shift
		;;
    -p)
		DEPLOY_PASSWORD="$2"
		shift
		;;
    -e)
		EXTERNAL_ID="$2"
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
# Change to Script Directory
#----------------------------
# Change directories to the script directory
if [ ! -d "$SCRIPTDIR" ]; then
   echo "ERROR: The directory does not exist [$SCRIPTDIR]"
   exit 1
fi
cd $SCRIPTDIR


#----------------------------
# Create Log File
#----------------------------
if [ ! -d "$SCRIPTDIR/logs" ]; then
   mkdir $SCRIPTDIR/logs
fi
# Create the automation log file with a header if it does not exist
if [ ! -f "$AUTOMATION_LOG_FILE" ]; then
   echo "STATUS: :: FILE_DATE:                          :: COMMAND:" > "$AUTOMATION_LOG_FILE"
fi

# Generate a unique file qualifier
DT=`date +%Y_%m_%d`
TM=`date +%H_%M_%S`
MYDATETIME=${DT}_${TM}
FILE_QUALIFIER="${MYDATETIME}"
FILE_QUALIFIER=`echo $FILE_QUALIFIER1 | sed 's/\./_/g'`
CAR_FILE_LIST="car_file_list_${FILE_QUALIFIER}.txt"

# If the car file path was passed into this script then only deploy that one car file by setting the CAR_FILE_DIR = CAR_FILE_PATH
if [ "$CAR_FILE_PATH" != "" ]; then
   if [ -f $CAR_FILE_PATH ]; then
      CAR_FILE_DIR=$CAR_FILE_PATH
   else
      echo "ERROR: The file does not exist [$CAR_FILE_PATH]"
	  exit 1
   fi
else
   if [ ! -d $CAR_FILE_DIR ]; then
      echo "ERROR: The directory does not exist [$CAR_FILE_DIR]"
	  exit 1
   fi
fi

#----------------------------
# Generate the car file list
#----------------------------
# Search sub-folders to generate the list of .car files and put the in a file to be processed
find $CAR_FILE_DIR -type f -printf '%T@ "%t","%p"\n' | sort -k 1 -n | cut -d' ' -f2- > $CAR_FILE_LIST

#----------------------------
# Loop through the car file list
#----------------------------
# Deploy each .car file in the list
while IFS="," read f1 f2
do
   PKGDATE="${f1%\"}"
   PKGDATE="${PKGDATE#\"}"
   PKGFILE="${f2%\"}"
   PKGFILE="${PKGFILE#\"}"
   PKGNAME=`basename $PKGFILE`
   PARENT="${PKGFILE%/*}"
   # Get the extension
   PKGEXT=`echo "$PKGNAME" | cut -d'.' -f2`
   # Convert extension to lower case
   PKGEXT="${PKGEXT,,}"
   
   SUBPROJECT_NAME=`basename $PARENT`
   GRANDPARENT="${PARENT%/*}"

   PROJECT_NAME=`basename $GRANDPARENT`
   GREATGRANDPARENT="${GRANDPARENT%/*}"

   ORGANIZATION=`basename $GREATGRANDPARENT`

   if [ "$debug" == "Y" ]; then
      echo "-----------------------------------------------------------------------------------------------------------------------------------------------"
      echo "$0: Invoke deployProject.sh"
      echo "-----------------------------------------------------------------------------------------------------------------------------------------------"
      echo "DATE=$PKGDATE"
      echo "PKGFILE=$PKGFILE"
      echo "PKGNAME=$PKGNAME"
      echo "PKGEXT=$PKGEXT"
      echo "EXTERNAL_ID=$EXTERNAL_ID"
      echo "ORGANIZATION=$ORGANIZATION"
      echo "PROJECT_NAME=$PROJECT_NAME"
      echo "SUBPROJECT_NAME=$SUBPROJECT_NAME"
      echo "-----------------------------------------------------------------------------------------------------------------------------------------------"
   fi

   # Add double quotes around the ENCRYPT_PASSWORD value.
   ENCRYPT_COMMAND=-"ep"
   if [ "$ENCRYPT_PASSWORD" == "" ]; then
      ENCRYPT_COMMAND=""
   else
      ENCRYPT_PASSWORD="$ENCRYPT_PASSWORD"
   fi
   
   if [ "$PKGEXT" == "car" ]; then
	   echo ""
	   echo "-----------------------------------------------------------------------------------------------------------------------------------------------"
	   echo   "\"${SCRIPTDIR}/deployProject.sh\" -i \"$PKGFILE\" -o \"$OPTION_FILE\" -h \"$DEPLOY_HOST\" -p $DEPLOY_PORT -u \"$DEPLOY_USER\" -d \"$DEPLOY_DOMAIN\" -up \"********\" $ENCRYPT_COMMAND $ENCRYPT_PASSWORD -print -c -pd EXCEL -pe \"$ENV\" -po \"$ORGANIZATION\" -pp \"$PROJECT_NAME\" -ps \"$SUBPROJECT_NAME\" -inp1 \"$EXTERNAL_ID\""
	   PKGCMD="\"${SCRIPTDIR}/deployProject.sh\" -i \"$PKGFILE\" -o \"$OPTION_FILE\" -h \"$DEPLOY_HOST\" -p $DEPLOY_PORT -u \"$DEPLOY_USER\" -d \"$DEPLOY_DOMAIN\" -up \"********\" $ENCRYPT_COMMAND $ENCRYPT_PASSWORD -print -c -pd EXCEL -pe \"$ENV\" -po \"$ORGANIZATION\" -pp \"$PROJECT_NAME\" -ps \"$SUBPROJECT_NAME\" -inp1 \"$EXTERNAL_ID\""
	   echo "-----------------------------------------------------------------------------------------------------------------------------------------------"
	   
	   #----------------------------
	   # Deploy .CAR File
	   #----------------------------
	   if [ "$listFilesOnly" != "Y" ]; then
		  # Invoke the deployment script
		  "${SCRIPTDIR}/deployProject.sh" -i "$PKGFILE" -o "$OPTION_FILE" -h "$DEPLOY_HOST" -p $DEPLOY_PORT -u "$DEPLOY_USER" -d "$DEPLOY_DOMAIN" -up "$DEPLOY_PASSWORD" $ENCRYPT_COMMAND $ENCRYPT_PASSWORD -print -c -pd EXCEL -pe "$ENV" -po "$ORGANIZATION" -pp "$PROJECT_NAME" -ps "$SUBPROJECT_NAME" -inp1 "$EXTERNAL_ID"
		  ERROR=$?
		  if [ $ERROR -eq 0 ]; then
			 echo "************************************************"
			 echo "* SUCCESS: $PKGNAME REMOVED"
			 echo "************************************************"
			 echo "SUCCESS :: $PKGDATE :: $PKGCMD" >> "$AUTOMATION_LOG_FILE"
			 echo "--------------------------------------" >> "$AUTOMATION_LOG_FILE"
			 rm -rf "$PKGFILE"
			 tail -2 "$AUTOMATION_LOG_FILE"
		  else
			 echo "************************************************"
			 echo "* ERROR: $PKGNAME NOT REMOVED"
			 echo "************************************************"
			 echo "ERROR   :: $PKGDATE :: $PKGCMD" >> "$AUTOMATION_LOG_FILE"
			 echo "--------------------------------------" >> "$AUTOMATION_LOG_FILE"
			 tail -2 "$AUTOMATION_LOG_FILE"
		  fi
	   fi
   else
	   echo ""
	   echo "-----------------------------------------------------------------------------------------------------------------------------------------------"
       echo "Skipping non-car file: $PKGFILE"
	   echo "-----------------------------------------------------------------------------------------------------------------------------------------------"
   fi
done < $CAR_FILE_LIST

#----------------------------
# Remove temp car file list
#----------------------------
rm $CAR_FILE_LIST

#----------------------------
# Exit the script
#----------------------------
exit $ERROR
