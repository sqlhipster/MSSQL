 #************************
# & "DatabaseHealthReport.ps1" "AllServers.txt"
#************************
#& "C:\PSScripts\DatabaseHealthReport.ps1" "C:\PSScripts\AllServers.txt"

#Import-Module -Name Utility

param 
(
  [string] $ServerFile = "C:\PSScripts\AllServers.txt",
  [string] $DBQueryPath = "C:\PSScripts\DatabaseHealthReport_query.sql",
  [string] $JobQueryPath = "C:\PSScripts\JobHealthReport_query.sql",
  [string] $SMTPServer = "mail.mechanicsbank.com",
  [string] $Subject = "MSSQL Daily Health Report",
  [string] $From = "Mechanics-HealthCheck@mechanicsbank.com",
  [string] $To = "matthew_potter@mechanicsbank.com",
  [string] $DiskQueryPath = "C:\PSScripts\DiskHealthReport_query.sql"
  
)

function SendEmail_w_Attachment
{
param(
	[string]$MailServer,
	[string]$MailSubject,
	[string]$MailFrom,
	[string]$MailTo,
	[string]$MailBody,
	[string]$MailAttachment,
	[string]$MailAttachmentName
)
	$SMTPClient = new-object system.net.mail.smtpClient $MailServer
	$Message = new-Object system.net.mail.mailmessage $MailFrom, $MailTo, $MailSubject, $MailBody
	$Message.isBodyhtml = $true
	
	if($MailAttachment.Length -gt 0)
	{
		#Get attachment string into stream - don't need to write it to a file
		$AttachByte = [System.Text.Encoding]::ASCII.GetBytes($MailAttachment)
		[reflection.assembly]::LoadWithPartialName("System.IO") | Out-Null
		$AttachStream = New-Object System.IO.MemoryStream	
		$AttachStream.Write($AttachByte, 0, $AttachByte.Length)
		$AttachStream.Seek(0, [system.Io.SeekOrigin]::Begin) | Out-Null
		$AttachObject = New-Object system.Net.Mail.Attachment($AttachStream, "$MailAttachmentName.html", "text/html")
		
		$Message.attachments.add($AttachObject)
	}
	
	$SMTPClient.Send($Message)
	$Message.dispose()
}

$DBHeader = "<tr bgcolor=`"#DEDEDE`"><td>Database</td><td>Recovery<br>Model</td><td>Last<br>Full Backup</td>"+`
		"<td>Last<br>Tran Backup</td><td>Data <br>File Size(GB)</td><td>Log File<br>Size (GB)</td>"+`
		"<td>Last Successful<br>CheckDB</td><td>VLF Count</td><td>AutoClose</td><td>AutoShrink</td><td>State</td><td>Deadlocks</td><td>Blocks</td></tr>"

$JobHeader = "<tr bgcolor=`"#DEDEDE`"><td>Job Name</td><td>Job Enabled?</td><td>Execution<br>Status</td>"+`
		"<td>Duration</td><td>Execution<br>Time</td></tr>"
		
$DiskHeader = "<tr bgcolor=`"#DEDEDE`"><td>MountName</td><td>Capacity(GB)</td><td>FreeSpzce(GB)</td>"+`
		"<td>% Free</td></tr>"

$htmlstring_Server = "<tr bgcolor=#DEDEDE><th colspan=4>SQL Instance</th></tr>"
$htmlstring = "<tr bgcolor=#DEDEDE><th colspan=2>SQL Instance</th></tr>"

$servers = Get-Content $ServerFile
$DBHealthCommand = [string]::join([environment]::newline, (get-content $DBQueryPath ))
$JobHealthCommand = [string]::join([environment]::newline, (get-content $JobQueryPath ))
$DiskHealthCommand = [string]::join([environment]::newline, (get-content $DiskQueryPath ))
$OSDisk = @{}

foreach ($server in $Servers)
{
	$connString = "Data Source=$server;Initial Catalog=master;Integrated Security=SSPI;Application Name=Daily Health Report from $LocalOS"
	
	$serverseverity = 0
	$dbseverity = 0
	$jobseverity = 0
	$diskseverity = 0
	
	$dbda = new-object System.Data.SqlClient.SqlDataAdapter ($DBHealthCommand, $connString)
	$dbda.SelectCommand.CommandTimeout = 120
	$dbdt = new-object System.Data.DataTable
	try{
		$dbda.fill($dbdt) | out-null
		}
	catch
	{
		#Set-Variable -Name $Exception -Value $_. -Scope "Script"
		$dbseverity = 5
	}

	$jobda = new-object System.Data.SqlClient.SqlDataAdapter ($JobHealthCommand, $connString)
	$jobda.SelectCommand.CommandTimeout = 120
	$jobdt = new-object System.Data.DataTable
	try{
		$jobda.fill($jobdt) | out-null
		}
	catch
	{
		#Set-Variable -Name $Exception -Value $_. -Scope "Script"
		$jobseverity = 5
	}
	
	
	$diskda = new-object System.Data.SqlClient.SqlDataAdapter ($DiskHealthCommand, $connString)
	$diskda.SelectCommand.CommandTimeout = 120
	$diskdt = new-object System.Data.DataTable
	try{
		$diskda.fill($diskdt) | Out-Null
		}
	catch
	{
		#Set-Variable -Name $Exception -Value $_. -Scope "Script"
		$diskseverity = 5
	}
	
	if ($dbseverity -ne 5)
	{
	$DBString = $(foreach ($row in $dbdt){`
		"<tr>"+`
		$(if($row.IsReadOnly -eq $true){
			if($row.SnapOfDB -eq ""){"<td class=snap>"+$row.DBName+"<br><span class=undertype>Read-Only</span>"}
			else {"<td class=readonly>"+$row.DBName+"<br><span class=undertype>Snapshot of "+$row.SnapOfDB+"</span>"}
		}else{"<td>"+$row.DBName}
			)+`
		"</td><td>"+$row.RecoveryModel+`
		"</td><td "+$(If(($row.DBName -ne "tempdb") -and ($row.State_Ignore -ne 1) -and ($row.LastFullBackupThresholdDays -ne -1000) -and ($row.LastFullBackup -lt [datetime]::Now.AddDays($row.LastFullBackupThresholdDays)) -and ($row.SnapOfDB -eq "")){"class=sev5";$dbseverity=5})+">"+$row.LastFullBackup+`
		"</td><td "+$(If(($row.DBNAme -ne "tempdb") -and ($row.DBNAme -ne "model") -and ($row.LastTransBackup_Threshold_Hours -ne -1000) -and ($row.State_Ignore -ne 1) -and ($row.RecoveryModel -ne "SIMPLE") -and (($row.LastTranBackup -lt $row.LastFullBackup) -or ($row.LastTranBackup -lt [datetime]::Now.AddHours($row.LastTransBackup_Threshold_Hours)))){"class=sev5";$dbseverity=5})+">"+$row.LastTranBackup+`
		"</td><td>"+$("{0:N2}" -f $row.DataSize)+`
		"</td><td>"+$("{0:N2}" -f $row.LogSize)+`
		"</td><td "+$(If(($row.DBName -ne "tempdb") -and ($row.State_Ignore -ne 1) -and ($row.LastSuccessfulCheckDB -lt [DateTime]::Now.AddDays($row.LastSuccessfulCheckDB_Threshold_Days)) -and ($row.IsReadOnly -ne $true)){"class=sev5";$dbseverity=5})+">"+$row.LastSuccessfulCheckDB+`
		"</td><td "+$(If($row.VLFCount -gt $row.VLF_Threshold_Yellow){if($row.VLFCount -lt $row.VLF_Threshold_Orange){"class=sev1";if($dbseverity -lt 1){$dbseverity=1}}else{"class=sev2";if(($dbseverity -lt 2) -and ($row.VLFCount -gt $row.VLF_Threshold_Orange)){$dbseverity=2} }})+">"+$row.VLFCount+`
		"</td><td "+$(If(($row.IsAutoClose -eq 1) -and ($row.AutoClose_Ignore -eq 0)){"class=sev2";if($dbseverity -lt 2){$dbseverity=2}})+">"+$row.IsAutoClose+`
		"</td><td "+$(If(($row.IsAutoShrink -eq 1) -and ($row.AutoShrink_Ignore -eq 0)){"class=sev3";if($dbseverity -lt 3){$dbseverity=3}})+">"+$row.IsAutoShrink+`
		"</td><td "+$(If(($row.DBState -ne "ONLINE") -and ($row.State_Ignore -ne 1)){"class=sev5";if($dbseverity -lt 5){$dbseverity=5}})+">"+$row.DBState+`
        "</td><td "+$(If($row.Deadlock_Count -gt $row.Deadlock_Threshold_Count){"class=sev5";if($dbseverity -lt 5){$dbseverity=2}})+">"+$row.Deadlock_Count+`
        "</td><td "+$(If($row.Block_Count -gt $row.Block_Threshold_Count){"class=sev5";if($dbseverity -lt 5){$dbseverity=2}})+">"+$row.Block_Count+`
		"</td></tr>"})

	$DBString = $DBHeader + $DBString + "</table></td></tr>"
	}
	else
	{
		$DBString = "</table></td></tr>"
	}
	
	if($jobseverity -ne 5)
	{
	$jobString = $(foreach($row in $jobdt)`
	{ if($row.JobName -ne $LastJobName){$ExecutionCount = 0;$LastJobName = $row.JobName}else{$ExecutionCount = $ExecutionCount+1};if($row.RunStatus -ne 1){"<tr><td>$($row.JobName)</td><td>$($row.JobEnabled)</td>"+`
	"<td "+$(if($row.RunStatus -ne 1){if(($ExecutionCount -eq 0) -and ($row.JobName -Match "HOST_*")){"class=sev5";$jobseverity = 5}else{"class=sev4";if($jobseverity -lt 4){$jobseverity=2}}})+">$($row.RunStatus_Descr)</td>"+`
	"<td>"+$($duration = $row.DurationSeconds;if($duration -lt 60){"$duration seconds"}elseif($duration -ge 60 -and $duration -lt 3600){$("{0:N2}" -f $($duration / 60))+" minutes"}else{$("{0:N2}" -f $($duration / 3600))+" hours"})+"</td>"+`
	"<td>$($row.RunDateTime)</td></tr>"}
	}
	)
	
	$jobString = $JobHeader + $jobString + "</table></td></tr>"
	}
	else
	{
		$JobString = "</table></td></tr>"
	}
	
	if($diskseverity -ne 5)
	{
	
		$Volumes = @()
		
		$diskString = $DiskHeader
        
		$OS = ""
		
		foreach($row in $diskdt)
		{ 
			if($OS -eq "")
			{
				$OS = $row.HostOS
                
                #Write-Host $OS
				try
				{
					$RealOS = (gwmi -ComputerName $OS -Class Win32_ComputerSystem -ErrorAction Stop)
					$OS = $RealOS.Name
				
					Get-WmiObject -ComputerName $OS -Class Win32_Volume -Filter 'DriveType = 3' -ErrorAction Stop | %{$Volumes+= $_}
					if($OSDisk.ContainsKey($OS) -eq $false)
					{
						$OSList = @()
						$Volumes | %{$OSList += $_}
						$OSDisk.Add($OS, $OSList)
					}
				}
				catch
				{
					$OSDisk.Add($OS, $null)
					$diskseverity = 5
				}
			}
			
			$ThisVolume = $($Volumes | ?{$_.Name -eq $row.SubPath})
			if($ThisVolume -ne $null)
			{
                Write-Host $ThisVolume.Name.Trim()
				$PctFree = ($ThisVolume.FreeSpace/$ThisVolume.Capacity)*100
				$localdiskseverity = 0
				
                if($PctFree -le 5){$localdiskseverity=5}
				if($PctFree -gt 5 -and $PctFree -le 7 -and $localdiskseverity -lt 4){$localdiskseverity=2}
				if($PctFree -gt 7 -and $PctFree -le 10 -and $localdiskseverity -lt 3){$localdiskseverity=1}
				#if($PctFree -gt 15 -and $PctFree -le 20 -and $localdiskseverity -lt 2){$localdiskseverity=2}
				#if($PctFree -gt 20 -and $PctFree -le 25 -and $localdiskseverity -lt 1){$localdiskseverity=1}
                
				
				$diskString = $diskstring + "<tr class=sev$localdiskseverity><td>"+$ThisVolume.Name.Trim()+"</td><td>"+$("{0:N2}" -f ($ThisVolume.Capacity/1073741824))+"</td><td>"+$("{0:N2}" -f ($ThisVolume.FreeSpace/1073741824))+"</td><td>"+$("{0:N2}" -f ($ThisVolume.FreeSpace/$ThisVolume.Capacity*100))+"</td></tr>"		
			
				if($localdiskseverity -gt $diskseverity){$diskseverity = $localdiskseverity}
			}	
		}
		
		$diskString = $diskString + "</table></td></tr>"
	}
	else
	{
		$diskString = "</table></td></tr>"
	}
	
	
	
	$maxseverity = 0
	($dbseverity, $jobseverity, $diskseverity) | %{if($_ -gt $maxseverity){$maxseverity = $_}}
	
	
		
	$htmlstring = $htmlstring + "<tr><th class=sev"+$maxseverity+"><span onClick=`"toggle('"+$server.replace("\", "_")+"');`">"+$server+"</th><td style=`"display: ;`" id = `""+$server.replace("\", "_")+"`"><table>"+`
		"<tr><th class=sev"+$dbseverity+"><span onClick=`"toggle('"+$server.replace("\", "_")+"_DB');`">"+"Databases"+"</th><td style=`"display: none;`" id = `""+$server.replace("\", "_")+"_DB`"><table>"+$DBstring+`
		"<tr><th class=sev"+$jobseverity+"><span onClick=`"toggle('"+$server.replace("\", "_")+"_JOB');`">"+"Agent Jobs"+"</th><td style=`"display: none;`" id = `""+$server.replace("\", "_")+"_JOB`"><table>"+$jobstring+`
		"<tr><th class=sev"+$diskseverity+"><span onClick=`"toggle('"+$server.replace("\", "_")+"_DISK');`">"+"Disk"+"</th><td style=`"display: none;`" id = `""+$server.replace("\", "_")+"_DISK`"><table>"+$diskString+"</table>"
	
	$htmlstring_Server = $htmlstring_Server + "<tr><th class=sev"+$maxseverity+">"+$server+"</th>"+`
	"<th class=sev"+$dbseverity+">DB</th>"+`
	"<th class=sev"+$jobseverity+">JOBS</th>"+`
	"<th class=sev"+$diskseverity+">DISK</th></tr>"
	
	

}

$head = "<HTML><HEAD>
<style>
	body{font-family:Calibri; background-color:white;}
	table{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
	th{font-size:1.3em; border-width: 1px;padding: 2px;border-style: solid;border-color: black;vertical-align:text-top;}
	td{border-width: 1px;padding: 2px;border-style: solid;border-color: black;vertical-align:text-top;}
	td.sev0{background-color: #009900}
	td.sev1{background-color: #FFFF00}
	td.sev2{background-color: #FFCC00}
	td.sev3{background-color: #FF9900}
	td.sev4{background-color: #FF6600}
	td.sev5{background-color: #FF0000}
	
	th.sev0{background-color: #009900}
	th.sev1{background-color: #FFFF00}
	th.sev2{background-color: #FFCC00}
	th.sev3{background-color: #FF9900}
	th.sev4{background-color: #FF6600}
	th.sev5{background-color: #FF0000}
	
	tr.sev0{background-color: #009900}
	tr.sev1{background-color: #FFFF00}
	tr.sev2{background-color: #FFCC00}
	tr.sev3{background-color: #FF9900}
	tr.sev4{background-color: #FF6600}
	tr.sev5{background-color: #FF0000}
	
	td.snap{background-color: #9B9B9B}
	td.readonly{background-color: #3399FF}
	span.undertype{font-size:70%;font-style:italic}

</style>
<script type=`"text/javascript`">
   function toggle(ControlID) 
   {
		var control = document.getElementById(ControlID); 
		if( control.style.display =='none' )
		{
   			control.style.display = '';
 		}
		else
		{
   			control.style.display = 'none';
 		}
	}
</script>
<TITLE>SQL Server Health Check</TITLE></HEAD>
<body><table>
"

#OS Disk Usages
	$htmlstring = $htmlstring + "</table><br><table><tr bgcolor=#DEDEDE><th colspan=2>OS</th></tr>"
	$htmlstring_Server = $htmlstring_Server + "</table><br><table><tr bgcolor=#DEDEDE><th colspan=2>OS Stats</th></tr>"
	
	foreach($OSServer in ($OSDisk.Keys | sort))
	{
		$diskString = $diskheader
		
		$diskseverity = 0
		
		if($OSDisk[$OSServer].Count -eq $null)
		{
			$diskseverity = 5
		}
		else
		{
			foreach($ThisVolume in ($OSDisk[$OSServer]| sort @{Expression='Name'; Descending=$false }))
			{
				if($ThisVolume.Capacity -gt 0)
				{
					$PctFree = ($ThisVolume.FreeSpace/$ThisVolume.Capacity)*100
				}
				else
				{
					$PctFree=100
				}
					$localdiskseverity = 0
				
				if($PctFree -le 5){$localdiskseverity=5}
				if($PctFree -gt 5 -and $PctFree -le 7 -and $localdiskseverity -lt 4){$localdiskseverity=2}
				if($PctFree -gt 7 -and $PctFree -le 10 -and $localdiskseverity -lt 3){$localdiskseverity=1}
				#if($PctFree -gt 15 -and $PctFree -le 20 -and $localdiskseverity -lt 2){$localdiskseverity=2}
				#if($PctFree -gt 20 -and $PctFree -le 25 -and $localdiskseverity -lt 1){$localdiskseverity=1}
				
				if($localdiskseverity -gt $diskseverity){$diskseverity = $localdiskseverity}
				
				$diskString = $diskstring + "<tr class=sev$localdiskseverity><td>"+$ThisVolume.Name.Trim()+"</td><td>"+$("{0:N2}" -f ($ThisVolume.Capacity/1073741824))+"</td><td>"+$("{0:N2}" -f ($ThisVolume.FreeSpace/1073741824))+"</td><td>"+$("{0:N2}" -f ($PctFree))+"</td></tr>"		
			
			}
		}
			
		$maxseverity = 0
		($diskseverity, 0) | %{if($_ -gt $maxseverity){$maxseverity = $_}}
		
		
		$htmlstring = $htmlstring + "<tr><th class=sev$maxseverity><span onClick=`"toggle('"+$OSServer.replace("\", "_")+"_OS');`">"+$OSServer+"</th><td style=`"display: ;`" id = `""+$OSServer.replace("\", "_")+"_OS`"><table>"
		$htmlstring = $htmlstring + "<tr><th class=sev$diskseverity><span onClick=`"toggle('"+$OSServer.replace("\", "_")+"_OS_DISK');`">"+"Disk"+"</th><td style=`"display: none;`" id = `""+$OSServer.replace("\", "_")+"_OS_DISK`"><table>"+$diskString+"</table></table>"
		
		$htmlstring_server = $htmlstring_server +  "<tr><th class=sev$maxseverity>"+$OSServer+"</th>"+`
			"<th class=sev$diskseverity>DISK</th></tr>"
	}


$now = Get-Date
$foot = "</table><br>Report ran at " + $now + ".</i></body></html>"

<#
Severity 5 (Red)
	No Full Backup within 3 days
	No t-log backup since last full or within 24 hours
	DB State <> Online
	No Successful CheckDB within 7 days
	No Rows Returned
	No Jobs returned
	Job exists Most recent job execution within 24 hours not successful
	Free Disk Space < 5%

Severity 4 (Red-Orange)
	Job exists with non-successful run within 24 hours, but most recent successful
	Free Disk Space < 10% but greater than 5%
	
Severity 3 (Orange)
	AutoShrink Enabled
	Free Disk Space < 15% but greater than 10%

Severity 2 (Yellow-Orange)
	VLFCount > 500
	AutoClose Enabled
	Free Disk Space < 20% but greater than 15%

Severity 1 (Yellow)
	VLFCount between 200 and 500
	Free Disk Space < 25% but greater than 20%

Severity 0 (Green)
#>

$legend = "
<Br>
<br>
<table><tr><td><span onClick=`"toggle('LEGEND');`">Legend</span></td><td id=`"LEGEND`" style=`"display:none ;`">
<table>
<!--Severity 5 (Red)-->
	<tr><td class=sev5>No Full Backup within 3 days</td></tr>
	<tr><td class=sev5>No t-log backup since last full or within 24 hours</td></tr>
	<tr><td class=sev5>DB State <> Online</td></tr>
	<tr><td class=sev5>No Successful CheckDB within 7 days</td></tr>
	<tr><td class=sev5>No Rows Returned</td></tr>
	<tr><td class=sev5>No Jobs returned</td></tr>
	<tr><td class=sev5>Most recent job execution within 24 hours not successful</td></tr>
	<tr><td class=sev5>Free Disk Space < 5%</td></tr>
    <tr><td class=sev5>More than 100 Deadlocks in one day</td></tr>

<!--Severity 4 (Red-Orange)-->
	<tr><td class=sev4>Job exists with non-successful run within 24 hours, but most recent successful</td></tr>
	<tr><td class=sev4>Free Disk Space < 10% but greater than 5%</td></tr>
	
<!--Severity 3 (Orange)-->
	<tr><td class=sev3>AutoShrink Enabled
	<tr><td class=sev3>Free Disk Space < 15% but greater than 10%</td></tr>

<!--Severity 2 (Yellow-Orange)-->
	<tr><td class=sev2>VLFCount > 500</td></tr>
	<tr><td class=sev2>AutoClose Enabled</td></tr>
	<tr><td class=sev2>Free Disk Space < 20% but greater than 15%</td></tr>

<!--Severity 1 (Yellow)-->
	<tr><td class=sev1>VLFCount between 200 and 500</td></tr>
	<tr><td class=sev1>Free Disk Space < 25% but greater than 20%</td></tr>

<!--Severity 0 (Green)-->
	<tr><td class=sev0>No monitored condition exists</td></tr>
</table>
</td>
</tr>
</table>
"

$htmlbody = $head+$htmlstring_server+$foot
$attachment = $head+$htmlstring+$foot+$legend

#Write-Host $SMTPServer
#Write-Host $Subject
#Write-Host $From
#Write-Host $To

#SendEmail_w_Attachment -MailBody $htmlbody -MailAttachment $attachment -MailServer $SMTPServer -MailSubject $Subject -MailFrom $From -MailTo $To -MailAttachmentName "DatabaseHealthReport"

Out-File -FilePath "C:\PSScripts\DatabaseHealthReport.htm" -InputObject $attachment

exit 0

