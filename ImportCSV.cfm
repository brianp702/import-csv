<!--- override the ColdFusion timeout setting because this page can be slow --->
<cfsetting requestTimeOut = "240">
<cfoutput>
<cfparam name="form.file_name" default="">
<cfparam name="variables.success" default=false>
<cfparam name="session.systemMessage" default="">

<cfif IsDefined("form.submit_upload") AND form.file_name NEQ "">
	<cftry>	
		<cfparam name="CurrentPath" default="#GetDirectoryFromPath(GetCurrentTemplatePath())#">
		<cffile action="upload" fileField="form.file_name" destination="#CurrentPath#/Imports/CSAbandonedCalls/" nameConflict="Error">
		<cfcatch type="any">
			<cfset session.systemMessage = "A file with this name has already been uploaded.">
		</cfcatch>
	</cftry>

	<!--- if the file was successfully saved --->
	<cfif cffile.FileWasSaved>
		
		<!--- read the CSV-TXT file data --->
		<cffile action="read" file="#form.file_name#" variable="variables.CSVdata"> 
		
		<cftry>		
			<!--- import data --->			
			<cfquery name="importCSV" datasource="LEADGEN">

				<!--- loop through the CSV-TXT file on line breaks and insert into database --->
				<cfloop index="index" list="#variables.CSVdata#" delimiters="#chr(10)##chr(13)#">
					<cfset datetime = #ListGetAt('#index#', 1, ',')#>
					<cfset date = Mid(Replace(datetime, "-", "/", "all"), 2,11)>
					<cfset time = Mid(datetime, 13, 8)>
					<cfset datetime = DateFormat(date, "mm-dd-yyyy") & " " & TimeFormat(time, "hh:mm:ss tt")>									
					<cfset phone = Mid(ListGetAt('#index#', 2, ','), 2, 10)>		
					<cfset hold = Mid(ListGetAt('#index#', 3, ','), 2, 8)>				
						
					INSERT INTO CS_ABANDONED_CALLS (
						cac_date, 
						cac_phone, 
						cac_holdtime
					) VALUES (
						<cfqueryparam value="datetime" cfsqltype="cf_sql_timestamp">
						<cfqueryparam value="phone" cfsqltype="cf_sql_varchar">
						<cfqueryparam value="hold" cfsqltype="cf_sql_integer">
					)
				</cfloop>
				
				<cfset variables.success = true>
			</cfquery>			
				
			<cfif variables.success>	
				<cfset session.systemMessage = "Import successful">
			</cfif>
					
			<!--- catch import error --->	
			<cfcatch type = "any">
				<div align="center">
					<cfset session.systemMessage = "Error importing file. Check for the correct format and try again.">
					<cffile action = "delete" file = "#CurrentPath#\uploads\#CFFILE.clientFile#">
				</div>
			</cfcatch>
		</cftry>
	</cfif>
			
</cfif> 
</cfoutput>

<html>
<head>
	<title>CS Abandoned Calls Import</title>
</head>
<body>	
<cfoutput>
<div>#session.systemMessage#</div>
<div>
	<form method="post" action="#CGI.SCRIPT_NAME#" enctype="multipart/form-data" name="formupload">
		<h1>CS Abandoned Calls Import</h1>
		<div><input type="file" name="file_name"></div>
		<div><input type="submit" name="submit_upload" value="Upload and import csv file"></div>
	</form>
</div>
</cfoutput> 
</body>
</html>