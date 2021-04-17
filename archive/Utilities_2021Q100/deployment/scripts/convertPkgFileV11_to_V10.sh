#!/bin/bash
#****************************************************************
# BEGIN: convertPkgFileV11_to_V10.sh
#	return 0 when TDV 7.x version 10 package .car file was found and not converted
#	return 1 when TDV 8.x version 11 package .car file was found and converted
#   return 98 if there was a usage error.
#   retrun 99 if there an execution error.
#
#	Convert a package .car file from TDV 8.x version 11 to 
#	TDV 7.x version 10.  This can be used when migrating car 
#	files from 8.x to 7.x.  This may be required while 
#	performing a server upgrade from version 7.x to 8.x 
#	starting with DEV and slowly upgrading the higher 
#	environments over the course of several weeks.
#
# Usage: convertPkgFileV11_to_V10.sh <CAR_file> [-q]
#    (optional) -q is quiet option.
#****************************************************************
#
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
#----------------------------
# Set the script name
#----------------------------
INDENT="    "
S=${INDENT}$(basename -- "$0")

#----------------------------
# Assign input parameters
#----------------------------
PKGFILE=$1
QUIET=$2

#----------------------------
# Validate Input
#----------------------------
# Check for no input
if [ "$PKGFILE" == "" ] ; then
   echo "${INDENT}Usage: $S CAR_file [-q]"
   exit 98
fi

#----------------------------
# Resolve relative paths for the package file
#----------------------------
absolute=$PKGFILE
if [ -d "$PKGFILE" ]; then absolute=$absolute/.; fi
absolute=$(cd "$(dirname -- "$absolute")"; printf %s. "$PWD")
absolute="${absolute%?}"
PKG_FOLDER="$absolute/${f##*/}"
PKG_NAME="$(basename -- $PKGFILE)"
PKGFILE="${PKG_FOLDER}${PKG_NAME}"

#----------------------------
# Make sure the .car package file exists
#----------------------------
if [ ! -f "$PKGFILE" ] ; then
   echo "$S: The package .car file does not exist at path=$PKGFILE"
   echo "${INDENT}Usage: $S CAR_file [-q]"
   exit 98
fi

#----------------------------
# Resolve relative paths for the scriptdir
#----------------------------
SCRIPTDIR=`dirname path`
absolute=$SCRIPTDIR
if [ -d "$SCRIPTDIR" ]; then absolute=${absolute}/.; fi
absolute=$(cd "$(dirname -- "$absolute")"; printf %s. "$PWD")
absolute="${absolute%?}"
SCRIPTDIR="${absolute}"

#----------------------------
# Set additional parameters
#----------------------------
TMPDIRZIP="$SCRIPTDIR/tmpzip"
FOUND_PKG_VERSION_V11="0"
REPLACE_PKG_VERSION_V11="0"

#----------------------------
# Display input
#----------------------------
if [ "$QUIET" == "" ] ; then
   echo "${INDENT}=============================================================="
   echo "$S"
   echo "${INDENT}   Parameters:"
   echo "${INDENT}     PKGFILE=$PKGFILE"
   echo "${INDENT}   Derived variables:"
   echo "${INDENT}     SCRIPTDIR=$SCRIPTDIR"
   echo "${INDENT}     TMPDIRZIP=$TMPDIRZIP"
fi

if [ -f "$TMPDIRZIP" ] ; then
   # delete and remove the temp zip directory
   if [ "$QUIET" == "" ] ; then echo "$S: rm -rf $TMPDIRZIP" ; fi
   rm -rf "$TMPDIRZIP"
fi

# Unzip the package .car file into the temp zip directory
if [ "$QUIET" == "" ] ; then echo "$S: unzip $QUIET -o $PKGFILE -d $TMPDIRZIP" ; fi
unzip $QUIET -o "$PKGFILE" -d "$TMPDIRZIP"

# Test to make sure the directory got created during unzip
if [ -f "$TMPDIRZIP" ] ; then
   echo "$S: unzip failed.  Temporary folder was not created during unzip.  Aborting script."
   exit 99
fi


#****************************************************************
#
# Search binary.xml, contenxt.xml, metadata.xml
# Find package format version 11 in .xml files and determine
#   if conversion is required or not.
#
#****************************************************************
#
if [ "$QUIET" == "" ] ; then 
	echo "$S: Begin search for package format version 11"
	echo "$S:"
fi

FILENAME="binary.xml"
if [ -f "$TMPDIRZIP/$FILENAME" ] ; then
   if [ "$QUIET" == "" ] ; then echo "$S: searchText [$FILENAME]=`grep  -e \"<packageFormatVersion>11</packageFormatVersion>\" "$TMPDIRZIP/$FILENAME" | sed -e 's/^[[:space:]]*//'`" ; fi
   # Search for the string in the unzipped XML file and trim any spaces before and after
   searchText=`grep  -e "<packageFormatVersion>11</packageFormatVersion>" "$TMPDIRZIP/$FILENAME" | sed -e 's/^[[:space:]]*//'`
   if [ "$searchText" == "<packageFormatVersion>11</packageFormatVersion>" ] ; then
      FOUND_PKG_VERSION_V11="1"
   fi
fi

FILENAME="contents.xml"
if [ -f "$TMPDIRZIP/$FILENAME" ] ; then
   if [ "$QUIET" == "" ] ; then echo "$S: searchText [$FILENAME]=`grep  -e \"<packageFormatVersion>11</packageFormatVersion>\" "$TMPDIRZIP/$FILENAME" | sed -e 's/^[[:space:]]*//'`" ; fi
   # Search for the string in the unzipped XML file and trim any spaces before and after
   searchText=`grep  -e "<packageFormatVersion>11</packageFormatVersion>" "$TMPDIRZIP/$FILENAME" | sed -e 's/^[[:space:]]*//'`
   if [ "$searchText" == "<packageFormatVersion>11</packageFormatVersion>" ] ; then
      FOUND_PKG_VERSION_V11="1"
   fi
fi

FILENAME="metadata.xml"
if [ -f "$TMPDIRZIP/$FILENAME" ] ; then
   if [ "$QUIET" == "" ] ; then echo "$S: searchText [$FILENAME]=`grep  -e \"<packageFormatVersion>11</packageFormatVersion>\" "$TMPDIRZIP/$FILENAME" | sed -e 's/^[[:space:]]*//'`" ; fi
   # Search for the string in the unzipped XML file and trim any spaces before and after
   searchText=`grep  -e "<packageFormatVersion>11</packageFormatVersion>" "$TMPDIRZIP/$FILENAME" | sed -e 's/^[[:space:]]*//'`
   if [ "$searchText" == "<packageFormatVersion>11</packageFormatVersion>" ] ; then
      FOUND_PKG_VERSION_V11="1"
   fi
fi
if [ "$QUIET" == "" ] ; then 
	echo "$S:"
fi

#****************************************************************
# When FOUND_PKG_VERSION_V11=0 then the package .car file version is 10 [comes from DV version 7] then do nothing.
# When FOUND_PKG_VERSION_V11=1 then the package .car file version is 11 [comes from DV version 8] then 
#    convert the package .car file from package version 11 to package version 10 for DV 7.x import.
#****************************************************************
#
if [ "$FOUND_PKG_VERSION_V11" == "0" ] ; then
	echo "$S: *** Package Format Version 10 [DV 7.x] found. ***"
	MESSAGE="No package .car file conversion required."
else
	echo "$S: *** Package Format Version 11 [DV 8.x] found. ***"
	
	#****************************************************************
	#
	# Replace text in binary.xml, contenxt.xml, metadata.xml
	# Replace package format version 11 with 10 in .xml files
	#
	#****************************************************************
	if [ "$QUIET" == "" ] ; then 
		echo "$S:"
		echo "$S: Begin replace of package format version 11 with version 10"
		echo "$S:"
	fi
	
	EXT=".xml"
	FILENAME="binary"
	if [ -f "$TMPDIRZIP/${FILENAME}${EXT}" ] ; then
		if [ "$QUIET" == "" ] ; then echo "$S: sed -e 's+<packageFormatVersion>11</packageFormatVersion>+<packageFormatVersion>10</packageFormatVersion>+g' \"$TMPDIRZIP/${FILENAME}${EXT}\" > \"$TMPDIRZIP/${FILENAME}2${EXT}\"" ; fi
		# Search for the "packageFormatVersion=11" and modify it to the "packageFormatVersion=10" within the unzipped XML file.
		sed -e 's+<packageFormatVersion>11</packageFormatVersion>+<packageFormatVersion>10</packageFormatVersion>+g' "$TMPDIRZIP/${FILENAME}${EXT}" > "$TMPDIRZIP/${FILENAME}2${EXT}"
		ERROR1=$?
		if [ "$QUIET" == "" ] ; then echo "$S: mv \"$TMPDIRZIP/${FILENAME}2${EXT}\" \"$TMPDIRZIP/${FILENAME}${EXT}\"" ; fi
		mv "$TMPDIRZIP/${FILENAME}2${EXT}" "$TMPDIRZIP/${FILENAME}${EXT}"
		ERROR2=$?
		if [ $ERROR1 -ne 0 ] || [ $ERROR2 -ne 0 ] ; then
		   if [ -f "$TMPDIRZIP" ] ; then rm -rf "$TMPDIRZIP" ; fi
		   echo "$S: sed/mv operation failed.  Aborting script.  ERROR1(sed)=$ERROR1  ERROR2(mv)=$ERROR2"
		   exit 99
		fi
		REPLACE_PKG_VERSION_V11="1"
	fi
	
	FILENAME="contents"
	if [ -f "$TMPDIRZIP/${FILENAME}${EXT}" ] ; then
		if [ "$QUIET" == "" ] ; then echo "$S: sed -e 's+<packageFormatVersion>11</packageFormatVersion>+<packageFormatVersion>10</packageFormatVersion>+g' \"$TMPDIRZIP/${FILENAME}${EXT}\" > \"$TMPDIRZIP/${FILENAME}2${EXT}\"" ; fi
		# Search for the "packageFormatVersion=11" and modify it to the "packageFormatVersion=10" within the unzipped XML file.
		sed -e 's+<packageFormatVersion>11</packageFormatVersion>+<packageFormatVersion>10</packageFormatVersion>+g' "$TMPDIRZIP/${FILENAME}${EXT}" > "$TMPDIRZIP/${FILENAME}2${EXT}"
		ERROR1=$?
		if [ "$QUIET" == "" ] ; then echo "$S: mv \"$TMPDIRZIP/${FILENAME}2${EXT}\" \"$TMPDIRZIP/${FILENAME}${EXT}\"" ; fi
		mv "$TMPDIRZIP/${FILENAME}2${EXT}" "$TMPDIRZIP/${FILENAME}${EXT}"
		ERROR2=$?
		if [ $ERROR1 -ne 0 ] || [ $ERROR2 -ne 0 ] ; then
		   if [ -f "$TMPDIRZIP" ] ; then rm -rf "$TMPDIRZIP" ; fi
		   echo "$S: sed/mv operation failed.  Aborting script.  ERROR1(sed)=$ERROR1  ERROR2(mv)=$ERROR2"
		   exit 99
		fi
		REPLACE_PKG_VERSION_V11="1"
	fi
	
	FILENAME="metadata"
	if [ -f "$TMPDIRZIP/${FILENAME}${EXT}" ] ; then
		if [ "$QUIET" == "" ] ; then echo "$S: sed -e 's+<packageFormatVersion>11</packageFormatVersion>+<packageFormatVersion>10</packageFormatVersion>+g' \"$TMPDIRZIP/${FILENAME}${EXT}\" > \"$TMPDIRZIP/${FILENAME}2${EXT}\"" ; fi
		# Search for the "packageFormatVersion=11" and modify it to the "packageFormatVersion=10" within the unzipped XML file.
		sed -e 's+<packageFormatVersion>11</packageFormatVersion>+<packageFormatVersion>10</packageFormatVersion>+g' "$TMPDIRZIP/${FILENAME}${EXT}" > "$TMPDIRZIP/${FILENAME}2${EXT}"
		ERROR1=$?
		if [ "$QUIET" == "" ] ; then echo "$S: mv \"$TMPDIRZIP/${FILENAME}2${EXT}\" \"$TMPDIRZIP/${FILENAME}${EXT}\"" ; fi
		mv "$TMPDIRZIP/${FILENAME}2${EXT}" "$TMPDIRZIP/${FILENAME}${EXT}"
		ERROR2=$?
		if [ $ERROR1 -ne 0 ] || [ $ERROR2 -ne 0 ] ; then
		   if [ -f "$TMPDIRZIP" ] ; then rm -rf "$TMPDIRZIP" ; fi
		   echo "$S: sed/mv operation failed.  Aborting script.  ERROR1(sed)=$ERROR1  ERROR2(mv)=$ERROR2"
		   exit 99
		fi
		REPLACE_PKG_VERSION_V11="1"
	fi

	# If changes were made to the .xml files then update the zip file
	if [ "$REPLACE_PKG_VERSION_V11" == "1" ] ; then 
		CURRDIR=`pwd`
		# Change directory to the temp zip directory and update the existing package .car file with the changed XML files.
		if [ "$QUIET" == "" ] ; then echo "$S: cd $TMPDIRZIP" ; fi
		cd "$TMPDIRZIP"
		if [ "$QUIET" == "" ] ; then echo "$S: zip $PKGFILE -f *.xml" ; fi
		zip $QUIET "$PKGFILE" -f *.xml
		ERROR=$?
		if [ $ERROR -ne 0 ] ; then
			cd "$CURRDIR"
			if [ -f "$TMPDIRZIP" ] ; then rm -rf "$TMPDIRZIP" ; fi
			echo "$S: zip failed.  Aborting script.  ERROR=$ERROR"
			exit 99
		fi
		cd "$CURRDIR"

		MESSAGE="Successfully converted packageFormatVersion from 11 to 10 for $PKG_NAME"
	else
	   MESSAGE="No package .car file conversion required."
	fi
fi

# delete and remove the temp zip directory
if [ "$QUIET" == "" ] ; then echo "$S:" ; fi
if [ -f "$TMPDIRZIP" ] ; then
	if [ "$QUIET" == "" ] ; then echo "$S: rm -rf $TMPDIRZIP" ; fi
	rm -rf "$TMPDIRZIP"
fi

if [ "$QUIET" == "" ] ; then 
	echo "$S: RESULT=$FOUND_PKG_VERSION_V11  MESSAGE=$MESSAGE"
	echo "${INDENT}=============================================================="
fi

# Return code
exit $FOUND_PKG_VERSION_V11
