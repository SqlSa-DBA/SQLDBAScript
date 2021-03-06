# I'm wrapping everything into a function, it's just easier to reuse
function GenerateSPsScript([string]$serverName, [string]$dbname, [string]$scriptpath)
{
  # Lets load the SMO assembly first (this is basically a collection of SQL Server related objects)
  [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
   
  # Lets initiate a SQL server object
  $srv = New-Object "Microsoft.SqlServer.Management.SMO.Server" $serverName
   
  # Lets prepare a Database object and connect to it
  $db = New-Object "Microsoft.SqlServer.Management.SMO.Database"
  $db = $srv.Databases[$dbname] 
   
  # And finally lets create a Scripter object
  $scr = New-Object "Microsoft.SqlServer.Management.SMO.Scripter"
  $scr.Server = $srv
   
  # Now we can prepare the options for the Scripter object. Check this web site for the details:
  # https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.scriptingoptions.aspx
  $options = New-Object "Microsoft.SqlServer.Management.SMO.ScriptingOptions"
  $options.AllowSystemObjects = $false
  $options.IncludeDatabaseContext = $false
  $options.IncludeIfNotExists = $false
  $options.Default = $true
  $options.IncludeHeaders = $false
  $options.ToFileOnly = $true
  $options.AppendToFile = $true
   
  # Lets set the option of the target file name and create a text file where the SPs code will be exported
  $options.FileName = $scriptpath + "\$($dbname)_modified_stored_procs_$(get-date -f yyyy-MM-dd).sql"
  New-Item $options.FileName -type file -force | Out-Null
   
  # now apply the above options to the SMO.Scripter object
  $scr.Options = $options
   
  # OK, connection and settings are ready. Now we can start working with the database objects
  # We want to work with the Stored Procedures, so lets grab all the non-system SPs
  $StoredProcedures = $db.StoredProcedures | where {$_.IsSystemObject -eq $false}
   
  # Say you need to export only the SPs that were modified during the last 7 days
  $cd = Get-Date
  $d = $cd.AddDays(-7)
   
  # Now for every SP we will execute the Script method
  Foreach ($StoredProcedure in $StoredProcedures)
  {
    if ($StoredProcedures -ne $null -and $StoredProcedure.DateLastModified -ge $d)
    {   
      # Script the Stored Procedure
      $scr.Script($StoredProcedure)
    }
  }
} 
# Function is completed
 
# Finally we call the above function by putting our environment details
GenerateSPsScript "SQLServer\InstanceName" "DatabaseName" "D:\ExportFolder"
# If you have a default instance then just put the server name