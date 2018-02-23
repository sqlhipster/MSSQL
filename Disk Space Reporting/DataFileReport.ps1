Import-Module SQLPS -DisableNameChecking

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

#Path to central management server
#$serverGroupPath = "SQLSERVER:\SQLRegistration\Central Management Server Group\<CMSServerName>\<ServerGroup1>"
$serverGroupPath = "SQLSERVER:\SQLRegistration\Database Engine Server Group"
#$serverGroupPath = "SQLSERVER:\SQLRegistration\Database Engine Server Group\NorCal\IADTST-SQL01"
$HubbServerName = "LVEDWQA16"

#Get List of registered Servers from above path
$instanceNameList = dir $serverGroupPath -recurse | where {$_.mode -ne "d"} | select-object Name -unique

$scriptFile = "C:\PSScripts\DatabaseFileSizes.sql"
$scriptCommand = get-content($scriptFile)

  
foreach($instanceName in $instanceNameList) 
{
	$serverName = $instanceName.Name

    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = "server=$($serverName);Initial Catalog=master;Integrated Security=SSPI;"
    
    $FileCommand = $Connection.CreateCommand()
    $FileCommand.CommandText = $scriptCommand

        
    $DataAdapter = new-object System.Data.SqlClient.SqlDataAdapter $FileCommand

    $FileDT = new-object System.Data.DataTable
    
    Try
    {
        $DataAdapter.Fill($FileDT) | Out-Null
    }
    Catch
    {
        Write-Host "Could not load data from $serverName"
    }


    Write-DataTable –ServerInstance $HubbServerName –Database "DBA" –TableName “dbo.FileSizeLog” –Data $FileDT
    
    ##This method requires the most up to date PowerShell version 5.1 as of 1-31-2018
    #Write-SqlTableData -ServerInstance $HubbServerName -DatabaseName DBA -SchemaName dbo -TableName FileSizeLog -InputData $dtable

	#$Reader = Invoke-Sqlcmd -InputFile $scriptFile -ServerInstance $serverName -ConnectionTimeout 300
    #Invoke-Sqlcmd -Query "SELECT name from sys.databases" -ServerInstance $serverName -ConnectionTimeout 300

    #$Reader | format-table
    #Write-Output "Script Completed for $serverName"
	  
}