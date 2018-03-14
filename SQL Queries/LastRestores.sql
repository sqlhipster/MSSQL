WITH LastRestores AS
(
SELECT
    [d].[database_id],
	DatabaseName = [d].[name] ,
    [d].[create_date] ,
    [d].[compatibility_level] ,
    [d].[collation_name] ,
    r.*,
    RowNum = ROW_NUMBER() OVER (PARTITION BY d.Name ORDER BY r.[restore_date] DESC)
FROM master.sys.databases d
LEFT OUTER JOIN msdb.dbo.[restorehistory] r ON r.[destination_database_name] = d.Name
)
SELECT database_id, CHAR(39) + [destination_database_name] + CHAR(39), [restore_date]
FROM [LastRestores]
WHERE [RowNum] = 1
order by restore_date desc