Import-Module SQLPS -DisableNameChecking

param 
(
  [string] $ServerFile = "C:\PSScripts\AllServers.txt"
)

#Call the Write-DataTable function from ps1 script
function Write-DataTable 
{ 
    [CmdletBinding()] 
    param( 
    [Parameter(Position=0, Mandatory=$true)] [string]$ServerInstance, 
    [Parameter(Position=1, Mandatory=$true)] [string]$Database, 
    [Parameter(Position=2, Mandatory=$true)] [string]$TableName, 
    [Parameter(Position=3, Mandatory=$true)] $Data, 
    [Parameter(Position=4, Mandatory=$false)] [string]$Username, 
    [Parameter(Position=5, Mandatory=$false)] [string]$Password, 
    [Parameter(Position=6, Mandatory=$false)] [Int32]$BatchSize=50000, 
    [Parameter(Position=7, Mandatory=$false)] [Int32]$QueryTimeout=0, 
    [Parameter(Position=8, Mandatory=$false)] [Int32]$ConnectionTimeout=15 
    ) 
     
    $conn=new-object System.Data.SqlClient.SQLConnection 
 
    if ($Username) 
    { $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance,$Database,$Username,$Password,$ConnectionTimeout } 
    else 
    { $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout } 
 
    $conn.ConnectionString=$ConnectionString 
 
    try 
    { 
        $conn.Open() 
        $bulkCopy = new-object ("Data.SqlClient.SqlBulkCopy") $connectionString 
        $bulkCopy.DestinationTableName = $tableName 
        $bulkCopy.BatchSize = $BatchSize 
        $bulkCopy.BulkCopyTimeout = $QueryTimeOut 
        $bulkCopy.WriteToServer($Data) 
        $conn.Close() 
    } 
    catch 
    { 
        $ex = $_.Exception 
        Write-Error "$ex.Message" 
        continue 
    } 
 
} #Write-DataTable


$serverGroupPath = "SQLSERVER:\SQLRegistration\Database Engine Server Group"
$HubbServerName = "LVEDWQA16"
$instanceNameList = dir $serverGroupPath -recurse | where {$_.mode -ne "d"} | select-object Name -unique

$servers = Get-Content $ServerFile
$DiskSpaceDT = new-object System.Data.DataTable

foreach ($instanceName in $instanceNameList)
{
    $server = $instanceName.Name

    write-host $server

    $TableName = $server
    $table = New-Object system.Data.DataTable “$server”

    $col1 = New-Object system.Data.DataColumn Server,([string])
    $col2 = New-Object system.Data.DataColumn Drive,([string])
    $col3 = New-Object system.Data.DataColumn Size,([decimal])
    $col4 = New-Object system.Data.DataColumn Used,([decimal])
    $col5 = New-Object system.Data.DataColumn Free,([decimal])
    $col6 = New-Object system.Data.DataColumn PercentFree,([int])

    $table.columns.add($col1)
    $table.columns.add($col2)
    $table.columns.add($col3)
    $table.columns.add($col4)
    $table.columns.add($col5)
    $table.columns.add($col6)

    $drives = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $TableName

    $drives | ? {$_.DriveType -eq 3 } | % {$row = $table.NewRow();$row.Server = $server; $row.Drive = $_.DeviceID ; $row.Size = “{0:F3}” -f($_.Size/1gb) ; $row.Used = “{0:F3}” -f (($_.Size/1gb)-($_.FreeSpace/1gb)) ; $row.Free = “{0:F3}” -f ($_.FreeSpace/1gb); $row.PercentFree = “{0:F3}” -f ($_.FreeSpace/1gb) / ($_.Size/1gb) * 100 ;$table.Rows.Add($row) }

    #$table| format-table -AutoSize

    Write-DataTable –ServerInstance "LVEDWQA16" –Database "DBA" –TableName “dbo.DiskSpaceLog” –Data $table
}

#$table| format-table -AutoSize

