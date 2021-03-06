create table #loadStatement
(
	id_num int IDENTITY(1,1),
	SqlText varchar(300)
)

DECLARE @dbname VARCHAR(50) -- database name  
DECLARE @tblname VARCHAR(50) -- tabl name
DECLARE @sql1 VARCHAR(100)
DECLARE @sql2 VARCHAR(500)
DECLARE db_cursor CURSOR FOR  
SELECT name
FROM sys.databases 
where database_id > 4
and name not in (
'DAILY353',
'DAILY323',
'DAILY344',
'DAILY352',
'APS340',
'APS344',
'DAILY351',
'DAILY350',
'Daily340',
'LVSQLWEB_CRB',
'LVSQLWEB_CRBExternal_Cloud_PROD',
'STAGE_MNT',
'PayPlusUSA',
'I3_IC',
'STG_BANK_EDW')
order by name

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @dbname   

WHILE @@FETCH_STATUS = 0   
BEGIN   
	    INSERT INTO #loadStatement values ('insert into #tempTime (DatabaseName, StartTime) values (' + CHAR(39) + @dbname + CHAR(39) + ', getdate())')
		
		set @sql2 = ('USE ' + QUOTENAME(@dbname)) +
		' INSERT into #loadstatement SELECT distinct ''use '' + db_name() + ' +
		'CONCAT('' BEGIN TRY ALTER table '', QUOTENAME(SCHEMA_NAME(SCHEMA_ID)), ''.'', QUOTENAME(name),' +
		' '' REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE) END TRY BEGIN CATCH print error_message() END CATCH'') ' +
		'FROM sys.tables t inner join sys.partitions p on p.object_id = t.object_id where p.data_compression_desc = ''NONE'' '
		
		
		EXECUTE(@sql2)

		INSERT INTO #loadStatement values ('select * from #tempTime')
		INSERT INTO #loadStatement values ('update #tempTime set EndTime = getdate() where DatabaseName = ' + CHAR(39) + @dbname + CHAR(39))

        FETCH NEXT FROM db_cursor INTO @dbname   
END   

CLOSE db_cursor   
DEALLOCATE db_cursor




select * from #loadstatement order by id_num
drop table #loadstatement