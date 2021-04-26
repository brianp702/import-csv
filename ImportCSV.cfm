<!--- override the ColdFusion timeout setting because this page can be slow --->
<cfsetting requestTimeOut = "240">
<cfoutput>
<cfparam name="form.file_name" default="NULL">
	
<cfif isdefined("form.submit_upload") AND form.file_name NEQ "">
	<cftry>	
		<cfparam name="CurrentPath" default="#GetDirectoryFromPath(GetCurrentTemplatePath())#">
		<cffile action = "upload" fileField = "file_name" destination = "#CurrentPath#/Imports/CSAbandonedCalls/" nameConflict = "Error"><!--- get and read the CSV-TXT file --->
		<cfcatch type="any">
			A file with this name has already been uploaded.
			<cfabort>
		</cfcatch>
	</cftry>
	
	<cfif CFFILE.FileWasSaved><!--- if the file was successfully saved --->
		
		<!--- read the CSV-TXT file data --->
		<cffile action="read" file="#file_name#" variable="data"> 
		
		<cftry>		
			<!--- import data --->			
			<cfquery name="importcsv" datasource="LEADGEN">

					<!--- loop through the CSV-TXT file on line breaks and insert into database --->
					<cfloop index="index" list = "#data#" delimiters="#chr(10)##chr(13)#">
						<!--- get datetime, extract the date and time, format them in SQL "datetime" format --->
						<cfset datetime = #listgetAt('#index#', 1, ',')#>
						<cfset date = mid(Replace(datetime, "-", "/", "all"), 2,11)><!--- extracts date, replaces "-" with "/"> --->
						<cfset time = mid(datetime, 13, 8)><!--- extracts time from datetime --->
									
						<cfset date = DateFormat(date, "mm-dd-yyyy")>
						<cfset time = TimeFormat(time, "hh:mm:ss tt")>
						<cfset datetime = date & " " & time>
								
						<!--- extract the phone number --->				
						<cfset  phone = mid(#listgetAt('#index#', 2, ',')#, 2, 10)>
							
						<!--- extract the hold time --->			
						<cfset  hold = mid(#listgetAt('#index#', 3, ',')#, 2, 8)>				
							
						INSERT INTO CS_ABANDONED_CALLS (
							cac_date, 
							cac_phone, 
							cac_holdtime
						) VALUES (
							'#datetime#',
							'#phone#',
							'#hold#'
						)
					</cfloop>
					
					<cfset import_success = "yes">					    
			</cfquery>

			<!--- display success message --->
			<cfparam name="import_success" default = "NULL">
				
			<cfif import_success EQ "yes">	
				<div align="center">
					<b style="color: ##F00">Import successful</b><hr />
					<cfset import_success = "NULL">
				</div>
			</cfif>
					
			<!--- catch database error --->	
			<cfcatch type = "any">
				<div align="center">
					<b style="color: ##F00">Error importing file. The file is probably not in the expected format.<hr />
					<cffile action = "delete" file = "#CurrentPath#\uploads\#CFFILE.clientFile#">
					<cfif FileExists("#CurrentPath#\uploads\#CFFILE.clientFile#")>
						<br />There was an error and the file was not deleted. You will have to rename your file before trying again.<hr />
					</cfif>		
					<cfset import_success = "NULL">
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
