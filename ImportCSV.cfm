<!--- override the ColdFusion timeout setting because this page can be slow --->
<cfsetting requestTimeOut = "240">
<cfoutput>
<cfparam name="form.file_name" default="">
<cfparam name="variables.success" default=false>

<cfif IsDefined("form.submit_upload") AND form.file_name NEQ "">
	<cftry>	
		<cfparam name="CurrentPath" default="#GetDirectoryFromPath(GetCurrentTemplatePath())#">
		<cffile action="upload" fileField="form.file_name" destination="#CurrentPath#/Imports/CSAbandonedCalls/" nameConflict="Error">
		<cfcatch type="any">
			A file with this name has already been uploaded.
			<cfabort>
		</cfcatch>
	</cftry>

	<!--- if the file was successfully saved --->
	<cfif cffile.FileWasSaved>
		
		<!--- read the CSV-TXT file data --->
		<cffile action="read" file="#form.file_name#" variable="data"> 
		
		<cftry>		
			<!--- import data --->			
			<cfquery name="importCSV" datasource="LEADGEN">

				<!--- loop through the CSV-TXT file on line breaks and insert into database --->
				<cfloop index="index" list = "#data#" delimiters="#chr(10)##chr(13)#">
					<cfset datetime = #ListGetAt('#index#', 1, ',')#>
					<cfset date = Mid(Replace(datetime, "-", "/", "all"), 2,11)>
					<cfset time = Mid(datetime, 13, 8)>
					<cfset datetime = DateFormat(date, "mm-dd-yyyy") & " " & TimeFormat(time, "hh:mm:ss tt")>									
					<cfset phone = Mid(ListgetAt('#index#', 2, ','), 2, 10)>		
					<cfset hold = Mid(ListgetAt('#index#', 3, ','), 2, 8)>				
						
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
				<div align="center">
					Import successful<hr />
				</div>
			</cfif>
					
			<!--- catch import error --->	
			<cfcatch type = "any">
				<div align="center">
					Error importing file. Check for the correct format and try again.<hr />
					<cffile action = "delete" file = "#CurrentPath#\uploads\#CFFILE.clientFile#">
					</b>
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
<div align="center">
	<table cellpadding="5" cellspacing="0">
		<form method="post" action="#CGI.SCRIPT_NAME#" enctype="multipart/form-data" name="formupload">
			<tr>
				<td><h1>CS Abandoned Calls Import</h1></td>
			</tr>
			<tr>
				<td><input type="file" name="file_name"></td>
			</tr>
			<tr>
				<td><input type="submit" name="submit_upload" value="Upload and Import File"></td>
			</tr>
		</form>
	</table>
</div>
</cfoutput> 
</body>
</html>