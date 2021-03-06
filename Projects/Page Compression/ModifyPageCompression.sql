--USE [dba]
--ALTER TABLE [dbo].[cpu_details] REBUILD PARTITION = ALL
--WITH 
--(DATA_COMPRESSION = PAGE
--)


--select * from sys.databases

--select name from sys.databases where name like 'daily35%'

DECLARE @name VARCHAR(50) -- database name  
DECLARE @sql VARCHAR(200)
DECLARE db_cursor CURSOR FOR  
SELECT name 
FROM sys.databases 
where database_id > 4

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @name   

WHILE @@FETCH_STATUS = 0   
BEGIN   
	   
	   SET @SQL = N'USE ' + QUOTENAME(@name) + ' EXEC sp_MSforeachtable @command1 = ''alter table ? REBUILD WITH (DATA_COMPRESSION = PAGE);'''

	   EXECUTE(@SQL);

	   --print(@SQL)


	   --EXEC sp_MSforeachtable @command1 = 'alter table ? REBUILD WITH (DATA_COMPRESSION = PAGE);'  

       FETCH NEXT FROM db_cursor INTO @name   
END   

CLOSE db_cursor   
DEALLOCATE db_cursor


--SELECT [t].[name] AS [Table], [p].[partition_number] AS [Partition],
--    [p].[data_compression_desc] AS [Compression]
--FROM [sys].[partitions] AS [p]
--INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
--WHERE [p].[index_id] in (0,1)

--select db_name()
