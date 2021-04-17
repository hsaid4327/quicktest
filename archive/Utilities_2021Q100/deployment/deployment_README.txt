----------------------------------------------------------
INSTRUCTIONS:
----------------------------------------------------------
	1. Copy the "deployment" folder from the Utilities zip file to all target DV servers.
		Use a consistent folder path on each server.  
		For setup see the section "INSTRUCTIONS FOR SCRIPT SETUP" below to modify paths and ports.
	2. Review section I. regarding the privilege strategy
		a. Strategy 1 - Data Abstraction Best Practices Spreadsheet (requires: /shared/ASAssets/BestPractices_v81)
		b. Strategy 2 - Exporting resource ownership and privileges files.
	3. Review section II. regarding generate an options file for each target deployment server.
	4. Review section III. regarding customize "runAfterImport".
	5. Review section IV. regarding configure "validateDeployment".
	6. Review section V. regarding deployment scripts and how to use them.

----------------------------------------------------------
Deployment Considerations
----------------------------------------------------------
	The deployment folder is broken down into different subject areas that are all related to different deployment considerations.
	The list below describes the topics that are covered in this _README.
		  I. Manage Privileges and Resource Ownership using the runPrivilegeExport templates.
		 II. Generate Options file for data source connections
		III. Customize the "runAfterImport" procedure template for deployment.
		 IV. Configure the "validateDeployment" tables
		  V. Deployment scripts.

	=============================
	Deployment Folder Structure
	=============================
	This can be either windows or UNIX.  This structure must be copied to the DV target 
		server from the Utilities zip file.

	The recommended structure is shown below:
		/deployment			- Base folder which is to be copied from the Utilities zip file
			/carfiles		- A folder in which to place car files for deployment.
			/fullbackup		- A location for the deployProject.[bat|sh] to place the full server backup .car file
			/metadata		- A location to copy the "metadata.xml" file that gets extracted from the .car file 
								which is used for validating the deployment.
			/option_files	- A location to place option files.
			/privileges		- A location to write the Resource_Privileges_LOAD_DB.xlsx for Strategy 1 or 
								the privileges.xml file and resource_ownership.txt files for Strategy 2.
			/scripts		- The location for the various scripts:
				/logs					- A directory to write out warning and exception files.
				/deployProject.[bat|sh] - Deploy a project .car file.
				/convertPkgFileV11_to_V10.[bat|sh] - Convert a package format from V11 (8.x) to V10 (7.x).
				/JdbcSample.[bat|sh]	- Provides the ability to execute custom procedures on the DV server.
				/JdbcSample.class		- The required class file for JdbcSample.[bat|sh]
				/JdbcSample.java		- The original source code for JdbcSample.class

	=============================
	INSTRUCTIONS FOR SCRIPT SETUP
	=============================
	1. Modify variables for deployProject.[bat|sh] depending on your environment.

		------------------------------
		deployProject.bat
		------------------------------
		REM ####################################################################################################
		REM #   DEBUG=Y will send the DEBUG value to TDV procedures and the procedures will write to DV cs_server.log file.
		REM #         N will do nothing.
		set DEBUG=N
		REM ####################################################################################################


		REM ####################################################################################################
		REM # DV_HOME - This is the path on the deployment server of TDV home
		REM #    Required parameter.
		set DV_HOME=C:\MySW\TDV7.0.8
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
		set SERVER_ATTRIBUTE_DATABASE=
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
		set STRATEGY1_RESOURCE_PRIVILEGE_DATABASE=
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
		set RUN_AFTER_IMPORT_DATABASE=
		set RUN_AFTER_IMPORT_URL=runAfterImport
		REM ####################################################################################################


		REM ####################################################################################################
		REM # This is the published database and URL for the "validateDeployment" custom call.
		REM #   Optional-leave blank if not using this feature.  Only database needs to be unset if not using.
		REM #     set VALIDATE_DEPLOYMENT_DATABASE=ADMIN
		set VALIDATE_DEPLOYMENT_DATABASE=
		set VALIDATE_DEPLOYMENT_URL=validateDeployment
		REM # This is the remote server location where metadata.xml files will be copied to for the TDV server to read from.
		set VALIDATE_DEPLOYMENT_DIR=C:\MySW\TDV_Scripts\7 0\deployment\metadata
		REM # This is the full path to the DV Deployment Validation table.  This points to the customer implementation of the "DV_DEPLOYMENT_VALIDATION" table.
		REM #     e.g. /shared/Common/DeploymentValidation/Physical/Formatting/oracle/DV_DEPLOYMENT_VALIDATION
		set VALIDATE_DV_TABLE_PATH=/shared/Common/DeploymentValidation/Physical/Formatting/oracle/DV_DEPLOYMENT_VALIDATION
		REM # The full path to the DV sequence num generator procedure path that has no input and returns a single scalar INTEGER output.
		REM #     e.g. /shared/Common/DeploymentValidation/Physical/Formatting/getSequenceNum
		set VALIDATE_DV_PROCEDURE_PATH=/shared/Common/DeploymentValidation/Physical/Formatting/oracle/getSequenceNum
		REM ####################################################################################################

		------------------------------
		deployProject.sh
		------------------------------
		####################################################################################################
		#   DEBUG=Y will send the DEBUG value to TDV procedures and the procedures will write to DV cs_server.log file.
		#         N will do nothing.
		get_DEBUG()         { echo "N"; }
		####################################################################################################


		####################################################################################################
		# DV_HOME - This is the path on the deployment server of TDV home
		#    Required parameter.
		get_DV_HOME()       { echo "/Users/mtinius@tibco.com/Downloads/TDV7.0.8"; }
		####################################################################################################


		####################################################################################################
		# FULL_BACKUP_PATH - This is the path on the deployment server where TDV server backup files are stored.
		#    Required parameter.
		get_FULL_BACKUP_PATH() { echo "/Users/mtinius@tibco.com/Downloads/TDV_Scripts/7.0/deployment/fullbackup"; }
		####################################################################################################


		####################################################################################################
		# SERVER_ATTRIBUTE_DATABASE - This is the published database "ASAssets" and URL 
		#   "Utilities.repository.getServerAttribute" to get a server attribute.
		#   This is required if converting a .car file from 8.x to 7.x
		#   This is the standard, generic database and URL.
		#   Optional-leave blank if not using this feature.  Only database needs to be unset if not using.
		#     get_SERVER_ATTRIBUTE_DATABASE()     { echo "ASAssets"; }
		get_SERVER_ATTRIBUTE_DATABASE()     { echo ""; }
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
		get_STRATEGY2_RESOURCE_PRIVILEGE_FILE()      { echo "\\\vmware-host\Shared Folders\Downloads\TDV_Scripts\7.0\deployment\privileges\privileges.xml"; }
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
		get_STRATEGY2_RESOURCE_OWNERSHIP_FILE()      { echo "\\\vmware-host\Shared Folders\Downloads\TDV_Scripts\7.0\deployment\privileges\resource_ownership.txt"; }
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
		#     e.g. get_VALIDATE_DEPLOYMENT_DATABASE()  { echo "ADMIN"; }
		get_VALIDATE_DEPLOYMENT_DATABASE()  { echo ""; }
		get_VALIDATE_DEPLOYMENT_URL()       { echo "validateDeployment"; }
		# This is the remote server location where metadata.xml files will be copied to for the TDV server to read from.
		get_VALIDATE_DEPLOYMENT_DIR()       { echo "/Users/mtinius@tibco.com/Downloads/TDV_Scripts/7.0/deployment/metadata"; }
		# This is the full path to the DV Deployment Validation table.  This points to the customer implementation of the "DV_DEPLOYMENT_VALIDATION" table.
		#     e.g. /shared/Common/DeploymentValidation/Physical/Formatting/oracle/DV_DEPLOYMENT_VALIDATION
		get_VALIDATE_DV_TABLE_PATH()        { echo "/shared/Common/DeploymentValidation/Physical/Formatting/oracle/DV_DEPLOYMENT_VALIDATION"; }
		# The full path to the DV sequence num generator procedure path that has no input and returns a single scalar INTEGER output.
		#     e.g. /shared/Common/DeploymentValidation/Physical/Formatting/getSequenceNum
		get_VALIDATE_DV_PROCEDURE_PATH()    { echo "/shared/Common/DeploymentValidation/Physical/Formatting/oracle/getSequenceNum"; }
		####################################################################################################


	2. Modify variables for JdbcSample.[bat|sh] depending on your environment.

		------------------------------
		JdbcSample.bat
		------------------------------
		REM # Modify the DV_HOME
		SET DV_HOME=C:\MySW\TDV8.2
		REM # Modify \jre to \jdk for TDV 8.2 and higher
		set JAVA_HOME=%DV_HOME%\jdk

		------------------------------
		JdbcSample.sh
		------------------------------
		# Modify the DV_HOME
		DV_HOME="/MySW/TDV8.2"
		# Modify /jre to /jdk for TDV 8.2 and higher
		JAVA_HOME=$DV_HOME/jdk


----------------------------------------------------------
I.   Manage Privileges and Resource Ownership
----------------------------------------------------------
	=============================
	Strategy 1: Configuring Privilege Spreadsheet [Preferred Strategy]
		Fine-grained approach (selective)
	=============================
	Download the Data Abstraction Best Practices from the Github open source site:
		https://github.com/TIBCOSoftware/ASAssets_DataAbstractionBestPractices/tree/master/Release

	Review the documentation for the configruation of privileges:
		How To Use Data Abstraction Best Practices Privilege Scripts.pdf

		Summary:
			1. Copy the Resource_Privileges_LOAD_DB.xlsx spreadshet to <base_folder>/deployment/privileges
			2. Enable and configure /shared/ASAssets/BestPractices_v81/PrivilegeScripts/Metadata/Privileges_DS_EXCEL
				a. Configure the root path to point to the location the spreadsheet was copied to.
			3. Reintrospect /shared/ASAssets/BestPractices_v81/PrivilegeScripts/Metadata/Privileges_DS_EXCEL
			4. Test that the data can be successfully read

	=============================
	Strategy 2: Exporting Privileges and resource ownership
		Coarse-grained approach (all-or-nothing)
	=============================
	The following procedures serve as templates to export privileges to the privileges.xml file and resource ownership to the resource_ownership.txt file:
		DEV:	/shared/ASAssets/Utilities/deployment/privileges/templates/runPrivilegeExport_1_DEV_template
		TEST:	/shared/ASAssets/Utilities/deployment/privileges/templates/runPrivilegeExport_2_TEST_template
		PROD:	/shared/ASAssets/Utilities/deployment/privileges/templates/runPrivilegeExport_3_PROD_template

	Instructions:
		1.	Modify /shared/ASAssets/Utilities/environment/getEnvName() and provide an environment name 
				such as DEV, TEST, PROD etc based on the TDV server environment.
		2.	Copy this template to a different location outside of the /shared/ASAssets/Utilities folder 
				so that it does not get overwritten if the Utilities are updated.
		3.	Modify the variable "scriptEnv" below to match environment name that comes from getEnvName().
		4.	Modify the paths and ownership.  For DEV environments the ownership:domain should always 
				be null:null because you don't want to change ownership of your DEV resources.
		5.	Set privileges on those folder paths exactly as they should be set for this point in time.
		6.	Execute the procedure to export the privilege.xml file and the resource_ownership.txt file 
				to the TDV server path that you provide.
			Input:
				debug							CHAR(1),	- Y=debug on, N=debug off
				privilegeFileName				LONGVARCHAR - The full TDV server path location to privileges.xml file.		
					e.g. /home/files/deployment/privileges/privileges.xml
				resourceOwnershipFileName		LONGVARCHAR - The full TDV server path location to the resource_ownership.txt file.
					e.g. /home/files/deployment/privileges/resource_ownership.txt
			Output:
				invalidPathList					LONGVARCHAR - A comma-separated list of paths from this procedure that are not valid [do not exist].

	The concept behind this is simple.  
		1. The templates are used to take the "AS-IS" snapshot of privileges for the given folder paths listed in the template 
				at the time of execution and write them out to a file [privileges.xml].
		2. It is very important that the folder privileges for each folder listed be set exactly as they should be set 
				before exporting the privilege snapshot to the privileges.xml file.
		3. Subsequently, the privilege can be re-applied from the snapshot [privileges.xml] using importResourcePrivileges.
				They can be applied from Studio by executing "/shared/ASAssets/Utilities/deployment/privileges/importResourceOwnership" or
				they can be applied from the UNIX command line using deployPrivs.sh.  A copy of this script can be found in its entirety
				at the bottom of this procedure.
		4. For deployment, it is recommended to invoke the published importResourcePrivileges after importing the car file.
				This is typically done from the deployment shell script [deployProject.[bat|sh] which is provided in its 
				entirety at the bottom of this procedure.
				DataSource=ASAssets		Procedure: Utilities.deployment.importResourcePrivileges
				SQL: "SELECT * FROM Utilities.deployment.importResourcePrivileges(1, 0, 0, '$PRIVSFILE', 'SET_EXACTLY')"

	The objective of the template procedure is to allow the DV development team to maintain the privileges.xml and resource_ownership.txt files.
		1. For maintaining privileges (privileges.xml):
			The rows (resource locations and types) need to be maintained in this procedure.  
			If a resource is added, then the path and type need to be added to this procedure.
			If a resource is removed, then the path and type need to be removed from this procedure.
			If a change is made, to a resource in a one of the environments during deployment, then this procedure needs to be modified and 
				executed prior to deployment so that the privileges.xml file are updated and ready during deployment.
		2. For maintaining resource ownership (resource_ownership.txt)
			The row definition in the runPrivilegeExport_[DEV|TEST|PROD] procedure explicitly defines what the ownership
				should be for each resource path.  For DEV, the ownership:domain is always null:null because it is not
				reccommended to change ownership of resources in the development environment. 

		runPrivilegeExport Row Definition:
			owner: 			What the resource ownership should be set to.  If null then no resource owner is set and the path is bypassed.
							Ownership is explicitly declared here.  It is not determined by how the resourcePath is currently set.
			domain: 		The domain of the owner.  Ignored if owner is null.  Required if owner is not null.
			resourcePath:	The path from which to read (derive) the privileges for the given DV environment.
			resourceType:	The resource type for the given resourcePath.  i.e. CONTAINER, DATA_SOURCE.
		Row Format:			'owner:domain:resourcePath:resourceType,'

	=============================
	Importing (Apply) Privileges
	=============================
	Privileges are applied after deploying the CAR file.
	All privileges for all resources in the privileges.xml file are applied using the following procedure:
		/services/databases/ASAssets/Utilities/importResourcePrivileges >-----------------|
		/shared/ASAssets/Utilities/deployment/privileges/importResourcePrivileges <-------|

----------------------------------------------------------
II.  Generate Options file for data source connections
----------------------------------------------------------
	=============================
	Generate Options File
	=============================
	The procedure "/shared/ASAssets/Utilities/deployment/optionsfile/generateOptionsFile" is used to generate an options file on the TDV server.  
	The procedure invokes generateOptions.  If a file already exists, it adds an _copy# to the end of the file name. 
	You don't want to accidently overwrite the real file which contains the valid passwords.  Once the copy is generated, 
	it needs to be updated with the correct passwords.  Look for CHANGE_PASSWORD text within the file.
	If the file path is left null or blank, the file options are simply returned in the output variable.

	The option file may have blank lines and comments starting with a # in the first character of the line.

	=============================
	Sample Options File
	=============================
		-set /shared/test_import/"source"/Advisory DATA_SOURCE path "C:\MyFiles\datafiles"
		-set /shared/test_import/"source"/ds_XML DATA_SOURCE raw:url file:///C:\MySW\TDV7.0.8\docs\examples/productCatalog.xml
		-set /shared/test_import/"source"/ds_XMLCopy DATA_SOURCE raw:url file:///C:\MySW\TDV7.0.8\docs\examples/productCatalog.xml
		-set /shared/test_import/"source"/ds_inventory DATA_SOURCE database inventory
		-set /shared/test_import/"source"/ds_inventory DATA_SOURCE host localhost
		-set /shared/test_import/"source"/ds_inventory DATA_SOURCE password tutorial
		-set /shared/test_import/"source"/ds_inventory DATA_SOURCE port 9408
		-set /shared/test_import/"source"/ds_inventory DATA_SOURCE user tutorial
		-set /shared/test_import/"source"/ds_orders DATA_SOURCE database orders
		-set /shared/test_import/"source"/ds_orders DATA_SOURCE host localhost
		-set /shared/test_import/"source"/ds_orders DATA_SOURCE password tutorial
		-set /shared/test_import/"source"/ds_orders DATA_SOURCE port 9408
		-set /shared/test_import/"source"/ds_orders DATA_SOURCE user tutorial
		-set /shared/test_import/"source"/ds_ordersCopy DATA_SOURCE database orders
		-set /shared/test_import/"source"/ds_ordersCopy DATA_SOURCE host localhost
		-set /shared/test_import/"source"/ds_ordersCopy DATA_SOURCE password tutorial
		-set /shared/test_import/"source"/ds_ordersCopy DATA_SOURCE port 9408
		-set /shared/test_import/"source"/ds_ordersCopy DATA_SOURCE user tutorial

----------------------------------------------------------
III. Customize the "runAfterImport" procedure template for deployment.
----------------------------------------------------------
	The procedure "/shared/ASAssets/Utilities/deployment/run/runAfterImport_template" is a template for running internal DV procedures 
		after import of a CAR file during a DV migration.
	This procedure should be copied to a different location so that it does not get overwritten when the Utilities are upgraded.

	Instructions:
		1. Modify /shared/ASAssets/Utilities/environment/getEnvName() and provide an environment name such as DEV, TEST, PROD etc based on the TDV server environment.
		2. Copy the "runAfterImport_template" template to a different location outside of the /shared/ASAssets/Utilities folder so that it does not get overwritten if the Utilities are updated.
		3. Modify the copied procedure
			a. Modify the variable "scriptEnv" to match environment name that comes from getEnvName().
			b. Add procedure calls to add additional logic that you want to "run after import".
		4. Publish the copied procedure "runAfterImport" to /services/databases/ADMIN/runAfterImport
		5. The script deployProject.[bat|sh] would invoke runAfterImport.  

----------------------------------------------------------
IV. Configure the "validateDeployment" tables
----------------------------------------------------------
	This procedure is used to create the necessary resources required for validating the deployment.
		/shared/ASAssets/Utilities/deployment/validate/helpers/validateDeploymentInit

	validateDeploymentInit:
		This procedure is used to create and execute the DDL for the table 'DV_DEPLOYMENT_VALIDATION' and the sequence 'DV_DEPLOY_SEQ'.
		The user must provide a datasource that is either [oracle, sqlserver or postgres] for this operation to work successfully.
		The user must provide the full path to the datasource schema which is used to derive all necessary attributes for the generation.

		This procedure generates the necessary procedures and views to interface with the database table and sequence.  
		The following resources are generated into the DV folder container designated by "resourceContainer".  
			00_ExecuteDDL				- A packaged query used to execute DDL statements.
			00_ExecuteDMLIntResult		- A packaged query used to execute DML statements to get the next sequence and return an integer result.
			getSequenceNum				- A procedure that invokes 00_ExecuteDMLIntResult to get the next sequence using the proper database syntax.
			DV_DEPLOYMENT_VALIDATION	- A formatting layer view that invokes the physical datasource table.  This is the path
											that the user should provide to deployProjects.[bat|sh] for validating the deployment.

	Instructions:
		1. Execute /shared/ASAssets/Utilities/deployment/validate/helpers/validateDeploymentInit
			which will create the necessary table, sequence and DV resources for deployProject.[bat|sh} to interface with
			when validating the deployment .car file resources.

----------------------------------------------------------
V. Deployment scripts.
----------------------------------------------------------
	=============================
	Deployment Script
	=============================
	At deployment time, the following procedures are invoked from "deployProject.[bat|sh]":
		The password is optional and will be prompted if not provided.

		If using -c option to convert from 8.x to 7.x:
			DISCLAIMER: 
				Migrating resources from 8.x to 7.x is not generally supported.
				However, it does provide a way to move basic functionality coded in 8.x to 7.x.  
				It does not support the ability to move new features that exist in 8.x but do not exist in 7.x.  
				Exceptions may be thrown in this circumstance.

		Usage: 
		----------------------
		deployProject.[bat|sh] -i <import_CAR_file> -o <options_file> -h <hostname> -p <wsport> -u <username> -d <domain> -up <user_password> -ep <encryptionPassword>
				  [-v] [-c] [-e] [-print] [-printOnly] [-printWarning] [-inp1 value] [-inp2 value] [-inp3 value] 
				  [-privsOnly] [-pe privilege_environment] [-pd privilege_datasource] [-po privilege_organization] [-pp privilege_project] [-ps privilege_sub_project]
				  [-sn privilege_sheet_name] [-rp privilege_resource_path] [-rt privilege_resource_type] [-gn privilege_group_name] [-gt privilege_group_type] [-gd privilege_group_domain] [-be privilege_bypass_errors]

		Parameter Definitions:
		----------------------
		  -i  [mandatory] import archive (CAR) file path (full or relative).
		  -h  [mandatory] host name or ip address of the DV server deploying to.
		  -p  [mandatory] web service port of the target DV server deploying to.  e.g. 9400
		  -u  [mandatory] username with admin privileges.
		  -d  [mandatory] domain of the username.
		  -up [mandatory] user password.
		  -o  [optional] options file path (full or relative).
		  -ep [optional] encryption password for the archive .CAR file for TDV 8.x.
		  -v  [optional] verbose mode.  Verbose is turned on for secondary script calls.  Otherwise the default is verbose is off.
		  -c  [optional] execute package .car file version check and conversion.  
						Use -c in environments where you are migrating from DV 8.x into DV 7.x.
						If not provided, version checking and .car file conversion will not be done which would be optimal to use
							  when all environments are of the same major DV version such as all DV 7.x or all DV 8.x
		  -e  [optional] Encrypt the communication between client and TDV server.
		  -print        [optional] print info and contents of the package .car file and import the car file.  If -print is not used, the car will still be imported.
		  -printOnly    [optional] only print info and contents of the package .car file and do not import or execute any other option.  This option overrides -print.
		  -printWarning [optional] print the warnings for updatePrivilegesDriverInterface, importResourcePrivileges, importResourceOwnership and runAfterImport otherwise do not print them.
		  -privsOnly    [optional] execute the configured privilege strategy only.  Do no execute the full deployment.
								   Execute either privilege strategy 1 or 2 based on configuration.  If strategy 2 is configured, then resource ownership may also be executed if configured.

		 The following parameters may be passed into Strategy 1 for Privileges: updatePrivilegesDriverInterface
		   These parameters act as filters against the spreadsheet or database table.  The most common parameters are -pd, -pe, -po, -pp and -ps
		  -pe  [mandatory] privilege environment name.  [DEV, UAT, PROD]
		  -pd  [optional] privilege datasource type.  [EXCEL, DB_LLE_ORA, DB_LLE_SS, DB_PROD_ORA, DB_PROD_SS]
		  -po  [optional] privilege organization name.
		  -pp  [optional] privilege project name.
		  -ps  [optional] privilege sub-project name.
		  -sn  [optional] privilege excel sheet name.  [Privileges_shared, Privileges_databases, Privileges_webservices]
		  -rp  [optional] privilege resource path - The resource path in which to get/update privileges.  It may contain a wildcard "%".
		  -rt  [optional] privilege resource type - The resource type in which to get/update privileges.  It is always upper case. 
													   This will only be used when no "Resource_Path" or a single "Resource_Path" is provided.  
													   It is not used when a list of "Resource_Path" entries are provided.
													   E.g. DATA_SOURCE - a published datasource or physical metadata datasource.
															CONTAINER - a folder path, a catalog or schema path.
															COLUMN - a column from a table
															LINK - a published table or procedure.  If it resides in the path /services and points to a TABLE or PROCEDURE then it is a LINK.
															TABLE - a view in the /shared path.
															PROCEDURE a procedure in the /shared path.
		  -gn  [optional] privilege group name - The user/group name in which to get/update privileges.
		  -gt  [optional] privilege group type - Valid values are USER or GROUP
		  -gd  [optional] privilege group domain - The domain name in which to get/update privileges.
		  -be  [optional] privilege bypass errors - Bypass errors.  Throw exception when paths not found. N/Null (default) Do not bypass errors.  Y=bypass resource not found errors but report them.

		 The following parameters may be passed into Strategy 2 for Privileges: importResourcePrivileges
		  -recurseChildResources [1 or 0] - A bit [default=1] flag indicating whether the privileges of the resources in the XML file should be recursively applied to any child resources (assumes the resource is a container).
		  -recurseDependencies   [1 or 0] - A bit [default=0] flag indicating whether the privileges of the resources in the XML file should be applied to any resources that they use.
		  -recurseDependents     [1 or 0] - A bit [default=0] flag indicating whether the privileges of the resources in the XML file should be applied to any resources that are used by them.

		 The following parameter may be passed into validateDeployment and/or runAfterImport:
		  -inp1 [optional] Use this to represent a unique id for validating the deployment contents with an external log.
			 Format: -inp1 value
					 -inp1 signals the variable input.
					 value is the actual value with double quotes when spaces are present.
		  -inp2 [optional] Use this to represent any value
			 Format: -inp2 value
					 -inp2 signals the variable input.
					 value is the actual value with double quotes when spaces are present.
		  -inp3 [optional] Use this to represent any value
			 Format: -inp3 value
					 -inp3 signals the variable input.
					 value is the actual value with double quotes when spaces are present.

		Execution Steps:
		----------------------
		1. Perform DV server version check (if configured)
			"SELECT * FROM Utilities.repository.getServerAttribute('/server/config/info/versionFull')"

		2. Perform package .car file conversion if requested
			convertPkgFileV11_to_V10.[bat|sh] <package_file_path> 

		3. Full Server Backup if requested
			"$DV_HOME/bin/backup_export.sh" -pkgfile "$BACKUPFILENAME" $ENCRYPT -server "$HOST" -port "$WSPORT" -user "$USER" -password "$USER_PASSWORD" -domain "$DOMAIN" -includeStatistics

		4. Print contents if requested
 			"$DV_HOME/bin/pkg_import.sh" -pkgfile "$PKGFILE" $ENCRYPT -verbose -printinfo -printcontents -server "$HOST" -port $WSPORT -user "$USER" -password "$USER_PASSWORD" -domain "$DOMAIN" > "$ARCHIVE_RESULT_FILE"

		5. Validate the car file (if confifured)
 			a. Extract the car file to get metadata.xml
			b. Invoke DV procedure "validateDeployment"
				"$JDBC_SAMPLE_EXEC" "$VALIDATE_DEPLOYMENT_DATABASE" "$HOST" "$DBPORT" "$USER" "$USER_PASSWORD" "$DOMAIN" "SELECT * FROM $VALIDATE_DEPLOYMENT_URL('$DEBUG', '$INPUT1', '$archiveCreationDate', '$DEPLOYMENT_DATE_BEG', '$HOST', '$WSPORT', '$VALIDATE_DEPLOYMENT_DIR_FILE_PATH', '$VALIDATE_DV_TABLE_PATH', '$VALIDATE_DV_PROCEDURE_PATH')" > "$JDBC_RESULT_FILE"

		6. Import specified CAR file if requested
			"$DV_HOME/bin/pkg_import.sh" -pkgfile "$PKGFILE" -optfile "$OPTFILE" $ENCRYPT -server "$HOST" -port $WSPORT -user "$USER" -password "$USER_PASSWORD" -domain "$DOMAIN" > "$ARCHIVE_RESULT_FILE"

		7. Invoke Strategy 1 (if configured) for Privileges and Ownership setting using Data Abstraction Best Practices Spreadsheet
			"$JDBC_SAMPLE_EXEC" "$STRATEGY1_RESOURCE_PRIVILEGE_DATABASE" "$HOST" "$DBPORT" "$USER" "$USER_PASSWORD" "$DOMAIN" "SELECT * FROM $STRATEGY1_RESOURCE_PRIVILEGE_URL('$PRIVILEGE_DATASOURCE', 1, '$PRIVILEGE_ENVIRONMENT', '$PRIVILEGE_ORGANIZATION', '$PRIVILEGE_PROJECT', '$PRIVILEGE_SUBPROJECT', '$PRIVILEGE_SHEET_NAME', '$PRIVILEGE_RESOURCE_PATH', '$PRIVILEGE_RESOURCE_TYPE', '$PRIVILEGE_GROUP_NAME', '$PRIVILEGE_GROUP_TYPE', '$PRIVILEGE_GROUP_DOMAIN', 'Y', 'N', 'N', 'N', 'N', 'N', 'N', 'N', '$PRIVILEGE_BYPASS_ERRORS')" > "$JDBC_RESULT_FILE"
			Actual Path: /services/databases/ASAssets/Utilities/deployment/updatePrivilegesDriverInterface

		8. Invoke Strategy 2 (if configured) to read the file resource_ownership.txt and changes resource ownership for each path.
			"$JDBC_SAMPLE_EXEC" "$STRATEGY2_RESOURCE_OWNERSHIP_DATABASE" "$HOST" "$DBPORT" "$USER" "$USER_PASSWORD" "$DOMAIN" "SELECT * FROM $STRATEGY2_RESOURCE_OWNERSHIP_URL('$DEBUG', '$STRATEGY2_RESOURCE_OWNERSHIP_FILE')" > "$JDBC_RESULT_FILE"
			Actual Path: /services/databases/ASAssets/Utilities/deployment/importResourceOwnership

		9. Invoke Strategy 2 (if configured) to read the privileges.xml file and updates the privileges.
			"$JDBC_SAMPLE_EXEC" "$STRATEGY2_RESOURCE_PRIVILEGE_DATABASE" "$HOST" "$DBPORT" "$USER" "$USER_PASSWORD" "$DOMAIN" "SELECT * FROM $STRATEGY2_RESOURCE_PRIVILEGE_URL('$DEBUG', $RECURSE_CHILD_RESOURCES, $RECURSE_DEPENDENCIES, $RECURSE_DEPENDENTS, '$STRATEGY2_RESOURCE_PRIVILEGE_FILE', 'SET_EXACTLY')" > "$JDBC_RESULT_FILE"
			Actual Path: /services/databases/ASAssets/Utilities/deployment/importResourcePrivileges

		10. Invokes the post-deployment customization script (if configured): 
			"$JDBC_SAMPLE_EXEC" "$RUN_AFTER_IMPORT_DATABASE" "$HOST" "$DBPORT" "$USER" "$USER_PASSWORD" "$DOMAIN" "SELECT * FROM $RUN_AFTER_IMPORT_URL('$DEBUG', '$INPUT1', '$INPUT2', '$INPUT3')" > "$JDBC_RESULT_FILE"
			Actual Path: /services/databases/ADMIN/runAfterImport

		EXAMPLE:
		----------------------
			deployProject.bat -i "C:\MySW\TDV_Scripts\7 0\deployment\carfiles\A_TEST.car" -o "C:\MySW\TDV_Scripts\7 0\deployment\option_files\options.txt" -h "localhost" -u admin -d composite -up admin -p 9400 -pe DEV -print -pd EXCEL -po "Tibco,Tibco1" -pp "ATEST,ATEST1"   -ps ",ATEST1" -be Y -gt GROUP -gd composite -inp1 i1 -input2 i2 -input3 "input 3"

	=============================
	Privilege Script Execution
	=============================
	It is possible to apply privileges only from the Windows/UNIX command line using the following script:
		The password is optional and will be prompted if not provided.

		deployProject.[bat|sh] -privsOnly -h "localhost" -u admin -d composite -up admin -p 9400 -pd EXCEL -pe DEV -po "Tibco,Tibco1" -pp "ATEST,ATEST1" -ps ",ATEST1" -be Y -gt GROUP -gd composite 

		This example has Strategy 1 privilege spreadsheet configured.

		--------------------------------------------------------------------
		*** STRATEGY 1 ***
		*** Resetting privileges and ownership on specified resources. ***
		--------------------------------------------------------------------
		*** CALL "C:\MySW\TDV_Scripts\7 0\deployment\scripts\JdbcSample.bat" "ASAssets" "localhost" "9401" "admin" "********" "composite" "SELECT * FROM Utilities.deployment.updatePrivilegesDriverInterface('EXCEL', 1, 'DEV', 'Tibco,Tibco1', 'ATEST,ATEST1', ',ATEST1', '', '', '', '', 'GROUP', 'composite', 'Y', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'Y')" > "C:\MySW\TDV_Scripts\7 0\deployment\scripts\tmp_ps\jdbcSampleResults.txt" ***
				1 file(s) copied.
		*** WARNING: REVIEW FILE "C:\MySW\TDV_Scripts\7 0\deployment\scripts\logs\strategy1_privilege_output_localhost_9400_2019_12_28_08_54_53.log"
		*** "Utilities.deployment.updatePrivilegesDriverInterface" completed with status=WARNING ***


		OUTPUT FILE:
			This field "col[1]=" indicates WARNING or ERROR: col[1]=`WARNING`
			This field "col[2]=" provides the text and is pipe "|" delimited in the event it needs to be parsed.
			Contents of the log file ("C:\MySW\TDV_Scripts\7 0\deployment\scripts\logs\strategy1_privilege_output_localhost_9400_2019_12_28_08_54_53.log") are shown below:
				column count = 2
				row = `1`   col[1]=`WARNING`  col[2]=`executeNum=1|rowStatus=SUCCESS|rowsProcessed=2|sqlStatement=SELECT * FROM /shared/ASAssets/BestPractices_v81/PrivilegeScripts/updatePrivilegesDriver('EXCEL',1,'DEV','Tibco','ATEST',null,null,null,null,null,'GROUP','composite','Y','N','N','N','N','N','N','N','Y')|logOutput=SUCCESS|
				executeNum=2|rowStatus=WARNING|rowsProcessed=2|sqlStatement=SELECT * FROM /shared/ASAssets/BestPractices_v81/PrivilegeScripts/updatePrivilegesDriver('EXCEL',1,'DEV','Tibco1','ATEST1','ATEST1',null,null,null,null,null,null,'Y','N','N','N','N','N','N','N','Y')|logOutput=updatePrivilegesDriver : Status=SKIPPED: [BYPASS **ERROR**]  REVOKE ALL :: RESOURCE PATH NOT FOUND [DATA_SOURCE::/services/databases/A_TEST1]|logOutput=updatePrivilegesDriver : [2 of 2]  Status=SKIPPED: [BYPASS **ERROR**]  Row=98  PrivRows=3 SheetRow=10 Sheet=2Privileges_databases ResPath=/services/databases/A_TEST1 ResType=DATA_SOURCE Dependencies=N Dependents=N Child=YM mode=OVERWRITE_APPEND RevokeAll=Y Name=group1 Type=GROUP Domain=composite EnvType=DEV Privileges=R W E S U I D Owner= OwnerDomain=|
				` 


	=============================
	JdbcSample Script
	=============================
	The JdbcSample script is used to interface with a DV server and execute custom procedures.
	This procedure *** REQUIRES *** JdbcSample.class to be present in the target scripts folder.  
		It can be found in the Utilities zip file "deployment/scripts".
	The following scripts get executed via JdbcSample.

		1. Reads the Data Abstraction Best Practices Privilege Spreadsheet
			"SELECT * FROM %STRATEGY1_RESOURCE_PRIVILEGE_URL%('%PRIVILEGE_DATASOURCE%', 1, '%PRIVILEGE_ENVIRONMENT%', '%PRIVILEGE_ORGANIZATION%', '%PRIVILEGE_PROJECT%', '%PRIVILEGE_SUBPROJECT%', '%PRIVILEGE_SHEET_NAME%', '%PRIVILEGE_RESOURCE_PATH%', '%PRIVILEGE_RESOURCE_TYPE%', '%PRIVILEGE_GROUP_NAME%', '%PRIVILEGE_GROUP_TYPE%', '%PRIVILEGE_GROUP_DOMAIN%', 'Y', 'N', 'N', 'N', 'N', 'N', 'N', 'N', '%PRIVILEGE_BYPASS_ERRORS%')"
			Actual Path: /services/databases/ASAssets/Utilities/deployment/updatePrivilegesDriverInterface

		2. Reads the file resource_ownership.txt and changes resource ownership for each path.
			"SELECT * FROM %STRATEGY2_RESOURCE_OWNERSHIP_URL%('%DEBUG%', '%STRATEGY2_RESOURCE_OWNERSHIP_FILE%'))"
			Actual Path: /services/databases/ASAssets/Utilities/deployment/importResourceOwnership

		3. Reads the privileges.xml file and updates the privileges.
			"SELECT * FROM %STRATEGY2_RESOURCE_PRIVILEGE_URL%('%DEBUG%', %RECURSE_CHILD_RESOURCES%, %RECURSE_DEPENDENCIES%, %RECURSE_DEPENDENTS%, '%STRATEGY2_RESOURCE_PRIVILEGE_FILE%', 'SET_EXACTLY')"
			Actual Path: /services/databases/ASAssets/Utilities/deployment/importResourcePrivileges

		4. Invokes the post-deployment customization script: 
			"SELECT * FROM  %RUN_AFTER_IMPORT_URL%('%DEBUG%', '%INPUT1%', '%INPUT2%', '%INPUT3%')"
			Actual Path: /services/databases/ADMIN/runAfterImport


	(c) 2017 TIBCO Software Inc.  All rights reserved.
	
	Except as specified below, this software is licensed pursuant to the Eclipse Public License v. 1.0.
	The details can be found in the file LICENSE.
	
	The following proprietary files are included as a convenience, and may not be used except pursuant
	to valid license to Composite Information Server or TIBCO® Data Virtualization Server:
	csadmin-XXXX.jar, csarchive-XXXX.jar, csbase-XXXX.jar, csclient-XXXX.jar, cscommon-XXXX.jar,
	csext-XXXX.jar, csjdbc-XXXX.jar, csserverutil-XXXX.jar, csserver-XXXX.jar, cswebapi-XXXX.jar,
	and customproc-XXXX.jar (where -XXXX is an optional version number).  Any included third party files
	are licensed under the terms contained in their own accompanying LICENSE files, generally named .LICENSE.txt.
	
	This software is licensed AS-IS. Support for this software is not covered by standard maintenance agreements with TIBCO.
	If you would like to obtain assistance with this software, such assistance may be obtained through a separate paid consulting
	agreement with TIBCO.

