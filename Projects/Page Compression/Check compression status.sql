--sp_whoisactive

--select database_id, count(*) from sys.master_files where type = 0 group by database_id having count(*) > 1 order by database_id

--select * from sys.master_files where database_id in (24,25,26,52) and type = 0

--select 'select count(*) from ' + name from sys.tables
--where name not in
--(
--SELECT [t].[name] AS [Table]--, 
--	--[p].[partition_number] AS [Partition],
--    --[p].[data_compression_desc] AS [Compression], count(*) as pCount
--FROM [sys].[partitions] AS [p]
--INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
--/*WHERE [p].[index_id] in (0,1) and*/  where [p].[data_compression_desc] = 'PAGE'
--) order by name




DECLARE @dbname VARCHAR(50) -- database name  
DECLARE @tblname VARCHAR(50) -- tabl name
DECLARE @sql1 VARCHAR(100)
DECLARE @sql2 VARCHAR(500)
DECLARE db_cursor CURSOR FOR  
SELECT name 
FROM sys.databases 
where database_id > 4 
and database_id not in (18, 17, 16, 15, 14, 19, 13, 20, 21, 43, 44, 11, 38, 37, 46)

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @dbname   

WHILE @@FETCH_STATUS = 0   
BEGIN   
	    --set @sql2 = ('USE ' + QUOTENAME(@dbname)) + 
		--' INSERT into #loadstatement SELECT distinct ''use '' + db_name() + CONCAT('' ALTER table '', QUOTENAME(SCHEMA_NAME(SCHEMA_ID)), ''.'', QUOTENAME(name), '' REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);'') FROM sys.tables t inner join sys.partitions p on p.object_id = t.object_id where p.data_compression_desc = ''NONE'' '
		
		set @sql2 = ('USE ' + QUOTENAME(@dbname)) + ' select db_name(), name from sys.tables
			where name not in
			(
			SELECT [t].[name] AS [Table]
			FROM [sys].[partitions] AS [p]
			INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
			where [p].[data_compression_desc] = ''PAGE''
			)'

			EXECUTE(@sql2)

        FETCH NEXT FROM db_cursor INTO @dbname   
END   

CLOSE db_cursor   
DEALLOCATE db_cursor

