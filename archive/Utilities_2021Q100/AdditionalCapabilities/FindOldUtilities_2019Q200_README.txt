	README:

	The FindOldUtilities package includes the following procedures which can help you identify 
		where old utilities procedures have been registered as custom functions in TDV. 
	The FindOldUtilities is stand-alone and does not require any other Utilities to be present.


			checkForOldUtilitiesCustomFunctions - Check for any old custom functions and provide the location.
												Note: This uses a REST API datasource call that must be configured. 

			checkUsageForOldCustomFunctions - Check for usage of old custome function that only use the function name and not the fully-qualified path.
												Example: SET env = getEnvName();

			checkUsageForOldUtilities - Check for usage of old custom functions that use the explicit, fully-qualified path.
												Example: CALL /shared/ASAssets/Utilities/environment/getEnvName(env);


	These prodecures depends on internal REST services exposed on the TDV server which are introspected under the data source  
		/shared/ASAssets/FindOldUtilities/base/localCustomFunctions.

	To display a list of current custom functions, execute this view:
		/shared/ASAssets/FindOldUtilities/base/customFunctionPaths

	REQUIREMENTS:
		Please note that your TDV server must be on TDV 7 Hotfix 6 or later in order to use these procedures.

	CONFIGURATION:
		How to configure the localCustomFunctions datasource:
		You will need to make the following changes to the data source before you can call the procedures:
			1. Open the datasource: /shared/ASAssets/FindOldUtilities/base/localCustomFunctions
			2. Update the base URL: Confirm that the port in the URL is correct for your TDV server.  Example: http://localhost:9400
			3. Additionally, if your TDV server has been configured to disallow HTTP connections, you will need to update the url to use https.
			4. Update the user name and password: Provide the credentials for an account with administrator access on the TDV server.
