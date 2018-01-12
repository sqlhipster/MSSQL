SET NOCOUNT ON

INSERT INTO [DBA].[dbo].[DailyHealthReport_Overrides]             
([DatabaseName]
,[LastFullBackupThresholdDays]             
,[LastTransBackup_Threshold_Hours]             
,[LastSuccessfulCheckDB_Threshold_Days]             
,[VLF_Threshold_Yellow]             
,[AutoClose_Ignore]             
,[AutoShrink_Ignore]             
,[State_Ignore]             
,[Deadlock_Threshold_Count]             
,[Block_Threshold_Count]             
,[VLF_Threshold_Orange])  
Select name, -8, -24, -8, 200, 0, 0, 0, 100, 100, 200 
	from [master].sys.databases 
	where name not in (select databasename from dba.dbo.DailyHealthReport_Overrides) 

CREATE TABLE #DBInfo_LastKnownGoodCheckDB
    (
      ParentObject varchar(1000) NULL,
      Object varchar(1000) NULL,
      Field varchar(1000) NULL,
      Value varchar(1000) NULL,
      DatabaseName varchar(1000) NULL
    )
 
CREATE TABLE #DBInfo_VLF
    (
      RecoveryUnitID int,
	  FileID int,
      FileSize bigint,
      StartOffset bigint,
      FSeqNo int,
      Status tinyint,
      Parity bigint,
      CreateLSN varchar(8000),
      DatabaseName sysname null
    )

--Gather Database Info
DECLARE @DatabaseName varchar(1000),
    @SQL varchar(8000),
    @VersionTick BIT,
    @State_Desc NVARCHAR(60)

IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS varchar(1000)), 1) = '9' 
    SET @VersionTick = 1
ELSE 
    BEGIN
        IF LEFT(CAST(SERVERPROPERTY('ProductVersion') AS varchar(1000)), 2) = '10' 
            SET @VersionTick = 1
        ELSE 
            SET @VersionTick = 0
    END


--Gather Deadlock Info    
Declare @DL_Date int
Declare @DL_Date_Str nvarchar(300)
Declare @DL_Month nvarchar(2)
Declare @DL_Day nvarchar(2)

If Len(Cast(Month(DateAdd(day, -1,Getdate())) as nvarchar(2))) = 1
	Begin
		Set @DL_Month = '0' + Cast(Month(DateAdd(day, -1,Getdate())) as nvarchar(2))
	End
Else
	Begin
		Set @DL_Month = Cast(Month(DateAdd(day, -1,Getdate())) as nvarchar(2))
	End
	
If Len(Cast(Day(DateAdd(day, -1,Getdate())) as nvarchar(2))) = 1
	Begin
		Set @DL_Day = '0' + Cast(Day(DateAdd(day, -1,Getdate())) as nvarchar(2))
	End
Else
	Begin
		Set @DL_Day = Cast(Day(DateAdd(day, -1,Getdate())) as nvarchar(2))
	End

Set @DL_Date_Str = Cast(Year(DateAdd(day, -1,Getdate())) as nvarchar(4)) + @DL_Month + @DL_Day
	
Set @DL_Date = Cast(@DL_Date_Str as int)    


--Loop Through databases
DECLARE csrDatabases CURSOR FAST_FORWARD LOCAL
    FOR SELECT  name,
                state_desc
        FROM    sys.databases
        WHERE   name NOT IN ( 'tempdb' ) and database_id < 5

OPEN csrDatabases

FETCH NEXT FROM csrDatabases INTO @DatabaseName, @State_Desc

WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @State_Desc = 'ONLINE' 
            BEGIN
                IF @VersionTick = 1 
                    BEGIN
	    --Create dynamic SQL to be inserted into temp table
                        SET @SQL = 'DBCC DBINFO (' + CHAR(39) + @DatabaseName + CHAR(39) + ') WITH TABLERESULTS'
	
	    --Insert the results of the DBCC DBINFO command into the temp table
                        INSERT  INTO #DBInfo_LastKnownGoodCheckDB
                                (
                                  ParentObject,
                                  Object,
                                  Field,
                                  Value
                                )
                                EXEC ( @SQL
                                    )
									
	    --Set the database name where it has yet to be set
                        UPDATE  #DBInfo_LastKnownGoodCheckDB
                        SET     DatabaseName = @DatabaseName
                        WHERE   DatabaseName IS NULL
                    END	    
    --Insert the results of DBCC LOGINFO
                SET @SQL = 'DBCC LOGINFO(' + CHAR(39) + @DatabaseName + CHAR(39) + ')'

                INSERT  INTO #DBInfo_VLF
                        (
                          RecoveryUnitID,
						  FileID,
                          FileSize,
                          StartOffset,
                          FSeqNo,
                          Status,
                          Parity,
                          CreateLSN
                        )
                        EXEC ( @SQL
                            )

                UPDATE  #DBInfo_VLF
                SET     DatabaseNAme = @DatabaseNAme
                WHERE   DatabaseName IS NULL
            END

        FETCH NEXT FROM csrDatabases INTO @DatabaseName, @State_Desc
    END

IF @VersionTick = 1 
    BEGIN
	--Get rid of the rows that I don't care about
        DELETE  FROM #DBInfo_LastKnownGoodCheckDB
        WHERE   Field <> 'dbi_dbccLastKnownGood'
    END ;
 

WITH    LastFullBackup
          AS ( SELECT   bs.database_name,
                        MAX(bs.backup_finish_date) AS BackupDate
               FROM     msdb..backupset bs
               WHERE    bs.TYPE = 'D'
               GROUP BY bs.database_name
             ) ,
        LastTranBackup
          AS ( SELECT   bs.database_name,
                        MAX(bs.backup_finish_date) AS BackupDate
               FROM     msdb..backupset bs
               WHERE    bs.TYPE = 'L'
               GROUP BY bs.database_name
             ) ,
        DataSize
          AS ( SELECT   database_id,
                        SUM(CAST(size AS NUMERIC(18, 4)) * 8 / 1024 / 1024) AS Gig
               FROM     sys.master_files
               WHERE    type IN ( 0, 4 )
               GROUP BY database_id
             ) ,
        LogSize
          AS ( SELECT   database_id,
                        SUM(CAST(size AS NUMERIC(18, 4)) * 8 / 1024 / 1024) AS Gig
               FROM     sys.master_files
               WHERE    type = 1
               GROUP BY database_id
             ),
        DeadLock
          AS (Select [Database], Count(*) as [count] from DBA.dbo.Deadlock_Log
          Where Date = @DL_Date
		  Group By [database]
		  ),
		Blocking
			AS (  
			Select [name], COUNT(*) as [Block_Count] from dba.dbo.blocking
      where tstamp >= DateAdd(day, -1, GETDATE()) and tstamp < GETDATE()
  Group by [name] 
  )


    /*added distinct because there are two rows in the CheckDB command on 2008
             will worry this this later*/
    SELECT  DISTINCT
            SERVERPROPERTY('servername') AS ServerName,
            db.name AS DBName,
            CAST(db.recovery_model_desc AS VARCHAR(255)) AS RecoveryModel,
            CAST(db.is_auto_close_on AS varchar(255)) AS IsAutoClose,
            CAST(db.is_auto_shrink_on AS VARCHAR(255)) AS IsAutoShrink,
            ISNULL(LastFullBackup.BackupDate, '') AS LastFullBackup,
            ISNULL(LastTranBAckup.BackupDate, '') AS LastTranBackup,
            Datasize.Gig AS DataSize,
            LogSize.Gig AS LogSize,
            CAST(ISNULL(LastCHKDB.Value, '') AS DATETIME) AS LastSuccessfulCheckDB,
            ISNULL(VLFCount.VLFCount, 0) AS VLFCount,
            db.State_Desc AS DBState,
            db.is_read_only AS IsReadOnly,
            ISNULL((SELECT name FROM sys.databases inDB WHERE inDB.database_id = db.source_database_id), '') AS SnapOfDB,
            ISNULL(Deadlock.[Count], '0') as Deadlock_Count,
            ISNULL(Blocking.[Block_Count], '0') as Block_Count,
            DHRO.LastFullBackupThresholdDays,
            DHRO.LastTransBackup_Threshold_Hours,
            DHRO.LastSuccessfulCheckDB_Threshold_Days,
            DHRO.VLF_Threshold_Yellow,
            DHRO.AutoClose_Ignore,
            DHRO.AutoShrink_Ignore,
            DHRO.State_Ignore,
            DHRO.Deadlock_Threshold_Count,
            DHRO.Block_Threshold_Count,
            DHRO.VLF_Threshold_Orange
    INTO #TempStorage
    FROM    sys.databases db
            LEFT JOIN DataSize ON db.database_id = DataSize.database_id
            LEFT JOIN LogSize ON db.database_id = logsize.database_id
            LEFT JOIN LastFullBackup ON db.name = LastFullBackup.database_name
            LEFT JOIN LastTranBackup ON db.name = LastTranBackup.database_name
            LEFT JOIN #DBInfo_LastKnownGoodCheckDB LastCHKDB ON db.name = LastCHKDB.DatabaseName
            LEFT JOIN Deadlock on Deadlock.[database] = DB_Name(db.database_id)
            LEFT JOIN Blocking on Blocking.[name] = DB_NAME(db.database_id)
            LEFT JOIN ( SELECT  DatabaseName,
                                COUNT(FileID) AS VLFCount
                        FROM    #DBInfo_VLF
                        GROUP BY DatabaseName
                      ) VLFCount ON db.name = VLFCount.DatabaseName
            Left Join DBA.dbo.DailyHealthReport_Overrides DHRO on DHRO.DatabaseName = db.name
			where db.database_id < 5
    ORDER BY db.name
    
If not exists(Select name from DBA.sys.objects where name = 'Daily_Health_Report_Archive') 
	Begin
		CREATE TABLE [DBA].[dbo].[Daily_Health_Report_Archive](
			[ServerName] [sql_variant] NULL,
			[DBName] [sysname] NOT NULL,
			[RecoveryModel] [varchar](255) NULL,
			[IsAutoClose] [varchar](255) NULL,
			[IsAutoShrink] [varchar](255) NULL,
			[LastFullBackup] [datetime] NOT NULL,
			[LastTranBackup] [datetime] NOT NULL,
			[DataSize] float NULL,
			[LogSize] float NULL,
			[LastSuccessfulCheckDB] [datetime] NULL,
			[VLFCount] [int] NOT NULL,
			[DBState] [nvarchar](60) NULL,
			[IsReadOnly] [bit] NULL,
			[SnapOfDB] [sysname] NULL,
			[Deadlock_Count] [int] NOT NULL,
			[Block_Count] [int] NOT NULL,
			[DateRun] datetime not null Default (GetDate())
		) ON [PRIMARY]
	End
	
Insert Into [DBA].[dbo].[Daily_Health_Report_Archive]
([ServerName], [DBName], [RecoveryModel],[IsAutoClose],[IsAutoShrink],[LastFullBackup],[LastTranBackup],
[DataSize],[LogSize],[LastSuccessfulCheckDB],[VLFCount],[DBState],[IsReadOnly],[SnapOfDB],[Deadlock_Count], [Block_Count])
    Select [ServerName], [DBName], [RecoveryModel],[IsAutoClose],[IsAutoShrink],[LastFullBackup],[LastTranBackup],
[DataSize],[LogSize],[LastSuccessfulCheckDB],[VLFCount],[DBState],[IsReadOnly],[SnapOfDB],[Deadlock_Count], [Block_Count] from #TempStorage
    
Select * from #TempStorage

DROP TABLE #DBInfo_LastKnownGoodCheckDB
DROP TABLE #DBInfo_VLF
DROP TABLE #TempStorage