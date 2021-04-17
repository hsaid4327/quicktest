#!/bin/sh
######################################################################
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
######################################################################
#
# Modify the DV_HOME
DV_HOME="/Users/TDV7.0.8"
# Modify \jre to \jdk for TDV 8.2 and higher
JAVA_HOME="$DV_HOME/jre"

# Script Home Directory
SCRIPTDIR=`dirname path`
######################################################################
# DO NOT MODIFY BELOW THIS LINE
# This file is generated and regenerated when certain
# configuration settings are changed.

_CLASSPATH=$CLASSPATH
_JAVA_HOME=$JAVA_HOME

# Setup environment variables required for application
#
APPS_INSTALL_DIR="$DV_HOME/apps/jdbc"
CONF_INSTALL_DIR="$DV_HOME"

# JRE_VM_MODE values "32-bit" or "64-bit". Default "64-bit" if not configured.
JRE_VM_MODE="64-bit"

if [ -z $JAVA_HOME ]; then
  echo "Please configure your JAVA_HOME setting in this script"
  exit 0
fi


# Functions
#
configKeystoreSettings() {
  . "$CONF_INSTALL_DIR/bin/init_server_keystore_files.sh"
}

restoreEnvironment() {
   # Restore variables
   CLASSPATH=$_CLASSPATH
   export CLASSPATH
   JAVA_HOME=$_JAVA_HOME
   export JAVA_HOME
}


# Program options
#
CLASSPATH="$SCRIPTDIR"
# For 8.x
if [ -f "$APPS_INSTALL_DIR/lib/bcprov-jdk15on-1.62.jar" ]; then
    CLASSPATH="$CLASSPATH:$APPS_INSTALL_DIR/lib/bcprov-jdk15on-1.62.jar"
fi
# For 8.x
if [ -f "$APPS_INSTALL_DIR/lib/bcpkix-jdk15on-1.62.jar" ]; then
    CLASSPATH="$CLASSPATH:$APPS_INSTALL_DIR/lib/bcpkix-jdk15on-1.62.jar"
fi
# Standard classpath
CLASSPATH="$CLASSPATH:$APPS_INSTALL_DIR/lib/csjdbc.jar"

JAVA_OPTS=""
# For 8.x
if [ -f "$APPS_INSTALL_DIR/java.security" ]; then
    JAVA_OPTS="-Djava.security.properties=$APPS_INSTALL_DIR/java.security"
fi

# ensure 64-bit OS uses 64-bit JVM mode
#
# solaris and hpux do not default to 64-bit JVM mode with 64-bit JVMs
# other platforms do
#
OS_NAME=`uname`
case "$OS_NAME" in
  "SunOS"|"HP-UX") if [ "$JRE_VM_MODE" = "64-bit" ]; then
                     VM_ARGS="-d64 $VM_ARGS"
                     echo "JVM using -d64 flag"
                   fi
                   ;;
esac

configKeystoreSettings;

JAVA_OPTS="$VM_ARGS $JAVA_OPTS"


# Program arguments
#
DATA_SOURCE_NAME=$1
HOST_NAME=$2
PORT=$3
USER=$4
PASSWORD=$5
DOMAIN_NAME=$6
SQL_QUERY=$7
ENCRYPT_OPTION=

if [ "$8" = "-encrypt" ]; then
  ENCRYPT_OPTION=$8
 
  if [ "$9" = "-fileEncoding" ]; then 
    if [ "${10}" = "" ]; then
      echo "Missing file encoding value for $9 option."
      EXIT_CODE=1
      restoreEnvironment;
      exit $EXIT_CODE
    else
      JAVA_OPTS="$JAVA_OPTS -Dfile.encoding=${10}"
    fi
  fi
elif [ "$8" = "-fileEncoding" ]; then
  if [ "$9" = "" ]; then
    echo "Missing file encoding value for $8 option."
    EXIT_CODE=1
    restoreEnvironment;
    exit $EXIT_CODE
  else
    JAVA_OPTS="$JAVA_OPTS -Dfile.encoding=$9"
  fi
fi


# Display Debug Info.  Uncomment to display
#echo DV_HOME="$DV_HOME"
#echo APPS_INSTALL_DIR="$APPS_INSTALL_DIR"
#echo CONF_INSTALL_DIR="$CONF_INSTALL_DIR"
#echo CLASSPATH="$CLASSPATH"
#echo JAVA_OPTS="$JAVA_OPTS"
#echo exec "\"$JAVA_HOME/bin/java\" $JAVA_OPTS -classpath \"$CLASSPATH\" JdbcSample $DATA_SOURCE_NAME $HOST_NAME $PORT $USER \"********\" $DOMAIN_NAME \"$SQL_QUERY\" $ENCRYPT_OPTION"
#echo

# Run application 
exec "$JAVA_HOME/bin/java" $JAVA_OPTS -classpath "$CLASSPATH" JdbcSample $DATA_SOURCE_NAME $HOST_NAME $PORT $USER $PASSWORD $DOMAIN_NAME "$SQL_QUERY" $ENCRYPT_OPTION
EXIT_CODE=$?

restoreEnvironment;
exit $EXIT_CODE