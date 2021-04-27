<!--- override the ColdFusion timeout setting because this page can be slow --->
<cfsetting requestTimeOut = "240">
<cfoutput>
<cfparam name="FORM.file_name" default="NULL">
	
<cfif IsDefined("FORM.submit_upload") AND form.file_name NEQ "">
	<cftry>	
		<cfparam name="CurrentPath" default="#GetDirectoryFromPath(GetCurrentTemplatePath())#">
		<cffile action="upload" fileField="file_name" destination="#CurrentPath#/Imports/CSAbandonedCalls/" nameConflict="Error">
		<cfcatch type="any">
			A file with this name has already been uploaded.
			<cfabort>
		</cfcatch>
	</cftry>

	<!--- if the file was successfully saved --->
	<cfif CFFILE.FileWasSaved>
		
		<!--- read the CSV-TXT file data --->
		<cffile action="read" file="#FORM.file_name#" variable="data"> 
		
		<cftry>		
			<!--- import data --->			
			<cfquery name="importCSV" datasource="LEADGEN">

				<!--- loop through the CSV-TXT file on line breaks and insert into database --->
				<cfloop index="index" list = "#data#" delimiters="#chr(10)##chr(13)#">
					<cfset datetime = #listgetAt('#index#', 1, ',')#>
					<cfset date = mid(Replace(datetime, "-", "/", "all"), 2,11)>
					<cfset time = mid(datetime, 13, 8)>
					<cfset datetime = DateFormat(date, "mm-dd-yyyy") & " " & TimeFormat(time, "hh:mm:ss tt")>									
					<cfset phone = mid(listgetAt('#index#', 2, ','), 2, 10)>		
					<cfset hold = mid(listgetAt('#index#', 3, ','), 2, 8)>				
						
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
				
				<cfset import_success = "yes">
			</cfquery>

			<!--- display success message --->
			<cfparam name="import_success" default="">
				
			<cfif import_success EQ "yes">	
				<div align="center">
					<b style="color: ##F00">Import successful</b><hr />
					<cfset import_success = "">
				</div>
			</cfif>
					
			<!--- catch import error --->	
			<cfcatch type = "any">
				<div align="center">
					<b style="color: ##F00">Error importing file. The file is probably not in the expected format.<hr />
					<cffile action = "delete" file = "#CurrentPath#\uploads\#CFFILE.clientFile#">
					<cfif FileExists("#CurrentPath#\uploads\#CFFILE.clientFile#")>
						<br />There was an error and the file was not deleted. You will have to rename your file before trying again.<hr />
					</cfif>		
					<cfset import_success="">
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
	<style type="text/css" media="all">
		body { 
			background-color: #fff; 
			color: #000; 
			padding: 1em; 
			margin: 0; 
			font-family: Verdana, Arial, Helvetica, Sans-Serif; 
		}
		h1 {
			font-size:16px;
		}
	</style>
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
